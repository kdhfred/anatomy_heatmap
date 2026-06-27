import 'package:flutter/widgets.dart';

import 'body_types.dart';

/// Highlight data for one body-part slug.
class BodyHighlightData {
  /// Creates a heatmap highlight.
  const BodyHighlightData({
    required this.slug,
    this.intensity = 1,
    this.side = BodySide.both,
    this.color,
    this.metric,
  });

  /// Body part to highlight.
  final BodyPartSlug slug;

  /// Normalized heatmap intensity. Values outside 0..1 are clamped at render
  /// time so callers can pass raw normalized calculations safely.
  final double intensity;

  /// Which side(s) should receive the highlight.
  final BodySide side;

  /// Optional custom base color. Opacity still follows [intensity].
  final Color? color;

  /// Optional display/debug metric associated with the heatmap contribution.
  final String? metric;

  /// Returns [value] clamped to the 0.0..1.0 range. NaN becomes 0.0.
  static double normalizeIntensity(double value) {
    if (value.isNaN) {
      return 0;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  /// The safely clamped intensity used by rendering and color resolution.
  double get normalizedIntensity => normalizeIntensity(intensity);

  /// Creates a copy with selected fields changed.
  BodyHighlightData copyWith({
    BodyPartSlug? slug,
    double? intensity,
    BodySide? side,
    Color? color,
    String? metric,
  }) {
    return BodyHighlightData(
      slug: slug ?? this.slug,
      intensity: intensity ?? this.intensity,
      side: side ?? this.side,
      color: color ?? this.color,
      metric: metric ?? this.metric,
    );
  }

  @override
  String toString() {
    return 'BodyHighlightData(slug: $slug, intensity: $intensity, '
        'side: $side, metric: $metric)';
  }
}
