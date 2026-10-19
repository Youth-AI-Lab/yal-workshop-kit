# Wiki schema

<!-- This file is read when the model works in wiki/. It is the third layer of the
     "LLM Wiki" pattern: the raw sources (corpus/), the wiki (here), and this schema. -->

This folder is a knowledge wiki maintained by the model on the group's topic.
It is built **only** from the documents of `../corpus/`. The model never changes
`corpus/`: it is the layer of sources, it belongs to the humans.

## Structure

- `index.md`: the list of all pages, one line per page, with a ten-word summary.
  Always up to date: every page creation or deletion goes through the index.
- One page per **topic** (a notion, a rule, a place, an actor), never one page per source
  document. A document can feed several pages; a page can quote several documents.
- File name: `topic-in-lowercase-with-dashes.md`.

## Page format

    # <Topic title>

    <Summary in short sentences. One fact per sentence.>

    ## Sources
    - [[../corpus/NN-document-name.md]] — <what this source brings>

    ## See also
    - [[other-page]]

## Rules

1. **Every statement comes from a source listed in the Sources section of the page.** No
   addition from the model's general knowledge. When in doubt, don't write it.
2. **A contradiction between two sources is written as such**: "According to A, X; according
   to B, Y." The model does not decide.
3. **Update rather than duplicate.** Before creating a page, look in `index.md` for an
   existing page on the topic.
4. **Links are `[[wikilinks]]`** to files that exist. A link to a missing page is an error
   that the lint must report.
5. **Dating**: a page ends with `Last updated: YYYY-MM-DD`, the date of the last ingestion
   that touched it.

## Operations

- **Ingest** (skill `ingest`): read a document of `corpus/`, find the pages concerned in the
  index, update them or create new ones, update the index, list the pages touched.
- **Lint** (skill `lint`): go through the wiki, report contradictions, broken links,
  statements without a source, orphan pages (missing from the index or never linked).
- **Answer**: when the user asks for an answer "from the wiki", read `index.md`, open the
  relevant pages, answer quoting the pages and their sources.
