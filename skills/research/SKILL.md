---
name: research
description: "Investigate a question against primary sources."
---

# Research

Investigate a question against **primary sources** (official docs, source code, specs, first-party APIs), not secondary write-ups.

## Process

1. Dispatch a **quick** subagent to do the background research, so you keep working while it reads. Its job:
   - Follow every claim back to the source that owns it.
   - Write findings to a single Markdown file, citing each claim's source.
   - Save where the repo keeps such notes; match existing convention, or put it somewhere sensible and say where.
2. When the subagent returns, read the file and review its contents.
3. If the research is incomplete or sources are ambiguous, resolve the harder questions yourself.

## Completion

Done when: every claim in the findings file cites a primary source, no secondary write-ups are used, and the file is saved in the repo's convention. Checkable: dispatch a **quick** subagent to grep the findings file for URLs and verify they point to primary sources (docs, specs, source code).
