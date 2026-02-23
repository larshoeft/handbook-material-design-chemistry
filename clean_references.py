#!/usr/bin/env python3
import re
import os
from pybtex.database import parse_file, BibliographyData

# === Settings ===
SRC_DIR = "."  # Folder containing .qmd files
BIBFILE = "zotero.bib"  # Original .bib file
OUTPUT = "references.bib"  # Filtered .bib output
MISSING_KEYS_FILE = "missing_keys.txt"  # File to save missing keys
RESERVED_PREFIXES = [
    "fig",
    "tbl",
    "lst",
    "tip",
    "nte",
    "wrn",
    "imp",
    "cau",
    "thm",
    "lem",
    "cor",
    "prp",
    "cnj",
    "def",
    "exm",
    "exr",
    "sol",
    "rem",
    "alg",
    "eq",
    "sec",
]

# === Step 1: Find all .qmd files recursively ===
qmd_files = []
for root, dirs, files in os.walk(SRC_DIR):
    for file in files:
        if file.endswith(".qmd"):
            qmd_files.append(os.path.join(root, file))

# === Step 2: Collect all cited keys, ignoring reserved prefixes ===
keys = set()
pattern = re.compile(r"@([\w:-]+)")  # Match @key

for f in qmd_files:
    with open(f, "r", encoding="utf-8") as infile:
        text = infile.read()
        for key in pattern.findall(text):
            if not any(key.startswith(prefix + "-") for prefix in RESERVED_PREFIXES):
                keys.add(key)

print(f"Found {len(keys)} keys (after filtering reserved prefixes)")

# === Step 3: Read BibTeX and filter entries ===
bib_data = parse_file(BIBFILE)
filtered_entries = {k: v for k, v in bib_data.entries.items() if k in keys}

# === Step 4: Identify missing keys and save to file ===
missing = sorted(keys - set(filtered_entries.keys()))
if missing:
    print(
        f"⚠️ {len(missing)} keys were not found in the .bib file. Writing to '{MISSING_KEYS_FILE}'..."
    )
    with open(MISSING_KEYS_FILE, "w", encoding="utf-8") as f:
        for key in missing:
            f.write(key + "\n")
else:
    print("All keys were found in the .bib file!")

# === Step 5: Write new filtered .bib ===
new_bib = BibliographyData(entries=filtered_entries)
with open(OUTPUT, "w", encoding="utf-8") as f:
    new_bib.to_file(f)

print(f"✅ Finished! Filtered .bib saved as '{OUTPUT}'")
