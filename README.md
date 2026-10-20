# Youth AI Lab - Customising a chatbot

### Erasmus+ project Youth AI Lab - hands-on workshop for youth workers

- **Project:** Youth AI Lab (Erasmus+), with five partners:
  - L.A.B. (Aix-en-Provence, France)
  - UAB (Barcelona, Spain)
  - Perlatecnica (Naples, Italy)
  - Digitale Wolven (Antwerp, Belgium)
  - CSC Vent des Îles (La Rochelle, France)
- **Facilitator:** Sébastien Nedjar
- **Need help?**
  - Raise your hand and ask the facilitator: this is what they are here for.
  - If something breaks, don't panic: your files stay in the Codespace.

## Workshop - Customising a chatbot: from a bare model to a wildfire-prevention expert

> 🎯 **A 2-hour workshop, in pairs.** Nothing is graded. The goal is to **see what happens
> behind a chatbot**: what it reads before it answers, and who decides what it reads. You will
> use what you learn today when you run the **WikiYouthBot** activity with young people.

> 🎓 **Open your Codespace** (one per pair): 👉 **https://codespaces.new/Youth-AI-Lab/yal-workshop-kit**
>
> This link creates your own copy of the workshop kit, in VS Code, in your browser. Nothing to
> install. The detailed steps are in [Setup](#setup).

> 📚 **The facilitator's slides** use the same words as this page. You can follow the session
> here, at your own pace.

### Contents

- [Goals of the session](#goals-of-the-session)
- [Setup](#setup)
- [The tools of the day](#the-tools-of-the-day)
- [Overview: one chatbot, built piece by piece](#overview-one-chatbot-built-piece-by-piece)
- [Opening - The test set (★, 15 min)](#opening---the-test-set--15-min)
- [Block A - Give it a personality (★, 15 min)](#block-a---give-it-a-personality--15-min)
- [Block B - Give it everything you know (★, 12 min)](#block-b---give-it-everything-you-know--12-min)
- [Demo - Vector RAG (5 min, by the facilitator)](#demo---vector-rag-5-min-by-the-facilitator)
- [Block C - Let it search, and curate what it knows (★★★, 30 min)](#block-c---let-it-search-and-curate-what-it-knows--30-min)
- [Block D - Connect it to live data (★★, 13 min)](#block-d---connect-it-to-live-data--13-min)
- [Block E - Organise what it knows: the wiki (★★★, 18 min) - Capstone](#block-e---organise-what-it-knows-the-wiki--18-min---capstone)
- [Closing - Compare, and take it home (12 min)](#closing---compare-and-take-it-home-12-min)
- [Going further](#going-further)
- [Troubleshooting](#troubleshooting)

---

## Goals of the session

### What you will be able to do by the end of this session

You have **probably already chatted with a chatbot** such as ChatGPT, Gemini or Claude. You type
a question, and an answer comes back. But you cannot see **what the chatbot read** before it
answered. Was it a document? A web page? Nothing at all, only its memory? Soon, you may
customise a chatbot with young people, in the **WikiYouthBot** activity. There, a Claude Project
or a Gemini Gem gives you only **two boxes**: *Instructions* and *Knowledge*. This workshop
shows you what happens behind these two boxes, one step at a time.

This progression follows **Bloom's taxonomy**, a teaching model that describes levels of mastery
of a skill - from the simplest (understanding a concept) to the most complex (creating something
new).

| Bloom level | Blocks | You will be able to... | Modes |
|---|---|---|---|
| **Understand** | Opening, A | **explain** what a **context window** is, and why a **system prompt** changes how a chatbot behaves, but not what it knows | `bare`, `A` |
| **Apply** | B, C (search) | give the chatbot **all its knowledge at once**, then let it **search** the files itself, and **compare** the two with the gauge and the cost | `B`, `C` |
| **Analyse** | RAG demo, C (curation), D | **check a summary** written by the model against the original document, sentence by sentence; **tell apart** what a document can say and what only a **live tool** can say | `C`, `D` |
| **Create** | E, Closing | **grow a wiki** with a new source and find its contradictions; **plan your own chatbot** (Instructions and Knowledge) for your territory | `E` |

**All session long**, you also practise **testing a chatbot**: the same 11 questions, asked again
after each block, and scored in the same way. This is the most useful habit you can take home.

### Why this approach?

All the blocks of the day answer **one single question**:

> **What enters the model's context, when, and who decides?**

The **model** is the program that writes the answers (here: Claude, made by Anthropic). The
**context** is everything the model reads before it answers: your question, its instructions,
and any document it was given. The model knows nothing else about your situation. Each block
adds something to the context, in a different way.

- **Why the same 11 questions after every block?** Without a fixed test, you only have
  **impressions**. A chatbot can sound better and be wrong more often. With the same questions
  and the same scoring, the columns of your score table can be **compared**. This is also the
  idea of the "Press Conference" in WikiYouthBot.
- **Why is "I don't know" worth more than a wrong answer?** An invented answer looks **exactly as
  confident** as a true one. About fire, a wrong rule can be dangerous. So an invented answer
  gets **0**, and an honest "I don't know" gets 1 or 2.
- **Why Claude Code in a terminal, and not a chat website?** On a chat website, you see the
  boxes, but not what happens behind them. Here, you **see everything**: how full the context
  is, every file the model opens, every search, every tool it calls. The mechanisms are the
  same as in the tools you will use with young people.
- **Why one theme for the whole day?** With one running example, the steps can be compared. Our
  theme is **wildfire prevention**, with real official documents from the EU, France,
  Catalonia, Flanders and Italy. Our running example is **Feurisson**, the chatbot made by
  young people in La Rochelle to help prevent wildfires.
- **Why the same model for everyone?** Comparing two versions of a chatbot only makes sense with
  the **same base model**. The model is set for all pairs when you save your key.

**The chatbot is what you study today, not your teacher.** It can be wrong, and sound sure of
itself. Each time, look at **what it read**, and compare with the source. A good question to
ask it after an answer: `Which document did you use for this answer?`. Then open that document
and check. In the first blocks, the facilitator will help you read what you see. In the last
blocks, try to explain it yourselves, in your pair.

### How this connects to WikiYouthBot

With young people (12 to 15 years old), you will customise a chatbot in a Claude Project or a
Gemini Gem. Each block of today matches a part of that work:

- **Block A** (system prompt) is the **Instructions** box: always read, in full.
- **Blocks B and C** (documents and summaries) are the **Knowledge** box. When it is small, it
  is read in full (block B). When it is big, it is searched for pieces (the RAG demo).
- **Your test questions** are the **Press Conference**: the same questions before and after
  each change.
- **Blocks D and E** go one step further: live data, and knowledge that stays organised.

The full table is in the [Closing](#back-to-wikiyouthbot). If you remember only one thing:
you cannot see from the outside how a box is used. **That is why the test questions matter.**

### Before you start

#### What you need to know

- **No programming**: you will type about ten commands. They are all written on this page:
  copy them.
- **A little English**: the chatbot, the commands and this page are in English. Some official
  documents are in French, Italian, Catalan or Dutch. You don't need to read them all: dates and
  numbers are easy to compare in any language.
- **No expertise on wildfires**: the documents are here. You will learn as you go.
- **Your pair**: you work two by two, on one screen. One person types, the other reads the
  instructions and watches the gauge. Swap at each block.

#### Your environment

You work in a **GitHub Codespace**: VS Code (a text editor) running in your browser, on a
computer of GitHub. Everything is already installed. You need **one free GitHub account per
pair**. The facilitator gives each pair a **card** with an **API key**: a long password that
lets your Codespace use the model. The keys have a spend limit.

The chatbot runs in **Claude Code**, a program that lets a model work in a folder of files.
Developers use it to write code. We use it because it **shows everything**: what the model
reads, searches and does.

> [!NOTE]
> **This is intentional.** Claude Code is not the tool you will use with young people. It is a
> glass box: the same mechanisms as in a Claude Project or a Gemini Gem, but you can see inside.

### Reference documents

All of these are in your Codespace, in the file list on the left:

- `test-questions.md`: the 11 test questions, and your score table.
- `AGENTS.md`: the system prompt of your chatbot (block A).
- `examples/AGENTS.feurisson.md`: a filled-in example, inspired by Feurisson.
- `corpus/index.md` and `summaries/index.md`: the list of the official documents and of their
  summaries.
- `inbox/README.md`: the document you will add in block C.
- `mcp/fire-danger.json`: the live data of block D.
- In the terminal: `workshop help`, `corpus-add --help`, `wiki-start --help`, `wiki-graph --help`.

---

## Setup

Do these steps **once**, at the start of the session. They take about 5 minutes.

### Step 1 - Open your Codespace

1. **Sign in to GitHub** with the account of one of you (a free account is enough).
2. **Open the link** of the workshop:

   👉 **https://codespaces.new/Youth-AI-Lab/yal-workshop-kit**

3. **Click** the green button **"Create codespace"**.
4. **Wait about 1 minute** while the Codespace is built.

You should see VS Code in your browser: the **list of files** on the left (`AGENTS.md`,
`README.md`, `corpus`, `summaries`…), and a **terminal** at the bottom of the screen. The
terminal is where you type commands. If you don't see it, open the menu (☰) at the top left,
then **"Terminal"**, then **"New Terminal"**.

> [!IMPORTANT]
> **Your Codespace is personal and it keeps your work.** Use the same one all session long: do
> **not** create a new one each time. If it stops after a long pause, reopen it from
> **https://github.com/codespaces**: nothing is lost.

### Step 2 - Let the Codespace wait for you

By default, a Codespace stops after **30 minutes** without activity. You lose nothing, but it
takes time to restart. To avoid this:

1. **Open** https://github.com/settings/codespaces in a new browser tab.
2. **Find** the setting **"Default idle timeout"**.
3. **Set it** to **120** minutes or more, and save.

### Step 3 - Save the key of your pair

1. **Click in the terminal**, at the bottom of the screen.
2. **Type** this command, then press **Enter**:

   ```bash
   workshop-login
   ```

3. **Paste the key** written on your card when the terminal asks for it:

   ```
   Paste the API key of your pair, then press Enter:
   ```

   > 💡 The key is **not shown** while you paste it. This is normal: it is a password.

4. **Press Enter.** The key is tested at once, with a very small request to the model.

You should see:

```
Key OK (Anthropic, model claude-sonnet-5-5). You can start: workshop bare
```

If your card has a key that starts with `sk-or-`, the message says `OpenRouter` and another
model name: this is fine too. If you see another message, look at
[Troubleshooting](#troubleshooting).

### Step 4 - Your first conversation

1. **Type**:

   ```bash
   workshop bare
   ```

   You should see this line, then the screen of Claude Code:

   ```
   Workshop — mode bare. To quit: /exit. Other modes: workshop bare | A | B | C | D | E
   ```

2. **The first time**, Claude Code asks you to **choose a theme** (colours) and to
   **trust the folder**. Accept both. It asks once more to trust a folder the first time you
   start mode A (the kit folder): accept again.
3. **Look above the input box**: a line shows how full the **context window** is. This is
   **the gauge**. Keep an eye on it all session long: it tells the story of the day.
4. **Type a first message**, for example `Hello, who are you?`, and press Enter. Read the answer.
5. **Leave** the conversation:

   ```
   /exit
   ```

Commands that start with `/` are typed **inside** a conversation. All other commands are typed
in the terminal, **outside** a conversation.

### Step 5 - Open a second terminal

Some commands take time. A second terminal lets you go on working in the first one.

1. **Click the `+`** at the top right of the terminal panel.
2. A new terminal opens. You can switch between the two in the list on the right of the panel.

> [!TIP]
> **One terminal to chat, one terminal to test.** Use the first one for `workshop`, the second
> one for `replay`.

If you got the message `Key OK` and had a first conversation, **everything is ready**.

---

## The tools of the day

### 📋 Memo - The commands

| Command | Where to type it | What it does |
|---|---|---|
| `workshop-login` | terminal | saves the key of your pair and tests it (once) |
| `workshop <mode>` | terminal | starts a conversation with the chatbot in one **mode**: `bare`, `A`, `B`, `C`, `D` or `E` |
| `replay <mode>` | terminal | asks all your test questions in this mode, one new conversation per question, and writes the answers in `answers/` |
| `replay <mode> 8 11` | terminal | the same, only for questions 8 and 11 |
| `workshop help` | terminal | what each mode puts in the context |
| `corpus-add …` | terminal | adds an official document to `corpus/` (block C) |
| `wiki-start` | terminal | unpacks the wiki (block E) |
| `wiki-graph` | terminal | draws the map of the wiki in `wiki/graph.md` (block E) |
| `/exit` | in a conversation | leaves the conversation |
| `/context` | in a conversation | shows in detail what fills the context window |
| `/mcp` | in a conversation | shows the live-data tool and its state (modes D and E) |
| `/status` | in a conversation | shows the gateway and the key in use |

The **mode** letters are not case-sensitive: `workshop a` works as well as `workshop A`.

### 📋 Memo - The words of the day

Each word is explained again the first time a block uses it.

| Word | What it means here |
|---|---|
| **Model** | The program that writes the answers. Here: Claude Sonnet, the same for every pair. |
| **Context** (or **context window**) | Everything the model reads before it answers. It has a maximum size: here, 200,000 tokens. |
| **Token** | The unit used to measure text for a model: a piece of a word. On average, 4 characters of English text. |
| **System prompt** | Instructions the model reads at the start of every conversation: who it is, its rules. |
| **Corpus** | The collection of official documents the chatbot can use. |
| **Summary** | A short text in English about one document, written by the model and checked by a person. |
| **Skill** | A written procedure that the model follows when it needs it. |
| **MCP** | *Model Context Protocol*: a standard way to give a tool to a model (here, a tool that reads live data). |
| **RAG** | *Retrieval-Augmented Generation*: a search engine picks pieces of documents, and only these pieces go to the model. |
| **Wiki** | Pages organised by topic, linked together, each fact with a note that gives its source. |

### What the chatbot can know

| Folder | What it holds | Who writes it |
|---|---|---|
| `corpus/` | **20 official documents** (web pages, PDF, Word), exactly as they were retrieved, never modified. A readable copy of each one is in `corpus/text/`. Start with `corpus/index.md`. | The authorities |
| `summaries/` | **One short summary in English per document.** Start with `summaries/index.md`: it says which ones a person has checked ("human-reviewed"). | The model; then a person checks it |
| `inbox/` | A document that is **not in the corpus yet**. You add it in block C. | - |
| `wiki/` | Appears in block E: pages by topic, each fact with a footnote to its source. | The model |

Every file of `corpus/text/`, `summaries/` and `wiki/` starts with a small **header** in the
**Open Knowledge Format (OKF)**: its type, its source, who wrote it, and who verified it. In a
summary, an entry of the `verified` list that starts with `by: human:` means that **a person**
checked it against the source. `status: draft` means that **no person** has checked it yet
(programs may have checked some of it).

### The work loop for each block

From the Opening to block E, you will repeat **the same work loop**. Each block only changes
step 2.

1. **Read** the context of the block: what problem did the previous step leave?
2. **Add** one thing to the chatbot (a system prompt, knowledge, a tool...).
3. **Chat** with it: `workshop <mode>`. Watch the gauge, and read what the model does.
4. **Replay** the test questions in the second terminal: `replay <mode>`.
5. **Score** each answer from 0 to 2, in the column of the mode, in `test-questions.md`.
6. **Compare** with the previous column, in your pair: what improved, what did not, at what cost?

### How to score

The rules are also at the top of `test-questions.md`.

| Score | When |
|---|---|
| **2** | Right, **and** it says where it comes from. For questions 7 ("unknown") and 9 ("out of scope"), the right answer is to say so. |
| **1** | Honest but not enough: it says it cannot know although the answer exists (in the documents or through a tool), or it is right without its source, or only partly right. |
| **0** | Wrong or invented. **An invented answer is worse than "I don't know".** |

So "I don't know" gets **2** when the answer exists nowhere (question 7), and **1** when it
exists somewhere the chatbot cannot reach yet (in a document or through a tool).

> [!IMPORTANT]
> **If an answer says "Warning: the model looked at the test material", score it 0.** The model
> opened `test-questions.md`, `answers/` or `examples/`: it may have copied the expected answer.
> An answer marked **ERROR** is not scored at all.

> [!TIP]
> **The reflex of the whole workshop**: after each answer, ask yourselves **"What entered the
> context, when, and who decided?"**. Look at the gauge, then at what the model read. The answer
> to this question explains almost every score of the day.

---

## Overview: one chatbot, built piece by piece

Each block answers the question of the day in a different way:

| Step | What you add | When it enters the context | Who decides | Mode |
|---|---|---|---|---|
| Start | Nothing: the model alone | - | - | `bare` |
| A | A system prompt (`AGENTS.md`): who it is, its rules | Always, at startup | You | `A` |
| B | Knowledge: all the summaries and documents | Always, in full | You | `B` |
| (demo) | Vector RAG: excerpts found by similarity | Per question | A search engine | - |
| C | Search in the files, and skills to curate the knowledge | Per question, what it finds | The model, step by step | `C` |
| D | A tool that reads live data (MCP) | Per question, if needed | The model, through a tool | `D` |
| E | A wiki, organised by topic, with a map | Per question, pages already written | The model, beforehand | `E` |
| (slide) | A local model; fine-tuning | - | - | - |

```mermaid
flowchart LR
  bare["bare: the model alone"] --> A["A: + system prompt"]
  A --> B["B: + all the knowledge, read in full"]
  B -.-> RAG["RAG demo: pieces picked by a search engine"]
  B --> C["C: system prompt + search + skills, nothing loaded in advance"]
  C --> D["D: C + a live tool (MCP)"]
  D --> E["E: D + the wiki"]
```

Each mode keeps what the previous one had, **except B**: from C on, nothing is loaded in
advance. The model knows **where** the knowledge is, and goes to fetch what it needs. To see
what a mode sets up, type `workshop help`.

The session lasts 2 hours: Opening 15 min, A 15 min, B 12 min, RAG demo 5 min, C 30 min,
D 13 min, E 18 min, Closing 12 min. The facilitator keeps time and tells you when to move on.

---

## Opening - The test set (★, 15 min)

### 📖 Before changing a chatbot, measure it

**Goal**: ask your 11 test questions to the model alone, and score its answers. This is your
**starting point**: every later column will be compared with this one.

A model alone has read a lot of text during its training, long ago. It has **no document** of
yours, and it does not know today's date or today's fire danger. Yet it will often answer
anyway. Your first job is to see **how often it is right, how often it says "I don't know", and
how often it invents**.

**What is provided**:

- `test-questions.md`: **11 questions, ready to use**, each with its category, its expected
  answer and its source. The six score columns (`Bare`, `A`, `B`, `C`, `D`, `E`) are empty.
- `replay`: the command that asks each question in a **new conversation**, so that nothing
  carries over from one question to the next.

### What to do

This first block is fully guided. Follow each step.

#### Step 1 - Read the test set

1. **Open** `test-questions.md`: click on its name in the file list on the left.
2. **Read** the scoring rules at the top, then the 11 questions. Notice the **categories**: some
   questions are precise, some ask for an explanation, one is about something nobody knows
   (7), one about today's level (8), two are traps (9 and 10), and one is about a document you
   will add later (11).

#### Step 2 - Replace questions (optional, now or never)

If you like, replace some questions with your own, for example a question about your
territory. For each question you replace:

1. **Keep the same category**, so that the test stays balanced.
2. **Write the expected answer, with its source** (the document where you found it).
3. **Keep the table format**: one line per question, cells separated by `|`, the number in the
   first cell. `replay` reads this table.
4. **Save** the file (`Ctrl+S`, or `Cmd+S` on a Mac).

> [!IMPORTANT]
> **Change the questions only BEFORE `replay bare`. Never afterwards.** If a question changes in
> the middle of the day, its scores can no longer be compared.

#### Step 3 - Replay the questions with the model alone

1. **Go to your second terminal** (see [Setup, step 5](#step-5---open-a-second-terminal)).
2. **Type**:

   ```bash
   replay bare
   ```

   Each question is asked to the bare chatbot, in a new conversation. You should see one line
   per question, then the name of the answer file and the total cost:

   ```
   Question 1 (1/11)…
   Question 2 (2/11)…
   …
   Question 11 (11/11)…
   Answers: answers/bare-14h05.md   (cost: $…)
   ```

   The time in the file name and the cost will be different for you.

3. **While it runs**, open the folder `answers/` in the file list: the file is written as the
   answers arrive. You can start reading at once.

#### Step 4 - Read the answer file

The file starts like this:

```
# Answers — mode bare — 2026-10-22 14:05

Score each answer from 0 to 2 in the Bare column of test-questions.md.

## 1. How many hectares burnt in the EU in 2025 according to EFFIS, and how many fires were mapped?
```

Under each question, you find the **answer** of the chatbot, then a line such as
`*Context: … tokens*`: the size of the context for this answer. In later modes, a line
`*What the model did:*` also lists the files it read, the searches it ran and the tools it
called. In mode `bare`, it can do none of this.

#### Step 5 - Score column Bare

1. **Compare** each answer with the expected answer in `test-questions.md`.
2. **Decide** 0, 1 or 2 with the [scoring rules](#how-to-score). Discuss it in your pair: you
   must agree.
3. **Type the score** in the **Bare** column. On each row, the last six cells are the columns
   Bare, A, B, C, D, E. For example, the end of row 1 becomes:

   ```
   … 7 783 fires (summaries/10) | 1 | | | | | |
   ```

4. **Add up** your scores in the row **Total /22**, and **save** the file.

> [!TIP]
> **Look for invented details.** The model alone may give a precise figure, a name of an
> organisation or a website, with great confidence. If it is not in the expected answer, check
> before you give a point. An invented answer gets 0.

### Think about it

The model alone answered some questions without any document. **Where did these answers come
from, and why can't it give a source?** Discuss it in your pair. (Hint: when was the model
trained, and what was in its training?)

You will do the same after each block. **The questions don't change: otherwise nothing is
comparable.**

---

## Block A - Give it a personality (★, 15 min)

### 📖 A system prompt changes how it behaves, not what it knows

**Context**: in the Opening, the model alone did not know who it was talking to, nor what it
was for. It may have invented answers. In this block, you give it **instructions**.

A **system prompt** is a text that the model reads **at the start of every conversation**,
before your first message. It says who the chatbot is, what it is for, and which rules it must
follow. Here, the system prompt is the file `AGENTS.md`. You decide what is in it, **once**,
and it is always read **in full**.

The sections of `AGENTS.md` are **the same as in the WikiYouthBot minimal prompt**: Identity,
Theme, Rules, Quality requirements, Target personas, Reference Q&A, Bans and constraints. What
you write here is exactly what young people will write in the *Instructions* box.

**Goal**: write the system prompt of your chatbot, then measure what it changes.

**What you will discover**:

- **The cost of a system prompt**: it is read at every message, so it takes a place in the
  context window, all the time.
- **What instructions can do**: change the tone, make the chatbot refuse, make it say "I don't
  know".
- **What instructions cannot do**: give knowledge that the model does not have.

**What is provided**:

- `AGENTS.md`: **to complete**. Its seven sections are empty. Each one has a hint between
  `<!--` and `-->`. These hints are comments: **they are not sent to the model**.
- `examples/AGENTS.feurisson.md`: a **complete example**, inspired by Feurisson. It is **not
  read by the chatbot**: only `AGENTS.md` is.
- `CLAUDE.md`: *do not modify*. Claude Code only reads this file, and its only line,
  `@AGENTS.md`, imports your system prompt.

### What to do

1. **Open** `AGENTS.md`, then **open the example next to it**: right-click on
   `examples/AGENTS.feurisson.md` in the file list, then **"Open to the Side"**.
2. **Read the example** section by section. Notice the **Rules**: say "I don't know", never
   invent, point out contradictions, never guess today's level.
3. **Write your own** system prompt in `AGENTS.md`, under each section title. You can take what
   you like from the example, but make it yours: your territory, your audience, your tone.
   Write full sentences, under the titles: **keep the titles as they are**.

   > ⚠️ Don't skip **Rules** and **Quality requirements**: the next blocks are scored on them.
   > For example: what should it answer when it does not know? What should it do when two
   > sources disagree? Should it say where each fact comes from?

4. **Save** the file (`Ctrl+S`).
5. **Start a conversation** in mode A:

   ```bash
   workshop A
   ```

   **Look at the gauge before you type anything**, and compare it with mode `bare`. The
   difference is the cost of your system prompt, paid at every message.

6. **Test the behaviour**. Ask a few questions, for example:
   - `Who are you?`
   - `What is the best insurance company for my house?` (question 9)
   - `How many hectares burnt in Campania in 2025?` (question 7)

   Does it follow your rules? Does it refuse, or reframe? Does it say "I don't know"?
7. **Leave** with `/exit`. If a rule is not followed, change `AGENTS.md`, save, and try again.
8. **Replay** the test questions in your second terminal, then **score column A**:

   ```bash
   replay A
   ```

**What to watch**: the **behaviour** changes (tone, refusals, "I don't know"). The
**knowledge** doesn't. The precise questions (1 to 4) do not improve, or the model makes things
up, sometimes with great confidence.

> [!TIP]
> **Checkpoint before moving on**: `AGENTS.md` has a text under each title, `workshop A` answers
> with your chatbot's identity, and column A is scored.

### Think about it

Even with a perfect system prompt, **why don't the precise questions (1 to 4) improve?**
Discuss it in your pair. (Hint: what is in `AGENTS.md`, and what is not?)

> **You built** a system prompt. **Reused in** the *Instructions* box of a Claude Project or a
> Gemini Gem, and in the "system prompt" field of any chatbot tool.

---

## Block B - Give it everything you know (★, 12 min)

### 📖 Reading everything is simple, but every message pays for everything

**Context**: in block A, the chatbot learnt how to behave, but it still knows nothing about
the documents. The simplest idea is to **give it all the documents**, at the start of each
conversation.

In mode B, **all the summaries and all the readable copies of the documents** are added to the
system prompt. The model reads them before your first question, and again at every message.
This is like the *Knowledge* box of a Claude Project or a Gemini Gem, when it is small enough to
be read in full.

A context window has a maximum size, counted in **tokens**. A token is a piece of a word: on
average, 4 characters of English text. Here the window holds 200,000 tokens. Our documents and
summaries take about 60,000 tokens: **about a third of the window**, before you have typed
anything.

**Goal**: give the chatbot all the knowledge, and see what it gains and what it costs.

**What is provided**:

- `summaries/`: 17 summaries in English. **4 have been checked by a person** ("human-reviewed"
  in the index). The others are drafts, checked only by machines ("machine-confirmed").
- `corpus/`: the 20 official documents, and their readable copies in `corpus/text/`.
- Nothing to write in this block: mode B loads everything for you.

### What to do

1. **Have a look** at `summaries/index.md` and `corpus/index.md`. This is everything we know.
   Notice the label at the end of each summary line: "(human-reviewed)" or "(machine-confirmed)".
2. **Start a conversation** in mode B:

   ```bash
   workshop B
   ```

   Watch the gauge jump to **about a third of the window, before your first question**.
3. **Ask for the details** of the context, in the conversation:

   ```
   /context
   ```

   > [!NOTE]
   > If `/context` does not answer in this mode, the gauge is enough: it gives the same story.

4. **Try the contradiction experiment.** `summaries/10-…` and `summaries/90-…` summarise two
   official pages of the European Commission, published the same day. **They disagree.** Ask:

   ```
   How many hectares burnt outside the EU in 2025?
   ```

   Does the model **point out the contradiction**, or **choose silently**? Real sources
   contradict each other too. Leave with `/exit`.
5. **Replay** the questions in your second terminal, then **score column B**:

   ```bash
   replay B
   ```

6. **Compare the cost** that `replay` prints at the end with the cost of `replay A`. Every
   single message pays for everything that is in the context.

**What to watch**: the precise questions are now answered. But we only have about twenty
documents. **With ten times more, they would not fit in the window at all.**

> [!TIP]
> **Checkpoint before moving on**: you saw the gauge at about a third before any question, you
> tried question 10, and column B is scored.

### Think about it

A youth centre has 200 documents about its town. **Why can't it use mode B?** And even with 20
documents, **why is mode B expensive?** (Hint: look at the gauge, and at what happens at each
new message.)

> **You built** a knowledge base of sourced documents. **Reused in** the *Knowledge* box of a
> Claude Project or a Gemini Gem: when it is small, it is read in full, like here.

---

## Demo - Vector RAG (5 min, by the facilitator)

### 📖 A search engine picks the pieces, and the model sees only those

**Context**: block B does not scale. When the knowledge is too big, most chatbot tools use a
**RAG** (*Retrieval-Augmented Generation*). The facilitator shows one, in another tool, on a
laptop. You only watch and discuss.

> Same documents as block B, cut into 322 small pieces. For each question, a search engine picks
> the 5 pieces that look most like the question. The model sees those 5 pieces, nothing else.

Two new words:

- **Chunk**: a small piece of a document (here, about 1,000 characters).
- **Embedding**: a list of numbers that captures the meaning of a chunk. Two chunks with
  close meanings have close lists of numbers. This is how the search engine finds the chunks
  that "look like" the question.

**What to watch**, for questions 3, 7 and 10:

- **Question 3**: the answer is in one precise sentence of a long order. Is the right piece
  among the 5?
- **Question 7**: nobody knows the answer. Does the search engine return nothing? **A RAG always
  returns something**, even when the answer is nowhere.
- **Question 10**: the two sources disagree. Do both enter the context, or only one?

Compare **what the model saw** (the excerpts) with **what it claims**.

This is what most chatbot tools do when the knowledge is too big to be read in full: fast and
cheap, but the model only sees what the search engine picked.

---

## Block C - Let it search, and curate what it knows (★★★, 30 min)

### 📖 Searching is cheaper than reading everything, and its failures are visible

**Context**: mode B reads everything, and pays for everything. The RAG demo reads only a few
pieces, but **a search engine** chooses them, and it always returns something. In mode C,
**nothing is loaded in advance**. The model knows where the knowledge is (two folders, each with
an index), and **it searches by itself**, step by step, like a person would.

It uses simple file tools: list a folder (`ls`), **search for a word** in files (`grep`), read
a file. When a search finds nothing, the model **sees zero results**. That failure is visible,
and the model can say "I don't know".

**Goal**: watch the model search, then **let a new document in** and vouch for its summary
yourselves.

**What you will discover**:

- **Agentic search**: the model decides what to open, one step after another. You can read
  each step in the conversation.
- **Skills**: written procedures that the model follows when it needs them.
- **Curation**: a person decides what enters the knowledge, and signs what the chatbot says
  about it.

**What is provided**:

- `.claude/skills/`: three skills, **complete**.
  - `summarize`: writes a draft summary of a document of `corpus/`, and a verification table.
  - `validate-summary`: records that a person checked a summary.
  - `source-note`: writes a summary from information you give it.
- `inbox/benevento-campagna-aib-2026.pdf`: a document in Italian, **not in the corpus yet**.
  Question 11 is about it.
- `corpus-add`: the command that adds a document to `corpus/`.

> [!NOTE]
> **Claude Code asks for your permission** before it writes or changes a file. In this block,
> the skills write files: read what it wants to do, then accept (**Yes**). Searching and
> reading do not need your permission.

### Part 1 - Watch the model search

1. **Start a conversation** in mode C:

   ```bash
   workshop C
   ```

   Look at the gauge: it is far below mode B. Nothing is loaded in advance.
2. **Ask question 3** of the test set (copy it from `test-questions.md`):

   ```
   In Bouches-du-Rhône, at which fire-risk levels is access to forest massifs forbidden, and at the 'severe' level, when is work allowed?
   ```

   Its answer is **not in the summaries**: it is only in the full text of an order.
3. **Read the steps** in the conversation. You should see the model read an index, search with
   `grep`, then open a document in `corpus/text/`. It reads only what seems useful. **The gauge
   stays low.** The exact steps may vary from one try to the next.
4. **Ask a question whose answer is nowhere**, for example question 7:

   ```
   How many hectares burnt in Campania in 2025?
   ```

   Watch the searches: they find documents about Campania, but **none of them gives a figure
   for 2025**. The model can see that the answer is not there, and say "I don't know". A RAG
   would still hand it the closest pieces, as if they were the answer.

### Part 2 - Skills: what they are

A **skill** is a folder with a file `SKILL.md`: a procedure the model follows when it needs it.
Only its **description** (at the top of the file) is always in the context. The rest is read
only when the skill is used. So a chatbot can have many skills without filling its context.

1. **Open** `.claude/skills/summarize/SKILL.md`.
2. **Read the header** between the two `---` lines: `name` and `description`. The description
   says **when** the model should use the skill.
3. **Read the steps and the rules**. Notice: "Never add a `verified` entry yourself, and never
   mark a summary as checked." Only a person can do that.

### Part 3 - Let a new document in, and vouch for it

Question 11 is about a document the chatbot does not have yet: the plan of the **Province of
Benevento** (Campania, Italy) for the 2026 fire season. You let it in, and you vouch for it.
This is the work young people do in the *Data Box* of WikiYouthBot.

#### Step 1 - Add the document to the corpus

1. **Open** `inbox/README.md` and **copy** its `corpus-add` command. It is one single line.
2. **Paste it** in the terminal (outside a conversation) and press **Enter**.

You should see:

```
Added: corpus/80-benevento-aib-2026.pdf (original, unchanged)
       corpus/text/80-benevento-aib-2026.md (readable copy, about 1,346 tokens)
Next, in "workshop C": summarize corpus/80-benevento-aib-2026.pdf
```

The document gets a number: **80**, or the next free one between 80 and 89. In the next steps,
use **your** number. Three things happened: the original is kept **unchanged** in `corpus/`, a
readable copy goes to `corpus/text/`, and a line is added to `corpus/index.md`.

#### Step 2 - Let the model write a draft summary

1. **In** `workshop C`, **ask**:

   ```
   summarize corpus/80-benevento-aib-2026.pdf
   ```

2. **Accept** when Claude Code asks for permission to write files. The `summarize` skill writes
   two files and adds a line to `summaries/index.md`:
   - `summaries/80-benevento-aib-2026.md`: the **draft summary**, 5 to 15 short sentences in
     English, one fact per sentence. Its header says `status: draft`, with no `verified` line.
   - `summaries/checks/80-benevento-aib-2026.md`: the **verification table**, with one row per
     sentence:

     ```
     | # | Sentence of the summary | Original passage (copied word for word) | OK? | Correction |
     ```

     The original passage is copied exactly, in Italian, so that you can find it with `Ctrl+F`.

#### Step 3 - Check each sentence yourselves

1. **Open** the table `summaries/checks/80-benevento-aib-2026.md`.
2. **Open the original document next to it**: right-click on `corpus/80-benevento-aib-2026.pdf`,
   then **"Open to the Side"**. The PDF viewer opens.
3. **For each row**: copy a few words of the original passage, search them in the PDF with
   `Ctrl+F`, and compare. Do this **even in Italian**: dates and numbers are easy to compare.

   > 💡 If `Ctrl+F` does not find a passage in the PDF (a line break can cut it), search it in
   > the readable copy, `corpus/text/80-benevento-aib-2026.md`.

4. **Fill the "OK?" column**: `yes` if the sentence says what the passage says, or write the
   right version in the "Correction" column.
5. **Save** the table.

> [!IMPORTANT]
> **Every row must be checked.** A general "it's fine" is not enough: the skill will list the
> rows that are not checked, and ask you to check them. Resist the temptation to trust the draft
> because it looks right. **You** sign it, not the model.

#### Step 4 - Validate the summary

1. **Tell the chatbot** that you checked it, with your name:

   ```
   I checked summary 80, I am <first name last name>
   ```

   or, if a sentence is wrong:

   ```
   sentence 3 is wrong, it should be …
   ```

2. The `validate-summary` skill applies **only your corrections**, then **shows you the
   corrected sentences and asks you to confirm them**. Read them, and confirm.
3. **Accept** the file changes. The skill then adds your name to the header, in a line
   `verified`, as `human:<first-name-last-name>` (for example `human:maria-rossi`), and sets
   `status: stable`.

#### Step 5 - Check the result

1. **Open** `summaries/index.md`. At the bottom, under "Added during the session", your summary
   went from **"(draft, not verified)"** to **"(human-reviewed)"**.
2. **Leave** the conversation with `/exit`.
3. **Replay** the questions in your second terminal, then **score column C**:

   ```bash
   replay C
   ```

**Question 11 can now be answered: by you, not by the model.** Before you added the document,
"I don't know" was worth 1. Now the right answer is in the corpus, and a person has checked it.

> [!TIP]
> **Checkpoint before moving on**: `corpus/80-…` exists, `summaries/index.md` says
> "(human-reviewed)" for it, and column C is scored.

### Think about it

The model wrote the summary, and it was probably right. **Why is it a person's name, and not the
model's, in the `verified` line?** Discuss it in your pair. (Hint: if a young person reads a
wrong date in the chatbot, who is responsible for it?)

### To go further (if time allows)

- **Add an official document of your own territory**: a web page, or a PDF that contains text.

  ```bash
  corpus-add "<address of the document>" --name <short-name>
  ```

  Then summarise it, check it and validate it, like Benevento. `corpus-add --help` explains all
  the options. A scanned PDF (only images) is refused: it has no text to read.
- **Create your own skill**: a folder `.claude/skills/<name>/` with a file `SKILL.md` that has
  the same header (`name`, `description`). Test it until it triggers **when it should, and only
  when it should**.

> **You built** a curation process: a person decides what gets in, and signs what the chatbot
> says about it. **Reused in** any chatbot: the *Knowledge* box is only as good as what you put
> in it. With young people: the Data Box of WikiYouthBot.

---

## Block D - Connect it to live data (★★, 13 min)

### 📖 No document can say what the danger is today: a tool can

**Context**: in block C, the chatbot learnt to search its documents. But documents are written
in advance. **No document can say what the fire danger level is today.** For this, the model
needs a **tool**: a small program that it can call, and that reads an official source of the
day.

**MCP** (*Model Context Protocol*) is a standard way to give tools to a model. The model does not
read the tool's data in advance: **it decides to call the tool** when a question needs it, and
only the tool's answer enters the context.

**Goal**: connect the chatbot to a live-data tool, and fill in today's data from the official
source.

**What you will discover**:

- **A tool call**: you see the model call a tool, and what the tool answers.
- **A deterministic tool**: it gives what the source says, nothing else. It never guesses.
- **Who fills the data**: here, you do, by hand, from the official page.

**What is provided**:

- `.mcp.json`: declares a small server, `mcp/fire_danger_server.py`. *Do not modify.*
- `mcp/fire_danger_server.py`: the tool server, with two tools: `territories` (the list of
  territories) and `fire_danger` (today's level for a territory). *Do not modify.*
- `mcp/fire-danger.json`: the data the tool reads, **to complete**. For five territories, it
  has a `scale` and a `source`, already checked by the facilitator (for Naples, they are still
  "TO BE COMPLETED"). The `date` and each `level` are **empty**: you fill them in today.

### What to do

1. **Start** mode C again, and ask:

   ```bash
   workshop C
   ```

   ```
   What is the fire danger level today in Antwerp?
   ```

   It cannot know. Leave with `/exit`.
2. **Start** mode D and ask the same question:

   ```bash
   workshop D
   ```

   Watch the **call to the `fire_danger` tool**. The level is still empty in the file, so the
   tool can only answer "TO BE COMPLETED". Does the model say that it does not know today's
   level, or does it guess?
3. **Look at the tool**: in the conversation, type `/mcp`. It shows the server `fire-danger` and
   its tools.
4. **Fill in today's data**. Open `mcp/fire-danger.json`:
   1. **Write today's date** in `date`, in the form year-month-day, for example `"2026-10-22"`.
   2. **Open the source of Antwerp** in a new browser tab: https://natuurenbos.be/waarschuwingen
      (province Antwerpen).
   3. **Copy today's colour code** into the `level` of Antwerp (for example `"groen"`), or
      `"season over"` if the source says so. The scale is in the file: groen, geel, oranje,
      rood.
   4. **Save** the file (`Ctrl+S`).

   > [!WARNING]
   > **Keep the quotes and the commas** of the file. If one is missing, the tool answers
   > `fire-danger.json is malformed (…). Fix it and try again.` Compare your line with the
   > lines around it.

5. **Back in the conversation, ask**: `check again`. The answer follows, **without restarting**:
   the tool reads the file at each call. The tool is deterministic: it gives what the source
   says, nothing else.
6. **Leave** with `/exit`, then **replay** and **score column D**:

   ```bash
   replay D
   ```

**Question 8 is the one that changes.**

> [!TIP]
> **Checkpoint before moving on**: `date` and the Antwerp `level` are filled, `workshop D`
> answers question 8 with a call to `fire_danger`, and column D is scored.

### Think about it

The tool gives exactly what you typed, nothing more. **Why is that better than a model that
"knows" today's level?** (Hint: in late October, the fire season is over in most of our
territories. What would a model that guesses say?)

### To go further (if time allows)

- **Fill in your own territory** in `mcp/fire-danger.json`: open its `source`, and copy today's
  level and one piece of advice per line into `advice`. Then ask the chatbot about it.

> **You built** a tool connection. **Reused in** chatbot tools that accept tools or MCP servers;
> with young people: "a live source per bot" (today's danger, the robot's sensors).

---

## Block E - Organise what it knows: the wiki (★★★, 18 min) - Capstone

### 📖 A wiki written in advance saves searching at every question

**Context**: in block C, the model searched the documents again **at every question**. It found
facts, but it never kept what it learnt. Another idea: let the model **write and maintain a
wiki**. A wiki is a set of pages **by topic**, linked together, where **each fact has a
footnote** (`[^id]`) to its source. The work is done **beforehand**. At question time, the
model reads pages already written.

The facilitator built a wiki before the session, from all the documents of `corpus/` (but not
the Benevento one: you added it yourselves), then checked it.

**Goal**: open the wiki, look at its map, add your Benevento summary to it, and let the model
check its consistency.

**What you will discover**:

- **Footnotes**: every fact of a page leads back to its source document.
- **The log**: the history of the wiki, including the **contradictions** found between sources.
- **Two new skills**: `ingest` (add a source to the wiki) and `lint` (check the wiki).

**What is provided**:

- `wiki-start`: unpacks the wiki in `wiki/`, with the skills `ingest` and `lint`.
- `wiki-graph`: draws the map of the wiki in `wiki/graph.md`.
- Your summary 80, validated in block C.

### What to do

1. **Unpack the wiki** (in the terminal, outside a conversation):

   ```bash
   wiki-start
   ```

   You should see:

   ```
   Wiki ready: 18 pages in wiki/ (start with wiki/index.md, history in wiki/log.md).
   New skills: ingest and lint (.claude/skills/).
   Next: workshop E, then for example: ingest summaries/8N-… into the wiki
   ```

2. **Explore the wiki**:
   1. **Open** `wiki/index.md`, then one page, for example `wiki/2025-eu-wildfire-season.md`.
      Each fact ends with a footnote such as `[^jrc2025]`. At the bottom of the page, the
      footnote gives the title of the source. In the header at the top, `sources` gives its
      file in `corpus/`.
   2. **Open** `wiki/log.md`: the history of the wiki. Look for the lines **Contradiction**.
3. **Draw the map**:

   ```bash
   wiki-graph
   ```

   You should see:

   ```
   Wrote wiki/graph.md: 18 pages, 20 source documents.
   To view it in VS Code: open wiki/graph.md and press Ctrl+Shift+V (Cmd+Shift+V on a Mac). This needs the extension bierner.markdown-mermaid.
   ```

   **Open** `wiki/graph.md` and press `Ctrl+Shift+V`. The legend:

   | Shape | Meaning |
   |---|---|
   | Rectangle | a page of the wiki |
   | Solid arrow | one page links to another |
   | Cylinder | a full document of `corpus/` |
   | Rounded shape (green) | a summary of `summaries/` |
   | Dotted arrow | from a document to each page that cites it |
   | Red dashed outline | cited, but does not exist |
   | Orange | the highlighted document, and the pages that cite it |

   The facilitator projects the same map for the whole wiki.
4. **Add your Benevento summary**. Your document is not in the wiki yet. Start mode E:

   ```bash
   workshop E
   ```

   then ask (with your number):

   ```
   ingest summaries/80-benevento-aib-2026.md into the wiki
   ```

   **Accept** when it asks for permission to write. The `ingest` skill updates or creates
   **1 to 5 topic pages**, puts a footnote on each fact, compares every figure with the wiki,
   and writes a line in `wiki/log.md`. **Watch which pages change.** Its report lists the pages
   created and updated, and the contradictions it found.
5. **See where your document went**, in the second terminal:

   ```bash
   wiki-graph --highlight 80
   ```

   Open `wiki/graph.md` again (`Ctrl+Shift+V`): **your document and the pages it feeds are
   orange.**
6. **Check the wiki**. In the conversation, ask:

   ```
   lint the wiki
   ```

   The model checks footnotes, links and contradictions. **It fixes nothing without your
   agreement**: the lint reports, the human decides. Leave with `/exit`.
7. **Replay** and **score column E**:

   ```bash
   replay E
   ```

> [!NOTE]
> **When two sources disagree, the wiki keeps both.** The rule of `ingest` is to write
> "According to one source, X; according to another, Y", with a footnote on each, and never to
> drop or reword a figure. This is why the log lists contradictions instead of hiding them.

> [!TIP]
> **Checkpoint before the Closing**: `wiki-graph --highlight 80` shows orange pages, the lint
> gave its report, and column E is scored.

### Think about it

The wiki found contradictions between official sources (for example 10 and 90). **Why must it
never choose one figure on its own?** (Hint: think of a young person who quotes the chatbot in a
talk, and a listener who read the other source.)

> **You built** a knowledge base that stays organised as it grows. **Reused in** the *Knowledge*
> box, when you give it clean pages instead of raw documents.

---

## Closing - Compare, and take it home (12 min)

### Compare the columns

1. **Open** `test-questions.md` and look at your six columns, from Bare to E.
2. **Discuss in your pair**: what improved, what got worse, and **at what context cost**? Each
   answer in `answers/` shows the size of the context used.
3. **Remember**: the same score with a smaller context **is a result**.
4. **Plan your own chatbot**, in your pair, in a few lines: what its *Instructions* would say
   (identity, theme, two rules), and which three documents of your territory would go into its
   *Knowledge*. Keep it: it is the starting point of your own WikiYouthBot session.

### Two more levels (on a slide)

The facilitator presents two more ways to customise a chatbot:

- **Level 4 - A local model**: the same steps, on your own machine. Nothing leaves it.
- **Level 5 - Fine-tuning**: the model is trained again on your knowledge. Nothing enters the
  context: the knowledge is in the model itself, and it is much harder to check or correct.

### Back to WikiYouthBot

With young people, you will customise a chatbot in a Claude Project or a Gemini Gem. There are
**only two boxes** there. Today you have seen what happens behind them.

| WikiYouthBot step | What the group does | Box | Here |
|---|---|---|---|
| 1. I Heard a Rumor | first rules, verification reflexes | Instructions | `AGENTS.md`, block A |
| 2. The Press Conference | 10 questions, quality requirements | Instructions | `test-questions.md`, `replay` |
| 3. The Data Box | local documents, figures, Q&A | Knowledge | `corpus/`, `summaries/`, blocks B and C |
| 4. The Chatbot Studio | personality, personas, mascot | Instructions | `AGENTS.md`, block A |

The **Instructions** box is block A: always read, in full. The **Knowledge** box is block B or
the RAG demo: depending on the tool and on its size, it is read in full or searched for
excerpts. You cannot see which from the outside: **that is why the test questions matter.**

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

Tools to build your own chatbot:

- **No code**: a Claude Project or a Gemini Gem (Instructions + Knowledge).
- **Your own server**: Open WebUI, the tool of the RAG demo (system prompt, knowledge base,
  tools).
- **Visual building blocks**: tools like Flowise or Langflow, where you connect boxes.
- **Code**: libraries like LangChain or LlamaIndex, or the same mechanisms as today (system
  prompt, skills, MCP) with the Claude Agent SDK.

---

## Going further

After the session, if you want to go deeper:

- **Your territory in the corpus**: add an official document with `corpus-add`, then summarise,
  check and validate it (block C, [To go further](#to-go-further-if-time-allows)).
- **Your territory in the live tool**: fill its level and advice in `mcp/fire-danger.json`
  (block D).
- **Your own skill**: write a `SKILL.md` for a task you repeat, and test when it triggers.
- [Model Context Protocol](https://modelcontextprotocol.io): the official site of MCP, the
  standard behind block D.
- [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog) (Google
  Cloud, file `okf/SPEC.md`): the format of the headers of our documents, summaries and wiki
  pages.

---

## Troubleshooting

**`This does not look like a key (it should start with sk-ant- or sk-or-). Nothing saved.`** -
The text you pasted is not a whole key. Copy it again from your card, with nothing before or
after it, and type `workshop-login` again.

**`Key saved, but Anthropic refuses it (HTTP 401). Check it with the facilitator.`** - The key
was saved, but it does not work. Show your card to the facilitator.

**`Key saved, but Anthropic could not be reached (network?). Try: workshop bare`** - The network
did not answer during the test. Your key is saved: try `workshop bare`. If it fails, ask the
facilitator.

**`Key saved, but the test answered HTTP <code> (model <model>). Tell the facilitator.`** - Show
the message to the facilitator.

**`No API key yet. Type: workshop-login`** - You have not saved your key yet. Do
[Setup, step 3](#step-3---save-the-key-of-your-pair).

**`Unknown mode: Z. Modes: bare, A, B, C, D, E (workshop help).`** - Check the letter after
`workshop` or `replay`. The modes are `bare`, `A`, `B`, `C`, `D` and `E`.

**`No wiki yet. First type: wiki-start`** - Mode E needs the wiki. Type `wiki-start` first
(block E, step 1).

**"I cannot leave the conversation!"** - Don't panic. Type `/exit` and press Enter. If nothing
happens, press `Ctrl+C` twice.

**The key does not appear when I paste it.** - This is normal: it is hidden, like a password.
Paste it once, then press Enter.

**Claude Code asks "Do you want to…?" before writing a file.** - This is normal: it asks for your
permission each time a skill writes or changes a file. Read what it wants to do, then accept.

**In `replay`, a line says `ERROR: …`.** - This answer failed: in the file it is marked
`**ERROR, do not score this one: …**`. If you see
`Three errors in a row: stopping. Check the key (workshop-login) and the network.`, check your
key, then ask the facilitator.

**`Warning: the model looked at the test material.`** - The model opened `test-questions.md`,
`answers/` or `examples/` to answer. It may have copied the expected answer: score this answer
0.

**`replay` takes a long time.** - Each question is a new conversation. You can go on working in
your first terminal. If time is short, the facilitator may ask you to replay only some
questions, for example `replay D 8 11`.

**`File not found: …`** (from `corpus-add`) - Check the name of the file. For the Benevento
document, copy the command of `inbox/README.md` again: it is one single line.

**`Not added: almost no text could be read (…). A scanned PDF (only images)? Ask the facilitator.`** -
This PDF is a picture of a page, with no text inside. The chatbot could not read it. Choose
another document, or ask the facilitator.

**`Could not download <address> (…)`** - Some websites refuse downloads. Save the document on
your computer, drag it into the file list of the Codespace, then give its file name to
`corpus-add`.

**`fire-danger.json is malformed (…). Fix it and try again.`** - A quote or a comma is missing in
`mcp/fire-danger.json`. Compare the line you changed with the lines around it, save, and ask
again.

**The map in `wiki/graph.md` shows text, not a drawing.** - Open the preview with `Ctrl+Shift+V`
(`Cmd+Shift+V` on a Mac), not the file itself. Run `wiki-graph` again after each ingest: the
file is rewritten from scratch.

**The Codespace stopped.** - It stops after a long pause. Reopen it from
https://github.com/codespaces: nothing is lost. To avoid it, see
[Setup, step 2](#step-2---let-the-codespace-wait-for-you).

**Something else?** - Raise your hand: the facilitator is here for this. Your files stay in the
Codespace.

---

*Youth AI Lab (Erasmus+) - Workshop "Customising a chatbot" - 2026*
