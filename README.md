# Youth AI Lab workshop — customising a chatbot

You work in pairs, in VS Code in your browser (a GitHub Codespace). Everything is already
installed. In the terminal at the bottom of the screen, first save the API key the facilitator
gave your pair:

    workshop-login      paste the key, press Enter: it is tested at once

Then two commands are enough:

    workshop <mode>     chat with the chatbot in one mode (bare, A, B, C or W)
    replay <mode>       ask your test questions in this mode, answers in answers/

The first time, Claude Code asks you to choose a theme and to trust the folder: accept.
To leave a conversation: `/exit`. If the Codespace stops after a long pause, reopen it:
nothing is lost.

Above the input box, a line shows how full the **context window** is.
Keep an eye on it all session long: it tells the story of what you are doing.

Our running example is **Feurisson**, the chatbot made by young people in La Rochelle to help
prevent wildfires. Today you build your own wildfire-prevention expert, step by step.

## What the chatbot can know: three layers

| Folder | What it holds | Who writes it |
|---|---|---|
| `corpus/` | The official documents (web pages, PDF, Word), as they were retrieved, never modified. A readable copy of each one is in `corpus/text/`. Start with `corpus/index.md`. | The authorities |
| `summaries/` | One short summary in English per document, checked against its source. Start with `summaries/index.md`. | People (helped by a model), then verified |
| `wiki/` | Pages by topic, linked together, each fact with a footnote to its source. Start with `wiki/index.md`. | The model, from the documents |

Every file starts with a small header in the **Open Knowledge Format (OKF)**: its type, its
source, who wrote it, and who verified it. In a summary, a `verified` line starting with
`human:` means that a person checked it against the source.

## The question of the day

> What enters the model's context, when, and who decides?

| Level | Mechanism | When it enters | Who decides | Mode |
|---|---|---|---|---|
| 0 | Nothing: the model alone | — | — | `bare` |
| 1 | System prompt (`AGENTS.md`) | Always, at startup | You | `A` |
| 2 | Knowledge in the context (`summaries/` and `corpus/`) | Always, in full | You | `B` |
| 3a | Skill (`.claude/skills/`) | On demand, if the model finds it useful | The model | `C` |
| 3b | Agentic search (ls, grep, reading) | Per question, the files found | The model, step by step | `C` |
| 3c | MCP tool (`.mcp.json`) | Live, from an external source | The model, through a tool | `C` |
| 3d | Vector RAG | Per question, similar excerpts | A search engine | demo |
| 3e | Model-maintained wiki (`wiki/`) | Per question, pages already summarised | The model, beforehand, at ingestion | `W` |
| 4 | Local model | Like 1 to 3, other infrastructure | — | slide |
| 5 | Fine-tuning | Nothing enters: it is in the weights | — | slide |

Each mode changes what enters the context. `bare` has no system prompt file and no access
to files: it is the starting point. A adds the system prompt. B adds everything we know.
C loads nothing in advance but lets the model fetch what it needs. W lets it read only the
wiki. To see what a mode sets up: `workshop help`.

## First of all: the test set

1. Open `test-questions.md`. Ten questions are ready, each with its expected answer and source.
   If you like, replace some with your own (a question about your territory, for example),
   keeping the category. Do it **now**: never change them after the next step.
2. Type `replay bare`. Each question is asked to the bare chatbot, in a fresh conversation.
   Tip: run `replay` in a second terminal (the `+` of the terminal panel) and keep chatting
   in the first one.
3. Open the file created in `answers/` and score each answer from 0 to 2, column Bare.

You will do the same after each block. The questions don't change: otherwise nothing is comparable.

## Block A — System prompt (level 1)

1. Open `AGENTS.md`. It is a deliberately minimal starting file.
2. Fill in its sections: identity, theme, rules, quality requirements, target personas,
   reference Q&A, bans and constraints. They are the same as in the WikiYouthBot minimal prompt.
3. `workshop A` to chat with it. Look at the gauge at startup: it is the cost of your system prompt.
4. `replay A`, then score column A.

What to watch: the behaviour changes, the knowledge doesn't. "Precise" questions don't
improve, or the model makes things up — sometimes with great confidence.

## Block B — Everything in the context (level 2)

1. Have a look at `summaries/index.md` and `corpus/index.md`: this is everything we know.
2. `workshop B`: all the summaries and all the documents are loaded at startup, about
   60 000 tokens. Watch the gauge jump to about a third of the window **before your first
   question**. `/context` shows the details.
3. `replay B`, then score column B. Note the cost that `replay` prints at the end, and compare
   it with A: every single message pays for everything.
