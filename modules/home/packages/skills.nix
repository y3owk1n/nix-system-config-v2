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

      # Matt Pocock's skills (engineering)
      matt-eng = {
        input = "mattpocock-skills";
        subdir = "skills/engineering";
        idPrefix = "matt-eng";
      };

      # Matt Pocock's skills (productivity)
      matt-prod = {
        input = "mattpocock-skills";
        subdir = "skills/productivity";
        idPrefix = "matt-prod";
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

      # Matt Pocock - Engineering
      "matt-eng_ask-matt"
      "matt-eng_code-review"
      "matt-eng_codebase-design"
      "matt-eng_diagnosing-bugs"
      "matt-eng_domain-modeling"
      "matt-eng_grill-with-docs"
      "matt-eng_implement"
      "matt-eng_improve-codebase-architecture"
      "matt-eng_prototype"
      "matt-eng_research"
      "matt-eng_resolving-merge-conflicts"
      "matt-eng_setup-matt-pocock-skills"
      "matt-eng_tdd"
      "matt-eng_to-spec"
      "matt-eng_to-tickets"
      "matt-eng_triage"
      "matt-eng_wayfinder"
      "matt-eng_wizard"

      # Matt Pocock - Productivity
      "matt-prod_grill-me"
      "matt-prod_grilling"
      "matt-prod_writing-for-agents"
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
