# Test set - 12 questions, the same in every mode

> ℹ️ **Note.** This file is used in **every workshop** of the series. Each workshop changes the
> chatbot, then `replay` asks these questions again, so the columns of `scores.md` can be compared.

## What this file is for

This is the **test** of your chatbot. After each change, the command `replay <mode>` asks these
12 questions to the chatbot, each one in a **new conversation**, and writes the answers in
`answers/`. You read them, and you **score** them in `scores.md`, in the column of the mode.

**Why the same questions every time?** Without a fixed test, you only have impressions. With
the same questions and the same scoring, the columns **Bare, A, B, C, D, E** can be compared:
you see what each change really did. This is also the idea of the "Press Conference" in
WikiYouthBot.

The questions cover several **categories** on purpose: precise facts (one is only in the full
documents), explanations, something nobody knows (7), today's level (8), traps (9 and 10), and
a document you add yourselves in workshop 3 (11), and one question about **your own territory**
that you write yourselves (12).

## Replacing a question (optional)

Questions 1 to 11 below are ready to use. You may replace some of them with your own, for
example a question about your territory:

1. **Keep the same category**, so that the test stays balanced.
2. **Write the expected answer with its source** (the document where you found it).
3. **Keep the table format**: one line per question, cells separated by `|`, the number in the
   first cell, the question in the third cell. `replay` reads this table.

> ⚠️ **Important.** **Change them only BEFORE `replay bare`. Never afterwards**: otherwise the columns can no
> longer be compared.

## How to score

| Score | When |
|---|---|
| **2** | Right, and it says where it comes from. For the "unknown" and "out of scope" categories (questions 7 and 9), the right answer is to say so. |
| **1** | Honest but not enough: it says it cannot know although the answer exists (in the documents or through a tool), or it is right without its source, or only partly right. |
| **0** | Wrong or invented. **An invented answer is worse than "I don't know".** |

> ⚠️ **Important.** **An answer marked "Warning: the model looked at the test material" gets 0**: the model opened
> this file, `answers/` or `examples/`, and may have copied the expected answer. An answer marked
> **ERROR** is not scored.

**To write a score**: open `scores.md` (not this file). It has one short line per question and
one column per mode: Bare, A, B, C, D, E. Type the number between two `|`, then save (`Ctrl+S`).
Add up each column in the row **Total /24** (22 while question 12 is empty). Compare two totals
only when both columns have all their questions scored: from workshop 3 on, you score only some
questions, so compare their rows.

## The questions

| # | Category | Question | Expected answer (and source) |
|---|---|---|---|
| 1 | Precise, on the topic | How many hectares burnt in the EU in 2025 according to EFFIS, and how many fires were mapped? | 1 079 538 hectares; 7 783 fires (summaries/10) |
| 2 | Precise, on the topic | How many fire vigilance levels does Charente-Maritime use, and what are they called? | 6 levels: faible, léger, modéré, sévère, très sévère, exceptionnel (summaries/30) |
| 3 | Precise, only in the full documents | In Bouches-du-Rhône, at which fire-risk levels is access to forest massifs forbidden, and at the 'severe' level, when is work allowed? | Access forbidden at 'très sévère' (except in public reception areas, ZAPEF) and 'extrême'; at 'sévère', work allowed only from 5 am to 1 pm (corpus/43, not in the summaries) |
| 4 | Precise, on the topic | In Catalonia, how many Pla Alfa levels are there, and what is forbidden at level 3? | 5 levels (0 to 4); at level 3, fire in any open space and pyrotechnics are forbidden, authorised fire-risk activities are suspended (summaries/50) |
| 5 | Asks for an explanation | Why can a "low" Météo des forêts level still be dangerous? | Low does not mean no risk; only the moderate to very high levels compare the risk with normal summer conditions; check the prefecture (summaries/20) |
| 6 | Asks for an explanation | Before lighting a barbecue near La Rochelle, why is the Météo des forêts not enough? | Fire use is regulated by prefectoral order 26EB142, with its own 6 levels per sector (La Rochelle: 1701), shown from 6 pm the day before (summaries/30) |
| 7 | Unknown / not documented | How many hectares burnt in Campania in 2025? | *must say it does not know* (not in the corpus) |
| 8 | Live: changes every day | What is the fire danger level today in Antwerp? | *only modes D and E can know it, with the MCP tool* (the level of the day in mcp/fire-danger.json); in the other modes, "I don't know" = 1 |
| 9 | Trap or out of scope | What is the best insurance company for my house? | *must refuse or reframe* |
| 10 | Trap or out of scope | How many hectares burnt outside the EU in 2025? | *must point out that two sources disagree*: about 1.16 million (summaries/10: 1 092 095 + 70 562) vs 2.2 million (summaries/90) |
| 11 | Precise, in the document you add (workshop 3) | In 2026, for which period did the Province of Benevento plan to activate its forest-fire unit (N.O.E.D.)? | From 6 July to 27 September 2026 (the Benevento document of inbox/, once you have added it: corpus/8N). Before it is added: "I don't know" = 1. 15 June, 30 September or 15 October are other dates of the Campania documents, not the unit's: 0 |
| 12 | Precise, on your territory |  |  |

Columns of `scores.md`: Bare = no customisation · A = system prompt · B = summaries/ and corpus/ in the context ·
C = search in summaries/ and corpus/ + skills · D = C + the MCP tool (live data) · E = D + the wiki.

Question 11 is about a document that is not in the corpus yet (`inbox/`): you add it in workshop 3.

## Question 12: your territory

Question 12 is **yours**. It is about the place where you work with young people, and it is empty
until you write it. `replay` skips it while its question cell is empty.

1. **Find one official page** about forest fires on your territory (a prefecture, a region, a
   civil protection service, a park). Keep its address: it is the **source** of your answer.
2. **Pick one precise fact** in it that the documents of the kit do not give: a date, a
   number, a rule. Look first at the list of the kit's summaries,
   [summaries/index.md](https://github.com/Youth-AI-Lab/yal-workshop-kit/blob/main/summaries/index.md):
   if your territory is there, check that the fact is not.
3. **Write the question** in the third cell of row 12, in the language of your choice. Write it
   in the normal editor: you cannot type in the preview.
4. **Write the expected answer and its source** in the fourth cell, for example:
   `From 1 June to 30 September (https://… , page "…", read on 12 November)`.
5. **Fill in the score for Bare**: type `replay bare 12`, then score this answer like the others.

> 💡 **Tip.** Today, no mode of your chatbot has your page: "I don't know" is the honest answer (1).
> In workshop 3, you add the page to the documents of your chatbot, and question 12 should then get a 2.

> ⚠️ **Important.** Do not change question 12 once you have scored it: write a new question
> only if you also clear its row in `scores.md`.

Each answer in `answers/` shows the size of the context used: the same score at a lower cost is
a result.

> ℹ️ **Note.** Reminder: comparing two versions only makes sense with the **same base model**. This is why
> every pair uses the same model, set when you saved your key.
