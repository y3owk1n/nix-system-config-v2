{ lib, ... }:
{
  # Agent Skills declarative configuration
  # Uses agent-skills-nix to manage skills across all harnesses

  programs.agent-skills = {
    enable = true;

    # Declare skill sources
    sources = {
      # Local skills embedded in this repo
      local = {
        path = ../../../skills;
      };

      # Matt Pocock's skills (engineering, productivity, misc)
      matt = {
        input = "mattpocock-skills";
        subdir = "skills";
        idPrefix = "matt";
        filter.maxDepth = 2;
      };

      # Cursor plugins (unslop, etc.)
      cursor = {
        input = "cursor-plugins";
        subdir = "pstack/skills";
        idPrefix = "cursor";
      };

      # Cursor team kit skills (deslop, etc.)
      cursor-team-kit = {
        input = "cursor-plugins";
        subdir = "cursor-team-kit/skills";
        idPrefix = "cursor-team-kit";
      };

      # Anthropic skills (frontend-design, etc.)
      anthropic = {
        input = "anthropics-skills";
        subdir = "skills";
        idPrefix = "anthropic";
      };

      # shadcn/ui skills
      shadcn = {
        input = "shadcn-ui";
        subdir = "skills";
        idPrefix = "shadcn";
      };

      # Emil Kowalski's skills (animation, design, etc.)
      emil = {
        input = "emil-skills";
        subdir = "skills";
        idPrefix = "emil";
      };

      # Caveman skills (compressed communication)
      caveman = {
        input = "caveman-skills";
        subdir = "skills";
        idPrefix = "julius";
      };
    };

    # Enable specific skills from the catalog
    skills.enable = [
      # Local custom skills
      "ship-spec"
      "ship-ticket"
      "add-skill"
      "create-pr"
      "find-skills"

      # Caveman skills
      "julius/caveman"

      # Cursor plugins
      "cursor/unslop"
      "cursor-team-kit/deslop"

      # Anthropic skills
      "anthropic/frontend-design"

      # shadcn/ui skills
      "shadcn/shadcn"

      # Emil Kowalski - Animation & Design
      "emil/animate"
      "emil/animation-vocabulary"
      "emil/apple-design"
      "emil/ask-sonner"
      "emil/emil-design-eng"
      "emil/find-animation-opportunities"
      "emil/improve-animations"
      "emil/pick-ui-library"
      "emil/prototype"

      # Matt Pocock - Engineering
      "matt/engineering/ask-matt"
      "matt/engineering/code-review"
      "matt/engineering/codebase-design"
      "matt/engineering/diagnosing-bugs"
      "matt/engineering/domain-modeling"
      "matt/engineering/grill-with-docs"
      "matt/engineering/implement"
      "matt/engineering/improve-codebase-architecture"
      "matt/engineering/prototype"
      "matt/engineering/research"
      "matt/engineering/resolving-merge-conflicts"
      "matt/engineering/setup-matt-pocock-skills"
      "matt/engineering/tdd"
      "matt/engineering/to-spec"
      "matt/engineering/to-tickets"
      "matt/engineering/triage"
      "matt/engineering/wayfinder"
      "matt/engineering/wizard"

      # Matt Pocock - Productivity
      "matt/productivity/grill-me"
      "matt/productivity/grilling"
      "matt/productivity/writing-for-agents"
    ];

    # Enable target harnesses for skill sync
    targets = {
      # Claude Code (~/.claude/skills)
      claude.enable = true;

      # Freebuff / generic agents (~/.agents/skills)
      agents.enable = true;

      # OpenCode (~/.config/opencode/skills)
      opencode.enable = true;
    };
  };

  # Flatten nested skills for Claude (it only scans one level deep)
  home.activation.flattenClaudeSkills = lib.hm.dag.entryAfter [ "agent-skills" ] ''
    claude_skills="$HOME/.claude/skills"
    if [ -d "$claude_skills" ]; then
      # Follow symlinks (-L) and find SKILL.md files nested more than 1 level deep
      find -L "$claude_skills" -mindepth 3 -name 'SKILL.md' | while read -r skill_file; do
        skill_dir="$(dirname "$skill_file")"
        skill_name="$(basename "$skill_dir")"
        target="$claude_skills/$skill_name"
        # Only create if not already a direct child
        if [ ! -e "$target" ] && [ ! -L "$target" ]; then
          ln -s "$skill_dir" "$target"
        fi
      done
    fi
  '';
}
