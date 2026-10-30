---
name: kriterium-anlegen
description: Legt ein neues Kriterium oder Verfahren aus der Vorlage an und bindet es ins Buch ein. Nutzen, wenn ein neuer Text begonnen wird.
---

# Kriterium anlegen

## Ablauf

1. **Fragen.** Klären: Kriterium oder Verfahren, Hauptkapitel, Titel, `sec-`-ID und beteiligte Personen. Noch fehlende Hauptkapitel nicht selbst erfinden, sondern nachfragen.

2. **Personen.** IDs in `book.author` und `contributors` in `_quarto.yml` prüfen. Neue Personen in `contributors` ergänzen. E-Mail und ORCID nur mit Einverständnis eintragen, sonst weglassen.

3. **Datei anlegen.** `part_how/criteria_specific_template.qmd` oder `part_how/frameworks_template.qmd` kopieren, nach `criteria_specific_<name>.qmd` oder `frameworks_<name>.qmd`. Den Block `sec-…`, die ID, den Titel, `author` und `date` anpassen.

4. **Einbinden.** `{{< include … >}}` im Hauptkapitel ergänzen und eine Zeile in `STATUS.md` anlegen.

5. **Prüfen.** `quarto render` ausführen. Es darf keine neue Warnung geben. Nicht ohne Anweisung committen.
