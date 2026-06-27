import 'package:flutter/widgets.dart';

import '../body_heatmap_color_scheme.dart';
import '../body_highlight_data.dart';
import '../body_types.dart';
import 'body_parts_heatmap.dart';

/// Forward-looking hand/finger semantic labels for Frez climbing use cases.
///
/// The upstream body SVG only identifies the hand as fragmented `hands` paths;
/// it does not provide visually verified thumb/index/middle/ring/pinky regions.
/// For v1, these labels are mapped explicitly to the whole hand (and wrist to
/// forearm + hand) so callers can test data flow without pretending finger-level
/// precision exists.
enum HandPartSlug { thumb, indexFinger, middle, ring, pinky, palm, wrist }

/// Highlight data for hand/finger semantics.
class HandHighlightData {
  /// Creates hand/finger highlight data.
  const HandHighlightData({
    required this.slug,
    this.intensity = 1,
    this.side = BodySide.both,
    this.color,
    this.metric,
  });

  /// Hand/finger semantic label.
  final HandPartSlug slug;

  /// Normalized heatmap intensity, clamped by [BodyHighlightData].
  final double intensity;

  /// Side semantics for the rendered hand region.
  final BodySide side;

  /// Optional custom base color.
  final Color? color;

  /// Optional display/debug metric.
  final String? metric;
}

/// Minimal v1 foundation for hand/finger heatmap semantics.
///
/// TODO: Replace whole-hand fallback mapping with visually verified finger path
/// segmentation before using this for precise thumb/index/middle/ring/pinky UI.
class HandPartsHeatmap extends StatelessWidget {
  /// Creates a hand heatmap foundation widget.
  const HandPartsHeatmap({
    super.key,
    this.gender = BodyGender.male,
    this.views = const [BodyView.front, BodyView.back],
    this.highlights = const [],
    this.colorScheme = BodyHeatmapColorScheme.redLoad,
    this.onPartTap,
    this.height,
  });

  /// Gender variant to render.
  final BodyGender gender;

  /// Body views containing hand fragments.
  final List<BodyView> views;

  /// Hand semantic highlight rows.
  final List<HandHighlightData> highlights;

  /// Color palette and stroke settings.
  final BodyHeatmapColorScheme colorScheme;

  /// Optional tap callback for the underlying hand/forearm regions.
  final ValueChanged<BodyPartTap>? onPartTap;

  /// Optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return BodyPartsHeatmap(
      gender: gender,
      views: views,
      highlights: _toBodyHighlights(highlights),
      colorScheme: colorScheme,
      onPartTap: onPartTap,
      hiddenParts: BodyPartSlug.values
          .where(
            (slug) =>
                slug != BodyPartSlug.hands && slug != BodyPartSlug.forearm,
          )
          .toSet(),
      height: height,
    );
  }

  List<BodyHighlightData> _toBodyHighlights(List<HandHighlightData> data) {
    return [for (final item in data) ..._mapHandHighlight(item)];
  }

  Iterable<BodyHighlightData> _mapHandHighlight(HandHighlightData item) sync* {
    yield BodyHighlightData(
      slug: BodyPartSlug.hands,
      intensity: item.intensity,
      side: item.side,
      color: item.color,
      metric: item.metric,
    );
    if (item.slug == HandPartSlug.wrist) {
      yield BodyHighlightData(
        slug: BodyPartSlug.forearm,
        intensity: item.intensity,
        side: item.side,
        color: item.color,
        metric: item.metric,
      );
    }
  }
}
