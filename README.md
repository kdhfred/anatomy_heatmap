# body_parts_heatmap

`body_parts_heatmap` is a small Flutter package for rendering body-part SVG
heatmaps. It ports the useful SVG path taxonomy from
[`react-native-body-highlighter`](https://github.com/HichamELBSI/react-native-body-highlighter)
and adds deterministic Frez-style muscle-to-body-part mapping semantics.

## Features

- Male and female body maps.
- Front and back body views.
- Body-part slug highlighting with left/right/both/common side semantics.
- Red/coral opacity heatmap rendering for primary, secondary, or aggregate load.
- Explicit muscle-name-to-SVG-slug adapter; no fuzzy runtime inference.
- Hand/finger semantic foundation with whole-hand fallback and TODOs for verified
  finger segmentation.

## Usage

The bundled `example/` app includes a male/female toggle plus tap-to-edit
activation sliders so you can inspect how each muscle slug responds.

```dart
import 'package:body_parts_heatmap/body_parts_heatmap.dart';

final adapter = MuscleToBodyPartAdapter();
final mapped = adapter.mapToHighlights(
  primaryMuscles: const ['Pectoralis', 'Triceps'],
  secondaryMuscles: const ['Rotator Cuff', 'Forearm'],
);

BodyPartsHeatmap(
  gender: BodyGender.male,
  views: const [BodyView.front, BodyView.back],
  highlights: mapped.highlights,
  colorScheme: BodyHeatmapColorScheme.redLoad,
  onPartTap: (tap) {
    // tap.slug, tap.side, tap.view, tap.highlight?.metric
  },
);
```

In layouts without a bounded height, provide `height`:

```dart
const BodyPartsHeatmap(
  height: 360,
  highlights: [
    BodyHighlightData(slug: BodyPartSlug.chest, intensity: 1),
    BodyHighlightData(slug: BodyPartSlug.upperBack, intensity: 0.45),
  ],
);
```

## Heatmap semantics

The default `BodyHeatmapColorScheme.redLoad` uses:

- inactive body parts: light gray;
- primary muscles: warm red/coral at higher opacity;
- secondary muscles: the same hue at lower opacity;
- aggregate workout heatmaps: intensity `0.0..1.0` controls opacity, where higher
  intensity means more volume/load exposure.

Intensity is clamped safely. Values below `0` render inactive and values above
`1` render at maximum heat opacity.

## Deterministic muscle adapter

`MuscleToBodyPartAdapter` maps exercise metadata such as `target_muscles` and
`synergist_muscles` into SVG body-part slugs using an explicit alias table.
One input can map to multiple slugs: for example `Finger Flexors` maps to both
`forearm` and `hands`. If the same slug appears in both primary and secondary
sets, primary wins. Unknown labels are returned in `unmapped` so product tests
can detect missing taxonomy coverage.

## Hand/finger foundation

The upstream body SVG contains segmented `hands` fragments, but it does not
provide verified Frez semantic labels such as thumb, indexFinger/index, middle, ring, pinky,
or palm. `HandPartsHeatmap` intentionally maps these labels to the whole hand
for v1, and maps wrist to both hand and forearm. Finger-level mapping should be
added only after visual verification of each path fragment.

Future climbing patterns to model explicitly include `4F`, `3F front/back`,
`2F front/middle/back`, `mono`, `pinch/thumb opposition`, and custom pockets.

## Attribution and license

This package is MIT licensed. SVG path data and outline data are converted from
`react-native-body-highlighter`, which is MIT licensed. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for upstream copyright and
license notice.

The Flutter implementation uses `path_drawing` to parse SVG path strings into
Flutter `Path` objects. This keeps rendering in a `CustomPainter` without a React
Native or SVG widget runtime dependency.
