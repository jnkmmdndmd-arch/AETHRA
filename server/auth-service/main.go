package main

/*
#cgo LDFLAGS: -lsqlite3
#include <sqlite3.h>
#include <stdlib.h>
*/
import "C"

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
	"unsafe"
)

type Config struct {
	DBPath string
	Secret []byte
	Listen string
}

var cfg Config
var rateMu sync.Mutex
var rateBuckets = map[string][]time.Time{}

func sqlExec(db *C.sqlite3, query string) error {
	cquery := C.CString(query)
	defer C.free(unsafe.Pointer(cquery))
	var errMsg *C.char
	rc := C.sqlite3_exec(db, cquery, nil, nil, &errMsg)
	if rc != C.SQLITE_OK {
		msg := "unknown"
		if errMsg != nil {
			msg = C.GoString(errMsg)
			C.sqlite3_free(unsafe.Pointer(errMsg))
		}
		return fmt.Errorf("sqlite error: %s", msg)
	}
	return nil
}

func openDB(path, schemaPath string) (*C.sqlite3, error) {
	cpath := C.CString(path)
	defer C.free(unsafe.Pointer(cpath))
	var db *C.sqlite3
	if C.sqlite3_open(cpath, &db) != C.SQLITE_OK {
		return nil, errors.New("cannot open sqlite database")
	}
	if err := sqlExec(db, `PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;`); err != nil {
		C.sqlite3_close(db)
		return nil, err
	}
	schema, err := os.ReadFile(schemaPath)
	if err != nil {
		C.sqlite3_close(db)
		return nil, err
	}
	if err := sqlExec(db, string(schema)); err != nil {
		C.sqlite3_close(db)
		return nil, err
	}
	if err := ensureAvatarColumn(db); err != nil {
		C.sqlite3_close(db)
		return nil, err
	}
	return db, nil
}

func ensureAvatarColumn(db *C.sqlite3) error {
	cquery := C.CString("PRAGMA table_info(users);")
	defer C.free(unsafe.Pointer(cquery))
	var stmt *C.sqlite3_stmt
	if C.sqlite3_prepare_v2(db, cquery, -1, &stmt, nil) != C.SQLITE_OK {
		return errors.New("cannot inspect users table")
	}
	defer C.sqlite3_finalize(stmt)
	for C.sqlite3_step(stmt) == C.SQLITE_ROW {
		namePtr := C.sqlite3_column_text(stmt, 1)
		if namePtr != nil && C.GoString((*C.char)(unsafe.Pointer(namePtr))) == "avatar_id" {
			return nil
		}
	}
	return sqlExec(db, "ALTER TABLE users ADD COLUMN avatar_id INTEGER NOT NULL DEFAULT 0;")
}

func randomID() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b)
}

func pbkdf2SHA256(password string, salt []byte, iterations int) []byte {
	out := make([]byte, 32)
	u := make([]byte, 32)
	msg := append(append([]byte{}, salt...), 0, 0, 0, 1)
	mac := hmac.New(sha256.New, []byte(password))
	mac.Write(msg)
	u = mac.Sum(nil)
	copy(out, u)
	for i := 1; i < iterations; i++ {
		mac = hmac.New(sha256.New, []byte(password))
		mac.Write(u)
		u = mac.Sum(nil)
		for j := range out {
			out[j] ^= u[j]
		}
	}
	return out
}

func signToken(uid, username string, ttl time.Duration) string {
	return signTokenWithCharacter(uid, username, "ranger", 0, ttl)
}

func signTokenWithCharacter(uid, username, character string, avatarID int, ttl time.Duration) string {
	exp := time.Now().Add(ttl).Unix()
	body := fmt.Sprintf("%s|%s|%s|%d|%d", uid, username, character, avatarID, exp)
	mac := hmac.New(sha256.New, cfg.Secret)
	mac.Write([]byte(body))
	sig := hex.EncodeToString(mac.Sum(nil))
	return base64.RawURLEncoding.EncodeToString([]byte(body)) + "." + sig
}

type authReq struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	Character string `json:"character"`
	AvatarID  int    `json:"avatar_id"`
}
type authResp struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	Character string `json:"character"`
	AvatarID  int    `json:"avatar_id"`
	Token     string `json:"token"`
}

func tokenHash(token string) []byte {
	h := sha256.Sum256([]byte(token))
	return h[:]
}

