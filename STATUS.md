# Stand der Texte

Word-Dateien liegen in `_quellen_docx/Kapitel/`. Die Spalte „Word-Stand“ nennt die Zahlen vor dem Import.

| Text | Zuständig | Datei im Repo | Word-Datei | Importiert | Word-Stand | Offene Quellen |
|---|---|---|---|---|---|---|
| Relevanz | Sascha Bernholt | `part_why/_importance.qmd` | `2_Relevanz/Entwurf_Einleitung_Relevanz_v2.docx` | ja, 01.11.2026 | | 1, siehe unten |
| Ausrichtungen | Sascha Bernholt | `part_why/_orientations.qmd` | keine | | | |
| Design-Based Research | Leander Mecklenburg | `part_how/frameworks_dbr.qmd` | `4_Verfahren und Modelle/Steckbrief_DesignBasedResearch_Leander.docx` | ja, 01.11.2026 | 11 Einfügungen, 11 Löschungen (angenommen), 11 Kommentare | 11, siehe unten |
| Didaktische Rekonstruktion | Jannik Lossjew | `part_how/frameworks_rec.qmd` | `4_Verfahren und Modelle/Steckbrief_Didaktische Rekonstruktion.docx` | ja, 01.11.2026 | | 8, siehe unten |
| Universal Design for Learning | Stefanie Lenzer | `part_how/frameworks_udl.qmd` | keine | | | |
| Qualitätskriterien -- welche? | Sascha Bernholt | `part_how/_criteria_general.qmd` | keine | | noch offen | |
| Adaptivität | Gyde Asmussen | `part_how/criteria_specific_adaptivity.qmd` | `6_Kriterien/Steckbrief_Adaptivität_Gyde.docx` | ja, 31.10.2026 | | 2, siehe unten |
| Kognitive Belastung | Anja Annemüller | `part_how/criteria_specific_cognitiveload.qmd` | `6_Kriterien/Steckbrief_Cognitive_load_Anja.docx` | ja, 30.10.2026 | 2 Einfügungen, 2 Löschungen (angenommen), 8 Kommentare, 2 Markierungen | 3, siehe unten |
| Interesse | Lars Höft | `part_how/criteria_specific_interest.qmd` | `6_Kriterien/Steckbrief_Interesse_Lars.docx` | ja, 01.11.2026 | 159 Einfügungen, 143 Löschungen (angenommen), 12 Kommentare | 2, siehe unten |
| Kontextualisierung | Maximilian Traub | `part_how/criteria_specific_context.qmd` | `6_Kriterien/Steckbrief_Kontextualisierung_Max.docx` | ja, 31.10.2026 | | 24, siehe unten |
| Kumulatives Lernen | Sascha Bernholt | `part_how/criteria_specific_cumulative.qmd` | `6_Kriterien/Steckbrief_Kumulatives Lernen_Sascha.docx` | ja, 30.10.2026 | 10 Kommentare | 9, siehe unten |
| Präsenzerleben | Leander Mecklenburg | `part_how/criteria_specific_presence.qmd` | `6_Kriterien/Steckbrief_Präsenz Erleben_Leander_2.docx` | ja, 01.11.2026 | 117 Einfügungen, 111 Löschungen, Verschiebungen (angenommen), 10 Kommentare | 17, siehe unten |
| Emotionen |  | `part_how/criteria_specific_emotions.qmd` | keine | | noch nicht ins Buch eingebunden | |
| OER Verfügbarkeit | Clemens Frank | `part_how/criteria_specific_oer.qmd` | keine | | noch offen, nur Vorlage | |

## Nach dem Import über alle Texte vereinheitlichen

Der Word-Import ändert den Wortlaut nicht. Diese Punkte werden erst danach in einem eigenen Schritt angeglichen, und der Skill `docx-einarbeiten` ergänzt hier neue Fälle.

- Namen der `###`-Abschnitte, soweit gewünscht
- Abbildungen als echte Abbildungen mit `#fig-`-ID und Bildunterschrift, statt Bild und Text "Abb. 1: ..." getrennt
- Personenbezeichnungen ohne Gendern, zum Beispiel `Schüler`

## Für Zotero offene Quellen

