---
name: summarize
description: Writes a draft summary in summaries/ of a document of corpus/, with a verification table that a person can check line by line against the original. Use when the user says "summarize corpus/…", "write a summary of this document", "make a summary of the document I added".
---

# Writing a draft summary of a corpus document

A summary is short, in English, and checked by a person before anyone trusts it. You write the
draft and a verification table; a person validates it (skill `validate-summary`).

## Steps

1. **Find the document** in `corpus/` (its number `NN` or its name). Read its readable copy
   `corpus/text/NN-….md`, never the original file. Read `summaries/index.md` to know the
   existing summaries.
2. **Write `summaries/NN-<same-name>.md`** (same number and name as the document), starting with
   this OKF header:

        ---
        type: Source Summary
        title: "<Territory or topic>: <what the document says>"
        description: "<One sentence>"
        resource: <the address in the `sources` of the readable copy>
        tags: [<territory>, <topic>]
        status: draft
        language: en
        sources:
          - { id: source, resource: ../corpus/<original file of the document> }
        generated: { by: <your tool/model>, at: <now, UTC, YYYY-MM-DDThh:mm:ssZ> }
        ---

   No `verified` entry: nobody has checked it yet. Then `# <title>` and the summary: 5 to 15
   short sentences in English, one fact per sentence, chosen for wildfire prevention (rules,
   levels, dates, figures, who decides, what to do).
3. **Write `summaries/checks/NN-<same-name>.md`**, the verification table:

        ---
        type: Verification Table
        title: "Check of summary NN"
        resource: ../NN-<same-name>.md
        sources:
          - { id: source, resource: ../../corpus/text/NN-<same-name>.md }
        generated: { by: <your tool/model>, at: <now, UTC> }
        ---
        # Check of summary NN

        | # | Sentence of the summary | Original passage (copied word for word) | OK? | Correction |
        |---|---|---|---|---|

   One row per sentence of the summary, in the same order. The original passage is copied
   **exactly**, in the language of the document, so that a person can find it with Ctrl+F.
4. **Add a line to `summaries/index.md`**, under a `# Added during the session` heading
   (create it if needed): `* [<title>](NN-<same-name>.md) - <description> (draft, not verified)`.
5. **Tell the user** where the two files are, and how to finish: open the table next to the
   original, fill the "OK?" column, then say for example "I checked summary NN, I am
   <first name last name>" or "sentence 3 is wrong, it should be …".

## Rules

- Only what the document says: no fact from your general knowledge, no source you did not read.
- Copy figures, units and dates as the document writes them: no rounding, no "approximately".
- Keep the scope, the conditions and the exceptions ("in forest areas defined by the order",
  "except…", "from level…"). Dropping them changes the rule.
- If the document contradicts an existing summary, say so in your report and in the summary
  ("According to this document, X; summary MM says Y."). Do not decide.
- If a sentence has no passage to support it, delete the sentence.
- Never add a `verified` entry yourself, and never mark a summary as checked.

## What you don't do

- Create or change a file with a shell command (`cat >`, `sed -i`, `printf >>`, `echo >`…): use the
  Write and Edit tools, so that the person sees exactly what changes before accepting.
