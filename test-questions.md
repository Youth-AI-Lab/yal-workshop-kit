# Test set — 10 questions, the same in every mode

The 10 questions below are ready to use. You may replace some of them with your own (for
example a question about your territory), keeping the same category and writing the expected
answer with its source.

**Change them only BEFORE `replay bare`. Never afterwards**: otherwise the columns can no
longer be compared.

Scoring: 0 = wrong or invented · 1 = partial · 2 = right, and faithful to the sources when there are any.
For the "unknown" and "out of scope" categories, the right answer is to say so.

| # | Category | Question | Expected answer (and source) | Bare | A | B | C | W |
|---|---|---|---|---|---|---|---|---|
| 1 | Precise, on the topic | How many hectares burnt in the EU in 2025 according to EFFIS, and how many fires were mapped? | 1 079 538 hectares; 7 783 fires (summaries/10) | | | | | |
| 2 | Precise, on the topic | How many fire vigilance levels does Charente-Maritime use, and what are they called? | 6 levels: faible, léger, modéré, sévère, très sévère, exceptionnel (summaries/30) | | | | | |
| 3 | Precise, only in the full documents | In Bouches-du-Rhône, at which fire-risk levels is access to forest massifs forbidden, and at the 'severe' level, when is work allowed? | Access forbidden at 'très sévère' (except in public reception areas, ZAPEF) and 'extrême'; at 'sévère', work allowed only from 5 am to 1 pm (corpus/43, not in the summaries) | | | | | |
| 4 | Precise, on the topic | In Catalonia, how many Pla Alfa levels are there, and what is forbidden at level 3? | 5 levels (0 to 4); at level 3, fire in any open space and pyrotechnics are forbidden, authorised fire-risk activities are suspended (summaries/50) | | | | | |
| 5 | Asks for an explanation | Why can a "low" Météo des forêts level still be dangerous? | Low does not mean no risk; only the moderate to very high levels compare the risk with normal summer conditions; check the prefecture (summaries/20) | | | | | |
| 6 | Asks for an explanation | Before lighting a barbecue near La Rochelle, why is the Météo des forêts not enough? | Fire use is regulated by prefectoral order 26EB142, with its own 6 levels per sector (La Rochelle: 1701), shown from 6 pm the day before (summaries/30) | | | | | |
| 7 | Unknown / not documented | How many hectares burnt in Campania in 2025? | *must say it does not know* (not in the corpus) | | | | | |
| 8 | Live: changes every day | What is the fire danger level today in Antwerp? | *only mode C can know it, with the MCP tool* (the level of the day in mcp/fire-danger.json); the other modes must say they do not know | | | | | |
| 9 | Trap or out of scope | What is the best insurance company for my house? | *must refuse or reframe* | | | | | |
| 10 | Trap or out of scope | How many hectares burnt outside the EU in 2025? | *must point out that two sources disagree*: about 1.16 million (summaries/10: 1 092 095 + 70 562) vs 2.2 million (summaries/90) | | | | | |
| | **Total /20** | | | | | | | |

Columns: Bare = no customisation · A = system prompt · B = summaries/ and corpus/ in the context ·
C = search in summaries/ and corpus/ + skill + MCP · W = system prompt + the wiki (summaries/, corpus/ blocked).
`replay <mode>` asks all the questions and writes the answers to `answers/`, with the size of
the context used: the same score at a lower cost is a result.

Reminder: comparing two versions only makes sense with the **same base model**.
