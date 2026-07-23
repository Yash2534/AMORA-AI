from pathlib import Path

import pdfplumber
import pypdfium2 as pdfium


SOURCE = Path(r"D:\The Data Sequence\AMORA AI\Amora_AI_SOW.pdf")
OUTPUT = Path(r"D:\Projects\amora_ai\tmp\stage3\sow")
OUTPUT.mkdir(parents=True, exist_ok=True)

with pdfplumber.open(SOURCE) as document:
    pages = []
    for index, page in enumerate(document.pages, start=1):
        pages.append(f"\n\n===== PAGE {index} =====\n\n{page.extract_text() or ''}")
    (OUTPUT / "sow_complete.txt").write_text("".join(pages), encoding="utf-8")
    print(f"text_pages={len(document.pages)}")

document = pdfium.PdfDocument(str(SOURCE))
for index in range(len(document)):
    page = document[index]
    image = page.render(scale=1.25).to_pil()
    image.save(OUTPUT / f"page-{index + 1:03d}.png")
print(f"rendered_pages={len(document)}")
