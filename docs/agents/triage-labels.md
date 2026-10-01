# Triage Labels

The skills speak in terms of canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

This repo uses `to-spec`, `to-tickets` and `implement` only. Those skills apply a single role, `ready-for-agent`, so it is the only one mapped here. The `triage` skill and its other roles are not in use.

| Label in mattpocock/skills | Label in our tracker | Meaning                                 |
| -------------------------- | -------------------- | --------------------------------------- |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent |

When a skill mentions this role (e.g. "apply the AFK-ready triage label"), use the label string from the table.

If the label does not exist on GitHub yet, create it before applying it: `gh label create ready-for-agent --description "Fully specified, ready for an AFK agent"`.

The repo's own workflow labels (`active`, `blocked`, `parked`) are separate from this vocabulary. Leave them as they are.
