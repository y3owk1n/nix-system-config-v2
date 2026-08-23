# Rendering a feature file to a spec issue

The issue body is derived. Every section below is copied or lightly reflowed from
`prd/features/<slug>.md` — nothing is invented at render time. If a section would
be empty, drop it rather than writing filler.

```md
> Generated from `prd/features/<slug>.md`. Edit the PRD file, not this issue.

## Problem

{from ## Problem}

## Solution

{from ## Solution}

## User stories

{from ## User stories}

## Behaviours touched

{from ## Behaviours touched, each entry expanded with the text of the behaviour
it references so a reader on GitHub does not need the repo open}

## Seams

{from ## Seams}

## Decisions

{from ## Decisions}

## Out of scope

{from ## Out of scope}

<!-- prd-source: prd/features/<slug>.md@<blob-sha> -->
```

## The stamp

`git hash-object prd/features/<slug>.md` — the blob hash of the working-tree file.

Blob hash, not commit sha: it changes when and only when the file's content changes,
so a drift check is an exact comparison rather than a heuristic about which commits
touched what.

The stamp is an HTML comment, so it is invisible in the rendered issue and survives
`gh issue view --json body` intact.

## Re-render

`/ship` compares the stamp to the current hash before working any ticket. On a
mismatch it re-renders this body and edits the issue in place — same issue number,
same comments, same sub-issue links. Never open a second spec issue for a changed
feature file.
