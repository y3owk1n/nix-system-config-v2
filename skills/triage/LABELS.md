# Label vocabulary

### Type labels (exactly one per issue)

| Label          | Purpose                                 |
| -------------- | --------------------------------------- |
| `type:bug`     | Something is broken                     |
| `type:feature` | New feature or improvement              |
| `type:spec`    | Parent spec (parent work)               |
| `type:ticket`  | Implementation ticket (child of a spec) |
| `type:docs`    | Documentation only                      |
| `type:chore`   | Maintenance, dependencies, CI           |

### Status labels (exactly one per issue)

| Label                    | Purpose                                  |
| ------------------------ | ---------------------------------------- |
| `status:needs-triage`    | Maintainer needs to evaluate             |
| `status:needs-info`      | Waiting on reporter for more information |
| `status:ready-for-agent` | An agent can pick this up                |
| `status:ready-for-human` | Needs human implementation               |
| `status:in-progress`     | Work has started                         |
| `status:blocked`         | Cannot proceed, depends on another issue |
| `status:wontfix`         | Will not be actioned                     |

### Priority labels (exactly one per issue)

| Label               | Purpose                    |
| ------------------- | -------------------------- |
| `priority:critical` | Blocks everything, fix now |
| `priority:high`     | Important, fix soon        |
| `priority:medium`   | Normal priority            |
| `priority:low`      | Nice to have               |

### Scope labels (one or more per issue)

| Label            | Purpose                        |
| ---------------- | ------------------------------ |
| `scope:backend`  | Server-side, APIs, databases   |
| `scope:frontend` | UI, components, client-side    |
| `scope:infra`    | CI, deployment, infrastructure |
| `scope:cli`      | Command-line interface         |
| `scope:api`      | API contracts, schemas         |
| `scope:data`     | Data models, migrations        |

## Who reads this

`/triage` assigns these. `/spec` inherits `priority:*` and `scope:*` from the parent
spec onto every ticket it cuts, and `/ship` moves `status:*` as tickets start, block, and
merge. Change a label here and all three follow.

Propose new `scope:*` labels as needed. Keep the set small and orthogonal.
