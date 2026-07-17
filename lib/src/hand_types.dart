import 'package:flutter/widgets.dart';

import 'body_types.dart';

/// Controls how hands are represented in the full anatomy map.
enum HandDetailLevel {
  /// Render and hit-test each hand as one parent body region.
  ///
  /// A parent `hands` highlight controls the whole hand. Hand child highlights
  /// are aggregated into the parent region only when no parent highlight exists.
  handsOnly,

  /// Render and hit-test palm/thumb/index/middle/ring/little child segments.
  ///
  /// Exact child highlights take precedence over a parent `hands` fallback.
  segments,
}

/// Hand/finger semantic labels exposed by the segmented hand heatmap.
enum HandPartSlug {
  /// Aggregate key for the full rendered hand.
  hand,

  palm,
  thumb,
  indexFinger,
  middleFinger,
  ringFinger,
  littleFinger,
}

/// Exact hand regions backed by separate SVG fragments.
const renderedHandPartSlugs = <HandPartSlug>[
  HandPartSlug.palm,
  HandPartSlug.thumb,
  HandPartSlug.indexFinger,
  HandPartSlug.middleFinger,
  HandPartSlug.ringFinger,
  HandPartSlug.littleFinger,
];

/// Tree helper for the aggregate hand region.
extension HandPartSlugTreeX on HandPartSlug {
  /// Exact child segments for [HandPartSlug.hand].
  List<HandPartSlug> get children => this == HandPartSlug.hand
      ? renderedHandPartSlugs
      : const <HandPartSlug>[];
}

/// Convenience helpers for stable hand-part labels.
extension HandPartSlugX on HandPartSlug {
  /// A short human-readable label.
  String get label => switch (this) {
    HandPartSlug.hand => 'Hand',
    HandPartSlug.palm => 'Palm',
    HandPartSlug.thumb => 'Thumb',
    HandPartSlug.indexFinger => 'Index',
    HandPartSlug.middleFinger => 'Middle',
    HandPartSlug.ringFinger => 'Ring',
    HandPartSlug.littleFinger => 'Little',
  };
}

/// Highlight data for one hand/finger semantic segment.
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

  /// Normalized heatmap intensity, clamped to 0..1.
  final double intensity;

  /// Side semantics for the rendered hand region.
  final BodySide side;

  /// Optional custom base color.
  final Color? color;

  /// Optional display/debug metric.
  final String? metric;

  /// The safely clamped intensity used by rendering and color resolution.
  double get normalizedIntensity => _normalizeIntensity(intensity);

  /// Creates a copy with selected fields changed.
  HandHighlightData copyWith({
    HandPartSlug? slug,
    double? intensity,
    BodySide? side,
    Color? color,
    String? metric,
  }) {
    return HandHighlightData(
      slug: slug ?? this.slug,
      intensity: intensity ?? this.intensity,
      side: side ?? this.side,
      color: color ?? this.color,
      metric: metric ?? this.metric,
    );
  }

  @override
  String toString() {
    return 'HandHighlightData(slug: $slug, intensity: $intensity, '
        'side: $side, metric: $metric)';
  }
}

double _normalizeIntensity(double value) {
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

/// Callback payload for a tapped hand/finger segment.
class HandPartTap {
  /// Creates a tap payload.
  const HandPartTap({
    required this.gender,
    required this.view,
    required this.side,
    required this.slug,
    this.highlight,
  });

  /// Tapped gender view.
  final BodyGender gender;

  /// Tapped front/back view.
  final BodyView view;

  /// Tapped left/right hand side.
  final BodySide side;

  /// Tapped hand/finger slug.
  final HandPartSlug slug;

  /// Highlight data active for this segment, if any.
  final HandHighlightData? highlight;
}
