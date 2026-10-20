---
name: lint
description: Checks the consistency of the model-maintained wiki (wiki/) — OKF headers, footnotes and sources, broken links, contradictions between pages, statements without a source, silent omissions, orphan pages. Use when the user says "lint", "check the wiki", "look for contradictions", "is the wiki consistent?".
---

# Wiki lint

First read `wiki/CLAUDE.md`. Then go through **all** the pages of `wiki/` and write a report.
You fix nothing without the user's agreement: the lint reports, the human decides.

## Checks

1. **Headers**: every page (except `index.md` and `log.md`) starts with a YAML header with a
   non-empty `type`, a `sources` list and a `generated` entry.
2. **Footnotes**: every footnote `[^id]` used in a page is declared in its `sources`, and every
   declared source is used at least once.
3. **Sources**: every `sources[].resource` points to a file that exists in `corpus/` or
   `summaries/`. Report the sentences that end without a footnote, or whose footnote's source
   cannot support them (read the sources to check when feasible).
4. **Links**: every markdown link between pages points to an existing page. List broken links
   with the page that contains them.
5. **Index**: every page is in `index.md`, and every entry of `index.md` matches a file.
6. **Orphans**: pages that no other page links to.
7. **Contradictions**: two pages, or two sources of the same page, giving incompatible values
   or rules. Quote both passages. Read the sources themselves, not only the wiki: compare the
   figures each source gives for the same indicator, including their scope ("in the EU",
   "beyond the EU", "in all territories"). A different scope is a contradiction.
8. **Silent omissions and rewordings**: for each source of a page, every figure of the source
   on that page's topic must appear on the page, as the source writes it. Report a figure that
   is missing, rounded, or reworded so that it agrees with another source.
9. **Duplicates**: two pages covering the same topic under two names.

## Report format

    ## Wiki lint — YYYY-MM-DD
    - Pages: N · Header problems: N · Footnote problems: N · Broken links: N · Orphans: N · Contradictions: N
    ### Contradictions
    - <page A> vs <page B>: "…" / "…"
    ### Statements without a valid source
    - <page>: "…"
    ### Omissions and rewordings
    - <page> ← <source>: "<figure as the source writes it>"
    ### Headers, footnotes, links, index, orphans, duplicates
    - …
    ### Proposals
    - <one action per line, to be approved by the user>

If everything is clean, say so in one line. Don't propose actions for the sake of it.
