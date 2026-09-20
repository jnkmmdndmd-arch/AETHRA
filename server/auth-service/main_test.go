package main

import (
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
	tok := signToken("u1", "alice", time.Hour)
	if len(tok) < 30 {
		t.Fatal("token unexpectedly short")
	}
}
