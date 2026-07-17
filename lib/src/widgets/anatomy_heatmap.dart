import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../body_heatmap_color_scheme.dart';
import '../body_highlight_data.dart';
import '../body_render_region.dart';
import '../body_types.dart';
import '../data/body_svg_asset.dart';
import '../data/body_svg_assets.dart';
import '../data/hand_svg_segments.dart';
import '../hand_types.dart';
import '../muscle_region_types.dart';

/// Callback payload for a tapped public anatomy region.
class AnatomyRegionTap {
  /// Creates a tap payload.
  const AnatomyRegionTap({
    required this.gender,
    required this.view,
    required this.side,
    this.muscleRegion,
    this.handPart,
    this.muscleHighlight,
    this.handHighlight,
  }) : assert(
         (muscleRegion == null) != (handPart == null),
         'A tap must identify exactly one muscle or hand region.',
       ),
       assert(
         muscleHighlight == null || muscleRegion != null,
         'A muscle highlight requires a muscle-region tap.',
       ),
       assert(
         handHighlight == null || handPart != null,
         'A hand highlight requires a hand-region tap.',
       );

  /// Tapped gender view.
  final BodyGender gender;

  /// Tapped front/back view.
  final BodyView view;

  /// Tapped muscle region, or null for a hand tap.
  final MuscleRegionKey? muscleRegion;

  /// Tapped hand region, or null for a muscle tap.
  final HandPartSlug? handPart;

  /// Tapped SVG fragment side.
  final BodySide side;

  /// Muscle highlight active for this fragment, if any.
  final BodyHighlightData? muscleHighlight;

  /// Hand highlight active for this fragment, if any.
  final HandHighlightData? handHighlight;
}

/// Renders one or more anatomy heatmap SVG views.
class AnatomyHeatmap extends StatelessWidget {
  /// Creates an anatomy heatmap.
  const AnatomyHeatmap({
    super.key,
    this.gender = BodyGender.male,
    this.views = const [BodyView.front, BodyView.back],
    this.highlights = const [],
    this.handHighlights = const [],
    this.colorScheme = BodyHeatmapColorScheme.redLoad,
    this.handDetailLevel = HandDetailLevel.segments,
    this.onRegionTap,
    this.hiddenMuscleRegions = const {},
    this.hiddenHandRegions = const {},
    this.showOutline = true,
    this.spacing = 12,
    this.height,
    this.focusHighlights = false,
    this.focusPadding = 0.35,
  });

  /// Gender variant to render.
  final BodyGender gender;

  /// Front/back views to render. Empty input falls back to front view.
  final List<BodyView> views;

  /// Muscle highlights. Multiple rows for a side/region use the strongest
  /// normalized intensity.
  final List<BodyHighlightData> highlights;

  /// Hand highlights, including the aggregate [HandPartSlug.hand] region.
  final List<HandHighlightData> handHighlights;

  /// Color palette and stroke settings.
  final BodyHeatmapColorScheme colorScheme;

  /// How hands are represented in the full anatomy map.
  ///
  /// [HandDetailLevel.segments] preserves child palm/finger rendering and lets
  /// exact child highlights override a [HandPartSlug.hand] fallback.
  /// [HandDetailLevel.handsOnly] uses the parent highlight when present, then
  /// aggregates child hand highlights into the parent region as a fallback.
  final HandDetailLevel handDetailLevel;

  /// Optional tap callback for interactive heatmap use.
  final ValueChanged<AnatomyRegionTap>? onRegionTap;

  /// Muscle regions to omit from rendering and hit testing.
  final Set<MuscleRegionKey> hiddenMuscleRegions;

  /// Hand regions to omit from rendering and hit testing.
  ///
  /// Including [HandPartSlug.hand] hides the complete hand. Exact child values
  /// hide only those fragments when [handDetailLevel] is segments.
  final Set<HandPartSlug> hiddenHandRegions;

  /// Whether to paint the upstream outline/silhouette path.
  final bool showOutline;

  /// Space between multiple rendered views.
  final double spacing;

  /// Optional fixed widget height. If null, parent constraints determine size.
  final double? height;

  /// Whether each rendered view should zoom to the bounds of active highlights.
  ///
  /// When no active highlight can be resolved for a view, the original SVG
  /// viewBox is used.
  final bool focusHighlights;

