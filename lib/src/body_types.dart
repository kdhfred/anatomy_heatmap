/// Supported body-map gender variants ported from the upstream SVG assets.
enum BodyGender { male, female }

/// Supported body-map views.
enum BodyView { front, back }

/// Side semantics for a highlighted body part.
enum BodySide {
  /// Highlight only paths tagged as left in the SVG data.
  left,

  /// Highlight only paths tagged as right in the SVG data.
  right,

  /// Highlight both left and right paths, and common paths for the slug.
  both,

  /// Highlight only paths tagged as common in the SVG data.
  common,
}
