---
name: ingest
description: Ingests a document of corpus/ (full official document) or summaries/ (verified summary) into the model-maintained wiki (wiki/) — creates or updates the topic pages concerned, the index and the log. Use when the user says "ingest", "add to the wiki", "update the wiki with this document", or names a corpus/ or summaries/ file to integrate.
---

# Ingesting a document into the wiki

First read `wiki/CLAUDE.md`: it is the schema (OKF v0.2), it has the final say.

## Steps

1. **Read the source document** given in `corpus/` or `summaries/`. For a document of `corpus/`,
   read its readable copy in `corpus/text/` (same name, `.md`), not the original file. If no document is given, ask which
   one. Never change the source.
2. **Read `wiki/index.md`** and find the pages that already cover the topics of the document.
3. **For each topic of the document** (usually 1 to 5):
   - if a page exists: update it; add the source to its `sources` header with a short `id`;
   - otherwise: create the page with the header of the schema, then add it to `index.md`.
4. **Write every fact with its footnote** `[^id]`, the `id` being declared in `sources`.
5. **Check every figure of the new document** against the figures already in the wiki for the
   same indicator (same thing counted, same year). Look at the scope too: "in the EU",
   "beyond the EU" and "in all territories" are different scopes.
   - If they disagree in value **or in scope**, it is a contradiction, even if one source looks
     more precise or more reliable: write "According to one source, X;[^a] according to
     another, Y.[^b]" and do not decide.
   - **Never drop a figure because it does not fit**, and never reword a source to make it agree
     with another. Copy figures as the source writes them (no rounding, no "approximately").
6. **Set `generated`** on every page touched: `{ by: <your tool/model>, at: <now, UTC> }`.
7. **Add an entry to `wiki/log.md`**, under today's `## YYYY-MM-DD` heading (newest first):
   one line per page created or updated, and one `**Contradiction**` line per contradiction.
   In the log, name the source files (`corpus/…`); no footnotes there.
8. **Report** at the end: pages created, pages updated, contradictions found, and what you
   could not attach to a topic.

## What you don't do

- Complete a page with what you know from elsewhere: only the source document counts.
- Create one page "per document": pages are per topic.
- Leave a link to a page you have not created.