4. Experiment: `summaries/10-…` and `summaries/90-…` summarise two official pages of the
   European Commission, published the same day. They disagree. Ask "How many hectares burnt
   outside the EU in 2025?". Does the model point out the contradiction, or choose silently?
   Real sources contradict each other too.

What to watch: the precise questions are now answered. But we only have 21 documents. With ten
times more, they would not fit in the window at all.

## Block C — Fetch what is needed (level 3)

Nothing is loaded in advance. The model knows where the knowledge is, and goes to fetch it.

### A question B cannot answer: the MCP tool (3c)

1. In `workshop B`, ask: "What is the fire danger level today in Antwerp?". It cannot know.
2. In `workshop C`, ask the same question. Watch the call to the `fire_danger` tool:
   `.mcp.json` declares a small server (`mcp/fire_danger_server.py`) that reads today's level.
3. Edit `mcp/fire-danger.json`, then ask "check again": the answer follows, without restarting.
   `/mcp` shows the server and its tools.

### Agentic search (3b)

1. In `workshop C`, ask question 3 of the test set (Bouches-du-Rhône). Its answer is not in the
   summaries: it is only in the full text of an order.
2. Read the transcript: the model reads the summaries' index, searches with `grep`, then opens
   the right document in `corpus/text/`. It only read what seemed useful to it. The gauge stays low.
3. Ask a question whose answer is nowhere: the model sees it (zero results).
   A RAG always returns something.

### Skill (3a)

A skill is a folder with a `SKILL.md`. Only its description (at the top) is always in the
context; the content is read only if the model decides it needs it.

1. Look at `.claude/skills/source-note/SKILL.md`.
2. In `workshop C`, say "that's wrong, the right answer is…": the skill triggers and writes
   a new summary in `summaries/`. Then ask an ordinary question: it should not trigger.
3. Create your own skill: a folder `.claude/skills/<name>/SKILL.md` with the same header.
   Test until it triggers when it should, and only when it should.

Then `replay C` and score column C. Compare with B: the same answers or better, with a much
smaller context, and C is the only one that knows today's level.

### Vector RAG (3d) — demonstration

By the facilitator: the same documents, cut into chunks and indexed by similarity. Compare what
the model saw (excerpts) with what it claims. RAG keeps its place when the documents are too
many to search file by file or when the questions are vague.

## Block W — Organised knowledge (level 3e)

Instead of rediscovering the documents at every question, the model can maintain a wiki:
pages by topic, linked together, each fact with a footnote `[^id]` pointing to its source.
The facilitator built it before the session from all of `corpus/`, with the `ingest` skill,
then checked it with the `lint` skill.

1. Open `wiki/index.md`, then a page: each footnote leads to its source.
2. Open `wiki/log.md`: the history of the wiki, including the contradictions found between
   sources. They are visible here, not hidden in the answers.
3. The facilitator shows the wiki as a graph (graphify): you see what the model linked.
4. `replay W`: in this mode the model can read `wiki/` only (`summaries/` and `corpus/` are
   blocked). Score column W and compare with C.
5. To go further: in `workshop C`, ask "lint the wiki", or "ingest summaries/31-… into the
   wiki" and watch which pages change.

## Back to WikiYouthBot

With young people, you will customise a chatbot in a Claude Project or a Gemini Gem. There are
only two boxes there. Today you have seen what happens behind them.

| WikiYouthBot step | What the group does | Box | Here |
|---|---|---|---|
| 1. I Heard a Rumor | first rules, verification reflexes | Instructions | `AGENTS.md`, block A |
| 2. The Press Conference | 10 questions, quality requirements | Instructions | `test-questions.md`, `replay` |
| 3. The Data Box | local documents, figures, Q&A | Knowledge | `corpus/` and `summaries/`, blocks B and C |
| 4. The Chatbot Studio | personality, personas, mascot | Instructions | `AGENTS.md`, block A |

The Instructions box is level 1: always read, in full. The Knowledge box is level 2 or 3:
depending on the tool and on its size, it is read in full or searched for excerpts. You cannot
see which from the outside — that is why the test questions matter.

## Closing

Compare the columns of `test-questions.md`. What improved, what got worse, and at what
context cost (each answer in `answers/` shows the size of the context used).

Levels 4 (local model) and 5 (fine-tuning) are presented by the facilitator.

## Landmarks

- `workshop help`: what each mode does.
- `/context`: details what fills the context window.
- `/mcp`: state of the MCP servers (mode C only).
- `/status`: shows the gateway and the key in use.
- If something breaks: ask the facilitator. Your files stay in the Codespace.
