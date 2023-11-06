package handler

import "testing"

func TestGenerateHtml(t *testing.T) {
	input := "Hello jack, welcome!"
	want := "<strong>Hello jack, welcome!</strong>"
	got := generateHtml(input)
	if want != got {
		t.Errorf("excepted:%v, got:%v", want, got)
	}
}
