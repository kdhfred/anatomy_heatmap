import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:anatomy_heatmap/src/data/body_svg_asset.dart';
import 'package:anatomy_heatmap/src/data/body_svg_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  group('BodyPartSlug', () {
    test('exposes lats as a stable public slug', () {
      expect(BodyPartSlug.lats.upstreamSlug, 'lats');
      expect(BodyPartSlug.lats.label, 'Lats');
      expect(bodyPartSlugFromUpstream('lats'), BodyPartSlug.lats);
    });
  });

  group('MuscleToBodyPartAdapter', () {
    test('maps seeded aliases correctly', () {
      final adapter = MuscleToBodyPartAdapter();

      final result = adapter.mapPrimarySecondary(
        primaryMuscles: ['Pectoralis', 'Lats', 'Finger Flexors'],
        secondaryMuscles: ['Rotator Cuff', 'Soleus', 'Obliques'],
      );

      expect(result.primary, contains(BodyPartSlug.chest));
      expect(result.primary, contains(BodyPartSlug.lats));
      expect(result.primary, contains(BodyPartSlug.forearm));
      expect(result.primary, contains(BodyPartSlug.hands));
      expect(result.secondary, contains(BodyPartSlug.deltoids));
      expect(result.secondary, contains(BodyPartSlug.calves));
      expect(result.secondary, contains(BodyPartSlug.obliques));
      expect(result.unmapped, isEmpty);
    });

    test('maps back aliases to split taxonomy', () {
      final adapter = MuscleToBodyPartAdapter();

      final lats = adapter.mapPrimarySecondary(
        primaryMuscles: ['Latissimus', 'Latissimus Dorsi', 'Lats'],
        secondaryMuscles: const [],
      );
      expect(lats.primary, {BodyPartSlug.lats});

      final traps = adapter.mapPrimarySecondary(
        primaryMuscles: ['Trapezius', 'Traps'],
        secondaryMuscles: const [],
      );
      expect(traps.primary, {BodyPartSlug.trapezius});

      final scapularStabilizers = adapter.mapPrimarySecondary(
        primaryMuscles: [
          'Scapular stabilizers',
          'Scapular stabilisers',
          'Rhomboids',
          'Upper Back',
          'Teres',
        ],
        secondaryMuscles: const [],
      );
      expect(scapularStabilizers.primary, {BodyPartSlug.upperBack});

      final back = adapter.mapPrimarySecondary(
        primaryMuscles: ['Rhomboids', 'Erector Spinae'],
        secondaryMuscles: const [],
      );
      expect(back.primary, {BodyPartSlug.upperBack, BodyPartSlug.lowerBack});
    });

    test('primary wins over secondary on overlap', () {
      final result = MuscleToBodyPartAdapter().mapPrimarySecondary(
        primaryMuscles: ['Chest'],
        secondaryMuscles: ['Pecs', 'Triceps'],
      );

      expect(result.primary, contains(BodyPartSlug.chest));
      expect(result.secondary, isNot(contains(BodyPartSlug.chest)));
      expect(result.secondary, contains(BodyPartSlug.triceps));
    });

    test('unmapped labels are returned instead of swallowed', () {
      final result = MuscleToBodyPartAdapter().mapPrimarySecondary(
        primaryMuscles: ['Mystery Muscle'],
        secondaryMuscles: ['Unknown Stabilizer'],
      );

      expect(result.unmapped, {'Mystery Muscle', 'Unknown Stabilizer'});
    });

    test('keeps specific hand labels as hand child highlights', () {
      final mapped = MuscleToBodyPartAdapter().mapToHighlights(
        primaryMuscles: ['Thumb', 'Index Finger'],
        secondaryMuscles: ['Pinky'],
      );

      expect(mapped.result.primary, contains(BodyPartSlug.hands));
      expect(mapped.result.primary, contains(BodyPartSlug.forearm));
      expect(mapped.result.secondary, isNot(contains(BodyPartSlug.hands)));
      expect(
        mapped.highlights,
        contains(
          isA<BodyHighlightData>()
              .having((data) => data.slug, 'slug', BodyPartSlug.hands)
              .having((data) => data.handPart, 'handPart', HandPartSlug.thumb)
              .having((data) => data.intensity, 'intensity', 1),
        ),
      );
      expect(
        mapped.highlights,
        contains(
          isA<BodyHighlightData>()
              .having((data) => data.slug, 'slug', BodyPartSlug.hands)
              .having(
                (data) => data.handPart,
                'handPart',
                HandPartSlug.indexFinger,
              ),
        ),
      );
      expect(
        mapped.highlights.where(
          (data) => data.slug == BodyPartSlug.hands && data.handPart == null,
        ),
        isEmpty,
      );
    });

    test('can collapse specific hand labels to parent hands highlights', () {
      final mapped = MuscleToBodyPartAdapter().mapToHighlights(
        primaryMuscles: ['Thumb', 'Index Finger'],
        secondaryMuscles: ['Pinky'],
        handDetailLevel: HandDetailLevel.handsOnly,
      );

      expect(mapped.result.primary, contains(BodyPartSlug.hands));
      expect(mapped.result.primary, contains(BodyPartSlug.forearm));
      expect(mapped.result.secondary, isNot(contains(BodyPartSlug.hands)));
      expect(
        mapped.highlights.where((data) => data.slug == BodyPartSlug.hands),
        contains(
          isA<BodyHighlightData>()
              .having((data) => data.handPart, 'handPart', isNull)
              .having((data) => data.intensity, 'intensity', 1),
        ),
      );
      expect(
        mapped.highlights.where(
          (data) => data.slug == BodyPartSlug.hands && data.handPart != null,
        ),
        isEmpty,
      );
    });
  });

  group('heatmap intensity', () {
    test('clamps and normalizes safely', () {
      expect(BodyHighlightData.normalizeIntensity(-1), 0);
      expect(BodyHighlightData.normalizeIntensity(0.6), 0.6);
      expect(BodyHighlightData.normalizeIntensity(2), 1);
      expect(BodyHighlightData.normalizeIntensity(double.nan), 0);

      const scheme = BodyHeatmapColorScheme.redLoad;
      expect(scheme.colorForIntensity(-1), scheme.inactiveFill);
      expect(scheme.colorForIntensity(2).a, closeTo(0.92, 0.01));
    });

    test('uses dark navy for inactive hair paths', () {
      const scheme = BodyHeatmapColorScheme.redLoad;

      expect(scheme.fillFor(null, slug: BodyPartSlug.hair), scheme.hairFill);
      expect(scheme.hairFill, const Color(0xFF0B1220));
      expect(
        scheme.fillFor(null, slug: BodyPartSlug.head),
        scheme.inactiveFill,
      );
      expect(
        scheme.fillFor(
          const BodyHighlightData(slug: BodyPartSlug.hair, intensity: 0.5),
          slug: BodyPartSlug.hair,
        ),
        isNot(scheme.hairFill),
      );
    });

    test('muscle group preset uses region and hand-part colors', () {
      const scheme = BodyHeatmapColorScheme.muscleGroups;

      final chest = scheme.fillFor(
        const BodyHighlightData(slug: BodyPartSlug.chest, intensity: 1),
        slug: BodyPartSlug.chest,
      );
      final quads = scheme.fillFor(
        const BodyHighlightData(slug: BodyPartSlug.quadriceps, intensity: 1),
        slug: BodyPartSlug.quadriceps,
      );
      final index = scheme.fillFor(
        const BodyHighlightData(
          slug: BodyPartSlug.hands,
          handPart: HandPartSlug.indexFinger,
          intensity: 1,
        ),
        slug: BodyPartSlug.hands,
      );
      final palm = scheme.fillForHand(
        const HandHighlightData(slug: HandPartSlug.palm, intensity: 1),
      );

      expect(chest, isNot(quads));
      expect(index, isNot(palm));
      expect(chest.a, closeTo(0.92, 0.01));
      expect(quads.a, closeTo(0.92, 0.01));
      expect(index.a, closeTo(0.92, 0.01));
      expect(palm.a, closeTo(0.92, 0.01));
    });

    test('muscle group preset has light and dark brightness variants', () {
      expect(
        BodyHeatmapColorScheme.fromPreset(
          BodyHeatmapColorPreset.redLoad,
          brightness: Brightness.light,
        ),
        same(BodyHeatmapColorScheme.redLoad),
      );
      expect(
        BodyHeatmapColorScheme.fromPreset(
          BodyHeatmapColorPreset.redLoad,
          brightness: Brightness.dark,
        ),
        same(BodyHeatmapColorScheme.redLoadDark),
      );
      expect(
        BodyHeatmapColorScheme.redLoadForBrightness(Brightness.light),
        same(BodyHeatmapColorScheme.redLoad),
      );
      expect(
        BodyHeatmapColorScheme.redLoadForBrightness(Brightness.dark),
        same(BodyHeatmapColorScheme.redLoadDark),
      );
      expect(
        BodyHeatmapColorScheme.fromPreset(
          BodyHeatmapColorPreset.muscleGroups,
          brightness: Brightness.light,
        ),
        same(BodyHeatmapColorScheme.muscleGroups),
      );
      expect(
        BodyHeatmapColorScheme.fromPreset(
          BodyHeatmapColorPreset.muscleGroups,
          brightness: Brightness.dark,
        ),
        same(BodyHeatmapColorScheme.muscleGroupsDark),
      );
      expect(
        BodyHeatmapColorScheme.muscleGroupsForBrightness(Brightness.light),
        same(BodyHeatmapColorScheme.muscleGroups),
      );
      expect(
        BodyHeatmapColorScheme.muscleGroupsForBrightness(Brightness.dark),
        same(BodyHeatmapColorScheme.muscleGroupsDark),
      );
      expect(
        BodyHeatmapColorScheme.muscleGroupsDark.bodyPartHeatColors,
        same(BodyHeatmapColorScheme.muscleGroups.bodyPartHeatColors),
      );
      expect(
        BodyHeatmapColorScheme.muscleGroupsDark.handPartHeatColors,
        same(BodyHeatmapColorScheme.muscleGroups.handPartHeatColors),
      );
      expect(
        BodyHeatmapColorScheme.muscleGroupsDark.inactiveFill,
        isNot(BodyHeatmapColorScheme.muscleGroups.inactiveFill),
      );
    });

    test('red load preset can be seeded from a custom hue', () {
      const blueSeed = Color(0xFF2563EB);

      expect(
        BodyHeatmapColorScheme.fromPreset(
          BodyHeatmapColorPreset.redLoad,
          redLoadSeedColor: BodyHeatmapColorScheme.defaultRedLoadSeedColor,
        ),
        same(BodyHeatmapColorScheme.redLoad),
      );

      final seededLight = BodyHeatmapColorScheme.fromPreset(
        BodyHeatmapColorPreset.redLoad,
        redLoadSeedColor: blueSeed,
      );
      expect(seededLight.heatColor, blueSeed);
      expect(
        seededLight.inactiveFill,
        BodyHeatmapColorScheme.redLoad.inactiveFill,
      );
      expect(
        seededLight.borderColor,
        BodyHeatmapColorScheme.redLoad.borderColor,
      );
      expect(seededLight, isNot(same(BodyHeatmapColorScheme.redLoad)));

      final seededDark = BodyHeatmapColorScheme.redLoadFromSeed(
        blueSeed,
        brightness: Brightness.dark,
      );
      expect(seededDark.heatColor, blueSeed);
      expect(
        seededDark.inactiveFill,
        BodyHeatmapColorScheme.redLoadDark.inactiveFill,
      );
      expect(
        seededDark.borderColor,
        BodyHeatmapColorScheme.redLoadDark.borderColor,
      );
    });

    test(
      'preset color settings can be injected without replacing defaults',
      () {
        const customChest = Color(0xFF6D28D9);
        const customIndex = Color(0xFF14B8A6);

        final scheme =
            BodyHeatmapColorScheme.fromPreset(
              BodyHeatmapColorPreset.muscleGroups,
              brightness: Brightness.dark,
            ).withOverrides(
              inactiveFill: const Color(0xFF101010),
              bodyPartHeatColors: const {BodyPartSlug.chest: customChest},
              handPartHeatColors: const {HandPartSlug.indexFinger: customIndex},
            );

        expect(scheme.inactiveFill, const Color(0xFF101010));
        expect(scheme.bodyPartHeatColors[BodyPartSlug.chest], customChest);
        expect(
          scheme.bodyPartHeatColors[BodyPartSlug.quadriceps],
          BodyHeatmapColorScheme
              .muscleGroupsDark
              .bodyPartHeatColors[BodyPartSlug.quadriceps],
        );
        expect(
          scheme.handPartHeatColors[HandPartSlug.indexFinger],
          customIndex,
        );
        expect(
          scheme.handPartHeatColors[HandPartSlug.palm],
          BodyHeatmapColorScheme
              .muscleGroupsDark
              .handPartHeatColors[HandPartSlug.palm],
        );

        final replaced = scheme.copyWith(bodyPartHeatColors: const {});
        expect(replaced.bodyPartHeatColors, isEmpty);
        expect(replaced.handPartHeatColors, isNotEmpty);
      },
    );
  });

  group('hand tree taxonomy', () {
    test('exposes rendered hand children under hands', () {
      expect(
        BodyPartSlug.hands.handChildren,
        containsAll(const [
          HandPartSlug.palm,
          HandPartSlug.thumb,
          HandPartSlug.indexFinger,
          HandPartSlug.middleFinger,
          HandPartSlug.ringFinger,
          HandPartSlug.littleFinger,
        ]),
      );
      expect(BodyPartSlug.forearm.handChildren, isEmpty);
    });
  });

  group('SVG assets', () {
    test('all ported path data parses', () {
      for (final asset in bodySvgAssets) {
        if (asset.outlinePath case final outline?) {
          expect(parseSvgPathData(outline), isA<ui.Path>());
        }
        for (final part in asset.parts) {
          for (final pathData in [
            ...part.common,
            ...part.left,
            ...part.right,
          ]) {
            expect(parseSvgPathData(pathData), isA<ui.Path>());
          }
        }
      }
    });

    test('back taxonomy exposes traps and keeps lats split out', () {
      for (final gender in BodyGender.values) {
        final front = bodySvgAssetFor(gender, BodyView.front);
        final back = bodySvgAssetFor(gender, BodyView.back);

        expect(
          front.parts.map((part) => part.slug),
          containsAll([BodyPartSlug.neck, BodyPartSlug.trapezius]),
        );
        expect(
          back.parts.map((part) => part.slug),
          contains(BodyPartSlug.trapezius),
        );
        expect(
          back.parts.map((part) => part.slug),
          isNot(contains(BodyPartSlug.neck)),
        );

        final lats = back.parts.singleWhere(
          (part) => part.slug == BodyPartSlug.lats,
        );
        expect(lats.common, isEmpty);
        expect(lats.left, hasLength(1));
        expect(lats.right, hasLength(1));

        final trapezius = back.parts.singleWhere(
          (part) => part.slug == BodyPartSlug.trapezius,
        );
        expect(trapezius.common, isEmpty);
        expect(trapezius.left, hasLength(2));
        expect(trapezius.right, hasLength(2));

        final upperBack = back.parts.singleWhere(
          (part) => part.slug == BodyPartSlug.upperBack,
        );
        expect(upperBack.common, isEmpty);
        expect(upperBack.left, hasLength(gender == BodyGender.male ? 2 : 1));
        expect(upperBack.right, hasLength(gender == BodyGender.male ? 2 : 1));

        final lowerBack = back.parts.singleWhere(
          (part) => part.slug == BodyPartSlug.lowerBack,
        );
        expect(lowerBack.common, isEmpty);
        expect(lowerBack.left, hasLength(2));
        expect(lowerBack.right, hasLength(2));
      }
    });
  });

  testWidgets(
    'back renderer resolves upperBack as scapular stabilizers plus trapezius',
    (tester) async {
      final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
      final upperBack = asset.parts.singleWhere(
        (part) => part.slug == BodyPartSlug.upperBack,
      );
      final trapezius = asset.parts.singleWhere(
        (part) => part.slug == BodyPartSlug.trapezius,
      );

      final taps = await _tapBackHeatmap(
        tester,
        highlights: const [
          BodyHighlightData(slug: BodyPartSlug.upperBack, intensity: 1),
        ],
        svgPoints: [
          _pathInteriorPoint(upperBack.left.first),
          _pathInteriorPoint(trapezius.left.first),
          _pathInteriorPoint(trapezius.left.last),
        ],
      );

      expect(taps, hasLength(3));
      expect(taps[0].slug, BodyPartSlug.upperBack);
      expect(taps[0].highlight?.slug, BodyPartSlug.upperBack);
      expect(taps[1].slug, BodyPartSlug.trapezius);
      expect(taps[1].highlight?.slug, BodyPartSlug.upperBack);
      expect(taps[2].slug, BodyPartSlug.trapezius);
      expect(taps[2].highlight?.slug, BodyPartSlug.upperBack);
    },
  );

  testWidgets(
    'back trapezius highlight takes priority over compound upperBack',
    (tester) async {
      final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
      final upperBack = asset.parts.singleWhere(
        (part) => part.slug == BodyPartSlug.upperBack,
      );
      final trapezius = asset.parts.singleWhere(
        (part) => part.slug == BodyPartSlug.trapezius,
      );

      const upperBackColor = Color(0xFF00A060);
      const trapeziusColor = Color(0xFF7E22CE);
      final taps = await _tapBackHeatmap(
        tester,
        highlights: const [
          BodyHighlightData(
            slug: BodyPartSlug.upperBack,
            intensity: 1,
            color: upperBackColor,
          ),
          BodyHighlightData(
            slug: BodyPartSlug.trapezius,
            intensity: 1,
            color: trapeziusColor,
          ),
        ],
        svgPoints: [
          _pathInteriorPoint(upperBack.left.first),
          _pathInteriorPoint(trapezius.left.last),
        ],
      );

      expect(taps, hasLength(2));
      expect(taps[0].slug, BodyPartSlug.upperBack);
      expect(taps[0].highlight?.slug, BodyPartSlug.upperBack);
      expect(taps[0].highlight?.color, upperBackColor);
      expect(taps[1].slug, BodyPartSlug.trapezius);
      expect(taps[1].highlight?.slug, BodyPartSlug.trapezius);
      expect(taps[1].highlight?.color, trapeziusColor);
    },
  );

  testWidgets('widget smoke test renders front/back with a highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 320,
          child: AnatomyHeatmap(
            gender: BodyGender.male,
            views: [BodyView.front, BodyView.back],
            highlights: [
              BodyHighlightData(slug: BodyPartSlug.chest, intensity: 0.8),
              BodyHighlightData(slug: BodyPartSlug.lats, intensity: 0.6),
              BodyHighlightData(slug: BodyPartSlug.upperBack, intensity: 0.45),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap callback reports left and right body sides', (tester) async {
    final taps = <BodyPartTap>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 400,
            child: AnatomyHeatmap(
              gender: BodyGender.male,
              views: const [BodyView.front],
              highlights: const [
                BodyHighlightData(
                  slug: BodyPartSlug.chest,
                  side: BodySide.left,
                  intensity: 0.8,
                ),
              ],
              onPartTap: taps.add,
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(CustomPaint).first);

    await tester.tapAt(topLeft + const Offset(86, 112));
    await tester.pump();
    await tester.tapAt(topLeft + const Offset(116, 112));
    await tester.pump();

    expect(taps.map((tap) => tap.slug), everyElement(BodyPartSlug.chest));
    expect(
      taps.map((tap) => tap.side),
      containsAll([BodySide.left, BodySide.right]),
    );
    expect(taps.first.highlight?.side, BodySide.left);
    expect(taps.last.highlight, isNull);
  });

  testWidgets('female front/back smoke test renders', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 320,
          child: AnatomyHeatmap(
            gender: BodyGender.female,
            views: [BodyView.front, BodyView.back],
            highlights: [
              BodyHighlightData(slug: BodyPartSlug.chest, intensity: 0.8),
              BodyHighlightData(slug: BodyPartSlug.gluteal, intensity: 0.45),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('segmented hand heatmap reports palm and each finger', (
    tester,
  ) async {
    final taps = <HandPartTap>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 240,
            height: 260,
            child: HandPartsHeatmap(
              gender: BodyGender.male,
              views: const [BodyView.front],
              sides: const [BodySide.left],
              highlights: const [
                HandHighlightData(slug: HandPartSlug.palm, intensity: 0.2),
                HandHighlightData(slug: HandPartSlug.thumb, intensity: 1),
                HandHighlightData(
                  slug: HandPartSlug.indexFinger,
                  intensity: 0.9,
                ),
                HandHighlightData(
                  slug: HandPartSlug.middleFinger,
                  intensity: 0.8,
                ),
                HandHighlightData(
                  slug: HandPartSlug.ringFinger,
                  intensity: 0.7,
                ),
                HandHighlightData(
                  slug: HandPartSlug.littleFinger,
                  intensity: 0.6,
                ),
              ],
              onPartTap: taps.add,
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.byType(CustomPaint).first;
    final topLeft = tester.getTopLeft(paintFinder);
    final size = tester.getSize(paintFinder);
    final hand = bodySvgAssetFor(
      BodyGender.male,
      BodyView.front,
    ).parts.firstWhere((part) => part.slug == BodyPartSlug.hands);
    final pathsBySlug = <HandPartSlug, String>{
      HandPartSlug.palm: hand.left[0],
      HandPartSlug.thumb: hand.left[1],
      HandPartSlug.indexFinger: hand.left[2],
      HandPartSlug.middleFinger: hand.left[3],
      HandPartSlug.ringFinger: hand.left[5],
      HandPartSlug.littleFinger: hand.left[4],
    };
    final pathBounds = [
      for (final pathData in hand.left) parseSvgPathData(pathData).getBounds(),
    ];
    var viewBox = pathBounds.first;
    for (final bounds in pathBounds.skip(1)) {
      viewBox = viewBox.expandToInclude(bounds);
    }
    final padding = math.max(viewBox.width, viewBox.height) * 0.08;
    viewBox = viewBox.inflate(padding);

    Offset toGlobal(ui.Offset svgPoint) {
      final scale =
          (size.width / viewBox.width) < (size.height / viewBox.height)
          ? size.width / viewBox.width
          : size.height / viewBox.height;
      final dx = (size.width - viewBox.width * scale) / 2;
      final dy = (size.height - viewBox.height * scale) / 2;
      return topLeft +
          Offset(
            dx + (svgPoint.dx - viewBox.left) * scale,
            dy + (svgPoint.dy - viewBox.top) * scale,
          );
    }

    for (final entry in pathsBySlug.entries) {
      final center = parseSvgPathData(entry.value).getBounds().center;
      await tester.tapAt(toGlobal(center));
      await tester.pump();

      expect(taps.last.slug, entry.key);
      expect(taps.last.highlight?.slug, entry.key);
    }
  });

  testWidgets('full anatomy heatmap reports exact hand child segments', (
    tester,
  ) async {
    final taps = <BodyPartTap>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 400,
            child: AnatomyHeatmap(
              gender: BodyGender.male,
              views: const [BodyView.front],
              highlights: const [
                BodyHighlightData(slug: BodyPartSlug.hands, intensity: 1),
                BodyHighlightData(
                  slug: BodyPartSlug.hands,
                  handPart: HandPartSlug.indexFinger,
                  intensity: 0,
                ),
              ],
              onPartTap: taps.add,
            ),
          ),
        ),
      ),
    );

    final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
    final hand = asset.parts.firstWhere(
      (part) => part.slug == BodyPartSlug.hands,
    );
    final indexFingerCenter = parseSvgPathData(hand.left[2]).getBounds().center;
    final paintFinder = find.byType(CustomPaint).first;
    final topLeft = tester.getTopLeft(paintFinder);
    final size = tester.getSize(paintFinder);

    Offset toGlobal(ui.Offset svgPoint) {
      final viewBox = asset.viewBox;
      final scale =
          (size.width / viewBox.width) < (size.height / viewBox.height)
          ? size.width / viewBox.width
          : size.height / viewBox.height;
      final dx = (size.width - viewBox.width * scale) / 2;
      final dy = (size.height - viewBox.height * scale) / 2;
      return topLeft +
          Offset(
            dx + (svgPoint.dx - viewBox.left) * scale,
            dy + (svgPoint.dy - viewBox.top) * scale,
          );
    }

    await tester.tapAt(toGlobal(indexFingerCenter));
    await tester.pump();

    expect(taps.single.slug, BodyPartSlug.hands);
    expect(taps.single.handPart, HandPartSlug.indexFinger);
    expect(taps.single.highlight?.handPart, HandPartSlug.indexFinger);
    expect(taps.single.highlight?.normalizedIntensity, 0);
  });

  testWidgets(
    'full anatomy heatmap lets parent hands zero control collapsed hands',
    (tester) async {
      final taps = <BodyPartTap>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 400,
              child: AnatomyHeatmap(
                gender: BodyGender.male,
                views: const [BodyView.front],
                handDetailLevel: HandDetailLevel.handsOnly,
                highlights: const [
                  BodyHighlightData(slug: BodyPartSlug.hands, intensity: 0),
                  BodyHighlightData(
                    slug: BodyPartSlug.hands,
                    handPart: HandPartSlug.indexFinger,
                    intensity: 0.95,
                  ),
                ],
                onPartTap: taps.add,
              ),
            ),
          ),
        ),
      );

      final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
      final hand = asset.parts.firstWhere(
        (part) => part.slug == BodyPartSlug.hands,
      );
      final indexFingerCenter = parseSvgPathData(
        hand.left[2],
      ).getBounds().center;
      final paintFinder = find.byType(CustomPaint).first;
      final topLeft = tester.getTopLeft(paintFinder);
      final size = tester.getSize(paintFinder);

      Offset toGlobal(ui.Offset svgPoint) {
        final viewBox = asset.viewBox;
        final scale =
            (size.width / viewBox.width) < (size.height / viewBox.height)
            ? size.width / viewBox.width
            : size.height / viewBox.height;
        final dx = (size.width - viewBox.width * scale) / 2;
        final dy = (size.height - viewBox.height * scale) / 2;
        return topLeft +
            Offset(
              dx + (svgPoint.dx - viewBox.left) * scale,
              dy + (svgPoint.dy - viewBox.top) * scale,
            );
      }

      await tester.tapAt(toGlobal(indexFingerCenter));
      await tester.pump();

      expect(taps.single.slug, BodyPartSlug.hands);
      expect(taps.single.handPart, isNull);
      expect(taps.single.highlight?.handPart, isNull);
      expect(taps.single.highlight?.normalizedIntensity, 0);
    },
  );

  test('license and third-party notices exist', () {
    expect(File('LICENSE').existsSync(), isTrue);
    expect(File('THIRD_PARTY_NOTICES.md').existsSync(), isTrue);

    final notice = File('THIRD_PARTY_NOTICES.md').readAsStringSync();
    expect(notice, contains('react-native-body-highlighter'));
    expect(notice, contains('MIT License'));
  });
}