Der Skill `docx-einarbeiten` ergänzt hier je Import die Quellen, die in der Bibliothek `Handbook` fehlen oder deren Angaben von Word abweichen. Solche Zitate bleiben Text, bis das geklärt ist.

| Text | Quelle | Betroffene Zitate |
|---|---|---|
| Relevanz | Holzaepfel et al. (2020). Keine vollständige Angabe in Word. Zotero `holzapfel2024_qualitatsvoll` hat 2024, im Repo war dieser Key zitiert | (u. a. Holzaepfel et al., 2020) |
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
| Kontextualisierung | American Chemical Society [ACS]. (2001). Chemistry in context (3. Aufl.). McGraw Hill. | American Chemical Society 2001 |
| Kontextualisierung | Andersen, J. (2020). Entwicklung und Evaluierung eines spezifischen Anfängerpraktikums für Lehramtsstudierende im Fach Physik. Christian-Albrechts-Universität Kiel. | Andersen 2020 |
| Kontextualisierung | Anderson, T., & Shattuck, J. (2012). Design-Based Research: A Decade of Progress in Education Research? Educational Researcher, 41(1), 16--25. https://doi.org/10.3102/0013189X11428813 | Anderson 2012 |
| Kontextualisierung | Bennett, J., Lubben, F., & Hogarth, S. (2007). Bringing science to life: A synthesis of the research evidence on the effects of context-based and STS approaches to science teaching. Science Education, 91(3), 347--370. https://doi.org/10.1002/sce.20186 | Bennett 2007 |
| Kontextualisierung | Bulte, A. M. W., Westbroek, H. B., De Jong, O., & Pilot, A. (2006). A Research Approach to Designing Chemistry Education using Authentic Practices as Contexts. International Journal of Science Education, 28(9), 1063--1086. https://doi.org/10.1080/09500690600702520 | Bulte 2006 |
| Kontextualisierung | Busker, M. (2010). Entwicklung einer adressatenorientierten Übungskonzeption im Übergang Schule---Universität auf Basis empirischer Analysen von Studieneingangsvoraussetzungen im Fach Chemie. Christian-Albrechts-Universität zu Kiel. | Busker 2010 |
| Kontextualisierung | Easterday, M. W., Lewis, D. R., & Gerber, E. M. (2014). Design-Based Research Process: Problems, Phases, and Applications. https://repository.isls.org//handle/1/1130 | Easterday 2014 |
| Kontextualisierung | Fechner, S. (2009). Effects of Context-Oriented Learning on Student Interest and Achievement in Chemistry Education. Logos Verlag Berlin. | Fechner 2009 |
| Kontextualisierung | Finkelstein, N. (2005). Learning Physics in Context: A study of student learning about electricity and magnetism. International Journal of Science Education, 27(10), 1187--1209. https://doi.org/10.1080/09500690500069491 | Finkelstein 2005 |
| Kontextualisierung | Gilbert, J. K. (2006). On the Nature of "Context" in Chemical Education. International Journal of Science Education, 28(9), 957--976. https://doi.org/10.1080/09500690600702470 | Gilbert 2006 |
| Kontextualisierung | Güth, F. (2023). Interessenbasierte Differenzierung Mithilfe Systematisch Variierter Kontextaufgaben Im Fach Chemie (1st ed). Logos Verlag Berlin. | Güth 2023 |
| Kontextualisierung | Güth, F., & van Vorst, H. (2023). Context-based Learning as a Method for Differentiated Instruction in Chemistry Education. In G. S. Carvalho, A. S. Afonso, & Z. Anastácio (Hrsg.), Fostering Scientific Citizenship in an Uncertain World: Selected Papers from the ESERA 2021 Conference (S. 153--169). Springer International Publishing. https://doi.org/10.1007/978-3-031-32225-9_10 | Güth 2023 |
| Kontextualisierung | Hofstein, A., Kesner, M., & Ben-Zvi, R. (1999). Student Perceptions of Industrial Chemistry Classroom Learning Environments. Learning Environments Research, 2(3), 291--306. https://doi.org/10.1023/A:1009973908142 | Hofstein 1999 |
| Kontextualisierung | Nentwig, P. M., Demuth, R., Parchmann, I., Ralle, B., & Gräsel, C. (2007). Chemie im Kontext: Situating Learning in Relevant Contexts while Systematically Developing Basic Chemical Concepts. Journal of Chemical Education, 84(9), 1439. https://doi.org/10.1021/ed084p1439 | Nentwig 2007 |
| Kontextualisierung | Parchmann, I., Broman, K., Busker, M., & Rudnik, J. (2015). Context-Based Teaching and Learning on School and University Level. In Chemistry Education (S. 259--278). John Wiley & Sons, Ltd. https://doi.org/10.1002/9783527679300.ch10 | Parchmann 2015 |
| Kontextualisierung | Parchmann, I., Gräsel, C., Baer, A., Nentwig, P., Demuth, R., & Ralle the ChiK Project Group, B. (2006). "Chemie im Kontext": A symbiotic implementation of a context‐based teaching and learning approach. International Journal of Science Education, 28(9), 1041--1062. https://doi.org/10.1080/09500690600702512 | Parchmann 2006 |
| Kontextualisierung | Podschuweit, S., & Bernholt, S. (2018). Composition-Effects of Context-based Learning Opportunities on Students' Understanding of Energy. Research in Science Education, 48(4), 717--752. https://doi.org/10.1007/s11165-016-9585-z | Podschuweit 2018 |
| Kontextualisierung | Prins, G. T., Bulte, A. M. W., & Pilot, A. (2018). Designing context-based teaching materials by transforming authentic scientific modelling practices in chemistry. International Journal of Science Education, 40(10), 1108--1135. https://doi.org/10.1080/09500693.2018.1470347 | Prins 2018 |
| Kontextualisierung | Sevian, H., Dori, Y. J., & Parchmann, I. (2018). How does STEM context-based learning work: What we know and what we still do not know. International Journal of Science Education, 40(10), 1095--1107. https://doi.org/10.1080/09500693.2018.1470346 | Sevian 2018 |
| Kontextualisierung | Sevian, H., Hugi-Cleary, D., Ngai, C., Wanjiku, F., & Baldoria, J. M. (2018). Comparison of learning in two context-based university chemistry classes. International Journal of Science Education, 40(10), 1239--1262. https://doi.org/10.1080/09500693.2018.1470353 | Sevian 2018 |
| Kontextualisierung | Toan, H. T., Hang, N. T. T., Hai, T. T., Ngu, P. N. H., & Thao, T. T. P. (2025). Context-based learning in higher education 1992-2023: Trends and outstanding research areas from Scopus database. International Journal of Evaluation and Research in Education (IJERE), 14(5), 4050. https://doi.org/10.11591/ijere.v14i5.33259 | Toan 2025 |
| Kontextualisierung | Traub, M., Behrens, M., & Lenzer, S. (2026). Making chemistry labs more relevant -- development and evaluation of contextualised pre-lab materials for qualitative inorganic analysis. Chemistry Teacher International. https://doi.org/10.1515/cti-2025-0112 | Traub 2026 |
| Kontextualisierung | University of York Science education group [UYSEG]. (2000). Salters advanced chemistry, chemical storylines, Chemical ideas, activities and assessment and teachers' guide (2. Aufl.). UYSEG/Heinemann Educational. | University of York 2000 |
| Kontextualisierung | Van Vorst, H., & Aydogmus, H. (2021). One context fits all? -- Analysing students' context choice and their reasons for choosing a context-based task in chemistry education. International Journal of Science Education, 43(8), 1250--1272. https://doi.org/10.1080/09500693.2021.1908640 | Van Vorst 2021 |
| Didaktische Rekonstruktion | Komorek, M., Wilbers, J., & Duit, R. (1997). Didaktische Rekonstruktion im Bereich Chaostheorie. In Zur Didaktik der Physik und Chemie: Tagung 1996 (S. 128--130). | Komorek 1997 |
| Didaktische Rekonstruktion | Frerichs, V. (1999). Schülervorstellungen und wissenschaftliche Vorstellungen zu den Strukturen und Prozessen der Vererbung: Ein Beitrag zur didaktischen Rekonstruktion [Dissertation, Carl von Ossietzky Universität Oldenburg]. Didaktisches Zentrum. | Frerichs 1999 |
| Didaktische Rekonstruktion | Grospietsch, F., & Mayer, J. (2021). Didaktische Rekonstruktion als Planungs- und Forschungsrahmen nutzen: Fachliche Klärung, Gestaltung und Evaluation einer universitären Lehrveranstaltung zum Thema Gehirn und Lernen. HLZ -- Herausforderung Lehrerinnenbildung, 4(2), 165--192. <https://doi.org/10.11576/hlz-2548> | Grospietsch 2021 |
| Didaktische Rekonstruktion | Claussen, C. (2023). Zur Vermittlungsrolle von Naturwissenschaftsdidaktik in der forschungsbasierten Wissenschaftskommunikation: Stakeholderorientierte Weiterentwicklung eines Outreach-Formates für Schulen am Beispiel der Metaorganismus-Forschung [Dissertation, Christian-Albrechts-Universität zu Kiel]. | Claussen 2023 |
| Didaktische Rekonstruktion | Reimann, M., Herzog, S., Parchmann, I., & Schwarzer, S. (2020). Wirksamkeit der schulischen Vor- und Nachbereitung eines Schülerlaborbesuches. In Zeitschrift für Didaktik der Naturwissenschaften, 26(1), 227--240. <https://doi.org/10.1007/s40573-020-00121-y> | Reimann 2020 |
| Didaktische Rekonstruktion | Klafki (1969). Keine vollständige Angabe in Word | Klafki (1969) |
| Didaktische Rekonstruktion | Heimann, Otto & Schulz (1969). Keine vollständige Angabe in Word | Heimann, Otto und Schulz (1969) |
| Didaktische Rekonstruktion | Gerstenmeier & Mandl (1995). Keine vollständige Angabe in Word | (Gerstenmeier und Mandl, 1995) |
| Design-Based Research | Barab, Squire (2004). Design-Based Research: Putting a Stake in the Ground. DOI 10.1207/s15327809jls1301_1 | Barab 2004 |
| Design-Based Research | Anderson, Shattuck (2012). Design-Based Research:A Decade of Progress in Education Research?. DOI 10.3102/0013189X11428813 | Anderson 2012 |
| Design-Based Research | Easterday, Rees Lewis, Gerber (2014). Design-based research process: Problems, phases, and applications. | Easterday 2014 |
| Design-Based Research | Brown (1992). Design Experiments: Theoretical and Methodological Challenges in Creating Complex Interventions in Classroom Settings. | Brown 1992 |
| Design-Based Research | Mundy, Potgieter, Seery (2024). A design-based research approach to improving pedagogy in the teaching laboratory. DOI 10.1039/D3RP00134B | Mundy 2024 |
| Design-Based Research | Echeverri-Jimenez, Oliver-Hoyo (2024). A Roadmap to Support the Development of Chemistry Virtual Reality Learning Environments Merging Chemical Pedagogy and Educational Technology Design. DOI 10.1021/acs.jchemed.3c01205 | Echeverri-Jimenez 2024 |
| Design-Based Research | Mayring (2010). Qualitative Inhaltsanalyse. DOI 10.1007/978-3-531-92052-8_42 | Mayring 2010 |
| Design-Based Research | Krieglstein, Beege, Rey, Sanchez-Stockhammer, Schneider (2023). Development and Validation of a Theory-Based Questionnaire to Measure Different Types of Cognitive Load. DOI 10.1007/s10648-023-09738-0 | Krieglstein 2023 |
| Design-Based Research | Hartmann, Wirth, Schramm, Klimmt, Vorderer, Gysbers, Böcking, Ravaja, Laarni, Saari, Gouveia, Maria Sacau (2016). The Spatial Presence Experience Scale (SPES): A Short Self-Report Measure for Diverse Media Settings. DOI 10.1027/1864-1105/a000137 | Hartmann 2016 |
| Design-Based Research | Reeves, Crippen, McCray (2021). The varied experience of undergraduate students learning chemistry in virtual reality laboratories. DOI 10.1016/j.compedu.2021.104320 | Reeves 2021 |
| Design-Based Research | Mecklenburg & Lenzer (in prep.). Keine vollständige Angabe in Word | (Mecklenburg & Lenzer, in prep.) |
| Präsenzerleben | Slater, Wilbur (1997). A Framework for Immersive Virtual Environments (FIVE): Speculations on the Role of Presence in Virtual Environments. DOI 10.1162/pres.1997.6.6.603 | Slater 1997 |
| Präsenzerleben | Witmer, Singer (1998). Measuring Presence in Virtual Environments: A Presence Questionnaire. DOI 10.1162/105474698565686 | Witmer 1998 |
| Präsenzerleben | Wirth, Hartmann, Böcking, Vorderer, Klimmt, Schramm, Saari, Laarni, Ravaja, Gouveia, Biocca, Sacau, Jäncke, Baumgartner, Jäncke (2007). A Process Model of the Formation of Spatial Presence Experiences. DOI 10.1080/15213260701283079 | Wirth 2007 |
| Präsenzerleben | Makransky, Petersen (2021). The Cognitive Affective Model of Immersive Learning (CAMIL): a Theoretical Research-Based Model of Learning in Immersive Virtual Reality. DOI 10.1007/s10648-020-09586-2 | Makransky 2021 |
| Präsenzerleben | Buchner, Mulders (2026). Still trapped in media comparison? A systematic review of comparative research on immersive virtual reality in education. DOI 10.1080/10494820.2026.2617986 | Buchner 2026 |
| Präsenzerleben | Zusho, Pintrich, Coppola (2003). Skill and will: The role of motivation and cognition in the learning of college chemistry. DOI 10.1080/0950069032000052207 | Zusho 2003 |
| Präsenzerleben | Makransky, Terkildsen, Mayer (2019). Adding immersive virtual reality to a science lab simulation causes more presence but less learning. DOI 10.1016/j.learninstruc.2017.12.007 | Makransky 2019 |
| Präsenzerleben | Easterday, Rees Lewis, Gerber (2014). Design-based research process: Problems, phases, and applications. | Easterday 2014 |
| Präsenzerleben | Echeverri-Jimenez, Oliver-Hoyo (2024). A Roadmap to Support the Development of Chemistry Virtual Reality Learning Environments Merging Chemical Pedagogy and Educational Technology Design. DOI 10.1021/acs.jchemed.3c01205 | Echeverri-Jimenez 2024 |
| Präsenzerleben | Grassini, Laumann (2020). Questionnaire Measures and Physiological Correlates of Presence: A Systematic Review. DOI 10.3389/fpsyg.2020.00349 | Grassini 2020 |
| Präsenzerleben | Usoh, Catena, Arman, Slater (2000). Using Presence Questionnaires in Reality. DOI 10.1162/105474600566989 | Usoh 2000 |
| Präsenzerleben | Vorderer, Wirth, Gouveia, Biocca, Saari, Jäncke, Böcking, Schramm, Gysbers, Hartmann, Klimmt, Ravaja, Sacau, Baumgartner, Jäncke (2004). MEC Spatial Presence Questionnaire (MEC-SPQ). | Vorderer 2004 |
| Präsenzerleben | Hartmann, Wirth, Schramm, Klimmt, Vorderer, Gysbers, Böcking, Ravaja, Laarni, Saari, Gouveia, Maria Sacau (2016). The Spatial Presence Experience Scale (SPES): A Short Self-Report Measure for Diverse Media Settings. DOI 10.1027/1864-1105/a000137 | Hartmann 2016 |
| Präsenzerleben | Reeves, Crippen, McCray (2021). The varied experience of undergraduate students learning chemistry in virtual reality laboratories. DOI 10.1016/j.compedu.2021.104320 | Reeves 2021 |
| Präsenzerleben | Lee (2004). Keine vollständige Angabe in Word | Lee 2004 |
| Präsenzerleben | Dalgarno & Lee (2010). Keine vollständige Angabe in Word | Dalgarno & Lee (2010), Dalgarno & Lee, 2010 |
| Präsenzerleben | Mecklenburg & Lenzer (in prep.). Keine vollständige Angabe in Word | (Mecklenburg & Lenzer, in prep.) |
| Interesse | Schraw & Lehman (2001). Keine vollständige Angabe in Word | (Schraw & Lehman, 2001; Ainley 2006) |
| Interesse | Ainley (2006). Keine vollständige Angabe in Word | (Schraw & Lehman, 2001; Ainley 2006) |
