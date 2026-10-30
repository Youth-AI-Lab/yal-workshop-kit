# Youth AI Lab - Customising a chatbot

### Erasmus+ project Youth AI Lab - a series of five hands-on workshops for youth workers

- **Project:** Youth AI Lab (Erasmus+), with five partners:
  - L.A.B. (Aix-en-Provence, France)
  - UAB (Barcelona, Spain)
  - Perlatecnica (Naples, Italy)
  - Digitale Wolven (Antwerp, Belgium)
  - CSC Vent des Îles (La Rochelle, France)

> 🎯 **Five workshops of 2 hours, in pairs.** The goal is to **see what happens behind a
> chatbot**: what it reads before it answers, and who decides what it reads. Each workshop adds
> one piece to the chatbot of your pair. You can use what you learn if you run the
> **WikiYouthBot** activity with young people.

> 🎓 **Each workshop has its own repository**, with its own Codespace link: see
> [The series](#the-series). This repository is the **whole kit**: everything the five workshops
> use, in one place. The setup, the commands and the common problems are in [SETUP.md](SETUP.md).

### Contents

- [The series](#the-series)
- [Why this approach?](#why-this-approach)
- [What the chatbot can know](#what-the-chatbot-can-know)
- [The work loop](#the-work-loop)
- [How to score](#how-to-score)
- [From one workshop to the next](#from-one-workshop-to-the-next)
- [Going further](#going-further)

---

## The series

All five workshops answer **the same question**:

> **What enters the model's context, when, and who decides?**

The **model** is the program that writes the answers (here: Claude, made by Anthropic). The
**context** is everything the model reads before it answers: your question, its instructions,
and any document it was given. The model knows nothing else about your situation.

| # | Workshop | Question of the day | What your pair leaves with |
|---|---|---|---|
| 1 | [Instructions and knowledge](https://github.com/Youth-AI-Lab/yal-workshop-preprompt) | What does the chatbot read before it answers? | your system prompt (`AGENTS.md`), your question 12, columns Bare and A |
| 2 | [When knowledge overflows: everything in the context, then RAG](https://github.com/Youth-AI-Lab/yal-workshop-rag) | Who picks the pieces? | columns B and RAG |
| 3 | [Let it search, give it know-how](https://github.com/Youth-AI-Lab/yal-workshop-search) | What if the model searched by itself? | a document of your territory, checked by you; your own skill; column C |
| 4 | [Plug in tools](https://github.com/Youth-AI-Lab/yal-workshop-tools) | What happens when the chatbot acts outside? | your territory in the live-data tool, with its source; column D |
| 5 | [Organise what it knows](https://github.com/Youth-AI-Lab/yal-workshop-wiki) | How do you keep knowledge clean when it grows? | your document in the wiki; column E; the chatbot of your territory, packed |

Each workshop **stands on its own**, in its own repository, with only what it needs: if you
missed one, `workshop-start` puts in place what the earlier ones made (see
[From one workshop to the next](#from-one-workshop-to-the-next)).

What enters the context, workshop by workshop:

| Mode | What you add | When it enters the context | Who decides | Workshop |
|---|---|---|---|---|
| `bare` | Nothing: the model alone | - | - | 1 |
| `A` | A system prompt (`AGENTS.md`): who it is, its rules | Always, at startup | You | 1 |
| `B` | Knowledge: all the summaries and documents | Always, in full | You | 2 |
| `RAG` | Excerpts found by similarity, in Open WebUI | Per question | A search engine | 2 |
| `C` | Search in the files, and skills to curate the knowledge | Per question, what it finds | The model, step by step | 3 |
| `D` | A tool that reads live data (MCP) | Per question, if needed | The model, through a tool | 4 |
| `E` | A wiki, organised by topic, each fact with its source | Per question, pages already written | The model, beforehand | 5 |

**All series long**, you practise **testing a chatbot**: the same questions, asked again after
each change, and scored in the same way. This is the most useful habit you can take home.

---

## Why this approach?

- **Why the same questions in every workshop?** Without a fixed test, you only have
  **impressions**. A chatbot can sound better and be wrong more often. With the same questions
  and the same scoring, the columns of your score table can be **compared**. This is also the
  idea of the "Press Conference" in WikiYouthBot.
- **Why is "I don't know" worth more than a wrong answer?** An invented answer looks **exactly as
  confident** as a true one. About fire, a wrong rule can be dangerous. So an invented answer
  gets **0**, and an honest "I don't know" gets **1** (or **2** when the answer exists nowhere).
- **Why Claude Code in a terminal, and not a chat website?** On a chat website, you see the
  boxes, but not what happens behind them. Here, you **see everything**: how full the context
  is, every file the model opens, every search, every tool it calls.
- **Why one theme for the whole series?** With one running example, the steps can be compared.
  Our theme is **wildfire prevention**, with real official documents from the EU, France,
  Catalonia, Flanders and Italy. Our running example is **Feurisson**, a chatbot that young
  people in La Rochelle made to help prevent wildfires.
- **Why the same model for everyone?** Comparing two versions of a chatbot only makes sense with
  the **same base model**. The model is set for all pairs when you save your key.

**The chatbot is what you study.** It can be wrong, and sound sure of itself. Each time, look
at **what it read**, and compare with the source.

### How this connects to WikiYouthBot

In the WikiYouthBot activity, the chatbot is built in a tool with **two boxes**: *Instructions*
and *Knowledge*. You can already do it today with **Open WebUI**, a chat tool that your
organisation runs for a group: follow the [Open WebUI guide](https://github.com/Youth-AI-Lab/yal-openwebui-guide). The series shows what
happens behind these two boxes.

| WikiYouthBot step | What the group does | Box | In the series |
|---|---|---|---|
| 1. I Heard a Rumor | first rules, verification reflexes | Instructions | the five personalities, workshop 1 |
| 2. The Press Conference | questions, quality requirements | Instructions | `test-questions.md`, `replay`, every workshop |
| 3. The Data Box | local documents, figures, Q&A | Knowledge | `corpus/`, `summaries/`, workshops 2 and 3 |
| 4. The Chatbot Studio | personality, personas, mascot | Instructions | `AGENTS.md`, workshop 1 |

You cannot see from the outside how a box is used. **That is why the test questions matter.**

---

## What the chatbot can know

| Folder | What it holds | Who writes it |
|---|---|---|
| `corpus/` | **20 official documents** (web pages, PDF, Word), exactly as they were retrieved, never modified. A readable copy of each one is in `corpus/text/`. Start with `corpus/index.md`. | The authorities |
| `summaries/` | **One short summary in English per document.** Start with `summaries/index.md`: it says which ones a person has checked ("human-reviewed"). | The model; then a person checks it |
| `inbox/` | A document that is **not in the corpus yet**. You add it in workshop 3. | - |
| `wiki/` | Appears in workshop 5: pages by topic, each fact with a footnote to its source. | The model |

Every file of `corpus/text/`, `summaries/` and `wiki/` starts with a small **header** in the
**Open Knowledge Format (OKF)**: its type, its source, who wrote it, and who verified it. In a
summary, an entry of the `verified` list that starts with `by: human:` means that **a person**
checked it against the source. `status: draft` means that **no person** has checked it yet.

## The work loop

In every workshop, you repeat **the same work loop**. Each workshop changes step 2.

1. **Read** the context: what problem did the previous step leave?
2. **Add** one thing to the chatbot (a system prompt, knowledge, a tool...).
3. **Chat** with it: `workshop <mode>`. Watch the gauge, and read what the model does.
4. **Predict** which questions will improve, and why.
5. **Replay** the test questions: `replay <mode>`.
6. **Score** each answer from 0 to 2, in the column of the mode, in `scores.md`.
7. **Compare** with the previous column, in your pair: what improved, what did not, at what cost?

---

## How to score

The rules are also at the top of `test-questions.md`.

| Score | When |
|---|---|
| **2** | Right, **and** it says where it comes from. For questions 7 ("unknown") and 9 ("out of scope"), the right answer is to say so. |
| **1** | Honest but not enough: it says it cannot know although the answer exists (in the documents or through a tool), or it is right without its source, or only partly right. |
| **0** | Wrong or invented. **An invented answer is worse than "I don't know".** |

So "I don't know" gets **2** when the answer exists nowhere (question 7), and **1** when it
exists somewhere the chatbot cannot reach yet (in a document or through a tool).

There are 12 questions: 11 ready to use, and **question 12, which you write** about your
territory in workshop 1. The total of a column is out of **24**.

> ⚠️ **Important.** **If an answer says "Warning: the model looked at the test material", score it 0.** The model
> opened `test-questions.md`, `answers/` or `examples/`: it may have copied the expected answer.
> An answer marked **ERROR** is not scored at all.

> 💡 **Tip.** **The reflex of the whole series**: after each answer, ask yourselves **"What
> entered the context, when, and who decided?"**. Look at the gauge, then at what the model read.

---

## From one workshop to the next

Each workshop starts in a **new Codespace**: a Codespace that you do not use is deleted after 30
days, and the free quota of GitHub is limited. Your work travels in a `.zip` file.

1. **At the end of a workshop**, type `workshop-save`, then right-click on `my-work.zip` in the
   file list, then **"Download"**.
2. **At the next workshop**, open a new Codespace from the repository of that workshop
   ([SETUP.md](SETUP.md), steps 1 to 5), drag `my-work.zip` into the file list, then type, with
   the number of the workshop:

   ```bash
   workshop-start 2 --from my-work.zip
   ```

   It saves first what is already there, puts your files back, and adds what the earlier
   workshops made, the kit's example if you have none (for example Feurisson as `AGENTS.md`).

> ℹ️ **Note.** **Free quota**: GitHub Free gives 120 core-hours a month, which is **60 hours** on
> the 2-core machine of the kit, and 15 GB-months of storage. Delete your Codespaces at
> **https://github.com/codespaces** once your work is downloaded.

---

## Going further

The workshops show one way to build a chatbot. Other guides of the project show others:

- [Open WebUI guide](https://github.com/Youth-AI-Lab/yal-openwebui-guide): one chatbot per topic,
  activity or project, shared with a group during a session.
- [OpenCode guide](https://github.com/Youth-AI-Lab/yal-opencode-guide): a chatbot of your own with
  OpenCode, and five ways to pay for the model.
- [Local AI guide](https://github.com/Youth-AI-Lab/yal-local-ai-guide): a chatbot that runs on a
  computer of your organisation, so that the data does not leave it.
- [Dev containers guide](https://github.com/Youth-AI-Lab/yal-devcontainer-guide): this kit and the
  guides on your own computer, without a Codespace.
- [Hermes guide](https://github.com/Youth-AI-Lab/yal-hermes-guide): an assistant that remembers
  you and helps you prepare your sessions. It is for you, never for use with young people.
- [Model Context Protocol](https://modelcontextprotocol.io): the official site of MCP (workshop 4).
- [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog) (Google
  Cloud, file `okf/SPEC.md`): the format of the headers of our documents, summaries and wiki
  pages.

---

*Youth AI Lab (Erasmus+) - Series "Customising a chatbot" - 2026*
