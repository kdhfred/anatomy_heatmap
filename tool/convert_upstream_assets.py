#!/usr/bin/env python3
"""Convert react-native-body-highlighter TypeScript path assets to Dart.

Usage:
    python3 tool/convert_upstream_assets.py /path/to/react-native-body-highlighter

The generated file intentionally keeps SVG path data as Dart constants so the
Flutter package has no React Native runtime dependency. Upstream is MIT licensed;
keep THIRD_PARTY_NOTICES.md in sync when updating assets.
"""
from __future__ import annotations

import pathlib
import re
import sys
from typing import Iterable

ASSET_FILES = {
    ("male", "front"): "bodyFront.ts",
    ("male", "back"): "bodyBack.ts",
    ("female", "front"): "bodyFemaleFront.ts",
    ("female", "back"): "bodyFemaleBack.ts",
}

DART_SLUGS = {
    "chest": "BodyRenderRegion.chest",
    "abs": "BodyRenderRegion.abs",
    "obliques": "BodyRenderRegion.obliques",
    "biceps": "BodyRenderRegion.biceps",
    "triceps": "BodyRenderRegion.triceps",
    "forearm": "BodyRenderRegion.forearm",
    "hands": "BodyRenderRegion.hands",
    "deltoids": "BodyRenderRegion.deltoids",
    "trapezius": "BodyRenderRegion.trapezius",
    "upper-back": "BodyRenderRegion.upperBack",
    "lats": "BodyRenderRegion.lats",
    "lower-back": "BodyRenderRegion.lowerBack",
    "gluteal": "BodyRenderRegion.gluteal",
    "abductors": "BodyRenderRegion.abductors",
    "hamstring": "BodyRenderRegion.hamstring",
    "quadriceps": "BodyRenderRegion.quadriceps",
    "calves": "BodyRenderRegion.calves",
    "adductors": "BodyRenderRegion.adductors",
    "tibialis": "BodyRenderRegion.tibialis",
    "neck": "BodyRenderRegion.neck",
    "head": "BodyRenderRegion.head",
    "feet": "BodyRenderRegion.feet",
    "ankles": "BodyRenderRegion.ankles",
    "knees": "BodyRenderRegion.knees",
    "hair": "BodyRenderRegion.hair",
}

VIEW_BOXES = {
    ("male", "front"): (0, 0, 724, 1448),
    ("male", "back"): (724, 0, 724, 1448),
    ("female", "front"): (-50, -40, 734, 1538),
    ("female", "back"): (756, 0, 774, 1448),
}


def dart_string(value: str) -> str:
    return "r'''" + value.replace("'''", "''\"'\"''") + "'''"


def extract_array_source(text: str) -> str:
    match = re.search(r"=\s*\[", text)
    if not match:
        raise ValueError("Could not find exported array initializer")
    start = match.end() - 1
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                return text[start + 1 : index]
    raise ValueError("Could not find exported array body")


def split_top_level_objects(array_source: str) -> list[str]:
    objects: list[str] = []
    depth = 0
    start: int | None = None
    in_string = False
    escape = False
    for index, char in enumerate(array_source):
        if in_string:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                start = index
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and start is not None:
                objects.append(array_source[start : index + 1])
                start = None
    return objects


def extract_side_paths(object_source: str, side: str) -> list[str]:
    match = re.search(rf"\b{side}:\s*\[(.*?)\]", object_source, flags=re.S)
    if not match:
        return []
    return re.findall(r'"([^"]*)"', match.group(1), flags=re.S)


def parse_parts(asset_file: pathlib.Path) -> list[dict[str, object]]:
    text = asset_file.read_text()
    array_source = extract_array_source(text)
    parts = []
    for object_source in split_top_level_objects(array_source):
        slug_match = re.search(r'slug:\s*"([^"]+)"', object_source)
        if not slug_match:
            continue
        slug = slug_match.group(1)
        if slug not in DART_SLUGS:
            raise ValueError(f"Unknown slug {slug!r} in {asset_file}")
        parts.append(
            {
                "slug": slug,
                "common": extract_side_paths(object_source, "common"),
                "left": extract_side_paths(object_source, "left"),
                "right": extract_side_paths(object_source, "right"),
            }
        )
    return parts


def clone_part(part: dict[str, object]) -> dict[str, object]:
    return {
        "slug": part["slug"],
        "common": list(part["common"]),
        "left": list(part["left"]),
        "right": list(part["right"]),
    }


def find_part(parts: list[dict[str, object]], slug: str) -> dict[str, object]:
    for part in parts:
        if part["slug"] == slug:
            return part
    raise ValueError(f"Missing expected slug {slug!r}")


