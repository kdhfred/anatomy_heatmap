import 'package:flutter/widgets.dart';

import 'body_types.dart';
import 'hand_types.dart';
import 'muscle_region_types.dart';

/// Highlight data for one body-part slug.
class BodyHighlightData {
  /// Creates a heatmap highlight.
  const BodyHighlightData({
    required this.slug,
    this.handPart,
    this.intensity = 1,
    this.side = BodySide.both,
    this.color,
    this.metric,
  }) : muscleRegionKey = null;

  const BodyHighlightData._({
    required this.slug,
    required this.muscleRegionKey,
    this.handPart,
    this.intensity = 1,
    this.side = BodySide.both,
    this.color,
    this.metric,
  });

  /// Creates an exact highlight for one independently renderable muscle region.
  ///
  /// Unlike the legacy [BodyHighlightData] constructor, a
  /// [MuscleRegionKey.upperBack] highlight does not also highlight trapezius
  /// geometry on the back view.
  factory BodyHighlightData.muscleRegion({
    required MuscleRegionKey region,
    double intensity = 1,
    BodySide side = BodySide.both,
    Color? color,
    String? metric,
  }) {
    return BodyHighlightData._(
      slug: region.bodyPartSlug,
      muscleRegionKey: region,
      intensity: intensity,
      side: side,
      color: color,
      metric: metric,
    );
  }

  /// Body part to highlight.
  final BodyPartSlug slug;

  /// Exact atomic muscle-region identity, when created with
  /// [BodyHighlightData.muscleRegion].
  ///
  /// Null identifies the backwards-compatible slug highlight behavior.
  final MuscleRegionKey? muscleRegionKey;

  /// Optional child region under [BodyPartSlug.hands].
  ///
  /// When null, a `hands` highlight applies to every rendered hand child
  /// segment. When non-null, it applies only to the matching palm/finger
  /// segment, giving callers a tree-shaped `hands -> finger/palm` heatmap.
  final HandPartSlug? handPart;

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
    HandPartSlug? handPart,
    double? intensity,
    BodySide? side,
    Color? color,
    String? metric,
  }) {
    return BodyHighlightData._(
      slug: slug ?? this.slug,
      muscleRegionKey: slug == null && handPart == null
          ? muscleRegionKey
          : null,
      handPart: handPart ?? this.handPart,
      intensity: intensity ?? this.intensity,
      side: side ?? this.side,
      color: color ?? this.color,
      metric: metric ?? this.metric,
    );
  }

  @override
  String toString() {
    return 'BodyHighlightData(slug: $slug, muscleRegionKey: $muscleRegionKey, '
        'handPart: $handPart, '
        'intensity: $intensity, '
        'side: $side, metric: $metric)';
  }
}
