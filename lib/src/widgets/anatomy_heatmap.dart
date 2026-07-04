import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../body_heatmap_color_scheme.dart';
import '../body_highlight_data.dart';
import '../body_types.dart';
import '../data/body_svg_asset.dart';
import '../data/body_svg_assets.dart';
import '../data/hand_svg_segments.dart';
import '../hand_types.dart';

/// Callback payload for a tapped body-part fragment.
class BodyPartTap {
  /// Creates a tap payload.
  const BodyPartTap({
    required this.gender,
    required this.view,
    required this.slug,
    required this.side,
    this.handPart,
    this.highlight,
  });

  /// Tapped gender view.
  final BodyGender gender;

  /// Tapped front/back view.
  final BodyView view;

  /// Tapped body-part slug.
  final BodyPartSlug slug;

  /// Tapped child hand segment when [slug] is [BodyPartSlug.hands].
  final HandPartSlug? handPart;

  /// Tapped SVG fragment side.
  final BodySide side;

  /// Highlight data active for this fragment, if any.
  final BodyHighlightData? highlight;
}

/// Renders one or more anatomy heatmap SVG views.
class AnatomyHeatmap extends StatelessWidget {
  /// Creates an anatomy heatmap.
  const AnatomyHeatmap({
    super.key,
    this.gender = BodyGender.male,
    this.views = const [BodyView.front, BodyView.back],
    this.highlights = const [],
    this.colorScheme = BodyHeatmapColorScheme.redLoad,
    this.handDetailLevel = HandDetailLevel.segments,
    this.onPartTap,
    this.hiddenParts = const {},
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

  /// Highlight rows. Multiple rows for the same side/slug use the strongest
  /// normalized intensity.
  final List<BodyHighlightData> highlights;

  /// Color palette and stroke settings.
  final BodyHeatmapColorScheme colorScheme;

  /// How hands are represented in the full anatomy map.
  ///
  /// [HandDetailLevel.segments] preserves child palm/finger rendering and lets
  /// exact child highlights override a parent [BodyPartSlug.hands] fallback.
  /// [HandDetailLevel.handsOnly] uses the parent highlight when present, then
  /// aggregates child hand highlights into the parent region as a fallback.
  final HandDetailLevel handDetailLevel;

  /// Optional tap callback for interactive heatmap use.
  final ValueChanged<BodyPartTap>? onPartTap;

  /// Body parts to omit from rendering and hit testing.
  final Set<BodyPartSlug> hiddenParts;

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
    final highlightIndex = _HighlightIndex(highlights);
    final children = <Widget>[
      for (var index = 0; index < effectiveViews.length; index++) ...[
        if (index > 0) SizedBox(width: spacing),
        Expanded(
          child: _BodyViewHeatmap(
            asset: bodySvgAssetFor(gender, effectiveViews[index]),
            highlightIndex: highlightIndex,
            colorScheme: colorScheme,
            handDetailLevel: handDetailLevel,
            onPartTap: onPartTap,
            hiddenParts: hiddenParts,
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

/// Backwards-compatible name for callers that still render a body-region map.
@Deprecated('Use AnatomyHeatmap instead.')
class BodyPartsHeatmap extends AnatomyHeatmap {
  /// Creates a body-region heatmap using the legacy widget name.
  const BodyPartsHeatmap({
    super.key,
    super.gender,
    super.views,
    super.highlights,
    super.colorScheme,
    super.handDetailLevel,
    super.onPartTap,
    super.hiddenParts,
    super.showOutline,
    super.spacing,
    super.height,
    super.focusHighlights,
    super.focusPadding,
  });
}

class _BodyViewHeatmap extends StatelessWidget {
  const _BodyViewHeatmap({
    required this.asset,
    required this.highlightIndex,
    required this.colorScheme,
    required this.handDetailLevel,
    required this.onPartTap,
    required this.hiddenParts,
    required this.showOutline,
    required this.focusHighlights,
    required this.focusPadding,
  });

  final BodySvgAsset asset;
  final _HighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;
  final HandDetailLevel handDetailLevel;
  final ValueChanged<BodyPartTap>? onPartTap;
  final Set<BodyPartSlug> hiddenParts;
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
                  hiddenParts: hiddenParts,
                  paddingFraction: focusPadding,
                )
              : asset.viewBox;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onPartTap == null
                ? null
                : (details) {
                    final tap = _hitTest(
                      details.localPosition,
                      size,
                      effectiveViewBox,
                    );
                    if (tap != null) {
                      onPartTap!(tap);
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
                  hiddenParts: hiddenParts,
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

  BodyPartTap? _hitTest(
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
      if (hiddenParts.contains(part.slug)) {
        continue;
      }
      for (final fragment in _fragmentsFor(
        part,
        handDetailLevel,
      ).toList().reversed) {
        final path = _PathCache.parse(fragment.pathData);
        if (path.contains(svgPoint)) {
          return BodyPartTap(
            gender: asset.gender,
            view: asset.view,
            slug: part.slug,
            side: fragment.side,
            handPart: fragment.handPart,
            highlight: highlightIndex.highlightFor(
              part.slug,
              fragment.side,
              handPart: fragment.handPart,
              collapseHandChildren:
                  handDetailLevel == HandDetailLevel.handsOnly,
            ),
          );
        }
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
    required this.hiddenParts,
    required this.showOutline,
    required this.viewBox,
  });

  final BodySvgAsset asset;
  final _HighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;
  final HandDetailLevel handDetailLevel;
  final Set<BodyPartSlug> hiddenParts;
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
      if (hiddenParts.contains(part.slug)) {
        continue;
      }
      for (final fragment in _fragmentsFor(part, handDetailLevel)) {
        final highlight = highlightIndex.highlightFor(
          part.slug,
          fragment.side,
          handPart: fragment.handPart,
          collapseHandChildren: handDetailLevel == HandDetailLevel.handsOnly,
        );
        final fillPaint = ui.Paint()
          ..style = ui.PaintingStyle.fill
          ..color = colorScheme.fillFor(highlight, slug: part.slug);
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

  @override
  bool shouldRepaint(covariant _BodyHeatmapPainter oldDelegate) {
    return oldDelegate.asset != asset ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.handDetailLevel != handDetailLevel ||
        oldDelegate.hiddenParts != hiddenParts ||
        oldDelegate.showOutline != showOutline ||
        oldDelegate.viewBox != viewBox;
  }
}

ui.Rect _highlightFocusViewBox({
  required BodySvgAsset asset,
  required _HighlightIndex highlightIndex,
  required HandDetailLevel handDetailLevel,
  required Set<BodyPartSlug> hiddenParts,
  required double paddingFraction,
}) {
  ui.Rect? bounds;
  for (final part in asset.parts) {
    if (hiddenParts.contains(part.slug)) continue;
    for (final fragment in _fragmentsFor(part, handDetailLevel)) {
      final highlight = highlightIndex.highlightFor(
        part.slug,
        fragment.side,
        handPart: fragment.handPart,
        collapseHandChildren: handDetailLevel == HandDetailLevel.handsOnly,
      );
      if (highlight == null || highlight.normalizedIntensity <= 0) continue;
      final pathBounds = _PathCache.parse(fragment.pathData).getBounds();
      bounds = bounds == null ? pathBounds : bounds.expandToInclude(pathBounds);
    }
  }
  if (bounds == null || bounds.isEmpty) return asset.viewBox;
  return _paddedFocusRect(bounds, asset.viewBox, paddingFraction);
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

class _HighlightIndex {
  _HighlightIndex(List<BodyHighlightData> highlights) {
    for (final highlight in highlights) {
      _bySlug.putIfAbsent(highlight.slug, () => []).add(highlight);
    }
  }

  final Map<BodyPartSlug, List<BodyHighlightData>> _bySlug = {};

  BodyHighlightData? highlightFor(
    BodyPartSlug slug,
    BodySide pathSide, {
    HandPartSlug? handPart,
    bool collapseHandChildren = false,
  }) {
    final candidates = _bySlug[slug];
    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    if (slug != BodyPartSlug.hands) {
      return _strongestMatching(candidates, pathSide, (_) => true);
    }

    if (collapseHandChildren) {
      final parent = _strongestMatching(
        candidates,
        pathSide,
        (highlight) => highlight.handPart == null,
      );
      if (parent != null) {
        return parent;
      }

      final child = _strongestMatching(
        candidates,
        pathSide,
        (highlight) => highlight.handPart != null,
      );
      return child == null ? null : _asParentHandHighlight(child);
    }

    if (handPart != null) {
      final child = _strongestMatching(
        candidates,
        pathSide,
        (highlight) => _handPartMatches(highlight.handPart, handPart),
      );
      if (child != null) {
        return child;
      }
    }

    return _strongestMatching(
      candidates,
      pathSide,
      (highlight) => highlight.handPart == null,
    );
  }

  BodyHighlightData? _strongestMatching(
    List<BodyHighlightData> candidates,
    BodySide pathSide,
    bool Function(BodyHighlightData highlight) matches,
  ) {
    BodyHighlightData? strongest;
    for (final highlight in candidates) {
      if (!_sideMatches(highlight.side, pathSide) || !matches(highlight)) {
        continue;
      }
      if (strongest == null ||
          highlight.normalizedIntensity > strongest.normalizedIntensity) {
        strongest = highlight;
      }
    }
    return strongest;
  }

  BodyHighlightData _asParentHandHighlight(BodyHighlightData highlight) {
    return BodyHighlightData(
      slug: highlight.slug,
      intensity: highlight.intensity,
      side: highlight.side,
      color: highlight.color,
      metric: highlight.metric,
    );
  }

  bool _sideMatches(BodySide highlightSide, BodySide pathSide) {
    return switch (highlightSide) {
      BodySide.both => true,
      BodySide.common => pathSide == BodySide.common,
      BodySide.left => pathSide == BodySide.left,
      BodySide.right => pathSide == BodySide.right,
    };
  }

  bool _handPartMatches(
    HandPartSlug? highlightHandPart,
    HandPartSlug pathHandPart,
  ) {
    if (highlightHandPart == null) {
      return false;
    }
    if (highlightHandPart == HandPartSlug.wrist) {
      return pathHandPart == HandPartSlug.palm;
    }
    return highlightHandPart == pathHandPart;
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
) sync* {
  if (part.slug == BodyPartSlug.hands &&
      handDetailLevel == HandDetailLevel.segments) {
    for (final segment in handSvgSegmentsFor(part, BodySide.left)) {
      yield _PathFragment(
        segment.side,
        segment.pathData,
        handPart: segment.slug,
      );
    }
    for (final segment in handSvgSegmentsFor(part, BodySide.right)) {
      yield _PathFragment(
        segment.side,
        segment.pathData,
        handPart: segment.slug,
      );
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
