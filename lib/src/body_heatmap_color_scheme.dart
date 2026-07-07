import 'package:flutter/widgets.dart';

import 'body_highlight_data.dart';
import 'body_types.dart';
import 'hand_types.dart';

/// Built-in color presets for anatomy heatmaps.
enum BodyHeatmapColorPreset {
  /// Single red/coral heat hue with intensity-controlled opacity.
  redLoad,

  /// Distinct categorical hues for major regions and hand child segments.
  muscleGroups,
}

/// Colors used by [AnatomyHeatmap] to paint inactive and active body parts.
class BodyHeatmapColorScheme {
  /// Creates a color scheme for body heatmaps.
  const BodyHeatmapColorScheme({
    required this.inactiveFill,
    required this.heatColor,
    required this.borderColor,
    this.hairFill = const Color(0xFF0B1220),
    this.partStroke = const Color(0xFFFFFFFF),
    this.bodyPartHeatColors = const {},
    this.handPartHeatColors = const {},
    this.minActiveOpacity = 0.22,
    this.maxActiveOpacity = 0.92,
    this.partStrokeWidth = 0.8,
    this.outlineStrokeWidth = 1.6,
  });

  /// Light gray color used for inactive anatomical regions.
  final Color inactiveFill;

  /// Base red/coral hue used for active heatmap regions.
  final Color heatColor;

  /// Body outline stroke color.
  final Color borderColor;

  /// Dark navy fill used for inactive hair paths.
  final Color hairFill;

  /// Optional stroke between body-part fragments.
  final Color partStroke;

  /// Optional active-color overrides for specific body regions.
  ///
  /// [BodyHighlightData.color] still wins when a caller provides a per-row
  /// custom color.
  final Map<BodyPartSlug, Color> bodyPartHeatColors;

  /// Optional active-color overrides for child regions under [BodyPartSlug.hands].
  ///
  /// [BodyHighlightData.color] still wins when a caller provides a per-row
  /// custom color.
  final Map<HandPartSlug, Color> handPartHeatColors;

  /// Lowest opacity for a non-zero highlight intensity.
  final double minActiveOpacity;

  /// Highest opacity for intensity 1.0.
  final double maxActiveOpacity;

  /// Stroke width for body-part fragments in SVG coordinate units after scaling.
  final double partStrokeWidth;

  /// Stroke width for the body outline in SVG coordinate units after scaling.
  final double outlineStrokeWidth;

  /// Creates a scheme from a built-in [preset].
  ///
  /// Use [copyWith] or [withOverrides] on the returned scheme to inject
  /// product-specific colors while keeping preset defaults for everything else.
  static BodyHeatmapColorScheme fromPreset(
    BodyHeatmapColorPreset preset, {
    Brightness brightness = Brightness.light,
    Color redLoadSeedColor = defaultRedLoadSeedColor,
  }) {
    return switch (preset) {
      BodyHeatmapColorPreset.redLoad => redLoadForBrightness(
        brightness,
        seedColor: redLoadSeedColor,
      ),
      BodyHeatmapColorPreset.muscleGroups => muscleGroupsForBrightness(
        brightness,
      ),
    };
  }

  /// Default seed color for single-hue red/load heatmaps.
  static const defaultRedLoadSeedColor = Color(0xFFFF5A4F);

  /// Default Frez-style red load heatmap palette.
  static const redLoad = BodyHeatmapColorScheme(
    inactiveFill: Color(0xFFE8E8E8),
    heatColor: defaultRedLoadSeedColor,
    borderColor: Color(0xFFCCCCCC),
  );

  /// Dark-background variant of [redLoad].
  static const redLoadDark = BodyHeatmapColorScheme(
    inactiveFill: Color(0xFF242B36),
    heatColor: defaultRedLoadSeedColor,
    borderColor: Color(0xFF64748B),
    hairFill: Color(0xFFE5E7EB),
    partStroke: Color(0xFF111827),
  );

  /// Returns the [redLoad] preset that matches a Flutter brightness.
  static BodyHeatmapColorScheme redLoadForBrightness(
    Brightness brightness, {
    Color seedColor = defaultRedLoadSeedColor,
  }) {
    return redLoadFromSeed(seedColor, brightness: brightness);
  }

