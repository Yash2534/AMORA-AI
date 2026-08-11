from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path


ROOT = Path(r"D:\Projects\amora_ai")
SOURCE = ROOT / "tmp" / "project_audit" / "requirements" / "feature_note.json"
OUT = ROOT / "tmp" / "project_audit" / "requirements" / "feature_inventory.json"


def main() -> None:
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    modules: OrderedDict[str, list[dict]] = OrderedDict()
    current: str | None = None
    roadmap: list[dict] = []
    in_roadmap = False

    for paragraph in data["paragraphs"]:
        text = paragraph["text"].strip()
        style = paragraph["style"]
        match = re.match(r"^(\d+)\.\s+(.+)$", text)
        if match:
            current = f"{match.group(1)}. {match.group(2)}"
            modules[current] = []
            in_roadmap = False
            continue
        if text.lower() == "to be discussed":
            current = None
            in_roadmap = True
            continue
        if style.startswith("List Bullet"):
            item = {"name": text, "level": 2 if style == "List Bullet 2" else 1}
            if in_roadmap:
                roadmap.append(item)
            elif current is not None:
                modules[current].append(item)

    output = {
        "module_count": len(modules),
        "core_feature_element_count": sum(len(items) for items in modules.values()),
        "roadmap_item_count": len(roadmap),
        "modules": [{"module": name, "count": len(items), "items": items} for name, items in modules.items()],
        "roadmap": roadmap,
    }
    OUT.write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({
        "module_count": output["module_count"],
        "core_feature_element_count": output["core_feature_element_count"],
        "roadmap_item_count": output["roadmap_item_count"],
        "per_module": {entry["module"]: entry["count"] for entry in output["modules"]},
    }, indent=2))


if __name__ == "__main__":
    main()
