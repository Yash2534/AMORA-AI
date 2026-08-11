from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(r"D:\Projects\amora_ai")
SOURCE = ROOT / "tmp" / "project_audit" / "srs_render"
OUT = ROOT / "tmp" / "project_audit" / "srs_contact_sheets"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pages = sorted(SOURCE.glob("page-*.png"))
    batch_size = 4
    for batch_index in range(0, len(pages), batch_size):
        batch = pages[batch_index : batch_index + batch_size]
        opened = [Image.open(path).convert("RGB") for path in batch]
        thumb_width = 620
        thumb_height = int(opened[0].height * thumb_width / opened[0].width)
        margin = 30
        label_height = 38
        sheet = Image.new(
            "RGB",
            (thumb_width * 2 + margin * 3, (thumb_height + label_height) * 2 + margin * 3),
            "#E5E7EB",
        )
        draw = ImageDraw.Draw(sheet)
        for offset, (path, image) in enumerate(zip(batch, opened)):
            row, col = divmod(offset, 2)
            x = margin + col * (thumb_width + margin)
            y = margin + row * (thumb_height + label_height + margin)
            resized = image.resize((thumb_width, thumb_height), Image.Resampling.LANCZOS)
            sheet.paste(resized, (x, y + label_height))
            draw.text((x, y + 8), path.stem.replace("page-", "SRS page "), fill="#111827")
        start = batch_index + 1
        end = batch_index + len(batch)
        sheet.save(OUT / f"pages-{start:02d}-{end:02d}.png", optimize=True)
        for image in opened:
            image.close()


if __name__ == "__main__":
    main()
