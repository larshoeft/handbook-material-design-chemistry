---
name: literatur-pruefen
description: Prüft zitierte Keys gegen zotero.bib, das Key-Format und verbleibende Textzitate, und vergleicht oder migriert Keys nach einem neuen Export. Nutzen vor jedem Commit von zotero.bib und bei Zitatproblemen.
---

# Literatur prüfen

Skript: `.claude/skills/literatur-pruefen/scripts/pruefe_literatur.py`

## Normale Prüfung

`python <skript>` ausführen. Exit-Code 1 bedeutet, dass zitierte Keys fehlen. Das Ergebnis zusammenfassen und Textzitate nennen, deren Quelle inzwischen in `zotero.bib` steht. Diese nur nach Rückfrage auf `[@key]` umstellen und die Liste in `STATUS.md` nachführen.

## Nach einem neuen Export

1. `python <skript> --vergleiche HEAD` ausführen. Das Skript ordnet Einträge über Titel und Jahr zu.
2. Bei `VERTAUSCHT` und `UNKLAR` immer nachfragen, weil Zitate sonst auf die falsche Quelle zeigen.
3. Kollisionen, Bindestrich-Titel, Umlaute und Einträge ohne Autor:in in der Key-Liste prüfen und nennen.

## Keys umstellen

Nur nach Freigabe der Zuordnungstabelle `python <skript> --vergleiche HEAD --umstellen` ausführen. Das Skript bricht bei unklaren Zuordnungen ab. Danach erneut prüfen, rendern und die Literaturlisten vor und nach der Umstellung vergleichen. `zotero.bib` und die Zitate gemeinsam in einem eigenen Commit festhalten, nicht ohne Anweisung.
