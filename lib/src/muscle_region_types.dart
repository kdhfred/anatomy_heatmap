import 'body_types.dart';

/// Stable keys for the smallest muscle regions independently selectable by the
/// bundled SVG artwork.
///
/// These keys describe render geometry only. Exercise categories, primary and
/// secondary targeting, and other business groupings belong in caller code.
enum MuscleRegionKey {
  chest(BodyPartSlug.chest, 'chest', 'Chest', _frontOnly),
  abs(BodyPartSlug.abs, 'abs', 'Abs', _frontOnly),
  obliques(BodyPartSlug.obliques, 'obliques', 'Obliques', _frontOnly),
  biceps(BodyPartSlug.biceps, 'biceps', 'Biceps', _frontOnly),
  triceps(BodyPartSlug.triceps, 'triceps', 'Triceps', _frontAndBack),
  forearm(BodyPartSlug.forearm, 'forearm', 'Forearm', _frontAndBack),
  deltoids(BodyPartSlug.deltoids, 'deltoids', 'Deltoids', _frontAndBack),
  trapezius(BodyPartSlug.trapezius, 'trapezius', 'Trapezius', _frontAndBack),
  upperBack(BodyPartSlug.upperBack, 'upper-back', 'Upper back', _backOnly),
  lats(BodyPartSlug.lats, 'lats', 'Lats', _backOnly),
  lowerBack(BodyPartSlug.lowerBack, 'lower-back', 'Lower back', _backOnly),
  gluteal(BodyPartSlug.gluteal, 'gluteal', 'Gluteal', _backOnly),
  hamstring(BodyPartSlug.hamstring, 'hamstring', 'Hamstring', _backOnly),
  quadriceps(BodyPartSlug.quadriceps, 'quadriceps', 'Quadriceps', _frontOnly),
  calves(BodyPartSlug.calves, 'calves', 'Calves', _frontAndBack),
  adductors(BodyPartSlug.adductors, 'adductors', 'Adductors', _frontAndBack),
  tibialis(BodyPartSlug.tibialis, 'tibialis', 'Tibialis', _frontOnly),
  neck(BodyPartSlug.neck, 'neck', 'Neck', _frontOnly),
  abductors(BodyPartSlug.abductors, 'abductors', 'Abductors', _backOnly);

  const MuscleRegionKey(
    this.bodyPartSlug,
    this.wireKey,
    this.label,
    this.views,
  );

  /// Existing body-part slug that owns this region's SVG fragments.
  final BodyPartSlug bodyPartSlug;

  /// Stable serialized key. Do not persist [index] or the enum [name].
  final String wireKey;

  /// Human-readable English label.
  final String label;

  /// Views with bundled geometry for this region, for both supported genders.
  final Set<BodyView> views;

  /// Whether the bundled assets can render this region in [view].
  bool isRenderableIn(BodyView view) => views.contains(view);
}

const _frontOnly = {BodyView.front};
const _backOnly = {BodyView.back};
const _frontAndBack = {BodyView.front, BodyView.back};

/// Parses a stable muscle-region [wireKey].
MuscleRegionKey muscleRegionKeyFromWire(String wireKey) {
  final result = tryMuscleRegionKeyFromWire(wireKey);
  if (result == null) {
    throw ArgumentError.value(wireKey, 'wireKey', 'Unknown muscle-region key');
  }
  return result;
}

/// Parses [wireKey], returning null when it is not part of the public contract.
MuscleRegionKey? tryMuscleRegionKeyFromWire(String wireKey) {
  for (final region in MuscleRegionKey.values) {
    if (region.wireKey == wireKey) {
      return region;
    }
  }
  return null;
}

/// Muscle-region helpers for the backwards-compatible body-part taxonomy.
extension BodyPartMuscleRegionX on BodyPartSlug {
  /// Exact muscle region backed by this slug, or null for non-muscle parts.
  MuscleRegionKey? get muscleRegionKey {
    for (final region in MuscleRegionKey.values) {
      if (region.bodyPartSlug == this) {
        return region;
      }
    }
    return null;
  }
}
