import 'muscle_region_types.dart';

/// Renderer-only grouping for the bundled SVG fragments.
///
/// This file is deliberately not exported by the package barrel. Callers work
/// with [MuscleRegionKey] and `HandPartSlug`; decorative SVG groups remain an
/// implementation detail.
enum BodyRenderRegion {
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

extension BodyRenderRegionX on BodyRenderRegion {
  MuscleRegionKey? get muscleRegion => switch (this) {
    BodyRenderRegion.chest => MuscleRegionKey.chest,
    BodyRenderRegion.abs => MuscleRegionKey.abs,
    BodyRenderRegion.obliques => MuscleRegionKey.obliques,
    BodyRenderRegion.biceps => MuscleRegionKey.biceps,
    BodyRenderRegion.triceps => MuscleRegionKey.triceps,
    BodyRenderRegion.forearm => MuscleRegionKey.forearm,
    BodyRenderRegion.deltoids => MuscleRegionKey.deltoids,
    BodyRenderRegion.trapezius => MuscleRegionKey.trapezius,
    BodyRenderRegion.upperBack => MuscleRegionKey.upperBack,
    BodyRenderRegion.lats => MuscleRegionKey.lats,
    BodyRenderRegion.lowerBack => MuscleRegionKey.lowerBack,
    BodyRenderRegion.gluteal => MuscleRegionKey.gluteal,
    BodyRenderRegion.hamstring => MuscleRegionKey.hamstring,
    BodyRenderRegion.quadriceps => MuscleRegionKey.quadriceps,
    BodyRenderRegion.calves => MuscleRegionKey.calves,
    BodyRenderRegion.adductors => MuscleRegionKey.adductors,
    BodyRenderRegion.tibialis => MuscleRegionKey.tibialis,
    BodyRenderRegion.neck => MuscleRegionKey.neck,
    BodyRenderRegion.abductors => MuscleRegionKey.abductors,
    BodyRenderRegion.hands ||
    BodyRenderRegion.head ||
    BodyRenderRegion.feet ||
    BodyRenderRegion.ankles ||
    BodyRenderRegion.knees ||
    BodyRenderRegion.hair => null,
  };
}

BodyRenderRegion bodyRenderRegionFor(MuscleRegionKey region) =>
    switch (region) {
      MuscleRegionKey.chest => BodyRenderRegion.chest,
      MuscleRegionKey.abs => BodyRenderRegion.abs,
      MuscleRegionKey.obliques => BodyRenderRegion.obliques,
      MuscleRegionKey.biceps => BodyRenderRegion.biceps,
      MuscleRegionKey.triceps => BodyRenderRegion.triceps,
      MuscleRegionKey.forearm => BodyRenderRegion.forearm,
      MuscleRegionKey.deltoids => BodyRenderRegion.deltoids,
      MuscleRegionKey.trapezius => BodyRenderRegion.trapezius,
      MuscleRegionKey.upperBack => BodyRenderRegion.upperBack,
      MuscleRegionKey.lats => BodyRenderRegion.lats,
      MuscleRegionKey.lowerBack => BodyRenderRegion.lowerBack,
      MuscleRegionKey.gluteal => BodyRenderRegion.gluteal,
      MuscleRegionKey.hamstring => BodyRenderRegion.hamstring,
      MuscleRegionKey.quadriceps => BodyRenderRegion.quadriceps,
      MuscleRegionKey.calves => BodyRenderRegion.calves,
      MuscleRegionKey.adductors => BodyRenderRegion.adductors,
      MuscleRegionKey.tibialis => BodyRenderRegion.tibialis,
      MuscleRegionKey.neck => BodyRenderRegion.neck,
      MuscleRegionKey.abductors => BodyRenderRegion.abductors,
    };
