package yass

import (
	"strings"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/donjaime/yass/kit"
)

func TestKitCarriesThePlaybooksAndHook(t *testing.T) {
	names, text := kitSkills()
	want := []string{"yass-log", "yass-plan", "yass-shape", "yass-status", "yass-work"}
	if strings.Join(names, ",") != strings.Join(want, ",") {
		t.Fatalf("kit playbooks = %v, want %v", names, want)
	}
	for _, n := range names {
		if !strings.Contains(text[n], "name: "+n) {
			t.Errorf("%s: no name in its frontmatter", n)
		}
	}
	if b, err := kit.FS.ReadFile(HookPath + "/pre-commit"); err != nil || !strings.HasPrefix(string(b), "#!") {
		t.Errorf("kit hook missing or not a script: %v", err)
	}
}

func parseFront(t *testing.T, text string) map[string]any {
	t.Helper()
	m := fmRE.FindStringSubmatch(text)
	if m == nil {
		t.Fatalf("no frontmatter in %q", text)
	}
	var out map[string]any
	if err := yaml.Unmarshal([]byte(m[1]), &out); err != nil {
		t.Fatalf("frontmatter isn't YAML: %v\n%s", err, m[1])
	}
	return out
}

func TestStampSkill(t *testing.T) {
	_, text := kitSkills()
	for name, src := range text {
		fm := parseFront(t, stampSkill(src, "0.3.0"))
		if fm["name"] != name || fm["description"] == nil {
			t.Errorf("%s: stamping lost name or description: %v", name, fm)
		}
		md, _ := fm["metadata"].(map[string]any)
		if md["yass-version"] != "0.3.0" {
			t.Errorf("%s: metadata = %v, want yass-version 0.3.0", name, fm["metadata"])
		}
	}
	cases := map[string]string{
		"existing metadata kept":    "---\nname: x\nmetadata:\n  owner: me\n---\nbody\n",
		"restamp replaces version":  "---\nname: x\nmetadata:\n  yass-version: \"0.1.0\"\n---\nbody\n",
		"pseudo-version with dirty": "---\nname: x\n---\nbody\n",
	}
	for label, src := range cases {
		v := "0.3.0"
		if strings.HasPrefix(label, "pseudo") {
			v = "0.3.1-0.20261005034705-35527c13ffaf+dirty"
		}
		out := stampSkill(src, v)
		md, _ := parseFront(t, out)["metadata"].(map[string]any)
		if md["yass-version"] != v {
			t.Errorf("%s: yass-version = %v, want %s\n%s", label, md["yass-version"], v, out)
		}
		if label == "existing metadata kept" && md["owner"] != "me" {
			t.Errorf("%s: lost owner: %v", label, md)
		}
		if strings.Count(out, "yass-version") != 1 || !strings.HasSuffix(out, "---\nbody\n") {
			t.Errorf("%s: bad stamp\n%s", label, out)
		}
	}
}

func TestStampHookAndAgents(t *testing.T) {
	h := stampHook("#!/bin/sh\n# YASS hook\nexec yass hook\n", "0.3.0")
	if h != "#!/bin/sh\n# yass-version: 0.3.0\n# YASS hook\nexec yass hook\n" {
		t.Errorf("stampHook = %q", h)
	}
	a := stampAgents(strings.TrimSpace(render("agents.md", nil)), "0.3.0")
	if !strings.HasPrefix(a, "<!-- yass:begin version=0.3.0 (managed by") || !agentsRE.MatchString(a) {
		t.Errorf("stampAgents marker = %q", strings.SplitN(a, "\n", 2)[0])
	}
}

func TestReadStampAndOlder(t *testing.T) {
	dir := t.TempDir()
	put := func(rel, text string) string {
		p := dir + "/" + rel
		if err := write(p, text); err != nil {
			t.Fatal(err)
		}
		return p
	}
	_, text := kitSkills()
	skill := put("a/.agents/skills/yass-work/SKILL.md", stampSkill(text["yass-work"], "0.3.0"))
	old := put("b/.agents/skills/yass-work/SKILL.md", text["yass-work"])
	agents := put("AGENTS.md", "# Ours\n\n"+stampAgents(strings.TrimSpace(render("agents.md", nil)), "0.3.1-0.20261005034705-35527c13ffaf+dirty")+"\n")
	hook := put("tools/yass/githooks/pre-commit", stampHook("#!/bin/sh\necho\n", "0.2.0"))
	for p, want := range map[string]string{skill: "0.3.0", old: "", agents: "0.3.1-0.20261005034705-35527c13ffaf+dirty", hook: "0.2.0"} {
		if got := readStamp(p); got != want {
			t.Errorf("readStamp(%s) = %q, want %q", p, got, want)
		}
	}
	defer func(v string) { binVersion = v }(binVersion)
	binVersion = "v0.3.0"
	for stamp, want := range map[string]bool{"": true, "0.2.0": true, "0.3.0": false, "0.3.1": false, "0.3.0-rc.1": true, "0.3.0+dirty": false} {
		if got := olderThanBinary(stamp); got != want {
			t.Errorf("olderThanBinary(%q) at v0.3.0 = %v, want %v", stamp, got, want)
		}
	}
	binVersion = "dev"
	if olderThanBinary("0.1.0") {
		t.Error("a binary without a version shouldn't call anything older")
	}
}