  /// Padding around the resolved highlight bounds as a fraction of the larger
  /// highlight-bounds side.
  final double focusPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveViews = views.isEmpty ? const [BodyView.front] : views;
    final highlightIndex = _HighlightIndex(highlights, handHighlights);
    final children = <Widget>[
      for (var index = 0; index < effectiveViews.length; index++) ...[
        if (index > 0) SizedBox(width: spacing),
        Expanded(
          child: _BodyViewHeatmap(
            asset: bodySvgAssetFor(gender, effectiveViews[index]),
            highlightIndex: highlightIndex,
            colorScheme: colorScheme,
            handDetailLevel: handDetailLevel,
            onRegionTap: onRegionTap,
            hiddenMuscleRegions: hiddenMuscleRegions,
            hiddenHandRegions: hiddenHandRegions,
            showOutline: showOutline,
            focusHighlights: focusHighlights,
            focusPadding: focusPadding,
          ),
        ),
      ],
    ];

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    if (height != null) {
      return SizedBox(height: height, child: row);
    }
    return row;
  }
}

class _BodyViewHeatmap extends StatelessWidget {
  const _BodyViewHeatmap({
    required this.asset,
    required this.highlightIndex,
    required this.colorScheme,
    required this.handDetailLevel,
    required this.onRegionTap,
    required this.hiddenMuscleRegions,
    required this.hiddenHandRegions,
    required this.showOutline,
    required this.focusHighlights,
    required this.focusPadding,
  });

