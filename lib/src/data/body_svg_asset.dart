import 'dart:ui' show Rect;

import '../body_types.dart';

/// One SVG body map for a gender/view pair.
class BodySvgAsset {
  /// Creates body SVG data.
  const BodySvgAsset({
    required this.gender,
    required this.view,
    required this.viewBox,
    required this.parts,
    this.outlinePath,
  });

  /// Gender variant.
  final BodyGender gender;

  /// Front/back view.
  final BodyView view;

  /// Original SVG viewBox.
  final Rect viewBox;

  /// Optional outline/silhouette path from the upstream wrapper.
  final String? outlinePath;

  /// Body-part fragments for the view.
  final List<BodyPartSvgData> parts;
}

/// SVG path fragments for one body-part slug.
class BodyPartSvgData {
  /// Creates body-part SVG fragments.
  const BodyPartSvgData({
    required this.slug,
    this.common = const [],
    this.left = const [],
    this.right = const [],
  });

  /// Body-part slug.
  final BodyPartSlug slug;

  /// Fragments with no side-specific semantics.
  final List<String> common;

  /// Left-side fragments.
  final List<String> left;

  /// Right-side fragments.
  final List<String> right;
}