func recordSession(db *C.sqlite3, userID, token string, exp int64) error {
	q := fmt.Sprintf("INSERT INTO sessions(id,user_id,token_hash,created_at,expires_at,revoked_at) VALUES('%s','%s',X'%s',%d,%d,NULL);", sqlSafe(randomID()), sqlSafe(userID), hex.EncodeToString(tokenHash(token)), time.Now().Unix(), exp)
	return sqlExec(db, q)
}

func verifySession(db *C.sqlite3, userID, token string) bool {
	q := fmt.Sprintf("SELECT expires_at,revoked_at FROM sessions WHERE user_id='%s' AND token_hash=X'%s' LIMIT 1;", sqlSafe(userID), hex.EncodeToString(tokenHash(token)))
	c := C.CString(q)
	defer C.free(unsafe.Pointer(c))
	var stmt *C.sqlite3_stmt
	if C.sqlite3_prepare_v2(db, c, -1, &stmt, nil) != C.SQLITE_OK {
		return false
	}
	defer C.sqlite3_finalize(stmt)
	if C.sqlite3_step(stmt) != C.SQLITE_ROW {
		return false
	}
	exp := int64(C.sqlite3_column_int64(stmt, 0))
	revokedPtr := C.sqlite3_column_type(stmt, 1)
	if revokedPtr != 5 && C.sqlite3_column_int64(stmt, 1) > 0 {
		return false
	}
	return time.Now().Unix() <= exp
}

func revokeSession(db *C.sqlite3, token string) error {
	q := fmt.Sprintf("UPDATE sessions SET revoked_at=%d WHERE token_hash=X'%s' AND revoked_at IS NULL;", time.Now().Unix(), hex.EncodeToString(tokenHash(token)))
	return sqlExec(db, q)
}

func allowRate(key string, limit int, window time.Duration) bool {
	now := time.Now()
	rateMu.Lock()
	defer rateMu.Unlock()
	bucket := rateBuckets[key]
	cutoff := now.Add(-window)
	kept := bucket[:0]
	for _, t := range bucket {
		if t.After(cutoff) {
			kept = append(kept, t)
		}
	}
	if len(kept) >= limit {
		rateBuckets[key] = kept
		return false
	}
	rateBuckets[key] = append(kept, now)
	return true
}

func clientKey(r *http.Request) string {
	return r.RemoteAddr + "|" + r.URL.Path
}

func recordAudit(db *C.sqlite3, userID, action, ip string, metadata map[string]any) {
	encoded, _ := json.Marshal(metadata)
	q := fmt.Sprintf("INSERT INTO audit_logs(user_id,action,ip,created_at,metadata) VALUES('%s','%s','%s',%d,'%s');", sqlSafe(userID), sqlSafe(action), sqlSafe(ip), time.Now().Unix(), sqlSafe(string(encoded)))
	_ = sqlExec(db, q)
}

func main() {
	secret := strings.TrimSpace(os.Getenv("AETHRA_AUTH_SECRET"))
	if secret == "" {
		panic("AETHRA_AUTH_SECRET is required; refusing to start with an insecure default")
	}
	cfg = Config{DBPath: getenv("AETHRA_DB", "aethra.db"), Secret: []byte(secret), Listen: getenv("AETHRA_AUTH_LISTEN", ":8090")}
	db, err := openDB(cfg.DBPath, "../database_schema.sql")
	if err != nil {
		panic(err)
	}
	defer C.sqlite3_close(db)
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", 405)
			return
		}
		writeJSON(w, 200, map[string]bool{"ok": true})
	})
	mux.HandleFunc("/v1/auth/register", func(w http.ResponseWriter, r *http.Request) { handleRegister(db, w, r) })
	mux.HandleFunc("/v1/auth/login", func(w http.ResponseWriter, r *http.Request) { handleLogin(db, w, r) })
	mux.HandleFunc("/v1/auth/verify", func(w http.ResponseWriter, r *http.Request) { handleVerify(db, w, r) })
	mux.HandleFunc("/v1/auth/logout", func(w http.ResponseWriter, r *http.Request) { handleLogout(db, w, r) })
	mux.HandleFunc("/v1/profile", func(w http.ResponseWriter, r *http.Request) { handleProfile(db, w, r) })
	handler := rateLimitMiddleware(loggingMiddleware(mux))
	srv := &http.Server{Addr: cfg.Listen, Handler: handler, ReadHeaderTimeout: 5 * time.Second, IdleTimeout: 30 * time.Second, MaxHeaderBytes: 16 << 10}
	fmt.Println("AETHRA auth service listening on", cfg.Listen)
	cert := strings.TrimSpace(os.Getenv("AETHRA_AUTH_TLS_CERT"))
	key := strings.TrimSpace(os.Getenv("AETHRA_AUTH_TLS_KEY"))
	if (cert == "") != (key == "") {
		panic("AETHRA_AUTH_TLS_CERT and AETHRA_AUTH_TLS_KEY must be provided together")
	}
	if cert != "" {
		if err := srv.ListenAndServeTLS(cert, key); err != nil && !errors.Is(err, http.ErrServerClosed) {
			panic(err)
		}
		return
	}
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		panic(err)
	}
}