  final BodySvgAsset asset;
  final _HighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;
  final HandDetailLevel handDetailLevel;
  final ValueChanged<AnatomyRegionTap>? onRegionTap;
  final Set<MuscleRegionKey> hiddenMuscleRegions;
  final Set<HandPartSlug> hiddenHandRegions;
  final bool showOutline;
  final bool focusHighlights;
  final double focusPadding;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: asset.viewBox.width / asset.viewBox.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = ui.Size(constraints.maxWidth, constraints.maxHeight);
          final effectiveViewBox = focusHighlights
              ? _highlightFocusViewBox(
                  asset: asset,
                  highlightIndex: highlightIndex,
                  handDetailLevel: handDetailLevel,
                  hiddenMuscleRegions: hiddenMuscleRegions,
                  hiddenHandRegions: hiddenHandRegions,
                  paddingFraction: focusPadding,
                )
              : asset.viewBox;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onRegionTap == null
                ? null
                : (details) {
                    final tap = _hitTest(
                      details.localPosition,
                      size,
                      effectiveViewBox,
                    );
                    if (tap != null) {
                      onRegionTap!(tap);
                    }
                  },
            child: Semantics(
              label: '${asset.gender.name} anatomy heatmap ${asset.view.name}',
              child: CustomPaint(
                painter: _BodyHeatmapPainter(
                  asset: asset,
                  highlightIndex: highlightIndex,
                  colorScheme: colorScheme,
                  handDetailLevel: handDetailLevel,
                  hiddenMuscleRegions: hiddenMuscleRegions,
                  hiddenHandRegions: hiddenHandRegions,
                  showOutline: showOutline,
                  viewBox: effectiveViewBox,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }

  AnatomyRegionTap? _hitTest(
    ui.Offset localPosition,
    ui.Size size,
    ui.Rect viewBox,
  ) {
    if (size.isEmpty) {
      return null;
    }
    final transform = _ViewTransform.from(viewBox, size);
    final svgPoint = transform.toSvg(localPosition);

    for (final part in asset.parts.reversed) {
      if (_isRegionHidden(part.slug, hiddenMuscleRegions, hiddenHandRegions)) {
        continue;
      }
      for (final fragment in _fragmentsFor(
        part,
        handDetailLevel,
        hiddenHandRegions,
      ).toList().reversed) {
        final path = _PathCache.parse(fragment.pathData);
        if (!path.contains(svgPoint)) {
          continue;
        }
        final muscleRegion = part.slug.muscleRegion;
        final handPart = part.slug == BodyRenderRegion.hands
            ? fragment.handPart ?? HandPartSlug.hand
            : null;
        if (muscleRegion == null && handPart == null) {
          continue;
        }
        final highlight = _highlightForFragment(
          highlightIndex: highlightIndex,
          region: part.slug,
          pathSide: fragment.side,
          handPart: fragment.handPart,
          collapseHandChildren: handDetailLevel == HandDetailLevel.handsOnly,
        );
        return AnatomyRegionTap(
          gender: asset.gender,
          view: asset.view,
          side: fragment.side,
          muscleRegion: muscleRegion,
          handPart: handPart,
          muscleHighlight: highlight?.muscle,
          handHighlight: highlight?.hand,
        );
      }
    }
    return null;
  }
}

class _BodyHeatmapPainter extends CustomPainter {
  const _BodyHeatmapPainter({
    required this.asset,
    required this.highlightIndex,
    required this.colorScheme,
    required this.handDetailLevel,
    required this.hiddenMuscleRegions,
    required this.hiddenHandRegions,
    required this.showOutline,
    required this.viewBox,
  });

  final BodySvgAsset asset;
  final _HighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;
  final HandDetailLevel handDetailLevel;
  final Set<MuscleRegionKey> hiddenMuscleRegions;
  final Set<HandPartSlug> hiddenHandRegions;
  final bool showOutline;
  final ui.Rect viewBox;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (size.isEmpty) {
      return;
    }

    final transform = _ViewTransform.from(viewBox, size);
    canvas.save();
    canvas.translate(transform.dx, transform.dy);
    canvas.scale(transform.scale);
    canvas.translate(-viewBox.left, -viewBox.top);

    if (showOutline && asset.outlinePath != null) {
      final outlinePaint = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = colorScheme.outlineStrokeWidth / transform.scale
        ..strokeJoin = ui.StrokeJoin.round
        ..strokeCap = ui.StrokeCap.round
        ..color = colorScheme.borderColor;
      canvas.drawPath(_PathCache.parse(asset.outlinePath!), outlinePaint);
    }

    for (final part in asset.parts) {
      if (_isRegionHidden(part.slug, hiddenMuscleRegions, hiddenHandRegions)) {
        continue;
      }
      for (final fragment in _fragmentsFor(
        part,
        handDetailLevel,
        hiddenHandRegions,
      )) {
        final highlight = _highlightForFragment(
          highlightIndex: highlightIndex,
          region: part.slug,
          pathSide: fragment.side,
          handPart: fragment.handPart,
          collapseHandChildren: handDetailLevel == HandDetailLevel.handsOnly,
        );
        final fillPaint = ui.Paint()
          ..style = ui.PaintingStyle.fill
          ..color = _fillFor(part.slug, highlight);
        final path = _PathCache.parse(fragment.pathData);
        canvas.drawPath(path, fillPaint);

        if (colorScheme.partStrokeWidth > 0) {
          final strokePaint = ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = colorScheme.partStrokeWidth / transform.scale
            ..strokeJoin = ui.StrokeJoin.round
            ..strokeCap = ui.StrokeCap.round
            ..color = colorScheme.partStroke;
          canvas.drawPath(path, strokePaint);
        }
      }
    }

    canvas.restore();
  }

  Color _fillFor(BodyRenderRegion region, _ResolvedHighlight? highlight) {
    if (highlight?.muscle case final muscle?) {
      return colorScheme.fillFor(muscle);
    }
    if (highlight?.hand case final hand?) {
      return colorScheme.fillForHand(hand);
    }
    return region == BodyRenderRegion.hair
        ? colorScheme.hairFill
        : colorScheme.inactiveFill;
  }

  @override
  bool shouldRepaint(covariant _BodyHeatmapPainter oldDelegate) {
    return oldDelegate.asset != asset ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.handDetailLevel != handDetailLevel ||
        oldDelegate.hiddenMuscleRegions != hiddenMuscleRegions ||
        oldDelegate.hiddenHandRegions != hiddenHandRegions ||
        oldDelegate.showOutline != showOutline ||
        oldDelegate.viewBox != viewBox;
  }
}

ui.Rect _highlightFocusViewBox({
  required BodySvgAsset asset,
  required _HighlightIndex highlightIndex,
  required HandDetailLevel handDetailLevel,
  required Set<MuscleRegionKey> hiddenMuscleRegions,
  required Set<HandPartSlug> hiddenHandRegions,
  required double paddingFraction,
}) {
  ui.Rect? bounds;
  for (final part in asset.parts) {
    if (_isRegionHidden(part.slug, hiddenMuscleRegions, hiddenHandRegions)) {
      continue;
    }
    for (final fragment in _fragmentsFor(
      part,
      handDetailLevel,
      hiddenHandRegions,
    )) {
      final highlight = _highlightForFragment(
        highlightIndex: highlightIndex,
        region: part.slug,
        pathSide: fragment.side,
        handPart: fragment.handPart,
        collapseHandChildren: handDetailLevel == HandDetailLevel.handsOnly,
      );
      if (highlight == null || highlight.normalizedIntensity <= 0) {
        continue;
      }
      final pathBounds = _PathCache.parse(fragment.pathData).getBounds();
      bounds = bounds == null ? pathBounds : bounds.expandToInclude(pathBounds);
    }
  }
  if (bounds == null || bounds.isEmpty) {
    return asset.viewBox;
  }
  return _paddedFocusRect(bounds, asset.viewBox, paddingFraction);
}

_ResolvedHighlight? _highlightForFragment({
  required _HighlightIndex highlightIndex,
  required BodyRenderRegion region,
  required BodySide pathSide,
  HandPartSlug? handPart,
  bool collapseHandChildren = false,
}) {
  return highlightIndex.highlightFor(
    region,
    pathSide,
    handPart: handPart,
    collapseHandChildren: collapseHandChildren,
  );
}

ui.Rect _paddedFocusRect(
  ui.Rect bounds,
  ui.Rect outer,
  double paddingFraction,
) {
  final base = math.max(bounds.width, bounds.height);
  var rect = bounds.inflate(base * math.max(0, paddingFraction));
  final minWidth = outer.width * 0.08;
  final minHeight = outer.height * 0.08;
  rect = _expandRectToMinSize(rect, minWidth, minHeight);
  return _constrainRect(rect, outer);
}

ui.Rect _expandRectToMinSize(ui.Rect rect, double minWidth, double minHeight) {
  final width = math.max(rect.width, minWidth);
  final height = math.max(rect.height, minHeight);
  return ui.Rect.fromCenter(center: rect.center, width: width, height: height);
}

ui.Rect _constrainRect(ui.Rect rect, ui.Rect outer) {
  final width = math.min(rect.width, outer.width);
  final height = math.min(rect.height, outer.height);
  var left = rect.center.dx - width / 2;
  var top = rect.center.dy - height / 2;
  left = left.clamp(outer.left, outer.right - width).toDouble();
  top = top.clamp(outer.top, outer.bottom - height).toDouble();
  return ui.Rect.fromLTWH(left, top, width, height);
}

class _ResolvedHighlight {
  const _ResolvedHighlight.muscle(this.muscle) : hand = null;
  const _ResolvedHighlight.hand(this.hand) : muscle = null;

