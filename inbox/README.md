# Inbox - documents not yet in the corpus

> ℹ️ **Note.** This folder is used in **block C** of the workshop (see `README.md`, block C, part 3).

## What this folder is for

The chatbot does **not know** the documents of this folder yet. They are not in `corpus/`, so
the chatbot cannot read them, search them, or quote them. In block C, **you let one in
yourselves**:

1. you add it to `corpus/`, with the command `corpus-add`;
2. the model writes a draft summary of it, with the skill `summarize`;
3. you check the summary, sentence by sentence, against the original;
4. you sign it, with the skill `validate-summary`.

**Why?** A chatbot is only as good as what you put in its knowledge. A person decides what gets
in, and vouches for what the chatbot says about it. With young people, this is the *Data Box*
of WikiYouthBot.

## The document of today

`benevento-campagna-aib-2026.pdf`: the plan of the **Province of Benevento** (Campania, Italy)
for the 2026 forest-fire campaign, in Italian. **Question 11** of the test set is about it.
Before you add it, the best the chatbot can say is "I don't know" (scored 1).

## Step 1 - Add it to the corpus

1. **Copy** the command below. It is **one single line**, even if your screen cuts it:

   ```bash
   corpus-add inbox/benevento-campagna-aib-2026.pdf --name benevento-aib-2026 --title "Campagna AIB 2026 — Provincia di Benevento" --publisher "Provincia di Benevento (Campania)" --language it --description "Province of Benevento (Campania) plan for the 2026 forest-fire campaign." --url "https://www.provincia.benevento.it/system/files/field/allegati/2026/06/campagna_aib_2026_-_provincia_di_benevento_signed.pdf"
   ```

2. **Paste it** in the terminal, outside a conversation, with `Ctrl+Shift+V` (`Cmd+V` on a Mac),
   and press **Enter**. In the terminal, `Ctrl+V` alone may not paste.

You should see:

```
Added: corpus/80-benevento-aib-2026.pdf (original, unchanged)
       corpus/text/80-benevento-aib-2026.md (readable copy, about 1,346 tokens)
Next, in "workshop C": summarize corpus/80-benevento-aib-2026.pdf
```

The options give the information that goes into the header of the readable copy: a short name
(`--name`), the title, the publisher, the language (`it` = Italian), a one-sentence description,
and the address of the original (`--url`).

The document gets the number **80**, or the next free number between 80 and 89. Three things
happened:

- the original PDF is kept **unchanged** in `corpus/`;
- a **readable copy** (the text of the PDF, with an OKF header) goes to `corpus/text/`;
- a line is added to `corpus/index.md`, under "Added during the session".

> ℹ️ **Note.** The file stays in `inbox/` too. This is normal: `corpus-add` copies it, it does not move it.

## Step 2 - Summarise, check and validate

Go on with **block C, part 3, step 2** of `README.md`: in `workshop C`, ask
`summarize corpus/80-benevento-aib-2026.pdf` (with your number).

## To go further: a document of your own territory

You can also add an official document of your territory: a **web page**, or a **PDF that
contains text**. Put the address between quotes:

```bash
corpus-add "<address of the document>" --name <short-name>
```

- **A file on your computer?** Drag it into the file list of the Codespace, then give its file
  name instead of the address.
- **A scanned PDF** (only pictures of pages) is refused: it has no text to read.
- `corpus-add --help` explains all the options.
