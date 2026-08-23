---
name: add-skill
description: "Add a skill source or local skill to the Nix configuration."
---

# Add Skill

Two files control all skills:

- `flake.nix` — declares sources as flake inputs
- `modules/home/packages/skills.nix` — configures sources, enables skills

Skills sync to `~/.claude/skills`, `~/.agents/skills`, `~/.config/opencode/skills` on `just rebuild`.

## From a GitHub repo

### 1. Find the skill path

Clone and list the SKILL.md files:

```
cd /tmp && git clone --depth 1 <repo-url> && find <repo> -name 'SKILL.md'
```

`subdir` is the **parent of each skill folder** — the directory that _contains_ the `SKILL.md` files (or directories containing them). Never the skill folder itself. The `find` output is the source of truth; the table covers common patterns.

If a repo nests skills under multiple subdirectories (e.g. `skills/engineering/` and `skills/productivity/`), create **one source per subdirectory** — don't try to point a single source at a common ancestor.

| If the tree looks like...    | `subdir`          |
| ---------------------------- | ----------------- |
| `skills/foo/SKILL.md`        | `"skills"`        |
| `pstack/skills/foo/SKILL.md` | `"pstack/skills"` |
| `skills/eng/foo/SKILL.md`    | `"skills/eng"`    |

### 2. Add flake input

In `flake.nix`, under `# Agent Skills`:

```nix
<source-name> = {
  url = "github:<owner>/<repo>";
  flake = false;
};
```

### 3. Add source

In `modules/home/packages/skills.nix`, under `programs.agent-skills.sources`:

```nix
<source-name> = {
  input = "<source-name>";       # must match flake input name
  subdir = "<path-to-skills>";   # relative to repo root
  idPrefix = "<prefix>";         # namespaces IDs (e.g. "matt-eng", "cursor")
};
```

### 4. Enable skills

Add to `programs.agent-skills.skills.enable`:

```nix
"<idPrefix>_<skill-name>"        # e.g. "cursor_unslop"
"<idPrefix>_<category>_<name>"   # e.g. "matt-eng_tdd"
```

Skill ID format: `<idPrefix>_<relative-path-from-subdir>` (underscores, not slashes).

### 5. Verify

```
git add flake.nix modules/home/packages/skills.nix
nix flake update <source-name>
nix build '.#darwinConfigurations.Kyles-MacBook-Air.config.home-manager.users.kylewong.programs.agent-skills.bundlePath' --no-link --print-out-paths
```

Confirm the skill appears in the output.

## Local skill

1. Create `skills/<name>/SKILL.md`. The frontmatter `name:` must equal the directory name.
2. Add `"<name>"` to `skills.enable` — the `local` source is pre-configured.
3. Add a row to `AI_NOTES.md`, or the skill is invisible to you next month.

What goes inside the file — the description, the hierarchy, the completion criterion — is `/writing-for-agents`. It ships `writing-for-agents/CHECKS.md`, which catches a name that does not match its directory and an enable list out of step with disk.

## Skill sources

Browse at [skills.sh](https://skills.sh/) or see `add-skill/SOURCES.md` for recommended repos.

## Completion

Done when: the flake input is added, the source is configured in skills.nix, the skill is enabled, and `nix build` confirms it appears in the output. Checkable: the `nix build` above succeeds and the skill's id appears in the bundle output.
