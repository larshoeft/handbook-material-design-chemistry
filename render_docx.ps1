# Renders a single chapter file as docx, independent of the book project.
# Usage:  .\render_docx.ps1 part_how\criteria_specific_interest.qmd
# Output: _docx\<file name>.docx

param(
  [Parameter(Mandatory = $true)][string]$Datei
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$quelle = Resolve-Path $Datei
$name = [IO.Path]::GetFileNameWithoutExtension($quelle)

# Temporary folder outside the project so the book's _quarto.yml does not apply
$tmp = Join-Path ([IO.Path]::GetTempPath()) "render_docx_$name"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Path $tmp | Out-Null

Copy-Item $quelle (Join-Path $tmp "$name.qmd")
Copy-Item (Join-Path $root "zotero.bib"), (Join-Path $root "apa.csl") $tmp
Copy-Item (Join-Path $root "_extensions\german-quotes\german-quotes.lua") $tmp
if (Test-Path (Join-Path $root "img")) { Copy-Item -Recurse (Join-Path $root "img") $tmp }

@"
lang: de
bibliography: zotero.bib
csl: apa.csl
reference-section-title: Literatur
filters:
  - german-quotes.lua
format: docx
"@ | Set-Content -Encoding utf8 (Join-Path $tmp "_quarto.yml")

Push-Location $tmp
try {
  quarto render "$name.qmd"
  if ($LASTEXITCODE -ne 0) { throw "quarto render fehlgeschlagen" }
} finally {
  Pop-Location
}

$ziel = Join-Path $root "_docx"
New-Item -ItemType Directory -Force -Path $ziel | Out-Null
Copy-Item -Force (Join-Path $tmp "$name.docx") $ziel
Remove-Item -Recurse -Force $tmp

Write-Host "Erstellt: _docx\$name.docx"
