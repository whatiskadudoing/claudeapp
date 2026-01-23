#!/usr/bin/env python3
"""
Compile Localizable.xcstrings to .lproj/.strings files for SPM builds.

SPM doesn't compile String Catalogs (.xcstrings) to runtime-loadable format,
so we need to convert them to traditional .strings files manually.
"""

import json
import os
import sys
from pathlib import Path


def escape_string_value(value: str) -> str:
    """Escape special characters for .strings format."""
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def convert_xcstrings_to_strings(xcstrings_path: Path, output_dir: Path):
    """Convert .xcstrings file to .lproj/.strings directories."""

    with open(xcstrings_path, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    source_language = catalog.get("sourceLanguage", "en")
    strings = catalog.get("strings", {})

    # Collect all languages
    languages = set()
    languages.add(source_language)

    for key, entry in strings.items():
        localizations = entry.get("localizations", {})
        languages.update(localizations.keys())

    print(f"Found languages: {sorted(languages)}")

    # Generate .strings file for each language
    for lang in sorted(languages):
        # Normalize language code for directory name
        lproj_name = f"{lang}.lproj"
        lproj_dir = output_dir / lproj_name
        lproj_dir.mkdir(parents=True, exist_ok=True)

        strings_file = lproj_dir / "Localizable.strings"

        entries = []
        for key, entry in sorted(strings.items()):
            localizations = entry.get("localizations", {})

            # Try to get the localized value
            value = None
            if lang in localizations:
                loc = localizations[lang]
                if "stringUnit" in loc:
                    value = loc["stringUnit"].get("value")

            # Fall back to source language if not found
            if value is None and source_language in localizations:
                loc = localizations[source_language]
                if "stringUnit" in loc:
                    value = loc["stringUnit"].get("value")

            # Fall back to key itself if nothing found
            if value is None:
                value = key

            escaped_key = escape_string_value(key)
            escaped_value = escape_string_value(value)
            entries.append(f'"{escaped_key}" = "{escaped_value}";')

        with open(strings_file, "w", encoding="utf-8") as f:
            f.write("/* Generated from Localizable.xcstrings */\n\n")
            f.write("\n".join(entries))
            f.write("\n")

        print(f"  Created {strings_file} with {len(entries)} strings")


def main():
    if len(sys.argv) < 3:
        print("Usage: compile-strings.py <input.xcstrings> <output_bundle_dir>")
        sys.exit(1)

    xcstrings_path = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])

    if not xcstrings_path.exists():
        print(f"Error: {xcstrings_path} not found")
        sys.exit(1)

    print(f"Converting {xcstrings_path} to {output_dir}")
    convert_xcstrings_to_strings(xcstrings_path, output_dir)
    print("Done!")


if __name__ == "__main__":
    main()
