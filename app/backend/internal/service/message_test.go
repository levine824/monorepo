package service

import (
	"testing"
)

type test struct {
	input string
	want  string
}

func TestGenerateMessage(t *testing.T) {
	tests := []test{{
		input: "jack",
		want:  "Hello jack, welcome!",
	}, {
		input: "tom",
		want:  "Hi tom, welcome!",
	}, {
		input: "alice",
		want:  "Who are you?",
	}}
	for _, tc := range tests {
		got := generateMessage(tc.input)
		if tc.want != got {
			t.Errorf("excepted:%v, got:%v", tc.want, got)
		}
	}
}
