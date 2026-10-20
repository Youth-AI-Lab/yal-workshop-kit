# Inbox — documents not yet in the corpus

The chatbot does not know these documents yet. In block C, you let one in yourselves: you add
it to `corpus/`, the model summarises it, and you check the summary.

`benevento-campagna-aib-2026.pdf`: the plan of the Province of Benevento (Campania, Italy) for
the 2026 forest-fire campaign, in Italian. Question 11 of the test set is about it.

To add it, copy this command into the terminal (it is one single line):

    corpus-add inbox/benevento-campagna-aib-2026.pdf --name benevento-aib-2026 --title "Campagna AIB 2026 — Provincia di Benevento" --publisher "Provincia di Benevento (Campania)" --language it --description "Province of Benevento (Campania) plan for the 2026 forest-fire campaign." --url "https://www.provincia.benevento.it/system/files/field/allegati/2026/06/campagna_aib_2026_-_provincia_di_benevento_signed.pdf"

You can also add a document of your own territory: a web page, or a PDF that contains text.

    corpus-add "<address of the document>" --name <short-name>
