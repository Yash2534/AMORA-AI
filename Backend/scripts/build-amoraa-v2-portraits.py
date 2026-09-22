"""Build deterministic local AMORAA v2 development portraits from generated sheets."""

from pathlib import Path
from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "demo-assets" / "amoraa-v2-generated" / "source"
OUTPUT = ROOT / "demo-assets" / "amoraa-v2-generated" / "profiles"


def square_quadrant(image: Image.Image, index: int) -> Image.Image:
    width, height = image.size
    half_w, half_h = width // 2, height // 2
    gap = max(4, min(width, height) // 180)
    left = 0 if index % 2 == 0 else half_w + gap
    top = 0 if index < 2 else half_h + gap
    right = half_w - gap if index % 2 == 0 else width
    bottom = half_h - gap if index < 2 else height
    return image.crop((left, top, right, bottom))


def portrait_crop(image: Image.Image, zoom: float = 1.0) -> Image.Image:
    target_ratio = 4 / 5
    width, height = image.size
    crop_width = min(width, int(height * target_ratio))
    crop_height = min(height, int(crop_width / target_ratio))
    crop_width = int(crop_width / zoom)
    crop_height = int(crop_height / zoom)
    left = (width - crop_width) // 2
    top = max(0, int((height - crop_height) * 0.38))
    return image.crop((left, top, left + crop_width, top + crop_height)).resize((800, 1000), Image.Resampling.LANCZOS)


def save_pair(source: Image.Image, profile_number: int) -> None:
    primary = portrait_crop(source, 1.0)
    secondary = portrait_crop(source, 1.16)
    secondary = ImageOps.mirror(secondary)
    secondary = ImageEnhance.Color(secondary).enhance(0.96)
    secondary = ImageEnhance.Brightness(secondary).enhance(1.025)
    for photo_number, image in enumerate((primary, secondary), start=1):
        image.save(
            OUTPUT / f"amoraa-v2-profile-{profile_number:03d}-{photo_number:02d}.webp",
            "WEBP",
            quality=92,
            method=3,
        )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for old in OUTPUT.glob("amoraa-v2-profile-*.webp"):
        old.unlink()

    master = Image.open(SOURCE / "master-aisha-diptych.png").convert("RGB")
    divider = master.size[0] // 2
    save_pair(master.crop((0, 0, divider - 4, master.size[1])), 1)

    sheet_metadata = {
        1: [('Male', 25), ('Male', 28), ('Male', 30), ('Male', 32)],
        2: [('Male', 22), ('Male', 26), ('Male', 29), ('Male', 34)],
        3: [('Female', 23), ('Female', 26), ('Female', 30), ('Female', 33)],
        4: [('Other', 24), ('Female', 28), ('Male', 31), ('Other', 29)],
        5: [('Female', 22), ('Female', 25), ('Female', 29), ('Female', 32)],
        6: [('Male', 23), ('Male', 27), ('Male', 31), ('Male', 35)],
        7: [('Female', 24), ('Male', 28), ('Female', 31), ('Male', 33)],
        8: [('Other', 26), ('Female', 28), ('Male', 30), ('Female', 34)],
        9: [('Male', 24), ('Male', 27), ('Male', 29), ('Male', 36)],
        10: [('Female', 21), ('Female', 25), ('Female', 29), ('Female', 35)],
        11: [('Male', 25), ('Male', 27), ('Male', 29), ('Male', 31)],
        12: [('Male', 28), ('Male', 30), ('Male', 32), ('Male', 34)],
        13: [('Male', 22), ('Male', 26), ('Male', 33), ('Male', 36)],
    }
    sources = []
    for sheet_number, metadata in sheet_metadata.items():
        image = Image.open(SOURCE / f"grid-{sheet_number:02d}.png").convert("RGB")
        for quadrant, (gender, age) in enumerate(metadata):
            sources.append({'gender': gender, 'age': age, 'image': square_quadrant(image, quadrant), 'sheet': sheet_number, 'quadrant': quadrant})

    targets = [('Male', age) for age in [28, 29, 30, 26, 31, 28, 30, 27, 29, 32, 25, 31, 28, 29, 27, 39, 26, 30, 32, 28, 29, 30, 27, 28]]
    targets += [('Other', 33), ('Male', 34), ('Female', 35), ('Male', 22), ('Male', 23), ('Other', 24), ('Male', 25), ('Male', 26), ('Female', 27), ('Male', 28), ('Other', 29), ('Female', 30), ('Male', 31), ('Male', 32), ('Female', 33)]
    for profile_number, (gender, age) in enumerate(targets, start=2):
        choices = [source for source in sources if source['gender'] == gender]
        if not choices:
            raise RuntimeError(f"No unused {gender} portrait remains for profile {profile_number}.")
        selected = min(choices, key=lambda source: (abs(source['age'] - age), source['sheet'], source['quadrant']))
        sources.remove(selected)
        save_pair(selected['image'], profile_number)


if __name__ == "__main__":
    main()
