# Handbook

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
   - Title (e.g., `# Title`)  
   - Reference ID (e.g., `#sec-cs-title`)  
   - Author entry: `author="YOUR NAME"` (or a metadata block, see [Extensions](#extensions))

   **Tip:** Use Reference IDs for tables and figures consistently:  
   - Tables: `#tbl-cs-title-tablename`  
   - Figures: `#fig-cs-title-figurename`

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
   Export the Group Library as `zotero.bib`. Use the biblatex format and the option `keep updated`

8. **Clean the `.bib` file**  (ONLY FOR MAINTAINERS)   
   Use the Python script `clean_references.py` to remove unused references:

```bash
# Step 1: Create a virtual environment
python -m venv venv

# Step 2: Activate the virtual environment
# macOS / Linux
source venv/bin/activate
# Windows
venv\Scripts\activate

# Step 3: Install dependencies
pip install pybtex

# Step 4: Run the script
python clean_references.py
```

9. **Render the book** (ONLY FOR MAINTAINERS)   

```bash
quarto render
```

10. **Export a single chapter as Word (`.docx`)**   
    Use the PowerShell script `render_docx.ps1` to render one chapter file on its own, e.g. to share it for review. Run it from the project root:

```powershell
.\render_docx.ps1 part_how\criteria_specific_interest.qmd
```

   The output is written to `_docx/<file name>.docx` (ignored by git). The script renders the chapter outside the book project. Citations are resolved in APA style (`zotero.bib`, `apa.csl`) and listed under "Literatur" at the end, and images from `img/` are included. Section metadata (author, license) and cross-references to other chapters (`@sec-…`) are **not** included in the `.docx`.   
   If PowerShell blocks the script, run: `powershell -ExecutionPolicy Bypass -File .\render_docx.ps1 <file>`

### Extensions

The book uses two custom Lua filters in `_extensions/`. Both are registered in `_quarto.yml` (`filters:` with `at: pre-quarto`).

#### `section-authors`

Adds an author/date block below each `##` section heading, plus an optional license and a "cite as" reference. Labels follow `lang` (e.g. "Autor:in", "Lizenz", "Zitat").

Specify the information either as heading attributes or as a metadata block at the top of the chapter file, keyed by the section ID:

```markdown
---
sec-interest:
  author: "Max Mustermann"   # or a list of names
  date: 2026-10-02
  license: "CC BY-NC"        # CC abbreviations link to the license deed
  citation: true             # optional; or a map with Quarto citation fields
---

## Interesse {#sec-interest}
```

```markdown
## Interesse {#sec-interest author="Max Mustermann" date="2026-10-02"}
```

Heading attributes take precedence over the metadata block. Use exactly **one top-level key per section** (`sec-…`). Included files are merged key by key, so they do not override each other or the chapter's own `author`/`date`.

#### `section-bibliographies`

Creates a separate reference list per section instead of one for the whole book (based on [pandoc-ext/section-bibliographies](https://github.com/pandoc-ext/section-bibliographies)). For this reason `citeproc: false` is set in `_quarto.yml`. At the end of your section, add a heading with an empty `sectionrefs` div. It collects the references of all subsections:

```markdown
### Quellen

::: sectionrefs
:::
```

Inline citations link to the nearest reference list. Quarto cross-references (`@sec-…`, `@fig-…`, `@tbl-…`) are left to Quarto.

**Note:** Both filters only run when the whole book is rendered. They are not used by `render_docx.ps1`.

### Website themes

> **Note:** The theme profiles currently live on the branch `theming` and are not yet merged.

The look of the website is defined by [Quarto profiles](https://quarto.org/docs/projects/profiles.html). `_quarto.yml` holds the shared settings, and each profile adds a theme via `_quarto-<profile>.yml`:

| Profile | Look | Files | Output |
|---|---|---|---|
| `default` | Bootswatch `cosmo` + `simplex` (current website) | `_quarto-default.yml` | `_book/` |
| `ipn` | IPN blues (leibniz-ipn.de); Source Serif 4 / Source Sans 3 / Source Code Pro | `_quarto-ipn.yml`, `theme-ipn/ipn.scss`, `theme-ipn/ipn-dark.scss` | `_build/ipn/` |
| `ipn-alegreya` | IPN blues; Alegreya / Alegreya Sans / Alegreya Sans SC (small caps for labels) | `_quarto-ipn-alegreya.yml`, `theme-ipn/ipn.scss`, `theme-ipn/font-alegreya.scss`, `theme-ipn/ipn-dark.scss` | `_build/ipn-alegreya/` |
| `socviz` | Recreation of [socviz.co](https://socviz.co) (paid fonts replaced by free Google Fonts) | `_quarto-socviz.yml`, `theme-socviz/socviz.scss`, `theme-socviz/socviz-dark.scss` | `_build/socviz/` |

All profiles except `default` have a light and a dark mode. They also place figure captions, table captions and footnotes in the margin.

Render with a profile:

```bash
quarto render                          # default profile → _book/
quarto render --profile ipn            # → _build/ipn/
quarto render --profile ipn-alegreya   # → _build/ipn-alegreya/
quarto render --profile socviz         # → _build/socviz/
```

The `_build/` folder is ignored by git. It only holds output for comparing the variants. To change colors or fonts, edit the `.scss` files. The fonts are loaded from Google Fonts.

### Pipeline

`git merge` **main** → CI builds Docker image → Deploy static website   
*(Optionally via GitHub Actions instead of GitLab CI)*
