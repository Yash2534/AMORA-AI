from pathlib import Path

from PIL import Image, ImageDraw


source = Path('tmp/stage3/sow')
output = Path('tmp/stage3/sow_contact_sheets')
output.mkdir(parents=True, exist_ok=True)
pages = sorted(source.glob('page-*.png'))

thumb_width = 700
gap = 28
label_height = 34
for sheet_index in range(0, len(pages), 4):
    batch = pages[sheet_index:sheet_index + 4]
    thumbs = []
    for page in batch:
        image = Image.open(page).convert('RGB')
        height = round(image.height * thumb_width / image.width)
        thumbs.append((page, image.resize((thumb_width, height))))
    cell_height = max(image.height for _, image in thumbs) + label_height
    sheet = Image.new('RGB', (thumb_width * 2 + gap * 3, cell_height * 2 + gap * 3), 'white')
    draw = ImageDraw.Draw(sheet)
    for index, (page, image) in enumerate(thumbs):
        col = index % 2
        row = index // 2
        x = gap + col * (thumb_width + gap)
        y = gap + row * (cell_height + gap)
        draw.text((x, y), page.stem.replace('page-', 'Page '), fill='black')
        sheet.paste(image, (x, y + label_height))
    destination = output / f'sow-contact-{sheet_index // 4 + 1:02d}.png'
    sheet.save(destination, quality=92)

print(f'contact_sheets={len(list(output.glob("*.png")))}')
