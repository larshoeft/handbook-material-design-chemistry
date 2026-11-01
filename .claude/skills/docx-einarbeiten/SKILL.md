---
name: docx-einarbeiten
description: Arbeitet einen Word-Text aus _quellen_docx/ wortgetreu in eine .qmd-Datei ein und prüft das Wort für Wort. Nutzen, wenn ein Steckbrief, Kriterium oder Kapitel aus Word übernommen werden soll.
---

# Word-Text einarbeiten

Der Wortlaut bleibt unverändert, auch bei Tippfehlern und Stilproblemen. Erlaubt sind nur Markdown-Formatierung, die Zeichentabelle aus `.claude/CLAUDE.md` und Zitate als `[@key]`.

Skript: `.claude/skills/docx-einarbeiten/scripts/docx_vergleich.py`

## Ablauf

1. **Voraussetzungen.** Der Git-Stand muss sauber sein, sonst abbrechen und nachfragen. Zielzeile in `STATUS.md` suchen.

2. **Analyse.** `python <skript> analyse "<datei>"` ausführen. Änderungen, Kommentare und Markierungen zeigen und je Datei entscheiden lassen, ob angenommen, abgelehnt oder erst in Word geklärt wird. Nichts davon still übergehen. Kommentare und Markierungen kommen nur in den Bericht.

3. **Umwandeln.** `python <skript> markdown "<datei>" --aenderungen accept` oder `reject` ausführen. Die Ausgabe enthält schon die einfachen Zeichen und keine Attribute wie `{.underline}`.

4. **Überschriften.** Ohne Word-Formatvorlagen die Kandidaten aus der Analyse den Abschnitten der Vorlage zuordnen und bestätigen lassen. Abschnittsnamen bleiben wie in Word. Abweichungen von der Vorlage werden gemeldet, nicht geändert. Eine Kopfzeile wie „Kontextualisierung -- Maximilian Traub“ wird zu Titel und Person und im Bericht genannt.

5. **Zitate.** Für Zotero-Felder gilt die Zuordnung aus der Analyse. Sonst Textzitat und Literaturliste gegen `zotero.bib` abgleichen. Nur eindeutige Treffer werden zu `[@key]`, unsichere werden gemeldet und nie geraten. Fehlt die Quelle, bleibt das Textzitat stehen, und die Angaben aus Word kommen in `STATUS.md`. Das Word-Literaturverzeichnis wird nicht übernommen. Vollständige Literaturangaben im Fließtext werden zu `[@key]`, weil die Liste unter `### Quellen` automatisch entsteht. Das gilt als erklärte Abweichung im Wortvergleich.

6. **Weitere Inhalte.** Bilder nach `img/` kopieren, mit Dateiname `<ziel>_<name>`. Bei Diagrammen danach `.venv/Scripts/python scripts/hintergrund_transparent.py img/<datei>` ausführen und das Ergebnis auf hellem und dunklem Grund ansehen, Fotos überspringt das Skript. Fußnoten übernehmen. Tabellen möglichst als Pipe-Tabellen, sonst melden.

7. **Ersetzen.** Text in der Zieldatei ersetzen, weil Word führend ist. `sec-…`-Block, ID und `### Quellen` bleiben. Die wegfallenden Passagen aus dem Diff gehören in den Bericht.

8. **Wortvergleich.** `python <skript> vergleich "<datei>" <qmd> --aenderungen <wahl> --zitate` ausführen. Mit `--ohne-kopf <n>` werden die Wörter einer Word-Kopfzeile übersprungen. Exit-Code 1 bedeutet Abweichungen. Jede Abweichung korrigieren oder begründen, bis nur erklärte übrig sind. Die Zitatlisten beider Seiten vergleichen, weil der Textvergleich Zitate ausblendet.

9. **Abschluss.** `quarto render` ausführen und `STATUS.md` aktualisieren. Abweichungen von den Schreibregeln bleiben im Text und werden dort unter „Nach dem Import über alle Texte vereinheitlichen“ ergänzt, falls noch nicht aufgeführt. Nicht ohne Anweisung committen.

## Bericht

- Entscheidungen zu Änderungen, Kommentare und Markierungen
- Zuordnung der Überschriften
- Zitate, umgestellt, unsicher und ohne Quelle
- Bilder, Tabellen und Fußnoten
- Passagen, die nur im Repo standen und wegfallen
- Ergebnis des Wortvergleichs mit allen verbleibenden Abweichungen
