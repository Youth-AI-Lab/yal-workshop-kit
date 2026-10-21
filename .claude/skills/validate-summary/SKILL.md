---
name: validate-summary
description: Records that a person checked a summary of summaries/ against its source, after applying their corrections — adds a human `verified` entry to its OKF header and marks it stable. Use when the user says "I checked summary …", "the summary is correct", "validate the summary", "sentence N is wrong, it should be …".
---

# Recording the check of a summary by a person

Only a person can validate a summary. You write down what they did and said, nothing more.

## Steps

1. **Find the summary** (`summaries/NN-….md`) and **read its table** (`summaries/checks/NN-….md`).
2. **Ask for the name** of the person who checked it, if they did not give it. Write it as an
   OKF actor: `human:<first-name-last-name>`, lowercase, with dashes (e.g. `human:maria-rossi`).
3. **Make sure every row was checked.** A row is checked when its "OK?" cell says yes (or ok,
   oui, sì, sí, ja…) or holds a correction, or when the person says explicitly that they checked
   that sentence. If some rows are not checked, list them and ask the person to check them.
   A general "it's fine" is not enough.
4. **Apply their corrections**, and only theirs: change the sentence in the summary and the row
   of the table. If they say that a sentence is wrong without giving the right version, delete
   the sentence (and its row). Then **show the corrected sentences** to the person and ask them
   to confirm them: they vouch for the final text, not for your edit.
5. **Only when every row is checked and the corrections are confirmed**:
   - add to the header `verified:` the entry `{ by: human:<name>, at: <now, UTC> }`
     (create the `verified:` list if it does not exist; keep the existing entries);
   - set `status: stable`;
   - in `summaries/index.md`, replace "(draft, not verified)" by "(human-reviewed)" on its line.
6. **If they checked only part of it**, do not add `verified` and keep `status: draft`; add
   `review_note: "<which sentences were checked, by whom>"` to the header.
7. **Report** what changed: corrections, the new `verified` entry, the new status — or what is
   still missing before the summary can be validated.

## What you don't do

- Add a `verified` entry that the person did not ask for, or in the name of someone else.
- Add it before every row is checked and every correction is confirmed.
- Change a sentence that the person did not correct.
- Validate a summary yourself, even if it looks right to you.
- Create or change a file with a shell command (`cat >`, `sed -i`, `printf >>`, `echo >`…): use the
  Write and Edit tools, so that the person sees exactly what changes before accepting.
