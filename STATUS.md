# Stand der Texte

Word-Dateien liegen in `_quellen_docx/Kapitel/`. Die Spalte „Word-Stand“ nennt die Zahlen vor dem Import.

| Text | Datei im Repo | Word-Datei | Importiert | Word-Stand | Offene Quellen |
|---|---|---|---|---|---|
| Relevanz | `part_why/_importance.qmd` | `2_Relevanz/Entwurf_Einleitung_Relevanz_v2.docx` | nein | | noch nicht geprüft |
| Ausrichtungen | `part_why/_orientations.qmd` | keine | | | |
| Design-Based Research | `part_how/frameworks_dbr.qmd` | `4_Verfahren und Modelle/Steckbrief_DesignBasedResearch_Leander.docx` | nein | 11 Einfügungen, 11 Löschungen, 11 Kommentare | noch nicht geprüft |
| Didaktische Rekonstruktion | `part_how/frameworks_rec.qmd` | `4_Verfahren und Modelle/Steckbrief_Didaktische Rekonstruktion.docx` | nein | | noch nicht geprüft |
| Universal Design for Learning | `part_how/frameworks_udl.qmd` | keine | | | |
| Adaptivität | `part_how/criteria_specific_adaptivity.qmd` | `6_Kriterien/Steckbrief_Adaptivität_Gyde.docx` | ja, 31.10.2026 | | 2, siehe unten |
| Kognitive Belastung | `part_how/criteria_specific_cognitiveload.qmd` | `6_Kriterien/Steckbrief_Cognitive_load_Anja.docx` | ja, 30.10.2026 | 2 Einfügungen, 2 Löschungen (angenommen), 8 Kommentare, 2 Markierungen | 3, siehe unten |
| Interesse | `part_how/criteria_specific_interest.qmd` | `6_Kriterien/Steckbrief_Interesse_Lars.docx` | nein | 159 Einfügungen, 143 Löschungen, 12 Kommentare | noch nicht geprüft |
| Kontextualisierung | `part_how/criteria_specific_context.qmd` | `6_Kriterien/Steckbrief_Kontextualisierung_Max.docx` | nein | | noch nicht geprüft |
| Kumulatives Lernen | `part_how/criteria_specific_cumulative.qmd` | `6_Kriterien/Steckbrief_Kumulatives Lernen_Sascha.docx` | ja, 30.10.2026 | 10 Kommentare | 9, siehe unten |
| Präsenzerleben | `part_how/criteria_specific_presence.qmd` | `6_Kriterien/Steckbrief_Präsenz Erleben_Leander_2.docx` | nein | 117 Einfügungen, 111 Löschungen, 3 Verschiebungen, 10 Kommentare | noch nicht geprüft |
| Emotionen | `part_how/criteria_specific_emotions.qmd` | keine | | noch nicht ins Buch eingebunden | |

## Nach dem Import über alle Texte vereinheitlichen

Der Word-Import ändert den Wortlaut nicht. Diese Punkte werden erst danach in einem eigenen Schritt angeglichen, und der Skill `docx-einarbeiten` ergänzt hier neue Fälle.

- Gender mit Doppelpunkt: `Schüler*innen` zu `Schüler:innen`, `Expert*innen` zu `Expert:innen`
- Statistische Symbole kursiv: `N` zu `*N*`
- Namen der `###`-Abschnitte, soweit gewünscht

## Für Zotero offene Quellen

Der Skill `docx-einarbeiten` ergänzt hier je Import die Quellen, die in der Bibliothek `Handbook` fehlen oder deren Angaben von Word abweichen. Solche Zitate bleiben Text, bis das geklärt ist.

| Text | Quelle | Betroffene Zitate |
|---|---|---|
| Kognitive Belastung | Sweller, Van Merriënboer & Paas (2019). Cognitive Architecture and Instructional Design: 20 Years Later. Educational Psychology Review. DOI 10.1007/s10648-019-09465-5 | (Sweller et al., 1998, 2019) |
| Kognitive Belastung | Rodemer, Lindner, Eckhard, Graulich & Bernholt (2022). Dynamic signals in instructional videos support students to navigate through complex representations: An eye-tracking study. Applied Cognitive Psychology. DOI 10.1002/acp.3973 | (Rodemer et al., 2022), Rodemer et al. (2022) |
| Kognitive Belastung | Mayer (2021). Multimedia learning. Cambridge University Press | (Mayer, 2021; Sweller et al., 1998, 2011) |
| Kumulatives Lernen | Lossjew & Bernholt (subm.). Tracking student learning across a conceptual landscape. Chemistry Education Research & Practice. Fehlt in Zotero, laut Kommentar inzwischen 2026 | (Lossjew & Bernholt, subm.) |
| Kumulatives Lernen | Bernholt, Höft & Parchmann (2020), DOI 10.1007/s42010-019-00065-4. Zotero `bernholt2019_entwicklung` hat 2019 | Bernholt et al. 2020, Bernholt et al. (2020) |
| Kumulatives Lernen | Simonsmeier et al. (2022), Domain-specific prior knowledge and learning. Zotero `simonsmeier2021_domainspecific` hat 2021 | (Simonsmeier et al., 2022) |
| Kumulatives Lernen | Krajcik, McNeill & Reiser (2008), Learning-goals-driven design model. Zotero `krajcik2007_learninggoalsdriven` hat 2007 | (Krajcik et al., 2008) |
| Kumulatives Lernen | Baumert et al. (1997), TIMSS. Zotero `baumert1997_timss` nennt nur eine Person, Name und Titel sind beschädigt („Jürgenglish“) | (Baumert et al., 1997) |
| Kumulatives Lernen | SINUS (o.D.), Modul 5. Zotero `sinus1999_modul` hat 1999 | (SINUS, o.D.) |
| Kumulatives Lernen | Hattie (2008), Visible learning. Zotero `hattie2009_visible` hat 2009, Ausgabe unklar | Hattie (2008) |
| Kumulatives Lernen | Bruner (1970), Der Prozess der Erziehung. Berlin-Verlag. Zotero `bruner1980_prozess` hat 1980 | Bruner (1970) |
| Adaptivität | Aleven, McLaughlin, Glenn & Koedinger (2017), Instruction based on adaptive learning technologies. In Mayer & Alexander, Handbook of research on learning and instruction. Zotero `aleven2025_instruction` hat 2025 | (Aleven et al., 2017; Plass and Pawar, 2020), Aleven et al. (2017) |
| Adaptivität | Martin, Kubsch, Yik, Burlingham & Graulich (2025), Adaptive, but Equitable? Science Education. DOI 10.1002/sce.70042. Zotero `martin2026_adaptive` hat 2026 | (Martin et al., 2025) |
| Kumulatives Lernen | Renkl (2010), Lehren und Lernen. In Tippelt & Schmidt, Handbuch Bildungsforschung. DOI 10.1007/978-3-531-92015-3_39. Zotero `renkl2002_lehren` hat 2002 | (Renkl, 2010) |