func handleRegister(db *C.sqlite3, w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "method not allowed", 405)
		return
	}
	var req authReq
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if json.NewDecoder(r.Body).Decode(&req) != nil {
		http.Error(w, "invalid JSON", 400)
		return
	}
	req.Username = strings.TrimSpace(req.Username)
	if len(req.Username) < 3 || len(req.Username) > 24 || len(req.Password) < 8 || len(req.Password) > 128 {
		http.Error(w, "account policy failed", 400)
		return
	}
	if req.Character == "" {
		req.Character = "ranger"
	}
	if req.Character != "ranger" && req.Character != "engineer" && req.Character != "shadow" && req.Character != "grove" {
		http.Error(w, "invalid character", 400)
		return
	}
	if req.AvatarID < 0 || req.AvatarID >= 30 {
		http.Error(w, "invalid avatar", 400)
		return
	}
	uid := randomID()
	salt := make([]byte, 16)
	_, _ = rand.Read(salt)
	hash := pbkdf2SHA256(req.Password, salt, 150000)
	packed := append(salt, hash...)
	now := time.Now().Unix()
	q := fmt.Sprintf("INSERT INTO users(id,username,password_hash,character_id,avatar_id,created_at,updated_at) VALUES('%s','%s',X'%s','%s',%d,%d,%d);", sqlSafe(uid), sqlSafe(req.Username), hex.EncodeToString(packed), sqlSafe(req.Character), req.AvatarID, now, now)
	if err := sqlExec(db, q); err != nil {
		http.Error(w, "account already exists or database error", 409)
		return
	}
	token := signTokenWithCharacter(uid, req.Username, req.Character, req.AvatarID, 24*time.Hour)
	if err := recordSession(db, uid, token, time.Now().Add(24*time.Hour).Unix()); err != nil {
		http.Error(w, "session creation failed", 500)
		return
	}
	recordAudit(db, uid, "register", r.RemoteAddr, map[string]any{"character": req.Character})
	writeJSON(w, 200, authResp{UserID: uid, Username: req.Username, Character: req.Character, AvatarID: req.AvatarID, Token: token})
}

func handleLogin(db *C.sqlite3, w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "method not allowed", 405)
		return
	}
	var req authReq
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	if json.NewDecoder(r.Body).Decode(&req) != nil {
		http.Error(w, "invalid JSON", 400)
		return
	}
	uname := sqlSafe(strings.TrimSpace(req.Username))
	stmtSQL := fmt.Sprintf("SELECT id,password_hash,character_id,avatar_id FROM users WHERE username='%s' LIMIT 1;", uname)
	c := C.CString(stmtSQL)
	defer C.free(unsafe.Pointer(c))
	var stmt *C.sqlite3_stmt
	if C.sqlite3_prepare_v2(db, c, -1, &stmt, nil) != C.SQLITE_OK {
		http.Error(w, "database error", 500)
		return
	}
	defer C.sqlite3_finalize(stmt)
	if C.sqlite3_step(stmt) != C.SQLITE_ROW {
		http.Error(w, "invalid credentials", 401)
		return
	}
	idPtr := C.sqlite3_column_text(stmt, 0)
	blob := C.sqlite3_column_blob(stmt, 1)
	n := C.sqlite3_column_bytes(stmt, 1)
	charPtr := C.sqlite3_column_text(stmt, 2)
	avatarID := int(C.sqlite3_column_int(stmt, 3))
	uid := C.GoString((*C.char)(unsafe.Pointer(idPtr)))
	char := C.GoString((*C.char)(unsafe.Pointer(charPtr)))
	packed := C.GoBytes(blob, n)
	if len(packed) < 48 || subtle.ConstantTimeCompare(pbkdf2SHA256(req.Password, packed[:16], 150000), packed[16:]) != 1 {
		http.Error(w, "invalid credentials", 401)
		return
	}
	token := signTokenWithCharacter(uid, req.Username, char, avatarID, 24*time.Hour)
	if err := recordSession(db, uid, token, time.Now().Add(24*time.Hour).Unix()); err != nil {
		http.Error(w, "session creation failed", 500)
		return
	}
	recordAudit(db, uid, "login", r.RemoteAddr, nil)
	writeJSON(w, 200, authResp{UserID: uid, Username: req.Username, Character: char, AvatarID: avatarID, Token: token})
}

