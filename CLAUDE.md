# Handbuch Materialentwicklung

Deutschsprachiges Quarto-Buch zur Entwicklung qualitätsvoller Lehr-Lernmaterialien für den naturwissenschaftlichen Unterricht, mit Schwerpunkt Chemie und Physik. Fachlicher Rahmen sind die Didaktiken der Naturwissenschaften und die Pädagogische Psychologie. Das Buch entsteht gemeinsam in der Community.

**Rollen:** Beitragende schreiben einzelne Texte. Editor:innen prüfen Beiträge fachlich. Maintainer:innen betreuen Technik, Zotero und Veröffentlichung.

## Arbeitsablauf

- Gearbeitet wird auf cau-git mit Branch und Merge Request, Editor:innen prüfen vor dem Merge. GitHub dient nur dem Rendern der Webseite.
- Commit und Push nur auf ausdrückliche Anweisung.

## Übergangsphase: Word ist führend

Bis zur Umstellung auf Git gilt die Word-Fassung in `_quellen_docx/`. Der Ordner ist nur lokal vorhanden und wird nicht committet.

- Reihenfolge ist immer erst importieren, dann aktualisieren.
- Änderungen, die nur im Repo stehen, gehen beim nächsten Import dieses Textes verloren. Inhaltliche Änderungen vor dem Import gehören deshalb in die Word-Fassung.
- Den Stand je Text führt [STATUS.md](STATUS.md).

## Struktur

- Hauptkapitel sind `part_*/_*.qmd` und binden ihre Texte per `{{< include >}}` ein, zum Beispiel `part_how/_criteria_specific.qmd`. Die Kriterien werden später auf mehrere Hauptkapitel aufgeteilt.
- Ein Kriterium oder Verfahren ist eine eigene Datei mit `##`-Überschrift und `sec-`-ID.
- Die Vorlagen [criteria_specific_template.qmd](part_how/criteria_specific_template.qmd) und [frameworks_template.qmd](part_how/frameworks_template.qmd) dienen der Orientierung. Kurzformen der Abschnittsnamen sind erlaubt, und „Einsatzbedingungen/Umsetzungswissen“ und „Transferwissen“ sind optional. Am Ende steht immer `### Quellen` mit `::: sectionrefs`.
- Tabellen und Abbildungen tragen IDs wie `#tbl-…` und `#fig-…`, Abbildungen zusätzlich einen Alt-Text.

## Metadaten und Personen

- Angaben stehen im Block `sec-…:` am Dateianfang (`author`, `date`, `date-modified`, `license`).
- Jeder Abschnitt mit Autor:in bekommt automatisch einen Zitiervorschlag (`extensions.section-authors.citation` in `_quarto.yml`). `citation: false` im Block schaltet ihn ab.
- Personen werden per ID aufgerufen. Herausgeber:innen stehen in `book.author`, alle anderen Beitragenden in `contributors` in `_quarto.yml`. Affiliationen stehen in `affiliations`.
- E-Mail und ORCID werden nur mit Einverständnis der Person eingetragen.

## Literatur

- Quellen liegen in der Zotero-Gruppenbibliothek `Handbook`. Better BibTeX nutzt die Formel `auth.lower + year + "_" + shorttitle(1,0).lower`, zum Beispiel `putwain2018_controlvalue`.
- Keys werden gepinnt, auch bei neuen Einträgen vor dem Export.
- Eine benannte Person exportiert `zotero.bib` von Hand, ohne „keep updated“. Die Datei wird nie von Hand geändert.
- Vor jedem Commit von `zotero.bib` läuft der Skill `literatur-pruefen`.
- Im Text steht `[@key]`. Textzitate sind nur erlaubt, solange die Quelle in Zotero fehlt.
- Keine Aussage ohne geprüfte Quelle. Kennwerte und Details tragen eine Seitenangabe, und im Zweifel gilt der Volltext.

## Zeichen in den Quellen

Quarto setzt die Typografie beim Rendern, deshalb stehen in `.qmd`-Dateien einfache Zeichen. Bestandstexte werden je Text beim Import oder Aktualisieren umgestellt.

| Statt | Schreibe |
|---|---|
| `„…“`, `“…”` | `"…"` |
| `‚…‘`, `’` | `'` |
| `–` | `--` |
| `—` | `---` |
| `…` | `...` |
| geschütztes Leerzeichen | Leerzeichen |
| weiches Trennzeichen | entfernen |

## Schreibregeln für neue Texte

Beim Word-Import gelten diese Regeln nicht, dort bleibt der Wortlaut unverändert.

- Sätze ausformulieren statt Halbsätze mit Doppelpunkt anzuhängen. Ausnahme ist der Doppelpunkt vor einer Aufzählung.
- Gleiche Satzanfänge vermeiden, Autor (Jahr) ist auch als Satzanfang möglich.
- Gender mit Doppelpunkt, zum Beispiel `Autor:innen`.
- Statistische Symbole kursiv, zum Beispiel `*N*`.
- Begriffe der jeweiligen Quelle übernehmen und Konstrukte nicht vermischen.
- Im Kriterium Interesse meint „Interesse“ nur POI und FPM. Vocational Interest und Intrinsic Value der Erwartungs-Wert-Theorie werden mit dem Begriff ihrer Quelle benannt. Einschränkungen werden im Text genannt, statt den Befund zu streichen.

## Technik

- Rendern mit `quarto render`, nicht parallel zu `quarto preview`.
- Zeilenenden sind LF.
- Im Code stehen möglichst wenige und nur sehr knappe Kommentare.
- Filter liegen in `_extensions/` und sind im [README](README.md) beschrieben.

## Skills und Agenten

| Name | Art | Zweck |
|---|---|---|
| `docx-einarbeiten` | Skill | Word-Text wortgetreu importieren |
| `kriterium-aktualisieren` | Skill | Bestehenden Text systematisch überarbeiten |
| `kriterium-anlegen` | Skill | Neuen Text aus der Vorlage anlegen |
| `literatur-pruefen` | Skill | Keys und Zitate prüfen, Keys migrieren |
| `quellenpruefung` | Agent | Aussagen am Volltext prüfen |
| `fachredaktion` | Agent | Fachliche Sicht |
| `struktur-konsistenz` | Agent | Abgleich mit Vorlagen und anderen Texten |
| `build-technik` | Agent | Rendern und Ausgabe prüfen |
| `lua-extensions` | Agent | Filter auf Best Practices prüfen |
