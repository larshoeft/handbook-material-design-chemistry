---
name: quellen-nachtragen
description: Trägt fehlende Quellen mit DOI über Crossref in die Zotero-Bibliothek Handbook ein und stellt Textzitate auf [@key] um. Nutzen, wenn Quellen in STATUS.md offen sind oder neue Literatur ergänzt werden soll.
---

# Quellen nachtragen

Skripte in `.claude/skills/quellen-nachtragen/scripts/`: `crossref_pruefen.py` und `zitate_umstellen.py`

## Ablauf

1. **DOIs prüfen.** `python crossref_pruefen.py STATUS.md` ausführen. Abweichungen bei Person, Titel oder Jahr vorlegen, bevor etwas eingetragen wird. Ist das Jahr nur wegen Online-Vorabveröffentlichung anders, gilt das Heftjahr.

2. **Eintragen.** Mit `zotero_switch_library` zu `Handbook` wechseln (Gruppe 6433319). `zotero_add_item` mit `source_type: doi`, `if_exists: file` und `attach_mode: none` nutzen. DOIs, die Crossref nicht kennt (z. B. DataCite), über die CSL-Daten von doi.org und `source_type: csl_json` eintragen.

3. **Einträge prüfen.** Stichprobe mit `zotero_get_item_metadata`: Bibliothek ist `Handbook`, `citationKey` hat das Format `autorjahr_titelwort`. Eintragstyp, Buchtitel und Herausgeber:innen bei Kapiteln kontrollieren, die liefert Crossref oft nicht. Deutsche Einträge bekommen die Sprache `de`.

4. **Export.** `zotero.bib` muss die neuen Einträge enthalten. Danach `literatur-pruefen` ausführen.

5. **Zitate umstellen.** `python zitate_umstellen.py` zeigt die Änderungen, `--schreiben` führt sie aus. Nur eindeutige Treffer nach Person und Jahr werden umgestellt, Sammelzitate behalten fehlende Quellen als Text. Vollständige Angaben in Listen von Hand zu `@key` ändern. Die ausgegebene Zuordnung immer gegen Titel oder DOI prüfen, denn gleiche Person und gleiches Jahr beweisen nicht dasselbe Werk.

6. **Abschließen.** Erledigte Zeilen aus `STATUS.md` entfernen, `quarto render` ausführen und die Literaturlisten ansehen. Danach den Agenten `quellen-abgleich` starten. Nicht ohne Anweisung committen.

Ohne DOI wird nichts geraten. Solche Quellen bleiben in `STATUS.md`.
