import 'body_types.dart';

/// Stable keys for the smallest muscle regions independently selectable by the
/// bundled SVG artwork.
///
/// These keys describe render geometry only. Exercise categories, primary and
/// secondary targeting, and other business groupings belong in caller code.
enum MuscleRegionKey {
  chest('chest', 'Chest', _frontOnly),
  abs('abs', 'Abs', _frontOnly),
  obliques('obliques', 'Obliques', _frontOnly),
  biceps('biceps', 'Biceps', _frontOnly),
  triceps('triceps', 'Triceps', _frontAndBack),
  forearm('forearm', 'Forearm', _frontAndBack),
  deltoids('deltoids', 'Deltoids', _frontAndBack),
  trapezius('trapezius', 'Trapezius', _frontAndBack),
  upperBack('upper-back', 'Upper back', _backOnly),
  lats('lats', 'Lats', _backOnly),
  lowerBack('lower-back', 'Lower back', _backOnly),
  gluteal('gluteal', 'Gluteal', _backOnly),
  hamstring('hamstring', 'Hamstring', _backOnly),
  quadriceps('quadriceps', 'Quadriceps', _frontOnly),
  calves('calves', 'Calves', _frontAndBack),
  adductors('adductors', 'Adductors', _frontAndBack),
  tibialis('tibialis', 'Tibialis', _frontOnly),
  neck('neck', 'Neck', _frontOnly),
  abductors('abductors', 'Abductors', _backOnly);

  const MuscleRegionKey(this.wireKey, this.label, this.views);

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
