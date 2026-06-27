import 'package:flutter/widgets.dart';

import 'body_highlight_data.dart';
import 'body_types.dart';

/// Colors used by [BodyPartsHeatmap] to paint inactive and active body parts.
class BodyHeatmapColorScheme {
  /// Creates a color scheme for body heatmaps.
  const BodyHeatmapColorScheme({
    required this.inactiveFill,
    required this.heatColor,
    required this.borderColor,
    this.hairFill = const Color(0xFF0B1220),
    this.partStroke = const Color(0xFFFFFFFF),
    this.minActiveOpacity = 0.22,
    this.maxActiveOpacity = 0.92,
    this.partStrokeWidth = 0.8,
    this.outlineStrokeWidth = 1.6,
  });

  /// Light gray color used for inactive body parts.
  final Color inactiveFill;

  /// Base red/coral hue used for active heatmap regions.
  final Color heatColor;

  /// Body outline stroke color.
  final Color borderColor;

  /// Dark navy fill used for inactive hair paths.
  final Color hairFill;

  /// Optional stroke between body-part fragments.
  final Color partStroke;

  /// Lowest opacity for a non-zero highlight intensity.
  final double minActiveOpacity;

  /// Highest opacity for intensity 1.0.
  final double maxActiveOpacity;

  /// Stroke width for body-part fragments in SVG coordinate units after scaling.
  final double partStrokeWidth;

  /// Stroke width for the body outline in SVG coordinate units after scaling.
  final double outlineStrokeWidth;

  /// Default Frez-style red load heatmap palette.
  static const redLoad = BodyHeatmapColorScheme(
    inactiveFill: Color(0xFFE8E8E8),
    heatColor: Color(0xFFFF5A4F),
    borderColor: Color(0xFFCCCCCC),
  );

  /// Resolves a fill color for [highlight]. Null means inactive gray.
  ///
  /// Hair is not a muscle heatmap region, so inactive hair paths use
  /// [hairFill] rather than the generic light-gray body fill.
  Color fillFor(BodyHighlightData? highlight, {BodyPartSlug? slug}) {
    if (highlight == null || highlight.normalizedIntensity <= 0) {
      return slug == BodyPartSlug.hair ? hairFill : inactiveFill;
    }
    return colorForIntensity(
      highlight.normalizedIntensity,
      baseColor: highlight.color,
    );
  }

  /// Resolves a red/coral heatmap color with clamped intensity-based opacity.
  Color colorForIntensity(double intensity, {Color? baseColor}) {
    final normalized = BodyHighlightData.normalizeIntensity(intensity);
    if (normalized <= 0) {
      return inactiveFill;
    }
    final minOpacity = BodyHighlightData.normalizeIntensity(minActiveOpacity);
    final maxOpacity = BodyHighlightData.normalizeIntensity(maxActiveOpacity);
    final opacity = minOpacity + (maxOpacity - minOpacity) * normalized;
    return (baseColor ?? heatColor).withValues(alpha: opacity);
  }
}
