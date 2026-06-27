import 'body_highlight_data.dart';
import 'body_types.dart';
import 'hand_types.dart';

/// Deterministic adapter from exercise muscle labels to SVG body-part slugs.
///
/// The adapter intentionally uses an explicit alias table. Unknown labels are
/// returned in [MuscleMappingResult.unmapped] so product code and tests can add
/// missing taxonomy mappings deliberately rather than relying on fuzzy guesses.
class MuscleToBodyPartAdapter {
  /// Creates an adapter with optional additional explicit aliases.
  MuscleToBodyPartAdapter({
    Map<String, Set<BodyPartSlug>> aliases = const {},
    Map<String, HandPartSlug> handPartAliases = const {},
  }) : _aliases = Map.unmodifiable({
         ..._seedAliases,
         for (final entry in aliases.entries)
           _normalize(entry.key): Set.unmodifiable(entry.value),
       }),
       _handPartAliases = Map.unmodifiable({
         ..._seedHandPartAliases,
         for (final entry in handPartAliases.entries)
           _normalize(entry.key): entry.value,
       });

  final Map<String, Set<BodyPartSlug>> _aliases;
  final Map<String, HandPartSlug> _handPartAliases;

  /// Maps primary and secondary muscle labels into body-part slug sets.
  ///
  /// If a slug is present in both primary and secondary results, primary wins
  /// and the slug is removed from [MuscleMappingResult.secondary]. Hand child
  /// aliases still appear as their parent [BodyPartSlug.hands] in this coarse
  /// result; use [mapToHighlights] to retain exact palm/finger child data.
  MuscleMappingResult mapPrimarySecondary({
    required Iterable<String> primaryMuscles,
    required Iterable<String> secondaryMuscles,
  }) {
    final primary = <_BodyPartRef>{};
    final secondary = <_BodyPartRef>{};
    final unmapped = <String>{};

    void collect(Iterable<String> labels, Set<_BodyPartRef> target) {
      for (final raw in labels) {
        final label = raw.trim();
        if (label.isEmpty) {
          continue;
        }
        final refs = _refsFor(label);
        if (refs == null) {
          unmapped.add(label);
          continue;
        }
        target.addAll(refs);
      }
    }

    collect(primaryMuscles, primary);
    collect(secondaryMuscles, secondary);
    final primarySlugs = {for (final ref in primary) ref.slug};
    secondary.removeWhere((ref) => primarySlugs.contains(ref.slug));

    return MuscleMappingResult(
      primary: {for (final ref in primary) ref.slug},
      secondary: {for (final ref in secondary) ref.slug},
      unmapped: unmapped,
    );
  }

  /// Converts mapped primary/secondary labels to heatmap highlight records.
  ///
  /// Hand-specific labels such as `Thumb`, `Index Finger`, `Middle Finger`,
  /// `Ring Finger`, `Pinky`, and `Palm` emit `BodyPartSlug.hands` highlights
  /// with [BodyHighlightData.handPart] populated instead of collapsing to a
  /// single parent hand highlight.
  MuscleHighlightMapping mapToHighlights({
    required Iterable<String> primaryMuscles,
    required Iterable<String> secondaryMuscles,
    double primaryIntensity = 1,
    double secondaryIntensity = 0.45,
  }) {
    final primary = <_BodyPartRef>{};
    final secondary = <_BodyPartRef>{};
    final unmapped = <String>{};

    void collect(Iterable<String> labels, Set<_BodyPartRef> target) {
      for (final raw in labels) {
        final label = raw.trim();
        if (label.isEmpty) {
          continue;
        }
        final refs = _refsFor(label);
        if (refs == null) {
          unmapped.add(label);
          continue;
        }
        target.addAll(refs);
      }
    }

    collect(primaryMuscles, primary);
    collect(secondaryMuscles, secondary);
    final primarySlugs = {for (final ref in primary) ref.slug};
    secondary.removeWhere((ref) => primarySlugs.contains(ref.slug));

    return MuscleHighlightMapping(
      highlights: [
        for (final ref in primary)
          BodyHighlightData(
            slug: ref.slug,
            handPart: ref.handPart,
            intensity: primaryIntensity,
          ),
        for (final ref in secondary)
          BodyHighlightData(
            slug: ref.slug,
            handPart: ref.handPart,
            intensity: secondaryIntensity,
          ),
      ],
      result: MuscleMappingResult(
        primary: {for (final ref in primary) ref.slug},
        secondary: {for (final ref in secondary) ref.slug},
        unmapped: unmapped,
      ),
    );
  }

  Set<_BodyPartRef>? _refsFor(String label) {
    final normalized = _normalize(label);
    final slugs = _aliases[normalized];
    final handPart = _handPartAliases[normalized];
    if (slugs == null && handPart == null) {
      return null;
    }
    return {
      for (final slug in slugs ?? const <BodyPartSlug>{}) _BodyPartRef(slug),
      if (handPart != null) _BodyPartRef(BodyPartSlug.hands, handPart),
    };
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
    'Thumb': {BodyPartSlug.forearm},
    'Index': {},
    'Index Finger': {},
    'Middle': {},
    'Middle Finger': {},
    'Ring': {},
    'Ring Finger': {},
    'Little Finger': {},
    'Pinky': {},
    'Pinky Finger': {},
    'Small Finger': {},
    'Palm': {},
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

  static Map<String, HandPartSlug> get _seedHandPartAliases => {
    for (final entry in {
      'Thumb': HandPartSlug.thumb,
      'Index': HandPartSlug.indexFinger,
      'Index Finger': HandPartSlug.indexFinger,
      'Middle': HandPartSlug.middleFinger,
      'Middle Finger': HandPartSlug.middleFinger,
      'Ring': HandPartSlug.ringFinger,
      'Ring Finger': HandPartSlug.ringFinger,
      'Little Finger': HandPartSlug.littleFinger,
      'Pinky': HandPartSlug.littleFinger,
      'Pinky Finger': HandPartSlug.littleFinger,
      'Small Finger': HandPartSlug.littleFinger,
      'Palm': HandPartSlug.palm,
    }.entries)
      _normalize(entry.key): entry.value,
  };
}

class _BodyPartRef {
  const _BodyPartRef(this.slug, [this.handPart]);

  final BodyPartSlug slug;
  final HandPartSlug? handPart;

  @override
  bool operator ==(Object other) {
    return other is _BodyPartRef &&
        other.slug == slug &&
        other.handPart == handPart;
  }

  @override
  int get hashCode => Object.hash(slug, handPart);
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
