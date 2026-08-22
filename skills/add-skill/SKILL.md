---
name: add-skill
description: "Adds a skill source or individual skill to the Nix configuration. Use when installing from skills.sh, a GitHub repo, or creating a local skill."
---

# Add Skill

Two files control all skills:

- `flake.nix` — declares sources as flake inputs
- `modules/home/packages/skills.nix` — configures sources, enables skills

Skills sync to `~/.claude/skills`, `~/.agents/skills`, `~/.config/opencode/skills` on `just rebuild`.

## From a GitHub repo

### 1. Find the skill path

```bash
cd /tmp && git clone --depth 1 <repo-url> && find <repo> -name 'SKILL.md'
```

Common patterns and their `subdir` values:
| Path | `subdir` |
|---|---|
| `skills/<name>/SKILL.md` | `"skills"` |
| `<plugin>/skills/<name>/SKILL.md` | `"<plugin>/skills"` |
| `skills/<cat>/<name>/SKILL.md` | `"skills"` + `filter.maxDepth = 2` |

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
  idPrefix = "<prefix>";         # namespaces IDs (e.g. "matt", "cursor")
};
```

### 4. Enable skills

Add to `programs.agent-skills.skills.enable`:

```nix
"<idPrefix>/<skill-name>"        # e.g. "cursor/unslop"
"<idPrefix>/<category>/<name>"   # e.g. "matt/engineering/tdd"
```

Skill ID format: `<idPrefix>/<relative-path-from-subdir>`.

### 5. Verify

```bash
git add flake.nix modules/home/packages/skills.nix
nix flake update <source-name>
nix build '.#darwinConfigurations.Kyles-MacBook-Air.config.home-manager.users.kylewong.programs.agent-skills.bundlePath' --no-link --print-out-paths
```

Confirm the skill appears in the output.

## Local skill

1. Create `skills/<skill-name>/SKILL.md`:

```markdown
---
name: <skill-name>
description: "<what it does and when to use it>"
---

# <Skill Name>

<instructions>
```

2. Add `"<skill-name>"` to `skills.enable` — the `local` source is pre-configured.

## Skill sources

Browse at [skills.sh](https://skills.sh/) or these repos:

- `anthropics/skills` — document handling, design
- `mattpocock/skills` — engineering, TDD, debugging
- `cursor/plugins` — Cursor ecosystem
- `vercel-labs/agent-skills` — React/Next.js
- `emilkowalski/skills` — animation, design
- `shadcn-ui/ui` — shadcn/ui components
