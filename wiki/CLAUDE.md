---
type: Wiki Schema
title: "Schema of the model-maintained wiki"
description: "How the wiki pages are written, linked, sourced, indexed and logged (OKF v0.2)."
---
# Wiki schema

<!-- This file is read when the model works in wiki/. It is the third layer of the "LLM Wiki"
     pattern: the sources (../corpus/ and ../summaries/), the wiki (here), and this schema.
     The wiki is an OKF v0.2 bundle (Open Knowledge Format): markdown files with a YAML header. -->

This folder is a knowledge wiki maintained by the model on the group's topic.
It is built **only** from `../corpus/` (full official documents; read their readable copies in
`../corpus/text/`) and `../summaries/` (verified summaries, one per source). The model never
changes them: they are the layer of sources, they belong to the humans.

## Structure

- One page per **topic** (a notion, a rule, a place, an actor), never one page per source
  document. A document can feed several pages; a page can quote several documents.
- File name: `topic-in-lowercase-with-dashes.md`.
- `index.md` (reserved name): the list of all pages, grouped under headings. No YAML header.
  One line per page: `* [Title](file.md) - <the page's description>`.
- `log.md` (reserved name): the history of changes, newest first, under `## YYYY-MM-DD`
  headings. One line per change: `* **Creation**: …`, `* **Update**: …`, `* **Contradiction**: …`.
  The log names source files (`corpus/…`); footnotes belong to pages, not to the log.

## Page format

    ---
    type: Topic
    title: "<Topic title>"
    description: "<One sentence: what the page is about>"
    tags: [<territory>, <theme>]
    sources:
      - { id: <short-id>, resource: ../corpus/<NN-file>, title: "<title of the source>" }
      - { id: <short-id>, resource: ../summaries/<NN-file>, title: "<title of the summary>" }
    generated: { by: <tool/model>, at: <YYYY-MM-DDThh:mm:ssZ> }
    ---
    # <Topic title>

    <Short sentences. Each fact ends with the footnote of its source.>[^<short-id>]

    ## See also
    - [<Other topic>](other-topic.md)

    [^<short-id>]: <title of the source>

## Rules

1. **Every statement ends with a footnote `[^id]`, and every `id` is listed in `sources`.**
   No addition from the model's general knowledge. When in doubt, don't write it.
2. **A contradiction between two sources is written as such**: "According to one source, X;[^a]
   according to another, Y.[^b]" The model does not decide. It is also recorded in `log.md`.
3. **Copy figures as the source writes them**: no rounding, no "approximately", no rewording
   that makes two sources agree. Keep the scope ("in the EU", "beyond the EU", "in all
   territories"): a different scope is a contradiction.
4. **Update rather than duplicate.** Before creating a page, look in `index.md` for an existing
   page on the topic.
5. **Links are ordinary markdown links** to files that exist: `[Title](file.md)` between pages,
   `../corpus/…` or `../summaries/…` for sources.
6. **Dating**: `generated.at` is the date and time of the last ingestion that changed the page.

## Operations

- **Ingest** (skill `ingest`): read one document of `../corpus/` or `../summaries/`, find the
  pages concerned in `index.md`, update them or create new ones, update `index.md`, add an entry
  to `log.md`, list the pages touched.
- **Lint** (skill `lint`): check headers, footnotes, sources, links, index, contradictions,
  omissions; report, never fix without the user's agreement.
- **Answer**: read `index.md`, open the relevant pages, answer quoting the pages and the sources
  of their footnotes.
