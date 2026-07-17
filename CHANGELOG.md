## Unreleased

- Added stable `MuscleRegionKey` wire keys for the 19 independently selectable
  muscle regions backed by the bundled SVG artwork.
- Added exact muscle-region highlights and tap identities while preserving the
  legacy compound `upperBack` highlight behavior.
- Documented view availability, serialization, asset limits, and regeneration.

## 0.0.1

- Initial Flutter package with anatomical SVG heatmap rendering.
- Ported male/female front/back body path data from `react-native-body-highlighter`.
- Added deterministic muscle-label adapter and tests.
- Added tree-shaped hand heatmap rendering for `hands -> palm/thumb/index/middle/ring/little` in the full anatomy map.
- Added configurable hand detail levels for parent-only hands or palm/finger segments.
- Added `BodyHeatmapColorScheme` preset selection plus injectable color overrides for region-specific colors.
- Added seed-color customization for the single-hue `redLoad` preset.
- Updated the example app to follow system light/dark theme settings and switch preset styles live.
- Fixed hand highlight precedence so finger sliders update segmented hand opacity while parent hands control collapsed-hand opacity.
- Fixed zero-value hand sliders so explicit `0` remains inactive instead of falling back to parent-hand or child-hand colors.
- Added interactive example controls for male/female toggling and activation sliders.
