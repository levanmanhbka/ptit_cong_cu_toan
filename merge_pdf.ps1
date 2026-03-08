param(
    [string]$CoverPdf = "page0.pdf",
    [string]$MainPdf = "final_pdf.pdf",
    [string]$OutputPdf = "final2.pdf"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverPdf)) {
    throw "Missing file: $CoverPdf"
}

if (-not (Test-Path $MainPdf)) {
    throw "Missing file: $MainPdf"
}

# Prefer `py` on Windows, fallback to `python`.
$pythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = "py"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} else {
    throw "Python not found. Install Python 3 first."
}

$pythonCode = @'
import sys
from pathlib import Path

cover = Path(sys.argv[1])
main = Path(sys.argv[2])
out = Path(sys.argv[3])

try:
    from pypdf import PdfReader, PdfWriter
except Exception:
    try:
        from PyPDF2 import PdfReader, PdfWriter
    except Exception:
        raise SystemExit(
            "Missing PDF library. Install one of:\n"
            "  pip install pypdf\n"
            "or\n"
            "  pip install PyPDF2"
        )

writer = PdfWriter()

for page in PdfReader(str(cover)).pages:
    writer.add_page(page)

for page in PdfReader(str(main)).pages:
    writer.add_page(page)

with out.open("wb") as f:
    writer.write(f)

print(f"Created: {out}")
'@

$tmpPy = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), ".py")
[System.IO.File]::WriteAllText($tmpPy, $pythonCode, [System.Text.Encoding]::UTF8)

try {
    & $pythonCmd $tmpPy $CoverPdf $MainPdf $OutputPdf
}
finally {
    Remove-Item $tmpPy -ErrorAction SilentlyContinue
}
