# Youth AI Lab workshop — customising a chatbot

Today, in pairs, you build a chatbot that is an expert in **wildfire prevention**, one step at
a time. At each step you add one thing, then you ask the same test questions again, and you
see what changed. Our running example is **Feurisson**, the chatbot made by young people in
La Rochelle to help prevent wildfires.

You work in VS Code in your browser (a GitHub Codespace). Everything is already installed.
In the terminal at the bottom of the screen, first save the API key the facilitator gave your
pair:

    workshop-login      paste the key, press Enter: it is tested at once

Then two commands are enough:

    workshop <mode>     chat with the chatbot in one mode: bare, A, B, C, D or E
    replay <mode>       ask your test questions in this mode, answers in answers/

The first time, Claude Code asks you to choose a theme and to trust the folder: accept.
To leave a conversation: `/exit`. If the Codespace stops after a long pause, reopen it:
nothing is lost.

Above the input box, a line shows how full the **context window** is: everything the model
reads before it answers. Keep an eye on it all session long: it tells the story of the day.

## The question of the day

> What enters the model's context, when, and who decides?

Each step answers this question in a different way.

| Step | What you add | When it enters the context | Who decides | Mode |
|---|---|---|---|---|
| Start | Nothing: the model alone | — | — | `bare` |
| A | A system prompt (`AGENTS.md`): who it is, its rules | Always, at startup | You | `A` |
| B | Knowledge: all the summaries and documents | Always, in full | You | `B` |
| (demo) | Vector RAG: excerpts found by similarity | Per question | A search engine | — |
| C | Search in the files, and skills to curate the knowledge | Per question, what it finds | The model, step by step | `C` |
| D | A tool that reads live data (MCP) | Per question, if needed | The model, through a tool | `D` |
| E | A wiki, organised by topic, with a map | Per question, pages already written | The model, beforehand | `E` |
| (slide) | A local model; fine-tuning | — | — | — |

Each mode keeps what the previous one had, except B: from C on, nothing is loaded in advance.
To see what a mode sets up: `workshop help`.

## What the chatbot can know

| Folder | What it holds | Who writes it |
|---|---|---|
| `corpus/` | The official documents (web pages, PDF, Word), as they were retrieved, never modified. A readable copy of each one is in `corpus/text/`. Start with `corpus/index.md`. | The authorities |
| `summaries/` | One short summary in English per document. Start with `summaries/index.md`: it says which ones a person has checked. | The model; then a person checks it |
| `inbox/` | A document that is not in the corpus yet. You add it in block C. | — |
| `wiki/` | Appears in block E: pages by topic, each fact with a footnote to its source. | The model |

Every file starts with a small header in the **Open Knowledge Format (OKF)**: its type, its
source, who wrote it, and who verified it. In a summary, a `verified` line starting with
`human:` means that a person checked it against the source.

## Opening — the test set (15 min)

1. Open `test-questions.md`. Eleven questions are ready, each with its expected answer and
   source. If you like, replace some with your own (a question about your territory, for
   example), keeping the category. Do it **now**: never change them after the next step.
2. Type `replay bare`. Each question is asked to the bare chatbot, in a fresh conversation.
   Tip: run `replay` in a second terminal (the `+` of the terminal panel) and keep working
   in the first one.
3. Open the file created in `answers/` and score each answer from 0 to 2, column Bare.
   Read the scoring rules at the top of `test-questions.md`: an invented answer gets 0.
   "I don't know" gets 2 when the answer exists nowhere (question 7), and 1 when it exists
   somewhere the chatbot cannot reach yet (in a document or through a tool).

You will do the same after each block. The questions don't change: otherwise nothing is comparable.

## Block A — Give it a personality (15 min)

1. Open `AGENTS.md`: its sections are empty. Open `examples/AGENTS.feurisson.md` next to it:
   the same sections, filled in for Feurisson.
2. Write your own: identity, theme, rules, quality requirements, target personas, reference
   Q&A, bans and constraints. They are the same as in the WikiYouthBot minimal prompt.
   Don't skip **Rules** and **Quality requirements**: the next blocks are scored on them.
3. `workshop A` to chat with it. Look at the gauge at startup: it is the cost of your system prompt.
4. `replay A`, then score column A.

What to watch: the behaviour changes (tone, refusals, "I don't know"), the knowledge doesn't.
Precise questions don't improve, or the model makes things up, sometimes with great confidence.

> **You built** a system prompt. **Reused in** the *Instructions* box of a Claude Project or a
> Gemini Gem, and in the "system prompt" field of any chatbot tool.

