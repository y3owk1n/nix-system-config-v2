---
name: research
description: "Answer a question from primary sources when getting it wrong would be expensive — APIs, versions, protocol details, security claims."
---

# Research

**Primary source** means the artefact that owns the fact: official docs, the source code, the spec, the first-party API reference, the changelog. A blog post explaining any of those is secondary — useful for finding the primary source, never for citing.

## Process

### 1. Split the question

List every claim the answer depends on. A question that looks like one fact is usually four, and the wrong one is the one nobody checked.

### 2. Follow each claim to the artefact that owns it

- A version, flag, or signature → the source or the release notes for that version, not the docs homepage.
- A behaviour → the code, or a spec section number.
- A security or licensing claim → the primary text. Never a summary of it.

Dispatch parallel subagents when claims are independent. Read the returned file rather than trusting the summary.

### 3. Record what you could not verify

An unverifiable claim is a finding, not a gap to paper over. Say which source you wanted, what you found instead, and how confident that leaves you.

### 4. Write it up

One Markdown file. Every claim carries its source URL or `path:line`. Match the repo's convention for notes; if there is none, put it in `$TMPDIR` and say where.

## Completion

Done when: every claim in the findings file cites a primary source or is explicitly marked unverified with the reason, and no conclusion rests on a secondary write-up. Checkable: read the findings file and confirm each claim has a citation, and that each cited URL is a docs/spec/source/changelog host rather than a blog or aggregator.
