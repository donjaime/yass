package yass

import (
	"reflect"
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
