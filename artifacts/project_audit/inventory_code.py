from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(r"D:\Projects\amora_ai")
BACKEND = ROOT / "Backend" / "src"
OUT = ROOT / "tmp" / "project_audit" / "code_inventory.json"


def normalize_frontend_path(path: str) -> str:
    path = re.sub(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?", lambda m: f":{m.group(1)}", path)
    path = re.sub(r"\?.*$", "", path)
    return path


def backend_endpoints() -> list[dict]:
    server = (BACKEND / "server.js").read_text(encoding="utf-8")
    imports = dict(re.findall(r"const\s+(\w+)\s*=\s*require\(['\"]\.\/routes\/([^'\"]+)['\"]\)", server))
    mounts = {
        variable: prefix
        for prefix, variable in re.findall(
            r"app\.use\(['\"]([^'\"]+)['\"],\s*(\w+)\)", server
        )
    }
    file_prefix: dict[str, str] = {}
    for variable, file_stem in imports.items():
        if variable in mounts:
            file_prefix[file_stem + ".js"] = mounts[variable]

    endpoints = []
    route_pattern = re.compile(
        r"router\.(get|post|put|patch|delete)\s*\(\s*['\"]([^'\"]+)['\"]",
        re.IGNORECASE | re.DOTALL,
    )
    for path in sorted((BACKEND / "routes").glob("*.js")):
        prefix = file_prefix.get(path.name)
        if prefix is None:
            continue
        text = path.read_text(encoding="utf-8")
        for match in route_pattern.finditer(text):
            suffix = match.group(2)
            full_path = prefix if suffix == "/" else prefix.rstrip("/") + "/" + suffix.lstrip("/")
            endpoints.append({
                "method": match.group(1).upper(),
                "path": full_path,
                "route_file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": text[: match.start()].count("\n") + 1,
            })
    endpoints.sort(key=lambda item: (item["path"], item["method"]))
    return endpoints


def frontend_endpoint_literals() -> list[dict]:
    files = [
        ROOT / "lib" / "core" / "auth" / "auth_service.dart",
        ROOT / "lib" / "core" / "api" / "phase_two_api_service.dart",
        ROOT / "lib" / "features" / "onboarding" / "data" / "onboarding_api_service.dart",
        ROOT / "lib" / "features" / "discover" / "data" / "discover_api_service.dart",
        ROOT / "lib" / "features" / "chat" / "data" / "chat_repository.dart",
        ROOT / "lib" / "features" / "events" / "data" / "event_repository.dart",
        ROOT / "lib" / "features" / "monetization" / "data" / "monetization_repository.dart",
    ]
    entries: list[dict] = []
    string_pattern = re.compile(r"(['\"])(/api/[^'\"]+)\1")
    for path in files:
        text = path.read_text(encoding="utf-8")
        for match in string_pattern.finditer(text):
            raw = match.group(2)
            before = text[max(0, match.start() - 220) : match.start()]
            method_matches = list(re.finditer(r"['\"](GET|POST|PUT|PATCH|DELETE)['\"]", before))
            method = method_matches[-1].group(1) if method_matches else None
            if method is None:
                helper = before.rstrip().splitlines()[-1] if before.rstrip().splitlines() else ""
                if "_post(" in helper:
                    method = "POST"
            entries.append({
                "method": method or "UNKNOWN",
                "path": normalize_frontend_path(raw),
                "raw_path": raw,
                "file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": text[: match.start()].count("\n") + 1,
            })

    # Dynamic media retrieval is constructed from response IDs, so it is not
    # represented by a full literal above.
    entries.append({
        "method": "GET",
        "path": "/api/messages/:messageId/media/:mediaId",
        "raw_path": "response media URL",
        "file": "lib/features/chat/data/chat_repository.dart",
        "line": 483,
    })

    # Correct helper calls whose method is intentionally implicit.
    implicit_methods = {
        "/api/auth/signup": "POST",
        "/api/auth/resend-verification-code": "POST",
        "/api/auth/verify-account": "POST",
        "/api/auth/login": "POST",
        "/api/auth/google": "POST",
        "/api/auth/forgot-password": "POST",
        "/api/auth/verify-reset-code": "POST",
        "/api/auth/reset-password": "POST",
        "/api/conversations/:conversationId/media": "POST",
        "/api/events/:eventId/feedback": "POST",
        "/api/onboarding/photos": "POST",
        "/api/reports/:reportId/evidence": "POST",
        "/api/wallet/products": "GET",
    }
    for entry in entries:
        if entry["path"] in implicit_methods:
            entry["method"] = implicit_methods[entry["path"]]

    # Keep one evidence row per method/path while retaining the first callsite.
    unique: dict[tuple[str, str], dict] = {}
    for entry in entries:
        if entry["method"] == "UNKNOWN" and entry["path"] in implicit_methods:
            entry["method"] = implicit_methods[entry["path"]]
        unique.setdefault((entry["method"], entry["path"]), entry)
    return sorted(unique.values(), key=lambda item: (item["path"], item["method"]))


def dart_inventory() -> dict:
    dart_files = list((ROOT / "lib").rglob("*.dart"))
    presentation = [path for path in dart_files if "presentation" in path.parts]
    route_defs = []
    for path in dart_files:
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(r"static\s+const\s+(?:String\s+)?routeName\s*=\s*['\"]([^'\"]+)['\"]", text):
            route_defs.append({
                "path": match.group(1),
                "file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": text[: match.start()].count("\n") + 1,
            })
    return {
        "dart_file_count": len(dart_files),
        "presentation_file_count": len(presentation),
        "route_definition_count": len(route_defs),
        "route_definitions": sorted(route_defs, key=lambda item: item["path"]),
    }


def main() -> None:
    output = {
        "backend_endpoints": backend_endpoints(),
        "frontend_endpoint_literals": frontend_endpoint_literals(),
        "dart": dart_inventory(),
    }
    output["backend_endpoint_count"] = len(output["backend_endpoints"])
    output["frontend_endpoint_literal_count"] = len(output["frontend_endpoint_literals"])
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({
        "backend_endpoint_count": output["backend_endpoint_count"],
        "frontend_endpoint_literal_count": output["frontend_endpoint_literal_count"],
        **{key: value for key, value in output["dart"].items() if not isinstance(value, list)},
    }, indent=2))


if __name__ == "__main__":
    main()