## Block B — Give it everything you know (12 min)

1. Have a look at `summaries/index.md` and `corpus/index.md`: this is everything we know.
2. `workshop B`: all the summaries and all the documents are loaded at startup. Watch the gauge
   jump to about a third of the window **before your first question**. `/context` shows the details.
3. `replay B`, then score column B. Note the cost that `replay` prints at the end, and compare
   it with A: every single message pays for everything.
4. Experiment: `summaries/10-…` and `summaries/90-…` summarise two official pages of the
   European Commission, published the same day. They disagree. Ask "How many hectares burnt
   outside the EU in 2025?". Does the model point out the contradiction, or choose silently?
   Real sources contradict each other too.

What to watch: the precise questions are now answered. But we only have about twenty
documents. With ten times more, they would not fit in the window at all.

> **You built** a knowledge base of sourced documents. **Reused in** the *Knowledge* box of a
> Claude Project or a Gemini Gem: when it is small, it is read in full, like here.

## Demo — Vector RAG (5 min)

By the facilitator: the same documents, cut into small pieces ("chunks") and indexed by
similarity, in another tool. For each question, only the most similar pieces enter the context.
Compare what the model saw (the excerpts) with what it claims. Notice: a RAG always returns
something, even when the answer is nowhere. This is what most chatbot tools do when the
knowledge is too big to be read in full.

## Block C — Let it search, and curate what it knows (30 min)

From now on, nothing is loaded in advance. The model knows where the knowledge is, and goes
to fetch what it needs.

### Search

1. In `workshop C`, ask question 3 of the test set (Bouches-du-Rhône). Its answer is not in the
   summaries: it is only in the full text of an order.
2. Read the transcript: the model reads the index, searches with `grep`, then opens the right
   document in `corpus/text/`. It reads only what seems useful. The gauge stays low.
3. Ask a question whose answer is nowhere: the model sees it (zero results). A RAG would still
   return something.

### Skills: let a new document in

A skill is a folder with a `SKILL.md`: a procedure the model follows when it needs it. Only
its description (at the top) is always in the context. Look at `.claude/skills/summarize/SKILL.md`.

Question 11 is about a document the chatbot does not have yet: the plan of the Province of
Benevento (Italy) for the 2026 fire season, in `inbox/`. You let it in, and you vouch for it.

1. Open `inbox/README.md` and copy its `corpus-add` command into the terminal. The document
   gets a number (80, or the next free one): the original is kept unchanged in `corpus/`,
   a readable copy goes to `corpus/text/`, and a line is added to `corpus/index.md`.
2. In `workshop C`, ask: "summarize corpus/80-benevento-aib-2026.pdf" (your number). The
   `summarize` skill writes a draft in `summaries/` and a verification table in
   `summaries/checks/`.
3. Open the table next to the original document. For each sentence, find the original passage
   (Ctrl+F) and check it, even in Italian: dates and numbers are easy to compare. Fill the
   "OK?" column.
4. Tell the chatbot: "I checked summary 80, I am <first name last name>", or "sentence 3 is
   wrong, it should be …". The `validate-summary` skill applies your corrections and adds your
   name to `verified` in the header.
5. Open `summaries/index.md`: your summary went from "draft, not verified" to "human-reviewed".

Then `replay C` and score column C. Question 11 can now be answered: by you, not by the model.

To go further: add an official document of your own territory with
`corpus-add "<address>" --name <short-name>`, or create your own skill (a folder
`.claude/skills/<name>/SKILL.md` with the same header). Test it until it triggers when it
should, and only when it should.

> **You built** a curation process: a person decides what gets in, and signs what the chatbot
> says about it. **Reused in** any chatbot: the *Knowledge* box is only as good as what you
> put in it. With young people: the Data Box of WikiYouthBot.

## Block D — Connect it to live data (13 min)

No document can say what the fire danger level is **today**. A tool can: the model calls it,
and the tool reads an official source. This is **MCP** (Model Context Protocol), a standard
way to give tools to a model.

1. In `workshop C`, ask: "What is the fire danger level today in Antwerp?". It cannot know.
2. In `workshop D`, ask the same question. Watch the call to the `fire_danger` tool:
   `.mcp.json` declares a small server (`mcp/fire_danger_server.py`) that reads
   `mcp/fire-danger.json`. `/mcp` shows the server and its tools.
