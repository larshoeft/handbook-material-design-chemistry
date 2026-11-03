# Handbook

## Contributing

Rules for structure, citations and writing are in [CLAUDE.md](.claude/CLAUDE.md) (in German). The state of each text is in [STATUS.md](STATUS.md). Claude Code picks up the agents and skills in `.claude/` automatically.

## Workflow (Briefs)

This guide explains how to:  
- Create a brief using the template  
- Set up your environment and connect Quarto/Positron with Zotero  
- Generate a clean bibliography

### Steps

1. **Install software**  
   Install [Positron](https://positron.posit.co/download.html) or [RStudio](https://posit.co/download/rstudio-desktop/) and (optionally) [Zotero](https://www.zotero.org/) on your system.

2. **Set up the Group Library**  
   In Zotero, get invited to the group and subscribe to the Group Library named **"Handbook"**.  
   [Zotero Groups Documentation](https://www.zotero.org/support/groups)  
   **Note:** Do **not** sync attachments!

3. **Connect Positron or RStudio to Zotero (online)**  

   - For Positron: [Zotero Citations in the Visual Editor](https://quarto.org/docs/tools/positron/visual-editor.html#zotero-citations)  
   - For RStudio (without BetterBibTeX): [RStudio Citation Integration](https://posit.co/blog/rstudio-1-4-preview-citations/)

4. **Edit the `.qmd` templates**  
   Open the template [`part_how/criteria_specific_template.qmd`](https://cau-git.rz.uni-kiel.de/ipn/che/handbook-material-design-chemistry/-/raw/dev/part_how/criteria_specific_template.qmd?ref_type=heads&inline=false) in Visual Mode and create your content. Update the following:  

   - File name  
   - Title (e.g., `## Title`)  
   - Reference ID (e.g., `#sec-title`)  
   - Metadata block `sec-title:` with your ID from `_quarto.yml` (see [Extensions](#extensions))

   **Tip:** Use Reference IDs for tables and figures consistently:  
   - Tables: `#tbl-title-tablename`  
   - Figures: `#fig-title-figurename`

5. **Citation syntax**   
    Quarto uses standard Pandoc Markdown citation syntax.   
    
    - Citations go inside square brackets  
    - Multiple citations are separated by semicolons  
    - Each citation key begins with `@`

    Example:

    ```markdown
    [@smith2020]
    [@smith2020; @miller2018, p. 23]
    ```

    - Further documentation:   
        - [quarto.org](https://quarto.org/docs/authoring/citations.html)
        - [pandoc.org](https://pandoc.org/demo/example33/8.20-citation-syntax.html) 
        - [apaquarto](https://wjschne.github.io/apaquarto/writing.html#citations)

6. **Manage references**  
   Ensure that all references used in your brief are included in the **"Handbook"** Group Library.

7. **Export the bibliography**  (ONLY FOR MAINTAINERS)   
   Export the Group Library as `zotero.bib` by hand, in biblatex format and without `keep updated`. Citation keys are pinned and use the Better BibTeX formula in [CLAUDE.md](.claude/CLAUDE.md). Check the export with the skill `literatur-pruefen` before committing.

8. **Render the book** (ONLY FOR MAINTAINERS)   

```bash
quarto render
```

9. **Export a single chapter as Word (`.docx`)**   
    Use the PowerShell script `render_docx.ps1` to render one chapter file on its own, e.g. to share it for review. Run it from the project root:

```powershell
.\render_docx.ps1 part_how\criteria_specific_interest.qmd
```

   The output is written to `_docx/<file name>.docx` (ignored by git). The script renders the chapter outside the book project. Citations are resolved in APA style (`zotero.bib`, `apa.csl`) and listed under "Literatur" at the end, and images from `img/` are included. Section metadata (author, license) and cross-references to other chapters (`@sec-…`) are **not** included in the `.docx`.   
   If PowerShell blocks the script, run: `powershell -ExecutionPolicy Bypass -File .\render_docx.ps1 <file>`

### Extensions

The book uses three custom Lua filters in `_extensions/`. All are registered in `_quarto.yml` (`filters:` with `at: pre-quarto`).

#### `section-authors`

Adds an author/date block below each `##` section heading, plus an optional license and a "cite as" reference. Labels follow `lang` (e.g. "Autor:in", "Lizenz", "Zitat").

Specify the information either as heading attributes or as a metadata block at the top of the chapter file, keyed by the section ID:

```markdown
---
sec-interest:
  author: "Max Mustermann"   # or a list of names
  date: 2026-10-02           # first publication
  date-modified: 2026-11-15  # optional; last revision ("Zuletzt überarbeitet")
  license: "CC BY-NC"        # CC abbreviations link to the license deed
  citation: false            # optional; default from _quarto.yml, or a map with Quarto citation fields
---

## Interesse {#sec-interest}
```

```markdown
## Interesse {#sec-interest author="Max Mustermann" date="2026-10-02"}
```

Authors may also follow Quarto's author schema. ORCID, affiliations and e-mail are then shown as icons next to the name (the affiliation's name appears as a tooltip and links to its `url`, if given):

```markdown
---
sec-interest:
  author:
    - name: "Max Mustermann"
      email: "mustermann@leibniz-ipn.de"
      orcid: 0000-0002-1825-0097   # ID or https://orcid.org/… URL
      affiliation:
        - name: "IPN"
          url: "https://www.leibniz-ipn.de"
    - "Erika Musterfrau"          # a plain name works as well
---
```

Sections with authors get a "cite as" reference and a license by default (`extensions: section-authors:` with `citation` and `license` in `_quarto.yml`). Heading attributes take precedence over the metadata block. Use exactly **one top-level key per section** (`sec-…`). Included files are merged key by key, so they do not override each other or the chapter's own `author`/`date`.

Editors are listed in `book.author`, all other people in the top-level `contributors` of `_quarto.yml`, and affiliations in `affiliations`. Each needs an `id` and is defined once. Sections then refer to them. An unknown `ref` or a single unknown word produces a warning:

```markdown
---
sec-interest:
  author:
    - ref: lh                     # or short: author: "lh, sb"
    - name: "Erika Musterfrau"
      affiliation:
        - ref: ipn
---
```

```markdown
## Interesse {#sec-interest author="lh"}
```

The book's title page shows `book.author` as editors with the same icons, and section citations name them as editors of the book. It uses the template partial `_extensions/section-authors/title-metadata.html`, registered under `template-partials` in `_quarto.yml`.

An empty div `::: section-authors-all` (used in `index.qmd`) adds a list of everyone in `book.author` and `contributors` to the title block, below the editors: one comma-separated list, sorted by family name, with the same icons.

#### `section-bibliographies`

Creates a separate reference list per section instead of one for the whole book (based on [pandoc-ext/section-bibliographies](https://github.com/pandoc-ext/section-bibliographies)). For this reason `citeproc: false` is set in `_quarto.yml`. At the end of your section, add a heading with an empty `sectionrefs` div. It collects the references of all subsections:

```markdown
### Quellen

::: sectionrefs
:::
```

Inline citations link to the nearest reference list. Quarto cross-references (`@sec-…`, `@fig-…`, `@tbl-…` and the other Quarto prefixes) are left to Quarto. If a section cites nothing, its reference list and heading are left out.

**Note:** Both filters only run when the whole book is rendered. They are not used by `render_docx.ps1`.

#### `german-quotes`

Pandoc writes English quotation marks even with `lang: de`. For German documents this filter turns straight quotes in the source (`"…"`, `'…'`) into „…“ and ‚…‘. It also runs in `render_docx.ps1`.

#### `svg-inline`

In HTML output this filter embeds local SVG images directly in the page instead of linking them with `<img>`. The figures drawn with TikZ in `img/tikz/` use the CSS variables `--fig-dunkel`, `--fig-mittel`, `--fig-hell`, `--fig-blass`, `--fig-akzent`, `--fig-schrift` and `--fig-grund`, which the themes set, so the figures follow the active theme and its dark mode. Without a theme value the IPN colors apply. Rebuild the figures with `quarto run img/tikz/build.lua` (LuaLaTeX, no Python needed). It writes one SVG per font variant: `name.svg` (Helvetica), `name.ipn.svg` (Source Sans 3) and `name.socviz.svg` (Roboto Flex); the fonts are in `img/tikz/fonts/`, screenshots and other bitmaps used in figures in `img/tikz/bitmaps/` (embedded into the SVG). A profile chooses its variant with `figure-variant` in `_quarto-<profile>.yml`. The filter prefixes the ids inside each SVG with its file name, so several figures can share a page, and keeps `width`, classes and the alt text (`fig-alt`) of the image.

### Website themes

The look of the website is defined by [Quarto profiles](https://quarto.org/docs/projects/profiles.html). `_quarto.yml` holds the shared settings, and each profile adds a theme via `_quarto-<profile>.yml`:

| Profile | Look | Files | Output |
|---|---|---|---|
| `ipn` | Default and website. IPN blues (leibniz-ipn.de); Source Serif 4 / Source Sans 3 / Source Code Pro | `_quarto-ipn.yml`, `theme-ipn/ipn.scss`, `theme-ipn/fonts.scss`, `theme-ipn/ipn-dark.scss` | `_build/ipn/` |
| `ipn-literata` | IPN blues; Literata / Source Sans 3 / Source Code Pro | `_quarto-ipn-literata.yml`, `theme-ipn/ipn.scss`, `theme-ipn/fonts.scss`, `theme-ipn/font-literata.scss`, `theme-ipn/ipn-dark.scss` | `_build/ipn-literata/` |
| `socviz` | Recreation of [socviz.co](https://socviz.co); Source Serif 4 / Roboto Flex / IBM Plex Mono (free replacements for the paid socviz fonts) | `_quarto-socviz.yml`, `theme-socviz/socviz.scss`, `theme-socviz/socviz-dark.scss` | `_build/socviz/` |

All profiles have a light and a dark mode. They also place figure captions, table captions and footnotes in the margin.

Figures, tables and other floats are numbered per `##` section (e.g. Tabelle 4.6.2) instead of per chapter. Quarto has no option for this, so the Lua script `_scripts/float_numbers.lua` runs after rendering (`project: post-render`, executed by Quarto itself, no Python needed) and rewrites captions, cross-references and the search index.

All profiles share `styles.css` (the scrollbar space is reserved so columns do not shift between pages, wide tables scroll on their own, long words and DOIs break, the sidebar wraps on phones) and `toc-in-sidebar.html`. Below 992 px Quarto hides the page's table of contents; the script copies it, collapsed, below the active chapter in the sidebar.

Render with a profile:

```bash
quarto render                          # default profile ipn → _build/ipn/
quarto render --profile ipn-literata   # → _build/ipn-literata/
quarto render --profile socviz         # → _build/socviz/
```

The `_build/` folder is ignored by git. To change colors or fonts, edit the `.scss` files.

The `ipn` profiles host their fonts themselves, so no request goes to Google. `fonts/` holds the unmodified latin, latin-ext and greek files of the npm packages `@fontsource-variable/source-serif-4` (5.3.1), `source-sans-3` (5.3.1), `source-code-pro` (5.3.1) and `literata` (5.3.0), each with its OFL license. `theme-ipn/fonts.scss` and `theme-ipn/font-literata.scss` declare them with paths from the project root, and Quarto copies the files to `site_libs/bootstrap/fonts/`. Fallback faces of Georgia and Arial with matched metrics keep the text from shifting while the fonts load. The `socviz` profile still loads its fonts from Google Fonts.

### Pipeline

Work happens on cau-git, which mirrors all branches to GitHub. The website is rendered with the `ipn` profile by `.github/workflows/publish.yml` when the branch `publish` changes. To release the current state of `dev`:

```bash
git push origin dev:publish
```
