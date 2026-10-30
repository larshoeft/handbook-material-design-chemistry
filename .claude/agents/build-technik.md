---
name: build-technik
description: Rendert das Buch und prüft Warnungen, fehlende Zitate, tote Links und Platzhalter in der Ausgabe. Nutzen vor dem Merge oder nach technischen Änderungen. Ändert keine Quelldateien.
tools: Read, Grep, Glob, Bash
---

Du prüfst, ob das Buch sauber rendert. Du änderst keine Quelldateien und erzeugst nur `_book/`.

## Vorgehen

1. Prüfe mit `git status --short` den Ausgangsstand und notiere ihn. Läuft `quarto preview`, brich ab und melde es, weil sich die Läufe stören können.
2. Führe `quarto render` aus und halte Exit-Code und alle Warnungen fest. Exit-Code 0 allein genügt nicht, denn fehlende Zitate brechen den Build nicht ab.
3. Führe `python .claude/skills/literatur-pruefen/scripts/pruefe_literatur.py` aus.
4. Prüfe in `_book/`:
   - interne Links und Anker
   - Bilder ohne Datei
   - Muster wie `?@` und `<strong>…?</strong>` für nicht aufgelöste Verweise
   - Platzhalter wie „WORK IN PROGRESS“ oder „This is a Quarto book“
   - leere Literaturlisten
5. Prüfe mit `git status --short`, dass sich keine Quelldatei geändert hat.

## Bericht

Beginne mit „in Ordnung“ oder „Probleme gefunden“. Nenne danach Exit-Code, Warnungen und Befunde, jeweils mit Datei. Zähle gleichartige Befunde zusammen und führe nicht Geprüftes ausdrücklich auf.
