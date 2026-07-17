import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:path_drawing/path_drawing.dart';

import '../body_types.dart';
import '../hand_types.dart';
import 'body_svg_asset.dart';

/// One classified SVG path segment within the internal hands render region.
class HandSvgSegment {
  /// Creates a classified hand segment.
  const HandSvgSegment({
    required this.slug,
    required this.side,
    required this.pathData,
  });

  /// Palm/finger semantic represented by [pathData].
  final HandPartSlug slug;

  /// Left or right rendered body side.
  final BodySide side;

  /// SVG path data for this segment.
  final String pathData;
}

/// Classifies the upstream six hand paths into palm/thumb/finger children.
List<HandSvgSegment> handSvgSegmentsFor(BodyPartSvgData hand, BodySide side) {
  final paths = switch (side) {
    BodySide.left => hand.left,
    BodySide.right => hand.right,
    BodySide.both || BodySide.common => const <String>[],
  };
  final raw = [for (final pathData in paths) _RawHandPath(pathData)];

  if (raw.length < renderedHandPartSlugs.length) {
    return [
      for (final item in raw)
        HandSvgSegment(
          slug: HandPartSlug.palm,
          side: side,
          pathData: item.pathData,
        ),
    ];
  }

  final palm = raw.reduce((a, b) => a.area >= b.area ? a : b);
  final nonPalm = raw.where((item) => item != palm).toList();
  final thumb = nonPalm.reduce((a, b) => a.bounds.top <= b.bounds.top ? a : b);
  final fingers = nonPalm.where((item) => item != thumb).toList();
  final thumbIsLeftOfPalm = thumb.centerX < palm.centerX;
  fingers.sort((a, b) {
    final comparison = a.centerX.compareTo(b.centerX);
    return thumbIsLeftOfPalm ? comparison : -comparison;
  });

  final bySlug = <HandPartSlug, _RawHandPath>{
    HandPartSlug.palm: palm,
    HandPartSlug.thumb: thumb,
    for (
      var index = 0;
      index < math.min(fingers.length, _fingerSlugs.length);
      index++
    )
      _fingerSlugs[index]: fingers[index],
  };

  return [
    for (final slug in renderedHandPartSlugs)
      if (bySlug[slug] case final item?)
        HandSvgSegment(slug: slug, side: side, pathData: item.pathData),
  ];
}

/// Returns padded bounds for a standalone hand view.
ui.Rect paddedHandBoundsFor(List<HandSvgSegment> segments) {
  var bounds = _PathCache.parse(segments.first.pathData).getBounds();
  for (final segment in segments.skip(1)) {
    bounds = bounds.expandToInclude(
      _PathCache.parse(segment.pathData).getBounds(),
    );
  }
  final padding = math.max(bounds.width, bounds.height) * 0.08;
  return bounds.inflate(padding);
}

class _RawHandPath {
  _RawHandPath(this.pathData) : bounds = _PathCache.parse(pathData).getBounds();

  final String pathData;
  final ui.Rect bounds;

  double get area => bounds.width * bounds.height;

  double get centerX => bounds.center.dx;
}

const _fingerSlugs = [
  HandPartSlug.indexFinger,
  HandPartSlug.middleFinger,
  HandPartSlug.ringFinger,
  HandPartSlug.littleFinger,
];

class _PathCache {
  static final Map<String, ui.Path> _cache = <String, ui.Path>{};

  static ui.Path parse(String pathData) {
    return _cache.putIfAbsent(pathData, () => parseSvgPathData(pathData));
  }
}