  /// Creates a single-hue load heatmap from [seedColor].
  ///
  /// The seed controls the active heat color; intensity still maps to opacity.
  static BodyHeatmapColorScheme redLoadFromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final base = brightness == Brightness.dark ? redLoadDark : redLoad;
    if (seedColor == defaultRedLoadSeedColor) {
      return base;
    }
    return base.copyWith(heatColor: seedColor);
  }

  static const Map<BodyPartSlug, Color> _muscleGroupBodyPartHeatColors = {
    BodyPartSlug.chest: Color(0xFFE53935),
    BodyPartSlug.abs: Color(0xFFFFA000),
    BodyPartSlug.obliques: Color(0xFFFF7043),
    BodyPartSlug.biceps: Color(0xFF1E88E5),
    BodyPartSlug.triceps: Color(0xFF42A5F5),
    BodyPartSlug.forearm: Color(0xFF26A69A),
    BodyPartSlug.hands: Color(0xFF00ACC1),
    BodyPartSlug.deltoids: Color(0xFFAB47BC),
    BodyPartSlug.trapezius: Color(0xFF7E57C2),
    BodyPartSlug.upperBack: Color(0xFF5E35B1),
    BodyPartSlug.lats: Color(0xFF3949AB),
    BodyPartSlug.lowerBack: Color(0xFF8E24AA),
    BodyPartSlug.gluteal: Color(0xFFEC407A),
    BodyPartSlug.hamstring: Color(0xFF66BB6A),
    BodyPartSlug.quadriceps: Color(0xFF43A047),
    BodyPartSlug.calves: Color(0xFF7CB342),
    BodyPartSlug.adductors: Color(0xFF9CCC65),
    BodyPartSlug.tibialis: Color(0xFF26C6DA),
    BodyPartSlug.neck: Color(0xFF78909C),
    BodyPartSlug.head: Color(0xFF90A4AE),
    BodyPartSlug.feet: Color(0xFF8D6E63),
    BodyPartSlug.ankles: Color(0xFFA1887F),
    BodyPartSlug.knees: Color(0xFF689F38),
    BodyPartSlug.abductors: Color(0xFFF06292),
  };

  static const Map<HandPartSlug, Color> _muscleGroupHandPartHeatColors = {
    HandPartSlug.palm: Color(0xFF00ACC1),
    HandPartSlug.thumb: Color(0xFF00897B),
    HandPartSlug.indexFinger: Color(0xFF039BE5),
    HandPartSlug.middleFinger: Color(0xFF3949AB),
    HandPartSlug.ringFinger: Color(0xFF8E24AA),
    HandPartSlug.littleFinger: Color(0xFFD81B60),
    HandPartSlug.wrist: Color(0xFF26A69A),
  };

  /// Preset that gives major muscle/body regions distinct categorical hues.
  ///
  /// This is useful when the heatmap should communicate *which* regions are
  /// active, not only how much load they received.
  static const muscleGroups = BodyHeatmapColorScheme(
    inactiveFill: Color(0xFFE8E8E8),
    heatColor: Color(0xFFFF5A4F),
    borderColor: Color(0xFFCCCCCC),
    bodyPartHeatColors: _muscleGroupBodyPartHeatColors,
    handPartHeatColors: _muscleGroupHandPartHeatColors,
  );

  /// Dark-background variant of [muscleGroups].
  ///
  /// Region hues stay identical to the light preset; only inactive fills and
  /// strokes change so the SVG remains readable on dark surfaces.
  static const muscleGroupsDark = BodyHeatmapColorScheme(
    inactiveFill: Color(0xFF242B36),
    heatColor: Color(0xFFFF5A4F),
    borderColor: Color(0xFF64748B),
    hairFill: Color(0xFFE5E7EB),
    partStroke: Color(0xFF111827),
    bodyPartHeatColors: _muscleGroupBodyPartHeatColors,
    handPartHeatColors: _muscleGroupHandPartHeatColors,
  );

  /// Returns the [muscleGroups] preset that matches a Flutter brightness.
  static BodyHeatmapColorScheme muscleGroupsForBrightness(
    Brightness brightness,
  ) {
    return brightness == Brightness.dark ? muscleGroupsDark : muscleGroups;
  }

  /// Returns a copy with selected fields replaced.
  ///
  /// Map fields replace the existing map entirely. Use [withOverrides] when you
  /// want to merge a few product-specific colors into a preset.
  BodyHeatmapColorScheme copyWith({
    Color? inactiveFill,
    Color? heatColor,
    Color? borderColor,
    Color? hairFill,
    Color? partStroke,
    Map<BodyPartSlug, Color>? bodyPartHeatColors,
    Map<HandPartSlug, Color>? handPartHeatColors,
    double? minActiveOpacity,
    double? maxActiveOpacity,
    double? partStrokeWidth,
    double? outlineStrokeWidth,
  }) {
    return BodyHeatmapColorScheme(
      inactiveFill: inactiveFill ?? this.inactiveFill,
      heatColor: heatColor ?? this.heatColor,
      borderColor: borderColor ?? this.borderColor,
      hairFill: hairFill ?? this.hairFill,
      partStroke: partStroke ?? this.partStroke,
      bodyPartHeatColors: bodyPartHeatColors ?? this.bodyPartHeatColors,
      handPartHeatColors: handPartHeatColors ?? this.handPartHeatColors,
      minActiveOpacity: minActiveOpacity ?? this.minActiveOpacity,
      maxActiveOpacity: maxActiveOpacity ?? this.maxActiveOpacity,
      partStrokeWidth: partStrokeWidth ?? this.partStrokeWidth,
      outlineStrokeWidth: outlineStrokeWidth ?? this.outlineStrokeWidth,
    );
  }

  /// Merges product-specific color settings into this scheme.
  ///
  /// This is the preferred API for customizing built-in presets because callers
  /// can override only the colors they own while preserving preset defaults for
  /// every other body or hand region.
  BodyHeatmapColorScheme withOverrides({
    Color? inactiveFill,
    Color? heatColor,
    Color? borderColor,
    Color? hairFill,
    Color? partStroke,
    Map<BodyPartSlug, Color> bodyPartHeatColors = const {},
    Map<HandPartSlug, Color> handPartHeatColors = const {},
    double? minActiveOpacity,
    double? maxActiveOpacity,
    double? partStrokeWidth,
    double? outlineStrokeWidth,
  }) {
    return copyWith(
      inactiveFill: inactiveFill,
      heatColor: heatColor,
      borderColor: borderColor,
      hairFill: hairFill,
      partStroke: partStroke,
      bodyPartHeatColors: bodyPartHeatColors.isEmpty
          ? this.bodyPartHeatColors
          : {...this.bodyPartHeatColors, ...bodyPartHeatColors},
      handPartHeatColors: handPartHeatColors.isEmpty
          ? this.handPartHeatColors
          : {...this.handPartHeatColors, ...handPartHeatColors},
      minActiveOpacity: minActiveOpacity,
      maxActiveOpacity: maxActiveOpacity,
      partStrokeWidth: partStrokeWidth,
      outlineStrokeWidth: outlineStrokeWidth,
    );
  }

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
      baseColor: highlight.color ?? _baseColorFor(slug, highlight.handPart),
    );
  }

  /// Resolves a fill color for hand-only heatmaps.
  Color fillForHand(HandHighlightData? highlight) {
    if (highlight == null || highlight.normalizedIntensity <= 0) {
      return inactiveFill;
    }
    return colorForIntensity(
      highlight.normalizedIntensity,
      baseColor: highlight.color ?? handPartHeatColors[highlight.slug],
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

  Color? _baseColorFor(BodyPartSlug? slug, HandPartSlug? handPart) {
    if (slug == BodyPartSlug.hands && handPart != null) {
      return handPartHeatColors[handPart] ?? bodyPartHeatColors[slug];
    }
    if (slug == null) {
      return null;
    }
    return bodyPartHeatColors[slug];
  }
}
