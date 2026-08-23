# Checks

Run from the repo root. Every check prints findings or nothing. Nothing is a pass.

```bash
# 1. Every backticked slash-name reference resolves to a local or enabled external skill
grep -rhoE '`/[a-z][a-z0-9_-]*`' skills/ | tr -d '`/' | sort -u | while read r; do
  [ "$r" = "tmp" ] && continue
  ls skills/ | grep -qx "$r" || grep -q "\"$r\"" modules/home/packages/skills.nix \
    || echo "unresolved: /$r"
done

# 2. Every sibling-file pointer exists
for f in $(find skills -name "*.md"); do d=$(dirname "$f")
  grep -ohE '`[A-Z][A-Z0-9-]+\.md`|`[a-z-]+/[A-Z][A-Z0-9-]+\.md`' "$f" | tr -d '`' | sort -u |
  while read ref; do
    [[ "$ref" =~ ^(CLAUDE|AGENTS|CONTEXT)\.md$ ]] && continue
    [[ "$ref" == */* ]] && t="skills/$ref" || t="$d/$ref"
    [ -f "$t" ] || echo "missing: $f -> $ref"
  done
done

# 3. No orphan reference files — every sibling is pointed at by some SKILL.md
for f in $(find skills -name "*.md" ! -name "SKILL.md"); do
  grep -rq "$(basename $f)" $(dirname $f)/SKILL.md skills/*/SKILL.md 2>/dev/null \
    || echo "orphan: $f"
done

# 4. Frontmatter name matches directory
for f in skills/*/SKILL.md; do
  n=$(sed -n '2s/^name: //p' "$f")
  [ "$n" = "$(basename $(dirname $f))" ] || echo "name mismatch: $f = '$n'"
done

# 5. Every skill has a description and a Completion section
for f in skills/*/SKILL.md; do
  sed -n '3p' "$f" | grep -q '^description:' || echo "no description: $f"
  grep -q '^## Completion' "$f" || echo "no completion: $f"
done

# 6. Enable list matches disk, both directions
diff <(sed -n '/Local custom skills/,/^$/p' modules/home/packages/skills.nix \
       | grep -o '"[a-z-]*"' | tr -d '"' | sort) <(ls skills/ | sort)

# 7. The build agrees
nix eval '.#darwinConfigurations.Kyles-MacBook-Air.system' --impure >/dev/null && echo "eval ok"
```

## Reading the output

**unresolved** — a pointer to a skill that was renamed or never existed. The most common
breakage after a rename, and invisible until an agent tries to follow it.

**missing / orphan** — a sibling file and its pointer drifted apart. An orphan is usually a
file that was split out and then forgotten, which means its content is unreachable.

**name mismatch / no description / no completion** — the skill will not load, will never be
selected, or will never be finishable. Check 6 catching a difference means `just rebuild`
will fail, not degrade.
