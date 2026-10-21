---
name: source-note
description: Writes a summary for the summaries/ folder from information given by the user. Use when the user wants to add, correct or document something the chatbot should know, or says "add this to the summaries", "note this source", "that's wrong, the right answer is…".
---

# Writing a summary for summaries/

You turn what the user tells you into a summary in the `summaries/` folder, following the
template `summaries/00-template.md`. You never change `corpus/`: it holds the full official texts.

## Steps

1. Ask for the **source** if it is not given: full reference and date. Without a source, you
   still write the document, but you put `Source: TO BE COMPLETED` on the second line and you
   tell the user.
2. Rephrase in short sentences, one fact per sentence. Add no fact the user did not give.
   Do not complete it with your own knowledge.
3. Choose a file name: `NN-short-topic.md`, NN between 10 and 89 (0x and 9x are reserved).
4. Write the file, then show it to the user for proofreading.
5. If the document contradicts an existing summary of `summaries/` or a text of `corpus/`, say so explicitly and offer
   to update or delete the old one. Do not decide alone.

## What you don't do

- Invent a source, an organisation or a figure to "complete" the document.
- Change an existing document without the user's agreement.
- Create or change a file with a shell command (`cat >`, `sed -i`, `printf >>`, `echo >`…): use the
  Write and Edit tools, so that the person sees exactly what changes before accepting.
