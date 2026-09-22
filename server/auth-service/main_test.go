package main

import (
	"encoding/base64"
	"strings"
	"testing"
	"time"
)

func TestPasswordHashDeterministic(t *testing.T) {
	salt := []byte("0123456789abcdef")
	a := pbkdf2SHA256("correct horse battery", salt, 2000)
	b := pbkdf2SHA256("correct horse battery", salt, 2000)
	if string(a) != string(b) {
		t.Fatal("hash is not deterministic")
	}
}

func TestTokenShape(t *testing.T) {
	cfg.Secret = []byte("test-secret")
	tok := signTokenWithCharacter("u1", "alice", "ranger", 7, time.Hour)
	if len(tok) < 30 {
		t.Fatal("token unexpectedly short")
	}
	parts := strings.Split(tok, ".")
	if len(parts) != 2 {
		t.Fatal("token should have body and signature")
	}
	body, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		t.Fatal(err)
	}
	fields := strings.Split(string(body), "|")
	if len(fields) != 5 || fields[0] != "u1" || fields[1] != "alice" || fields[2] != "ranger" || fields[3] != "7" {
		t.Fatalf("unexpected token fields: %v", fields)
	}
}

func TestUsernamePolicy(t *testing.T) {
	for _, ok := range []struct {
		name  string
		valid bool
	}{
		{"player_01", true},
		{"ab", false},
		{"player name", false},
		{"player-name", false},
	} {
		if got := validUsername(ok.name); got != ok.valid {
			t.Fatalf("validUsername(%q)=%v, want %v", ok.name, got, ok.valid)
		}
	}
}