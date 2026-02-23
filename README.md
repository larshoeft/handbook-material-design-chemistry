# Handbook

## Workflow (Briefs)

This guide explains how to:  
- Create a brief using the template  
- Set up your environment and connect Quarto/Positron with Zotero  
- Generate a clean bibliography

### Steps

1. **Install software**  
   Install Positron or RStudio and Zotero on your system.

2. **Set up the Group Library**  
   In Zotero, add the Group Library named **"Handbook"**.

3. **Connect Quarto/Positron or RStudio to Zotero**  

   - For Positron: [Zotero Citations in the Visual Editor](https://quarto.org/docs/tools/positron/visual-editor.html#zotero-citations)  
   - For RStudio (without BetterBibTeX): [RStudio Citation Integration](https://posit.co/blog/rstudio-1-4-preview-citations/)

4. **Edit the `.qmd` templates**  
   Open the templates in Visual Mode and create your content. Update the following:  

   - File name  
   - Title (e.g., `# Title`)  
   - Reference ID (e.g., `#sec-cs-title`)  
   - Author entry: `author="YOUR NAME"`

5. **Manage references**  
   Make sure all references used are included in the **"Handbook"** Group Library.

6. **Export the bibliography**  
   Export the Group Library as `zotero.bib`.

7. **Clean the `.bib` file**  
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
8. Render the book

```bash
quarto render
```

## Pipeline

`git merge` → **main** → CI builds Docker image → Deploy static website  
*(Optionally via GitHub Actions instead of GitLab CI)*