  final BodyHighlightData? muscle;
  final HandHighlightData? hand;

  double get normalizedIntensity =>
      muscle?.normalizedIntensity ?? hand?.normalizedIntensity ?? 0;
}

class _HighlightIndex {
  _HighlightIndex(
    List<BodyHighlightData> muscleHighlights,
    List<HandHighlightData> handHighlights,
  ) {
    for (final highlight in muscleHighlights) {
      _byRegion
          .putIfAbsent(bodyRenderRegionFor(highlight.region), () => [])
          .add(highlight);
    }
    for (final highlight in handHighlights) {
      _byHandPart.putIfAbsent(highlight.slug, () => []).add(highlight);
    }
  }

  final Map<BodyRenderRegion, List<BodyHighlightData>> _byRegion = {};
  final Map<HandPartSlug, List<HandHighlightData>> _byHandPart = {};

  _ResolvedHighlight? highlightFor(
    BodyRenderRegion region,
    BodySide pathSide, {
    HandPartSlug? handPart,
    bool collapseHandChildren = false,
  }) {
    if (region != BodyRenderRegion.hands) {
      final highlight = _strongestMuscle(_byRegion[region], pathSide);
      return highlight == null ? null : _ResolvedHighlight.muscle(highlight);
    }

    final highlight = collapseHandChildren
        ? _collapsedHandHighlight(pathSide)
        : _exactHandHighlight(handPart, pathSide);
    return highlight == null ? null : _ResolvedHighlight.hand(highlight);
  }

  BodyHighlightData? _strongestMuscle(
    List<BodyHighlightData>? candidates,
    BodySide pathSide,
  ) {
    if (candidates == null) {
      return null;
    }
    BodyHighlightData? strongest;
    for (final highlight in candidates) {
      if (!_sideMatches(highlight.side, pathSide)) {
        continue;
      }
      if (strongest == null ||
          highlight.normalizedIntensity > strongest.normalizedIntensity) {
        strongest = highlight;
      }
    }
    return strongest;
  }

  HandHighlightData? _collapsedHandHighlight(BodySide pathSide) {
    final parent = _strongestHand(_byHandPart[HandPartSlug.hand], pathSide);
    if (parent != null) {
      return parent;
    }

    HandHighlightData? strongest;
    for (final entry in _byHandPart.entries) {
      if (entry.key == HandPartSlug.hand) {
        continue;
      }
      final candidate = _strongestHand(entry.value, pathSide);
      if (candidate != null &&
          (strongest == null ||
              candidate.normalizedIntensity > strongest.normalizedIntensity)) {
        strongest = candidate;
      }
    }
    return strongest;
  }

