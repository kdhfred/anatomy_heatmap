import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../body_heatmap_color_scheme.dart';
import '../body_types.dart';
import '../data/body_svg_asset.dart';
import '../data/body_svg_assets.dart';
import '../data/hand_svg_segments.dart';
import '../hand_types.dart';

/// Renders segmented palm/thumb/index/middle/ring/little-finger heatmaps.
///
/// The upstream body SVG stores each hand as six path fragments. This widget
/// classifies those fragments by geometry so palm and every finger can be
/// highlighted and hit-tested independently instead of falling back to the
/// whole `hands` body region.
class HandPartsHeatmap extends StatelessWidget {
  /// Creates a segmented hand/finger heatmap widget.
  const HandPartsHeatmap({
    super.key,
    this.gender = BodyGender.male,
    this.views = const [BodyView.front],
    this.sides = const [BodySide.left, BodySide.right],
    this.highlights = const [],
    this.colorScheme = BodyHeatmapColorScheme.redLoad,
    this.onPartTap,
    this.spacing = 12,
    this.height,
  });

  /// Gender variant to render.
  final BodyGender gender;

  /// Body views containing hand fragments. Empty input falls back to front view.
  final List<BodyView> views;

  /// Hand sides to render. [BodySide.both] expands to left and right.
  final List<BodySide> sides;

  /// Hand semantic highlight rows.
  final List<HandHighlightData> highlights;

  /// Color palette and stroke settings.
  final BodyHeatmapColorScheme colorScheme;

  /// Optional tap callback for the exact hand/finger segment.
  final ValueChanged<HandPartTap>? onPartTap;

  /// Space between rendered hands/views.
  final double spacing;

  /// Optional fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveViews = views.isEmpty ? const [BodyView.front] : views;
    final effectiveSides = _effectiveSides(sides);
    final highlightIndex = _HandHighlightIndex(highlights);
    final panes = <Widget>[
      for (final view in effectiveViews)
        for (final side in effectiveSides)
          _HandViewHeatmap(
            asset: bodySvgAssetFor(gender, view),
            side: side,
            highlightIndex: highlightIndex,
            colorScheme: colorScheme,
            onPartTap: onPartTap,
          ),
    ];

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < panes.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Expanded(child: panes[index]),
        ],
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: row);
    }
    return row;
  }

  static List<BodySide> _effectiveSides(List<BodySide> sides) {
    if (sides.isEmpty) {
      return const [BodySide.left, BodySide.right];
    }
    final result = <BodySide>[];
    void add(BodySide side) {
      if (!result.contains(side)) {
        result.add(side);
      }
    }

    for (final side in sides) {
      switch (side) {
        case BodySide.left:
        case BodySide.right:
          add(side);
        case BodySide.both:
          add(BodySide.left);
          add(BodySide.right);
        case BodySide.common:
          break;
      }
    }
    return result.isEmpty ? const [BodySide.left, BodySide.right] : result;
  }
}

class _HandViewHeatmap extends StatelessWidget {
  const _HandViewHeatmap({
    required this.asset,
    required this.side,
    required this.highlightIndex,
    required this.colorScheme,
    required this.onPartTap,
  });

  final BodySvgAsset asset;
  final BodySide side;
  final _HandHighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;
  final ValueChanged<HandPartTap>? onPartTap;

  @override
  Widget build(BuildContext context) {
    final hand = asset.parts.firstWhere(
      (part) => part.slug == BodyPartSlug.hands,
    );
    final segments = handSvgSegmentsFor(hand, side);
    final viewBox = paddedHandBoundsFor(segments);

    return AspectRatio(
      aspectRatio: viewBox.width / viewBox.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = ui.Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onPartTap == null
                ? null
                : (details) {
                    final tap = _hitTest(
                      details.localPosition,
                      size,
                      viewBox,
                      segments,
                    );
                    if (tap != null) {
                      onPartTap!(tap);
                    }
                  },
            child: Semantics(
              label:
                  '${asset.gender.name} ${asset.view.name} ${side.name} segmented hand heatmap',
              child: CustomPaint(
                painter: _HandHeatmapPainter(
                  segments: segments,
                  viewBox: viewBox,
                  highlightIndex: highlightIndex,
                  colorScheme: colorScheme,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }

  HandPartTap? _hitTest(
    ui.Offset localPosition,
    ui.Size size,
    ui.Rect viewBox,
    List<HandSvgSegment> segments,
  ) {
    if (size.isEmpty) {
      return null;
    }
    final transform = _ViewTransform.from(viewBox, size);
    final svgPoint = transform.toSvg(localPosition);

    for (final segment in segments.reversed) {
      final path = _PathCache.parse(segment.pathData);
      if (path.contains(svgPoint)) {
        return HandPartTap(
          gender: asset.gender,
          view: asset.view,
          side: side,
          slug: segment.slug,
          highlight: highlightIndex.highlightFor(segment.slug, segment.side),
        );
      }
    }
    return null;
  }
}

class _HandHeatmapPainter extends CustomPainter {
  const _HandHeatmapPainter({
    required this.segments,
    required this.viewBox,
    required this.highlightIndex,
    required this.colorScheme,
  });

  final List<HandSvgSegment> segments;
  final ui.Rect viewBox;
  final _HandHighlightIndex highlightIndex;
  final BodyHeatmapColorScheme colorScheme;

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

    for (final segment in segments) {
      final highlight = highlightIndex.highlightFor(segment.slug, segment.side);
      final fillPaint = ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = _fillFor(highlight);
      final path = _PathCache.parse(segment.pathData);
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

    canvas.restore();
  }

  Color _fillFor(HandHighlightData? highlight) {
    if (highlight == null || highlight.normalizedIntensity <= 0) {
      return colorScheme.inactiveFill;
    }
    return colorScheme.colorForIntensity(
      highlight.normalizedIntensity,
      baseColor: highlight.color,
    );
  }

  @override
  bool shouldRepaint(covariant _HandHeatmapPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.viewBox != viewBox ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _HandHighlightIndex {
  _HandHighlightIndex(List<HandHighlightData> highlights) {
    for (final highlight in highlights) {
      _bySlug.putIfAbsent(highlight.slug, () => []).add(highlight);
    }
  }

  final Map<HandPartSlug, List<HandHighlightData>> _bySlug = {};

  HandHighlightData? highlightFor(HandPartSlug slug, BodySide pathSide) {
    final candidates = [
      ...?_bySlug[slug],
      if (slug == HandPartSlug.palm) ...?_bySlug[HandPartSlug.wrist],
    ];
    if (candidates.isEmpty) {
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
