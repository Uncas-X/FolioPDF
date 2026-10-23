#!/usr/bin/env python3
"""Check every literal L() key and localized model enum against all 16 UI languages."""
import json
import pathlib
import plistlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LANGUAGES = ["zh-Hans", "en", "zh-Hant", "ja", "ko", "fr", "de", "es", "it", "pt-BR", "ru", "ar", "hi", "tr", "nl", "pl"]
ENUMS = {"SortOrder", "OutputMode", "PaperSize", "ImageCompression", "PDFLayout"}


def keys_used():
    keys = set()
    for source in (ROOT / "Sources").rglob("*.swift"):
        text = source.read_text()
        for match in re.finditer(r'\bL\("((?:[^"\\]|\\.)*)"\)', text):
            value = match.group(1)
            if "\\(" not in value:
                keys.add(json.loads('"' + value + '"'))
        # Fixed diagnostics are translated at the app boundary with L(reason).
        diagnostic_patterns = [
            r'(?:ConversionError\.(?:invalidSettings|outputFailure)|InterfaceError\.malformed|warnings\.append)\("((?:[^"\\]|\\.)*)"\)',
            r'BookmarkError\.invalidLine\([^,\n]+,\s*"((?:[^"\\]|\\.)*)"\)',
        ]
        for pattern in diagnostic_patterns:
            for match in re.finditer(pattern, text):
                value = match.group(1)
                if "\\(" not in value:
                    keys.add(json.loads('"' + value + '"'))
        for name in ENUMS:
            enum = re.search(r'\benum\s+' + name + r'\b[^\{]*\{([^}]*)\}', text, re.S)
            if enum:
                keys.update(re.findall(r'=\s*"([^"\\]*)"', enum.group(1)))
    return keys


def main():
    used = keys_used()
    if "--list" in sys.argv:
        print(json.dumps(sorted(used), ensure_ascii=False, indent=2))
        return 0
    path = ROOT / "Sources/FolioPDF/Resources/Localizations.json"
    values = json.loads(path.read_text())
    problems = []
    catalog = (ROOT / "Sources/FolioPDF/Localization.swift").read_text()
    selectable = re.findall(r'\.init\(id: "([^"]+)", nativeName:', catalog)
    metadata = plistlib.loads((ROOT / "packaging/Info.plist").read_bytes())
    if selectable != LANGUAGES or metadata["CFBundleLocalizations"] != LANGUAGES:
        problems.append("Language picker / Info.plist does not match the requested language order.")
    if set(values) != set(LANGUAGES):
        problems.append("Translation resource language set differs from the supported languages.")
    for language in LANGUAGES:
        dictionary = values.get(language, {})
        if set(dictionary) != set(values["en"]):
            problems.append(f"{language}: translation key set differs from English.")
        for key in sorted(used | set(values["en"])):
            if not isinstance(dictionary.get(key), str) or not dictionary.get(key).strip():
                problems.append(f"{language}: missing {key!r}")
                continue
            placeholders = lambda value: sorted(re.findall(r'%(?:\d+\$)?[-+0 #]*(?:\d+)?(?:\.\d+)?(?:ll|l|z)?[diuoxXfFeEgGaAcCsSp@]', value))
            if placeholders(key) != placeholders(dictionary[key]):
                problems.append(f"{language}: format placeholders differ for {key!r}")
    if problems:
        print("\n".join(problems))
        return 1
    print(f"Localization verified: {len(used)} UI phrases × {len(LANGUAGES)} languages; no missing or empty translations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
