import 'body_highlight_data.dart';
import 'body_types.dart';

/// Deterministic adapter from exercise muscle labels to SVG body-part slugs.
///
/// The adapter intentionally uses an explicit alias table. Unknown labels are
/// returned in [MuscleMappingResult.unmapped] so product code and tests can add
/// missing taxonomy mappings deliberately rather than relying on fuzzy guesses.
class MuscleToBodyPartAdapter {
  /// Creates an adapter with optional additional explicit aliases.
  MuscleToBodyPartAdapter({Map<String, Set<BodyPartSlug>> aliases = const {}})
    : _aliases = Map.unmodifiable({
        ..._seedAliases,
        for (final entry in aliases.entries)
          _normalize(entry.key): Set.unmodifiable(entry.value),
      });

  final Map<String, Set<BodyPartSlug>> _aliases;

  /// Maps primary and secondary muscle labels into body-part slug sets.
  ///
  /// If a slug is present in both primary and secondary results, primary wins
  /// and the slug is removed from [MuscleMappingResult.secondary].
  MuscleMappingResult mapPrimarySecondary({
    required Iterable<String> primaryMuscles,
    required Iterable<String> secondaryMuscles,
  }) {
    final primary = <BodyPartSlug>{};
    final secondary = <BodyPartSlug>{};
    final unmapped = <String>{};

    void collect(Iterable<String> labels, Set<BodyPartSlug> target) {
      for (final raw in labels) {
        final label = raw.trim();
        if (label.isEmpty) {
          continue;
        }
        final slugs = _aliases[_normalize(label)];
        if (slugs == null) {
          unmapped.add(label);
          continue;
        }
        target.addAll(slugs);
      }
    }

    collect(primaryMuscles, primary);
    collect(secondaryMuscles, secondary);
    secondary.removeAll(primary);

    return MuscleMappingResult(
      primary: primary,
      secondary: secondary,
      unmapped: unmapped,
    );
  }

  /// Converts mapped primary/secondary labels to heatmap highlight records.
  MuscleHighlightMapping mapToHighlights({
    required Iterable<String> primaryMuscles,
    required Iterable<String> secondaryMuscles,
    double primaryIntensity = 1,
    double secondaryIntensity = 0.45,
  }) {
    final result = mapPrimarySecondary(
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
    );

    return MuscleHighlightMapping(
      highlights: [
        for (final slug in result.primary)
          BodyHighlightData(slug: slug, intensity: primaryIntensity),
        for (final slug in result.secondary)
          BodyHighlightData(slug: slug, intensity: secondaryIntensity),
      ],
      result: result,
    );
  }

  static String _normalize(String label) => label
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-/]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Map<String, Set<BodyPartSlug>> get _seedAliases => _aliasesFrom({
    'Pectoralis': {BodyPartSlug.chest},
    'Pecs': {BodyPartSlug.chest},
    'Chest': {BodyPartSlug.chest},
    'Latissimus': {BodyPartSlug.upperBack},
    'Lats': {BodyPartSlug.upperBack},
    'Rhomboids': {BodyPartSlug.upperBack},
    'Upper Back': {BodyPartSlug.upperBack},
    'Teres': {BodyPartSlug.upperBack},
    'Trapezius': {BodyPartSlug.trapezius},
    'Traps': {BodyPartSlug.trapezius},
    'Scapular stabilizers': {BodyPartSlug.trapezius},
    'Scapular stabilisers': {BodyPartSlug.trapezius},
    'Erector Spinae': {BodyPartSlug.lowerBack},
    'Lower Back': {BodyPartSlug.lowerBack},
    'Biceps': {BodyPartSlug.biceps},
    'Brachialis': {BodyPartSlug.biceps},
    'Brachioradialis': {BodyPartSlug.forearm},
    'Triceps': {BodyPartSlug.triceps},
    'Deltoid': {BodyPartSlug.deltoids},
    'Deltoids': {BodyPartSlug.deltoids},
    'Shoulder': {BodyPartSlug.deltoids},
    'Shoulders': {BodyPartSlug.deltoids},
    'Rotator Cuff': {BodyPartSlug.deltoids},
    'Infraspinatus': {BodyPartSlug.deltoids},
    'Rear Delt': {BodyPartSlug.deltoids},
    'Forearm': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Wrist': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Finger Flexors': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Finger Extensors': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Grip': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Thumb': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Palm': {BodyPartSlug.forearm, BodyPartSlug.hands},
    'Quadriceps': {BodyPartSlug.quadriceps},
    'Quads': {BodyPartSlug.quadriceps},
    'Rectus Femoris': {BodyPartSlug.quadriceps},
    'Vastus': {BodyPartSlug.quadriceps},
    'Hamstrings': {BodyPartSlug.hamstring},
    'Hamstring': {BodyPartSlug.hamstring},
    'Biceps Femoris': {BodyPartSlug.hamstring},
    'Semitendinosus': {BodyPartSlug.hamstring},
    'Semimembranosus': {BodyPartSlug.hamstring},
    'Glutes': {BodyPartSlug.gluteal},
    'Gluteus': {BodyPartSlug.gluteal},
    'Calves': {BodyPartSlug.calves},
    'Calf': {BodyPartSlug.calves},
    'Gastrocnemius': {BodyPartSlug.calves},
    'Soleus': {BodyPartSlug.calves},
    'Abs': {BodyPartSlug.abs},
    'Core': {BodyPartSlug.abs},
    'Rectus Abdominis': {BodyPartSlug.abs},
    'Waist': {BodyPartSlug.abs},
    'Obliques': {BodyPartSlug.obliques},
    'Adductors': {BodyPartSlug.adductors},
    'Adductor': {BodyPartSlug.adductors},
    'Tibialis': {BodyPartSlug.tibialis},
  });

  static Map<String, Set<BodyPartSlug>> _aliasesFrom(
    Map<String, Set<BodyPartSlug>> aliases,
  ) {
    return Map.unmodifiable({
      for (final entry in aliases.entries)
        _normalize(entry.key): Set.unmodifiable(entry.value),
    });
  }
}

/// Result of deterministic muscle-label mapping.
class MuscleMappingResult {
  /// Creates a mapping result.
  MuscleMappingResult({
    required Set<BodyPartSlug> primary,
    required Set<BodyPartSlug> secondary,
    required Set<String> unmapped,
  }) : primary = Set.unmodifiable(primary),
       secondary = Set.unmodifiable(secondary),
       unmapped = Set.unmodifiable(unmapped);

  /// Slugs mapped from target/primary muscles.
  final Set<BodyPartSlug> primary;

  /// Slugs mapped from synergist/secondary muscles, excluding primary wins.
  final Set<BodyPartSlug> secondary;

  /// Original input labels that were not found in the explicit alias table.
  final Set<String> unmapped;

  /// Whether all provided labels were mapped.
  bool get isFullyMapped => unmapped.isEmpty;
}

/// Convenience bundle containing heatmap highlights plus the raw mapping result.
class MuscleHighlightMapping {
  /// Creates a highlight mapping bundle.
  const MuscleHighlightMapping({
    required this.highlights,
    required this.result,
  });

  /// Primary and secondary heatmap highlight rows.
  final List<BodyHighlightData> highlights;

  /// Underlying deterministic mapping result.
  final MuscleMappingResult result;
}