func handleVerify(db *C.sqlite3, w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodPost {
		http.Error(w, "method not allowed", 405)
		return
	}
	token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		http.Error(w, "invalid token", 401)
		return
	}
	body, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		http.Error(w, "invalid token", 401)
		return
	}
	mac := hmac.New(sha256.New, cfg.Secret)
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	if subtle.ConstantTimeCompare([]byte(expected), []byte(parts[1])) != 1 {
		http.Error(w, "invalid token", 401)
		return
	}
	fields := strings.Split(string(body), "|")
	if len(fields) != 5 {
		http.Error(w, "invalid token", 401)
		return
	}
	var exp int64
	if _, err := fmt.Sscan(fields[4], &exp); err != nil || time.Now().Unix() > exp {
		http.Error(w, "expired token", 401)
		return
	}
	if !verifySession(db, fields[0], token) {
		http.Error(w, "session revoked or expired", 401)
		return
	}
	writeJSON(w, 200, map[string]any{"ok": true, "user_id": fields[0], "username": fields[1], "character": fields[2], "avatar_id": atoiSafe(fields[3])})
}

func handleLogout(db *C.sqlite3, w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", 405)
		return
	}
	token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if token == "" || revokeSession(db, token) != nil {
		http.Error(w, "logout failed", 400)
		return
	}
	userID := ""
	if parts := strings.Split(token, "."); len(parts) == 2 {
		if body, err := base64.RawURLEncoding.DecodeString(parts[0]); err == nil {
			fields := strings.Split(string(body), "|")
			if len(fields) == 5 {
				userID = fields[0]
			}
		}
	}
	recordAudit(db, userID, "logout", r.RemoteAddr, map[string]any{"revoked": true})
	writeJSON(w, 200, map[string]bool{"ok": true})
}

func handleProfile(db *C.sqlite3, w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", 405)
		return
	}
	token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		http.Error(w, "invalid token", 401)
		return
	}
	body, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		http.Error(w, "invalid token", 401)
		return
	}
	fields := strings.Split(string(body), "|")
	if len(fields) != 5 || !verifySession(db, fields[0], token) {
		http.Error(w, "invalid session", 401)
		return
	}
	var req struct { AvatarID int `json:"avatar_id"` }
	r.Body = http.MaxBytesReader(w, r.Body, 4096)
	if json.NewDecoder(r.Body).Decode(&req) != nil || req.AvatarID < 0 || req.AvatarID >= 30 {
		http.Error(w, "invalid avatar", 400)
		return
	}
	q := fmt.Sprintf("UPDATE users SET avatar_id=%d, updated_at=%d WHERE id='%s';", req.AvatarID, time.Now().Unix(), sqlSafe(fields[0]))
	if err := sqlExec(db, q); err != nil {
		http.Error(w, "profile update failed", 500)
		return
	}
	character := fields[2]
	username := fields[1]
	newToken := signTokenWithCharacter(fields[0], username, character, req.AvatarID, 24*time.Hour)
	if err := recordSession(db, fields[0], newToken, time.Now().Add(24*time.Hour).Unix()); err != nil {
		http.Error(w, "session creation failed", 500)
		return
	}
	_ = revokeSession(db, token)
	writeJSON(w, 200, map[string]any{"username": username, "character": character, "avatar_id": req.AvatarID, "token": newToken})
}

func atoiSafe(v string) int { var n int; _, _ = fmt.Sscan(v, &n); if n < 0 || n > 29 { return 0 }; return n }
func sqlSafe(v string) string { return strings.ReplaceAll(v, "'", "''") }
func getenv(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
func rateLimitMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !allowRate(clientKey(r), 60, time.Minute) {
			http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { next.ServeHTTP(w, r) })
}
