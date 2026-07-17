# anatomy_heatmap

## Credits

`anatomy_heatmap` is the Flutter version / port of
[`react-native-body-highlighter`](https://github.com/HichamELBSI/react-native-body-highlighter).
It converts the upstream body SVG path data and outline data into Dart and adds
Flutter `CustomPainter` rendering, stable muscle-region keys, and tree-shaped
hand regions (`hand -> palm/thumb/index/middle/ring/little`).

Upstream credit:

- **Project:** `react-native-body-highlighter`
- **Author / copyright:** Copyright (c) 2022 ELABBASSI Hicham
- **Repository:** <https://github.com/HichamELBSI/react-native-body-highlighter>
- **Notice file:** [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)

---

`anatomy_heatmap` is a small Flutter package for rendering body-part SVG
heatmaps. It ports the useful SVG path taxonomy from
[`react-native-body-highlighter`](https://github.com/HichamELBSI/react-native-body-highlighter)
and adds stable, independently selectable muscle-region keys.

## Preview

Example app running on an iPhone 17 Pro Max simulator:

<p align="center">
  <img src="doc/images/anatomy_heatmap_iphone17_pro_max.png" alt="anatomy_heatmap example app running on an iPhone 17 Pro Max simulator" width="360">
</p>

## Features

- Male and female body maps.
- Front and back body views.
- Muscle and hand highlighting with left/right/both/common side semantics.
- Stable atomic `MuscleRegionKey` wire keys backed only by independently
  selectable bundled SVG geometry.
- Seed-color opacity heatmap rendering for primary, secondary, or aggregate load.
- Preset color styles, including a region-specific `muscleGroups` palette.
- Caller-owned exercise and business grouping; the package exposes renderable
  regions without prescribing a product taxonomy.
- Tree-shaped hand heatmaps: `hand` can be highlighted as a parent or split
  into palm, thumb, index, middle, ring, and little-finger child regions.
- Configurable full-body hand detail level: aggregate to parent `hand` or
  render palm/finger child segments.
- Example app follows the device/system light or dark theme and can switch
  preset styles live.

## Usage

The bundled `example/` app includes a male/female toggle, preset style selector,
and tap-to-edit activation sliders so you can inspect how each muscle region
responds.

```dart
import 'package:anatomy_heatmap/anatomy_heatmap.dart';

AnatomyHeatmap(
  gender: BodyGender.male,
  views: const [BodyView.front, BodyView.back],
  highlights: const [
    BodyHighlightData(region: MuscleRegionKey.chest, intensity: 1),
    BodyHighlightData(region: MuscleRegionKey.triceps, intensity: 0.6),
  ],
  handHighlights: const [
    HandHighlightData(slug: HandPartSlug.indexFinger, intensity: 0.8),
  ],
  colorScheme: BodyHeatmapColorScheme.muscleGroups,
  handDetailLevel: HandDetailLevel.segments,
  onRegionTap: (tap) {
    // Exactly one of tap.muscleRegion or tap.handPart is non-null.
    // tap.side and tap.view identify the rendered fragment.
  },
);
```

In layouts without a bounded height, provide `height`:

```dart
AnatomyHeatmap(
  height: 360,
  highlights: [
    BodyHighlightData(
      region: MuscleRegionKey.chest,
      intensity: 1,
    ),
    BodyHighlightData(
      region: MuscleRegionKey.upperBack,
      intensity: 0.45,
    ),
  ],
);
```

## Atomic muscle regions

`MuscleRegionKey` is the rendering contract for muscle data. It intentionally
contains no exercise, primary/secondary, or product grouping semantics. Persist
`wireKey`, never the enum `name` or `index`.

The canonical wire-key order is:

`chest`, `abs`, `obliques`, `biceps`, `triceps`, `forearm`, `deltoids`,
`trapezius`, `upper-back`, `lats`, `lower-back`, `gluteal`, `hamstring`,
`quadriceps`, `calves`, `adductors`, `tibialis`, `neck`, `abductors`.

Use `muscleRegionKeyFromWire` for strict parsing or
`tryMuscleRegionKeyFromWire` for nullable parsing. Each key exposes its `label`,
supported `views`, and `isRenderableIn(view)`.

```dart
final storedKey = muscleRegionKeyFromWire('upper-back');

AnatomyHeatmap(
  views: const [BodyView.back],
  highlights: [
    BodyHighlightData(
      region: storedKey,
      intensity: 1,
      side: BodySide.left,
    ),
  ],
  onRegionTap: (tap) {
    // tap.muscleRegion reports the exact muscle geometry that was tapped.
  },
);
```

Front-only regions are `chest`, `abs`, `obliques`, `biceps`, `quadriceps`,
`tibialis`, and `neck`. Back-only regions are `upper-back`, `lats`,
`lower-back`, `gluteal`, `hamstring`, and `abductors`. The remaining keys have
front and back geometry for both supported genders.

Every `MuscleRegionKey` selects only its own SVG geometry. For example,
`upper-back` and `trapezius` are always independent. Non-highlightable SVG
geometry such as head, hair, knees, ankles, and feet remains an internal
rendering detail rather than part of the public region taxonomy.

The source artwork cannot independently render serratus anterior or
iliopsoas/hip flexors. It also does not safely distinguish individual heads or
fibers within the pectorals, deltoids, biceps, triceps, forearms, rotator cuff,
upper back, spinal erectors, gluteals, adductors, quadriceps, hamstrings, calves,
obliques, abs, or neck. Multiple SVG paths inside one key are not public
anatomical identities; finer targeting requires semantically annotated or new
artwork.

## Heatmap semantics

The default `BodyHeatmapColorScheme.redLoad` uses:

- inactive anatomical regions: light gray;
- primary muscles: warm red/coral at higher opacity;
- secondary muscles: the same hue at lower opacity;
- aggregate workout heatmaps: intensity `0.0..1.0` controls opacity, where higher
  intensity means more volume/load exposure.

Intensity is clamped safely. Values below `0` render inactive and values above
`1` render at maximum heat opacity.

`redLoad` is a seed-based single-hue preset. The default seed is the existing
coral red, but you can choose another hue and keep the same opacity model:

```dart
final scheme = BodyHeatmapColorScheme.fromPreset(
  BodyHeatmapColorPreset.redLoad,
  brightness: Theme.of(context).brightness,
  redLoadSeedColor: const Color(0xFF2563EB),
);
```

For a more anatomical/categorical look, use
`BodyHeatmapColorScheme.muscleGroups`. It keeps the same intensity-based opacity
model but assigns different base hues to major regions and hand child segments.
Caller-provided `BodyHighlightData.color` still overrides any preset color.
For system-aware examples, select a preset style and pass the current brightness:

```dart
final scheme = BodyHeatmapColorScheme.fromPreset(
  BodyHeatmapColorPreset.muscleGroups,
  brightness: Theme.of(context).brightness,
);
```

Preset colors are only defaults. Inject product-specific color settings with
`withOverrides`:

```dart
final scheme = BodyHeatmapColorScheme.fromPreset(
  BodyHeatmapColorPreset.muscleGroups,
  brightness: Theme.of(context).brightness,
).withOverrides(
  muscleRegionHeatColors: {
    MuscleRegionKey.chest: const Color(0xFFDC2626),
    MuscleRegionKey.quadriceps: const Color(0xFF16A34A),
  },
  handPartHeatColors: {
    HandPartSlug.indexFinger: const Color(0xFF0284C7),
  },
);
```

Use `copyWith` instead when you want to replace a color map entirely.

## Hand detail levels

The full `AnatomyHeatmap` can treat hands at two levels:

- `HandDetailLevel.handsOnly`: renders each hand as a parent `hand` region.
  A parent `hand` highlight controls the whole hand; if no parent highlight is
  supplied, existing palm/finger highlights are aggregated into that region.
- `HandDetailLevel.segments`: renders palm, thumb, index, middle, ring, and
  little-finger child paths in the full body map. Exact child highlights take
  precedence over a parent `hand` fallback so finger opacity remains adjustable.

```dart
AnatomyHeatmap(
  handHighlights: const [
    HandHighlightData(slug: HandPartSlug.hand, intensity: 0.7),
  ],
  handDetailLevel: HandDetailLevel.handsOnly,
);
```

Callers own exercise-name and business-group mappings. Convert those concepts to
the smallest renderable keys at the product boundary:

```dart
const productGroups = <String, Set<MuscleRegionKey>>{
  'push': {MuscleRegionKey.chest, MuscleRegionKey.triceps},
};

final highlights = [
  for (final region in productGroups['push'] ?? const <MuscleRegionKey>{})
    BodyHighlightData(region: region, intensity: 1),
];
```

Use `HandPartsHeatmap` when you want a dedicated zoomed-in palm/finger panel
regardless of the full-body hand level.

## Segmented hand/finger heatmaps

The upstream body SVG contains six `hands` fragments per side. `AnatomyHeatmap`
classifies those fragments by geometry, so `HandPartSlug.hand` can behave like a
parent node with child palm/finger heatmap regions:

```dart
AnatomyHeatmap(
  handHighlights: const [
    // Parent hand highlight: applies to every palm/finger child unless a
    // stronger child highlight is provided.
    HandHighlightData(slug: HandPartSlug.hand, intensity: 0.25),
    HandHighlightData(
      slug: HandPartSlug.indexFinger,
      intensity: 1,
    ),
    HandHighlightData(
      slug: HandPartSlug.middleFinger,
      intensity: 0.7,
    ),
  ],
  onRegionTap: (tap) {
    // tap.handPart is hand/palm/thumb/indexFinger/middleFinger/ringFinger/littleFinger.
  },
);
```

For a zoomed hand-only UI, use the same taxonomy with `HandPartsHeatmap`:

```dart
HandPartsHeatmap(
  views: const [BodyView.front],
  sides: const [BodySide.left, BodySide.right],
  highlights: const [
    HandHighlightData(slug: HandPartSlug.palm, intensity: 0.3),
    HandHighlightData(slug: HandPartSlug.thumb, intensity: 0.8),
    HandHighlightData(slug: HandPartSlug.indexFinger, intensity: 1),
    HandHighlightData(slug: HandPartSlug.middleFinger, intensity: 0.7),
    HandHighlightData(slug: HandPartSlug.ringFinger, intensity: 0.5),
    HandHighlightData(slug: HandPartSlug.littleFinger, intensity: 0.35),
  ],
  onPartTap: (tap) {
    // tap.slug is palm/thumb/indexFinger/middleFinger/ringFinger/littleFinger.
  },
);
```

Future climbing patterns to model explicitly include `4F`, `3F front/back`,
`2F front/middle/back`, `mono`, `pinch/thumb opposition`, and custom pockets.

## Regenerating SVG assets

`lib/src/data/body_svg_assets.dart` is generated; do not edit it by hand. Clone
or check out `react-native-body-highlighter`, then run:

```sh
python3 tool/convert_upstream_assets.py /path/to/react-native-body-highlighter
dart format lib/src/data/body_svg_assets.dart
flutter test
flutter analyze
```

The converter owns the lats and abductors path-index splits and the rear-neck
to trapezius merge. Review those geometry-sensitive overrides whenever the
upstream assets change.

## License

`anatomy_heatmap` is MIT licensed. See [`LICENSE`](LICENSE) for the full package
license text.

This repository also includes Dart-converted SVG path data and body outline data
derived from `react-native-body-highlighter`, which is MIT licensed. The
upstream copyright and MIT notice are preserved in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Keep that notice when
redistributing this package or derived path data.

Summary:

- Package source code in this repository: MIT, copyright (c) 2026
  `anatomy_heatmap` contributors.
- Converted anatomy SVG path data and outline data: derived from
  `react-native-body-highlighter`, MIT, copyright (c) 2022 ELABBASSI Hicham.
- Runtime dependency `path_drawing` is pulled from pub.dev and remains under its
  own package license; it is not vendored into this repository.

Files:

- [`LICENSE`](LICENSE): MIT license for this package.
- [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md): upstream MIT notice for
  `react-native-body-highlighter` SVG path and outline data.
