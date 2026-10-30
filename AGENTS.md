# Chatbot instructions

<!-- WHAT THIS FILE IS
     This file is the system prompt of your chatbot (level 1, workshop 1 of README.md). The model
     reads it in full at the start of every conversation, before your first message. It plays
     the role of the "Instructions" box of the chatbot in WikiYouthBot (in Open WebUI, for example),
     with the same sections.
     Claude Code only reads CLAUDE.md: CLAUDE.md imports this file (its line @AGENTS.md).

     HOW TO FILL IT
     1. Open the example next to this file: examples/AGENTS.feurisson.md (right-click on it,
        then "Open to the Side"). Take what you like, and make it yours.
     2. Under each section title, write full, short sentences. Keep the titles as they are.
     3. Save (Ctrl+S), start `workshop A`, and talk to your chatbot. If a rule is not followed,
        change this file, save, and try again.
     4. Replay your questions (`replay A`) and score column A of scores.md.

     Comments like this one are NOT sent to the model: they are hints for you. You can leave
     them in the file. -->

## Identity
<!-- Who is your chatbot? Give it a name, a personality, and a way of speaking.
     Questions to ask yourselves: is it a character (Feurisson is a hedgehog)? Is it formal or
     friendly? Does it speak in short sentences? -->

## Theme
<!-- What is it specialised in? Narrow it down: which territory? which part of the topic?
     Say also what it does with a question about another territory. -->

## Rules
<!-- What it must ALWAYS do, or NEVER do. Don't skip this section: the next workshops are scored
     on it. Answer at least these questions:
     - What does it answer when it does not know? (e.g. "I don't know", and never invent)
     - What does it do when two sources disagree? (e.g. point out the contradiction)
     - Can it guess today's fire danger level? (it should not: only a source of the day can) -->

## Quality requirements
<!-- What does a good answer contain? For example: where each fact comes from (the name of the
     document); the date and the territory of each figure; a warning when a summary is still a
     draft that no person has checked. -->

## Target personas
<!-- Who is talking to it? A 14-year-old preparing a talk? A youth worker preparing an
     activity? A baker near the forest? For each one, say how it adapts its tone and the
     length of its answers. -->

## Reference Q&A
<!-- A frequent question, and the exact answer you expect, with its source (a document of
     summaries/ or corpus/). One good example shows the model the tone and the format. -->

## Bans and constraints
<!-- What does it refuse? (e.g. questions outside the theme, kindly, with a suggestion)
     When must the tone change? (e.g. someone reports a fire in progress: no jokes, the
     emergency numbers first) -->
