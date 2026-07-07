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

/// Body-part slugs exposed by the heatmap package.
enum BodyPartSlug {
  chest,
  abs,
  obliques,
  biceps,
  triceps,
  forearm,
  hands,
  deltoids,
  trapezius,
  upperBack,
  lats,
  lowerBack,
  gluteal,
  hamstring,
  quadriceps,
  calves,
  adductors,
  tibialis,
  neck,
  head,
  feet,
  ankles,
  knees,
  hair,
  abductors,
}

/// Convenience helpers for stable body-part slug conversion.
extension BodyPartSlugX on BodyPartSlug {
  /// The upstream/react-native SVG slug spelling.
  String get upstreamSlug => switch (this) {
    BodyPartSlug.upperBack => 'upper-back',
    BodyPartSlug.lats => 'lats',
    BodyPartSlug.lowerBack => 'lower-back',
    BodyPartSlug.chest => 'chest',
    BodyPartSlug.abs => 'abs',
    BodyPartSlug.obliques => 'obliques',
    BodyPartSlug.biceps => 'biceps',
    BodyPartSlug.triceps => 'triceps',
    BodyPartSlug.forearm => 'forearm',
    BodyPartSlug.hands => 'hands',
    BodyPartSlug.deltoids => 'deltoids',
    BodyPartSlug.trapezius => 'trapezius',
    BodyPartSlug.gluteal => 'gluteal',
    BodyPartSlug.hamstring => 'hamstring',
    BodyPartSlug.quadriceps => 'quadriceps',
    BodyPartSlug.calves => 'calves',
    BodyPartSlug.adductors => 'adductors',
    BodyPartSlug.tibialis => 'tibialis',
    BodyPartSlug.neck => 'neck',
    BodyPartSlug.head => 'head',
    BodyPartSlug.feet => 'feet',
    BodyPartSlug.ankles => 'ankles',
    BodyPartSlug.knees => 'knees',
    BodyPartSlug.hair => 'hair',
    BodyPartSlug.abductors => 'abductors',
  };

  /// A simple human-readable label.
  String get label => switch (this) {
    BodyPartSlug.upperBack => 'Upper back',
    BodyPartSlug.lats => 'Lats',
    BodyPartSlug.lowerBack => 'Lower back',
    BodyPartSlug.abs => 'Abs',
    BodyPartSlug.abductors => 'Abductors',
    _ => name[0].toUpperCase() + name.substring(1),
  };
}

/// Converts upstream SVG slug strings into package enum values.
BodyPartSlug bodyPartSlugFromUpstream(String slug) => switch (slug) {
  'chest' => BodyPartSlug.chest,
  'abs' => BodyPartSlug.abs,
  'obliques' => BodyPartSlug.obliques,
  'biceps' => BodyPartSlug.biceps,
  'triceps' => BodyPartSlug.triceps,
  'forearm' => BodyPartSlug.forearm,
  'hands' => BodyPartSlug.hands,
  'deltoids' => BodyPartSlug.deltoids,
  'trapezius' => BodyPartSlug.trapezius,
  'upper-back' => BodyPartSlug.upperBack,
  'lats' => BodyPartSlug.lats,
  'lower-back' => BodyPartSlug.lowerBack,
  'gluteal' => BodyPartSlug.gluteal,
  'hamstring' => BodyPartSlug.hamstring,
  'quadriceps' => BodyPartSlug.quadriceps,
  'calves' => BodyPartSlug.calves,
  'adductors' => BodyPartSlug.adductors,
  'tibialis' => BodyPartSlug.tibialis,
  'neck' => BodyPartSlug.neck,
  'head' => BodyPartSlug.head,
  'feet' => BodyPartSlug.feet,
  'ankles' => BodyPartSlug.ankles,
  'knees' => BodyPartSlug.knees,
  'hair' => BodyPartSlug.hair,
  'abductors' => BodyPartSlug.abductors,
  _ => throw ArgumentError.value(slug, 'slug', 'Unknown body-part slug'),
};