  HandHighlightData? _exactHandHighlight(
    HandPartSlug? handPart,
    BodySide pathSide,
  ) {
    if (handPart != null) {
      final exact = _strongestHand(_byHandPart[handPart], pathSide);
      if (exact != null) {
        return exact;
      }
    }
    return _strongestHand(_byHandPart[HandPartSlug.hand], pathSide);
  }

  HandHighlightData? _strongestHand(
    List<HandHighlightData>? candidates,
    BodySide pathSide,
  ) {
    if (candidates == null) {
      return null;
    }
    HandHighlightData? strongest;
    for (final highlight in candidates) {
      if (!_sideMatches(highlight.side, pathSide)) {
        continue;
      }
      if (strongest == null ||
          highlight.normalizedIntensity > strongest.normalizedIntensity) {
        strongest = highlight;
      }
    }
    return strongest;
  }

  bool _sideMatches(BodySide highlightSide, BodySide pathSide) {
    return switch (highlightSide) {
      BodySide.both => true,
      BodySide.common => pathSide == BodySide.common,
      BodySide.left => pathSide == BodySide.left,
      BodySide.right => pathSide == BodySide.right,
    };
  }
}

class _PathFragment {
  const _PathFragment(this.side, this.pathData, {this.handPart});

  final BodySide side;
  final String pathData;
  final HandPartSlug? handPart;
}

Iterable<_PathFragment> _fragmentsFor(
  BodyPartSvgData part,
  HandDetailLevel handDetailLevel,
  Set<HandPartSlug> hiddenHandRegions,
) sync* {
  if (part.slug == BodyRenderRegion.hands &&
      handDetailLevel == HandDetailLevel.segments) {
    for (final side in const [BodySide.left, BodySide.right]) {
      for (final segment in handSvgSegmentsFor(part, side)) {
        if (_isHandRegionHidden(segment.slug, hiddenHandRegions)) {
          continue;
        }
        yield _PathFragment(
          segment.side,
          segment.pathData,
          handPart: segment.slug,
        );
      }
    }
    return;
  }
  for (final path in part.common) {
    yield _PathFragment(BodySide.common, path);
  }
  for (final path in part.left) {
    yield _PathFragment(BodySide.left, path);
  }
  for (final path in part.right) {
    yield _PathFragment(BodySide.right, path);
  }
}

bool _isRegionHidden(
  BodyRenderRegion region,
  Set<MuscleRegionKey> hiddenMuscleRegions,
  Set<HandPartSlug> hiddenHandRegions,
) {
  if (region == BodyRenderRegion.hands) {
    return hiddenHandRegions.contains(HandPartSlug.hand);
  }
  final muscleRegion = region.muscleRegion;
  return muscleRegion != null && hiddenMuscleRegions.contains(muscleRegion);
}

bool _isHandRegionHidden(
  HandPartSlug region,
  Set<HandPartSlug> hiddenHandRegions,
) {
  return hiddenHandRegions.contains(HandPartSlug.hand) ||
      hiddenHandRegions.contains(region);
}

class _ViewTransform {
  const _ViewTransform({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.viewBox,
  });

  factory _ViewTransform.from(ui.Rect viewBox, ui.Size size) {
    final scale = (size.width / viewBox.width) < (size.height / viewBox.height)
        ? size.width / viewBox.width
        : size.height / viewBox.height;
    final drawnWidth = viewBox.width * scale;
    final drawnHeight = viewBox.height * scale;
    return _ViewTransform(
      scale: scale,
      dx: (size.width - drawnWidth) / 2,
      dy: (size.height - drawnHeight) / 2,
      viewBox: viewBox,
    );
  }

  final double scale;
  final double dx;
  final double dy;
  final ui.Rect viewBox;

  ui.Offset toSvg(ui.Offset local) {
    return ui.Offset(
      (local.dx - dx) / scale + viewBox.left,
      (local.dy - dy) / scale + viewBox.top,
    );
  }
}

class _PathCache {
  static final Map<String, ui.Path> _cache = <String, ui.Path>{};

  static ui.Path parse(String pathData) {
    return _cache.putIfAbsent(pathData, () => parseSvgPathData(pathData));
  }
}
