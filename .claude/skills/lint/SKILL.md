---
name: lint
description: Checks the consistency of the model-maintained wiki (wiki/) — contradictions between pages, broken links, statements without a source, orphan pages. Use when the user says "lint", "check the wiki", "look for contradictions", "is the wiki consistent?".
---

# Wiki lint

First read `wiki/CLAUDE.md`. Then go through **all** the pages of `wiki/` and write a report.
You fix nothing without the user's agreement: the lint reports, the human decides.

## Checks

1. **Links**: every `[[target]]` points to an existing file (`wiki/target.md` or
   `../corpus/...`). List broken links with the page that contains them.
2. **Index**: every page of `wiki/` (except `CLAUDE.md` and `index.md`) is in `index.md`,
   and every index entry matches a file.
3. **Orphans**: pages that no other page links to.
4. **Sources**: every page has a non-empty Sources section, and every source quoted exists in
   `corpus/`. Report the paragraphs stating a fact that no listed source can support (read the
   sources to check when feasible).
5. **Contradictions**: two pages, or two sources of the same page, giving incompatible values
   or rules. Quote both passages. Read the sources themselves, not only the wiki: compare the
   figures each source gives for the same indicator, including their scope ("in the EU",
   "beyond the EU", "in all territories"). A different scope is a contradiction.
6. **Silent omissions and rewordings**: for each source listed on a page, every figure of the
   source on that page's topic must appear on the page, as the source writes it. Report a
   figure that is missing, rounded, or reworded so that it agrees with another source.
7. **Duplicates**: two pages covering the same topic under two names.

## Report format

    ## Wiki lint — YYYY-MM-DD
    - Pages: N · Broken links: N · Orphans: N · Without source: N · Contradictions: N
    ### Contradictions
    - <page A> vs <page B>: "…" / "…"
    ### Broken links
    - <page> → [[target]]
    ### Statements without a source
    - <page>: "…"
    ### Omissions and rewordings
    - <page> ← <source>: "<figure as the source writes it>"
    ### Orphans / duplicates
    - …
    ### Proposals
    - <one action per line, to be approved by the user>

If everything is clean, say so in one line. Don't propose actions for the sake of it.
