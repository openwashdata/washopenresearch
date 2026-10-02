# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## This repo

Single-context. `docs/` is also the pkgdown output directory, so `docs/agents/` and `docs/adr/` sit next to the built site. Never run `pkgdown::clean_site()` here: it deletes everything in `docs/`, including these files. `pkgdown::build_site()` leaves them in place.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. They get created when terms or decisions actually get resolved.

## File structure

```
/
├── CONTEXT.md
├── docs/
│   ├── adr/
│   │   └── 0001-short-decision-title.md
│   └── agents/
└── R/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a spec, a ticket, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for the user).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0003 (short decision title), but worth reopening because…_
