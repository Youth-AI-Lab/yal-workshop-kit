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

## The question of the day

> What enters the model's context, when, and who decides?

| Level | Mechanism | When it enters | Who decides | Mode |
|---|---|---|---|---|
| 0 | Nothing: the model alone | — | — | `bare` |
| 1 | System prompt (`AGENTS.md`) | Always, at startup | You | `A` |
| 2 | Knowledge in the context (`corpus/`) | Always, in full | You | `B` |
| 3a | Skill (`.claude/skills/`) | On demand, if the model finds it useful | The model | `C` |
| 3b | Agentic search (ls, grep, reading) | Per question, the files found | The model, step by step | `C` |
| 3c | MCP tool (`.mcp.json`) | Live, from an external source | The model, through a tool | `C` |
| 3d | Vector RAG | Per question, similar excerpts | A search engine | demo |
| 3e | Model-maintained wiki (`wiki/`) | Per question, pages already summarised | The model, beforehand, at ingestion | `W` |
| 4 | Local model | Like 1 to 3, other infrastructure | — | slide |
| 5 | Fine-tuning | Nothing enters: it is in the weights | — | slide |

Each mode adds something to the previous one. `bare` has no system prompt file and no access
to files: it is the starting point. To see what a mode sets up: `workshop help`.

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

## Block B — Knowledge in the context (level 2)

1. Look at the documents in `corpus/` (see `corpus/README.md`). Add your own if you have some.
2. `workshop B`: the whole corpus is loaded at startup. Watch the gauge rise before your first
   question.
3. `replay B`, then score column B.
4. Experiment: `corpus/90-contradiction.md` and `corpus/10-eu-2025-wildfire-season.md` are two
   official pages of the European Commission, published the same day. They disagree.
   Ask "How many hectares burnt outside the EU in 2025?". Does the model arbitrate, point out
   the contradiction, or choose silently? Real sources contradict each other too.

## Block C — Out of the context (level 3)

In this mode, the corpus is no longer loaded in advance. The model only knows it exists:
it is up to the model to go and look. It can also use skills and an MCP tool.

### Agentic search (3b)

1. `workshop C`. The gauge stays low. Ask a precise question on the topic.
2. Read the transcript: the model lists the folder, runs a `grep`, reads one or two files,
   then answers. It only read what seemed useful to it.
3. Ask a question whose answer is nowhere: the model sees it (zero results).
   A RAG always returns something.

### Skill (3a)

A skill is a folder with a `SKILL.md`. Only its description (at the top) is always in the
context; the content is read only if the model decides it needs it.

1. Look at `.claude/skills/source-note/SKILL.md`.
2. In `workshop C`, say "that's wrong, the right answer is…": the skill triggers and writes
   a document for `corpus/`. Then ask an ordinary question: it should not trigger.
3. Create your own skill: a folder `.claude/skills/<name>/SKILL.md` with the same header.
   Test until it triggers when it should, and only when it should.

### MCP tool (3c)

`.mcp.json` declares a small server (`mcp/fire_danger_server.py`) that returns today's fire
danger level, which the model cannot know. It is an example of "live" knowledge.

1. In `workshop C`, ask "what is the fire danger level today in Charente-Maritime?". Watch the
   tool call.
2. Edit `mcp/fire-danger.json`, then ask "check again": the answer follows, without restarting.
3. `/mcp` shows the state of the server and its tools.

Then `replay C` and score column C. Compare with B: same score, less context?

### Vector RAG (3d) — demonstration

By the facilitator: same corpus, but cut into chunks and indexed by similarity. Compare what
the model saw (excerpts) with what it claims. RAG keeps its place when the corpus is larger
than the context or when questions are vague; on your documents, agentic search does as well.

### Model-maintained wiki (3e)

Instead of rediscovering the corpus at every question, the model maintains a wiki: summarised
pages, linked together, quoting their sources. The schema of the wiki is in `wiki/CLAUDE.md`;
the model never changes `corpus/`.

1. In `workshop C`, ask: "ingest corpus/10-xxx.md into the wiki". The `ingest` skill creates or
   updates the pages concerned and `wiki/index.md`. Open them.
2. Ingest a second document on the same topic: the existing page is updated, not duplicated.
3. Ask: "lint the wiki". The `lint` skill looks for contradictions, broken links and
   statements without a source.
4. `replay W`: the model answers from the wiki alone. Score column W and compare with C.

To see the wiki as a graph, the facilitator projects their graphify view. `INFERRED` edges
are the ones the model guessed: nobody wrote them.

## Back to WikiYouthBot

With young people, you will customise a chatbot in a Claude Project or a Gemini Gem. There are
only two boxes there. Today you have seen what happens behind them.

| WikiYouthBot step | What the group does | Box | Here |
|---|---|---|---|
| 1. I Heard a Rumor | first rules, verification reflexes | Instructions | `AGENTS.md`, block A |
| 2. The Press Conference | 10 questions, quality requirements | Instructions | `test-questions.md`, `replay` |
| 3. The Data Box | local documents, figures, Q&A | Knowledge | `corpus/`, blocks B and C |
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
- `/mcp`: state of the MCP servers (modes C and W only).
- `/status`: shows the gateway and the key in use.
- If something breaks: ask the facilitator. Your files stay in the Codespace.