Future<List<BodyPartTap>> _tapBackHeatmap(
  WidgetTester tester, {
  required List<BodyHighlightData> highlights,
  required List<ui.Offset> svgPoints,
}) async {
  final taps = <BodyPartTap>[];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 362,
        height: 724,
        child: AnatomyHeatmap(
          gender: BodyGender.male,
          views: const [BodyView.back],
          highlights: highlights,
          showOutline: false,
          onPartTap: taps.add,
        ),
      ),
    ),
  );
  await tester.pump();

  final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
  final paintFinder = find.byType(CustomPaint).first;
  final topLeft = tester.getTopLeft(paintFinder);
  final size = tester.getSize(paintFinder);
  for (final svgPoint in svgPoints) {
    await tester.tapAt(_toGlobal(asset, size, topLeft, svgPoint));
    await tester.pump();
  }
  return taps;
}

ui.Offset _pathInteriorPoint(String pathData) {
  final path = parseSvgPathData(pathData);
  final bounds = path.getBounds();
  for (final divisions in const [9, 17, 33]) {
    for (var yIndex = 1; yIndex < divisions; yIndex++) {
      for (var xIndex = 1; xIndex < divisions; xIndex++) {
        final candidate = ui.Offset(
          bounds.left + bounds.width * xIndex / divisions,
          bounds.top + bounds.height * yIndex / divisions,
        );
        if (path.contains(candidate)) {
          return candidate;
        }
      }
    }
  }
  return bounds.center;
}

Offset _toGlobal(
  BodySvgAsset asset,
  Size paintSize,
  Offset topLeft,
  ui.Offset svgPoint,
) {
  final scale = math.min(
    paintSize.width / asset.viewBox.width,
    paintSize.height / asset.viewBox.height,
  );
  final dx = (paintSize.width - asset.viewBox.width * scale) / 2;
  final dy = (paintSize.height - asset.viewBox.height * scale) / 2;
  return topLeft +
      Offset(
        dx + (svgPoint.dx - asset.viewBox.left) * scale,
        dy + (svgPoint.dy - asset.viewBox.top) * scale,
      );
}
