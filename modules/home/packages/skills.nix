_: {
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
        idPrefix = "caveman";
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
      "implement"
      "improve-codebase-architecture"
      "init-project"
      "code-review"
      "diagnosing-bugs"
      "research"
      "triage"
      "grill-interview"
      "grill-with-docs"
      "to-spec"
      "to-tickets"

      # Caveman skills
      "caveman_caveman"

      # Cursor plugins
      "cursor_unslop"
      "cursor-team-kit_deslop"

      # Anthropic skills
      "anthropic_frontend-design"

      # shadcn/ui skills
      "shadcn_shadcn"

      # Emil Kowalski - Animation & Design
      "emil_animate"
      "emil_animation-vocabulary"
      "emil_emil-design-eng"
      "emil_find-animation-opportunities"
      "emil_improve-animations"
      "emil_prototype"
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
}
