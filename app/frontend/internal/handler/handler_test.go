package handler

import "testing"

type test struct {
	input string
	want  string
}

func TestGenerateHtml(t *testing.T) {
	tests := []test{{
		input: "Hello jack, welcome!",
		want:  "<strong>Hello jack, welcome!</strong>",
	}, {
		input: "Hello tom, welcome!",
		want:  "<strong>Hello tom, welcome!</strong>",
	}}
	for _, tc := range tests {
		got := generateHtml(tc.input)
		if tc.want != got {
			t.Errorf("excepted:%v, got:%v", tc.want, got)
		}
	}

}
