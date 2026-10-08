package yass

import (
	"reflect"
	"strings"
	"testing"
)

func TestByCreated(t *testing.T) {
	mk := func(name, created string) *Change {
		return &Change{Name: name, Meta: map[string]string{"created": created}}
	}
	cs := []*Change{ // as loaded: by name
		mk("2026-10-04-zebra", ""),
		mk("2026-10-05-apple", "2026-10-05T15:00:00Z"),
		mk("2026-10-05-bad-stamp", "yesterday"),
		mk("2026-10-05-mango", ""),
		mk("2026-10-05-zebra", "2026-10-05T10:00:00-04:00"),
		mk("no-date", ""),
	}
	byCreated(cs)
	var got []string
	for _, c := range cs {
		got = append(got, c.Name)
	}
	want := []string{"no-date", "2026-10-04-zebra", "2026-10-05-bad-stamp", "2026-10-05-mango", "2026-10-05-zebra", "2026-10-05-apple"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("byCreated = %q, want %q", got, want)
	}
}

func TestChangeFolder(t *testing.T) {
	for _, tc := range []struct{ path, want string }{
		{"archive/2026-10-01-a/change.md", "archive/2026-10-01-a"},
		{"archive/2026/10/2026-10-01-a/change.md", "archive/2026/10/2026-10-01-a"},
		{"archive/2026/10/2026-10-01-a/2026-10-02-p/change.md", "archive/2026/10/2026-10-01-a"},
		{"changes/2026/10/x/change.md", "changes/2026"},
	} {
		if got := changeFolder(strings.Split(tc.path, "/")); got != tc.want {
			t.Errorf("changeFolder(%q) = %q, want %q", tc.path, got, tc.want)
		}
	}
}
