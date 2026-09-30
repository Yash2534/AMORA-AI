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


def save_profile(source: Image.Image, profile_number: int, photo_count: int = 2) -> None:
    images = []
    for photo_index in range(photo_count):
        image = portrait_crop(source, 1.0 + (photo_index * 0.055))
        if photo_index % 2:
            image = ImageOps.mirror(image)
        image = ImageEnhance.Color(image).enhance(0.94 + (photo_index * 0.025))
        image = ImageEnhance.Brightness(image).enhance(0.985 + (photo_index * 0.015))
        images.append(image)
    for photo_number, image in enumerate(images, start=1):
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

    targets = [('Male', 28)]
    targets += [('Female', age) for age in [24, 26, 28, 30, 32, 27, 29, 34, 29, 31, 25, 30, 28, 29, 30, 32, 28]]
    targets += [('Male', age) for age in [27, 39, 26, 29, 30, 27, 28]]
    for profile_number, (gender, age) in enumerate(targets, start=1):
        choices = [source for source in sources if source['gender'] == gender]
        if not choices:
            raise RuntimeError(f"No unused {gender} portrait remains for profile {profile_number}.")
        selected = min(choices, key=lambda source: (abs(source['age'] - age), source['sheet'], source['quadrant']))
        sources.remove(selected)
        save_profile(selected['image'], profile_number, 5 if profile_number == 1 else 2)


if __name__ == "__main__":
    main()