3. In `mcp/fire-danger.json`, the scale and the official source of each territory are already
   filled in, but not today's level. Write today's date in `date` (e.g. 2026-10-22). For
   Antwerp (question 8), open its source and copy today's colour code into `level` (or "season
   over", if the source says so). Save, and ask "check again": the answer follows, without
   restarting. The tool is deterministic: it gives what the source says, nothing else.
   If you have time, do the same for your own territory.
4. `replay D`, then score column D. Question 8 is the one that changes.

> **You built** a tool connection. **Reused in** chatbot tools that accept tools or MCP
> servers; with young people: "a live source per bot" (today's danger, the robot's sensors).

## Block E — Organise what it knows: the wiki (18 min)

Instead of searching the documents again at every question, the model can write and maintain
a wiki: pages by topic, linked together, each fact with a footnote `[^id]` to its source.
The facilitator built one before the session, from all of `corpus/`, then checked it.

1. `wiki-start`: the wiki arrives in `wiki/`, with two new skills, `ingest` and `lint`.
2. Open `wiki/index.md`, then a page: each footnote leads to its source. Open `wiki/log.md`:
   the history of the wiki, including the contradictions found between sources.
3. `wiki-graph`, then open `wiki/graph.md` and press Ctrl+Shift+V: the map of the wiki, pages
   and sources. The facilitator projects the same map for the whole wiki.
4. Your Benevento document is not in the wiki yet. In `workshop E`, ask:
   "ingest summaries/80-… into the wiki". Watch which pages change, then
   `wiki-graph --highlight 80`: your document and the pages it feeds turn orange.
5. "lint the wiki": the model checks footnotes, links and contradictions.
6. `replay E`, then score column E.

> **You built** a knowledge base that stays organised as it grows. **Reused in** the
> *Knowledge* box, when you give it clean pages instead of raw documents.

## Closing (12 min)

Compare the columns of `test-questions.md`. What improved, what got worse, and at what context
cost (each answer in `answers/` shows the size of the context used). The same score with a
smaller context is a result.

The facilitator presents two more levels: a **local model** (the same steps, on your own
machine, nothing leaves it) and **fine-tuning** (nothing enters the context: the knowledge is
in the model itself, and it is much harder to check or correct).

### Back to WikiYouthBot

With young people, you will customise a chatbot in a Claude Project or a Gemini Gem. There are
only two boxes there. Today you have seen what happens behind them.

| WikiYouthBot step | What the group does | Box | Here |
|---|---|---|---|
| 1. I Heard a Rumor | first rules, verification reflexes | Instructions | `AGENTS.md`, block A |
| 2. The Press Conference | 10 questions, quality requirements | Instructions | `test-questions.md`, `replay` |
| 3. The Data Box | local documents, figures, Q&A | Knowledge | `corpus/`, `summaries/`, blocks B and C |
| 4. The Chatbot Studio | personality, personas, mascot | Instructions | `AGENTS.md`, block A |

The Instructions box is block A: always read, in full. The Knowledge box is block B or the RAG
demo: depending on the tool and on its size, it is read in full or searched for excerpts. You
cannot see which from the outside: that is why the test questions matter.

### Take it home: your own chatbot

What you did today is not tied to this tool. Each step has a place in other tools:

| Today | Where it goes |
|---|---|
| `AGENTS.md` (block A) | the system prompt, or *Instructions* box |
| `corpus/` and `summaries/` (blocks B, C) | the *Knowledge* box, or the documents of a RAG |
| The check of each summary (block C) | your own process, before anything enters the *Knowledge* box |
| The MCP tool (block D) | the tools of the chatbot, when the tool accepts them |
| The wiki (block E) | clean pages to put in the *Knowledge* box |
| `test-questions.md` and `replay` | always: the same questions before and after each change |

- **No code**: a Claude Project or a Gemini Gem (Instructions + Knowledge).
- **Your own server**: Open WebUI, the tool of the RAG demo (system prompt, knowledge base, tools).
- **Visual building blocks**: tools like Flowise or Langflow, where you connect boxes.
- **Code**: libraries like LangChain or LlamaIndex, or the same mechanisms as today (system
  prompt, skills, MCP) with the Claude Agent SDK.

## Landmarks

- `workshop help`: what each mode does.
- `corpus-add --help`: how to add a document to `corpus/`.
- `wiki-start --help`, `wiki-graph --help`: the wiki commands (block E).
- `/context`: details what fills the context window.
- `/mcp`: state of the MCP server (modes D and E).
- `/status`: shows the gateway and the key in use.
- If something breaks: ask the facilitator. Your files stay in the Codespace.
