---
name: kriterium-aktualisieren
description: Überarbeitet ein bestehendes Kriterium oder Verfahren systematisch, mit Abgleich zur Vorlage, Quellen- und Fachprüfung und Freigabe vor jeder Änderung. Nutzen, wenn ein vorhandener Text inhaltlich aktualisiert werden soll.
---

# Kriterium aktualisieren

## Ablauf

1. **Status.** In `STATUS.md` nachsehen. Ist der Text noch nicht importiert, warnen, weil Word führend ist und Änderungen beim Import verloren gehen. Dann fragen, ob zuerst `docx-einarbeiten` laufen soll.

2. **Prüfen.** Die Agenten `struktur-konsistenz`, `quellenpruefung` und `fachredaktion` für den Text starten, dazu den Skill `literatur-pruefen`.

3. **Vorlegen.** Befunde zu einer nummerierten Änderungsliste zusammenfassen, nach Gewicht sortiert und jeweils mit Stelle, Vorschlag und Quelle. Noch nichts ändern und je Punkt die Freigabe einholen.

4. **Umsetzen.** Nur freigegebene Punkte umsetzen, nach den Schreibregeln in `CLAUDE.md`. Zeichen des Textes auf die einfachen Formen umstellen. Neue Aussagen brauchen eine geprüfte Quelle, neue Quellen kommen auf die Liste in `STATUS.md`, falls sie in Zotero fehlen.

5. **Abschließen.** `date-modified` setzen, `quarto render` ausführen, `STATUS.md` aktualisieren. Nicht ohne Anweisung committen.

## Bericht

Umgesetzte und abgelehnte Punkte, offene Quellen und was nicht geprüft werden konnte.
