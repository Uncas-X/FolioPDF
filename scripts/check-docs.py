#!/usr/bin/env python3
"""Validate the 16 complete documentation editions and their local links."""
from collections import Counter
from pathlib import Path
import os
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = [
    ("zh-Hans", "简体中文"), ("en", "English"), ("zh-Hant", "繁體中文"),
    ("ja", "日本語"), ("ko", "한국어"), ("fr", "Français"), ("de", "Deutsch"),
    ("es", "Español"), ("it", "Italiano"), ("pt-BR", "Português (Brasil)"),
    ("ru", "Русский"), ("ar", "العربية"), ("hi", "हिन्दी"), ("tr", "Türkçe"),
    ("nl", "Nederlands"), ("pl", "Polski"),
]
BEGIN, END = "<!-- languages:start -->", "<!-- languages:end -->"


def document(kind, language):
    if language == "zh-Hans":
        return ROOT / ("README.md" if kind == "readme" else "docs/VALIDATION.md")
    stem = "README" if kind == "readme" else "VALIDATION"
    return ROOT / "docs" / kind / f"{stem}.{language}.md"


def navigation(kind, language, path):
    links = []
    for code, label in LANGUAGES:
        target = os.path.relpath(document(kind, code), path.parent)
        links.append(f"**{label}**" if code == language else f"[{label}]({target})")
    return BEGIN + "\n" + " · ".join(links) + "\n" + END


def without_fences(text):
    return re.sub(r"```[^\n]*\n.*?```", "", text, flags=re.S)


def outline(text):
    return [len(x) for x in re.findall(r"^(#{1,6}) ", without_fences(text), re.M)]


def table_shape(text):
    return [line.count("|") for line in text.splitlines() if line.startswith("|")]


def commands(text):
    blocks = re.findall(r"```sh\n(.*?)```", text, re.S)
    return [line.strip() for block in blocks for line in block.splitlines()
            if line.strip() and not line.lstrip().startswith("#")]


def inline_code(text):
    return Counter(re.findall(r"`([^`\n]+)`", without_fences(text)))


def test_counts(text):
    return re.findall(r"^\|[^|]+\|\s*(\d+)\s*\|", text, re.M)


def main():
    update = "--update-navigation" in sys.argv
    errors = []
    count = 0
    for kind in ["readme", "validation"]:
        canonical = document(kind, "zh-Hans").read_text()
        for code, _ in LANGUAGES:
            path = document(kind, code)
            label = str(path.relative_to(ROOT))
            if not path.exists():
                errors.append(f"Missing edition: {label}")
                continue
            text = path.read_text()
            if re.search(r"freepic2pdf", text, re.I):
                errors.append(f"Removed product reference remains: {label}")
            if kind == "readme" and ("JPEG XL" not in text or "`.jxl`" not in text):
                errors.append(f"Missing JPEG XL input documentation: {label}")
            expected = navigation(kind, code, path)
            if update:
                text = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n*", "", text, flags=re.S)
                title, body = text.split("\n", 1)
                text = title + "\n\n" + expected + "\n\n" + body.lstrip("\n")
                path.write_text(text)
            if expected not in text:
                errors.append(f"Invalid language navigation: {label}")
            if outline(text) != outline(canonical):
                errors.append(f"Missing or extra sections: {label}")
            if table_shape(text) != table_shape(canonical):
                errors.append(f"Missing or changed table structure: {label}")
            if commands(text) != commands(canonical):
                errors.append(f"Build commands differ: {label}")
            if test_counts(text) != test_counts(canonical):
                errors.append(f"Test counts differ: {label}")
            missing = inline_code(canonical) - inline_code(text)
            if missing:
                errors.append(f"Missing technical literals in {label}: {dict(missing)}")
            for target in re.findall(r"\]\(([^)\s]+)\)", text):
                url = urlsplit(target)
                if url.scheme or target.startswith("#"):
                    continue
                resolved = (path.parent / unquote(url.path)).resolve()
                if not resolved.is_relative_to(ROOT) or not resolved.exists():
                    errors.append(f"Broken local link in {label}: {target}")
            if code not in ("zh-Hans", "zh-Hant"):
                body = text.split(END, 1)[-1]
                body = re.sub(r"^\*\*简体中文\*\*.*$", "", body, flags=re.M)
                if re.search(r"[\u4e00-\u9fff]{12,}", body):
                    errors.append(f"Possible untranslated Chinese paragraph: {label}")
            count += 1
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Documentation verified: {count} full documents across {len(LANGUAGES)} languages; navigation, sections, tables, commands, technical literals and local links checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
