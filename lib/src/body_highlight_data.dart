import 'package:flutter/widgets.dart';

import 'body_types.dart';
import 'muscle_region_types.dart';

/// Highlight data for one independently renderable muscle region.
class BodyHighlightData {
  /// Creates a heatmap highlight.
  const BodyHighlightData({
    required this.region,
    this.intensity = 1,
    this.side = BodySide.both,
    this.color,
    this.metric,
  });

  /// Muscle-region identity owned by the renderer contract.
  final MuscleRegionKey region;

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
    MuscleRegionKey? region,
    double? intensity,
    BodySide? side,
    Color? color,
    String? metric,
  }) {
    return BodyHighlightData(
      region: region ?? this.region,
      intensity: intensity ?? this.intensity,
      side: side ?? this.side,
      color: color ?? this.color,
      metric: metric ?? this.metric,
    );
  }

  @override
  String toString() {
    return 'BodyHighlightData(region: $region, intensity: $intensity, '
        'side: $side, metric: $metric)';
  }
}
