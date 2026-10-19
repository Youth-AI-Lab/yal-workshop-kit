---
name: ingest
description: Ingests a corpus/ document into the model-maintained wiki (wiki/) — creates or updates the topic pages concerned and the index. Use when the user says "ingest", "add to the wiki", "update the wiki with this document", or names a corpus/ file to integrate.
---

# Ingesting a document into the wiki

First read `wiki/CLAUDE.md`: it is the schema, it has the final say.

## Steps

1. **Read the source document** given in `corpus/`. If none is given, ask which one.
   Never change this file.
2. **Read `wiki/index.md`** and find the pages that already cover the topics of the document.
3. **For each topic of the document** (usually 1 to 5):
   - if a page exists: update it, adding the source to its Sources section;
   - otherwise: create the page following the schema, then add it to `index.md`.
4. **Follow the rules of the schema**: every statement has a listed source; a contradiction
   with an existing page is written "According to A, X; according to B, Y" and reported to the
   user, without deciding.
   - **Check every figure of the new document** against the figures already in the wiki for the
     same indicator (same thing counted, same year). Look at the scope too: "in the EU",
     "beyond the EU" and "in all territories" are different scopes.
   - If they disagree in value **or in scope**, it is a contradiction, even if one source
     looks more precise or more reliable.
   - **Never drop a figure because it does not fit**, and never reword a source to make it agree
     with another. Copy figures as the source writes them (no rounding, no "approximately").
5. **Date** every page touched (`Last updated: YYYY-MM-DD`).
6. **Report** at the end: pages created, pages updated, contradictions found, and what you
   could not attach to a topic.

## What you don't do

- Complete a page with what you know from elsewhere: only the source document counts.
- Create one page "per document": pages are per topic.
- Leave a `[[link]]` to a page you have not created.