def apply_taxonomy_overrides(
    gender: str,
    view: str,
    parts: list[dict[str, object]],
) -> list[dict[str, object]]:
    """Apply repo-local taxonomy splits on top of upstream path assets.

    Upstream groups latissimus-dorsi geometry into ``upper-back`` and exposes
    upper traps as a separate ``trapezius`` part plus rear-neck geometry as
    ``neck``. It also groups the upper/lateral gluteal fragments with the main
    gluteal region. This package presents lats and hip abductors as first-class
    slugs and treats the back-view rear-neck and upper-traps geometry as
    ``trapezius``. The broader ``upperBack`` compound behavior is resolved by
    the renderer rather than by duplicating stored SVG geometry.
    """

    result = [clone_part(part) for part in parts]
    if view != "back":
        return result

    lats_indices = {
        ("male", "back"): {"left": {1}, "right": {2}},
        ("female", "back"): {"left": {1}, "right": {1}},
    }[(gender, view)]
    abductor_indices = {
        ("male", "back"): {"left": {0}, "right": {0}},
        ("female", "back"): {"left": {0}, "right": {1}},
    }[(gender, view)]
    neck = find_part(result, "neck")
    trapezius = find_part(result, "trapezius")
    for side in ("common", "left", "right"):
        trapezius[side] = [*neck[side], *trapezius[side]]
    result.remove(neck)

    upper_back = find_part(result, "upper-back")

    lats = {"slug": "lats", "common": [], "left": [], "right": []}
    for side in ("left", "right"):
        paths = list(upper_back[side])
        moved_indices = lats_indices[side]
        lats[side] = [
            path for index, path in enumerate(paths) if index in moved_indices
        ]
        upper_back[side] = [
            path for index, path in enumerate(paths) if index not in moved_indices
        ]

    upper_back_index = result.index(upper_back)
    result.insert(upper_back_index + 1, lats)

    gluteal = find_part(result, "gluteal")
    abductors = {"slug": "abductors", "common": [], "left": [], "right": []}
    for side in ("left", "right"):
        paths = list(gluteal[side])
        moved_indices = abductor_indices[side]
        abductors[side] = [
            path for index, path in enumerate(paths) if index in moved_indices
        ]
        gluteal[side] = [
            path for index, path in enumerate(paths) if index not in moved_indices
        ]

    gluteal_index = result.index(gluteal)
    result.insert(gluteal_index + 1, abductors)
    return result


def extract_wrapper_paths(upstream: pathlib.Path) -> dict[tuple[str, str], str]:
    result: dict[tuple[str, str], str] = {}
    for gender, wrapper_name in [
        ("male", "SvgMaleWrapper.tsx"),
        ("female", "SvgFemaleWrapper.tsx"),
    ]:
        text = (upstream / "components" / wrapper_name).read_text()
        paths = re.findall(r'd="([^"]+)"', text, flags=re.S)
        if len(paths) != 2:
            raise ValueError(f"Expected 2 outline paths in {wrapper_name}, got {len(paths)}")
        result[(gender, "front")] = paths[0]
        result[(gender, "back")] = paths[1]
    return result


def emit_list(name: str, values: Iterable[str], indent: str = "        ") -> list[str]:
    values = list(values)
    if not values:
        return []
    lines = [f"{indent}{name}: ["]
    lines += [f"{indent}  {dart_string(value)}," for value in values]
    lines.append(f"{indent}],")
    return lines


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    upstream = pathlib.Path(sys.argv[1]).expanduser().resolve()
    if not (upstream / "LICENSE").exists():
        raise SystemExit(f"Missing upstream LICENSE under {upstream}")

    outline_paths = extract_wrapper_paths(upstream)
    output = pathlib.Path("lib/src/data/body_svg_assets.dart")
    lines: list[str] = [
        "// GENERATED CODE - DO NOT EDIT BY HAND.",
        "// Generated by tool/convert_upstream_assets.py from:",
        "// https://github.com/HichamELBSI/react-native-body-highlighter",
        "// Upstream license: MIT, Copyright (c) 2022 ELABBASSI Hicham.",
        "",
        "import 'dart:ui' show Rect;",
        "",
        "import '../body_render_region.dart';",
        "import '../body_types.dart';",
        "import 'body_svg_asset.dart';",
        "",
        "/// Body SVG path assets ported from react-native-body-highlighter.",
        "const bodySvgAssets = <BodySvgAsset>[",
    ]

    for (gender, view), asset_name in ASSET_FILES.items():
        left, top, width, height = VIEW_BOXES[(gender, view)]
        lines += [
            "  BodySvgAsset(",
            f"    gender: BodyGender.{gender},",
            f"    view: BodyView.{view},",
            f"    viewBox: Rect.fromLTWH({left}, {top}, {width}, {height}),",
            f"    outlinePath: {dart_string(outline_paths[(gender, view)])},",
            "    parts: [",
        ]
        parts = apply_taxonomy_overrides(
            gender,
            view,
            parse_parts(upstream / "assets" / asset_name),
        )
        for part in parts:
            lines += [
                "      BodyPartSvgData(",
                f"        slug: {DART_SLUGS[part['slug']]},",
            ]
            lines += emit_list("common", part["common"])
            lines += emit_list("left", part["left"])
            lines += emit_list("right", part["right"])
            lines += ["      ),"]
        lines += ["    ],", "  ),"]

    lines += [
        "];",
        "",
        "/// Returns the SVG body asset for [gender] and [view].",
        "BodySvgAsset bodySvgAssetFor(BodyGender gender, BodyView view) {",
        "  return bodySvgAssets.firstWhere(",
        "    (asset) => asset.gender == gender && asset.view == view,",
        "  );",
        "}",
        "",
    ]

    output.write_text("\n".join(lines))
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
