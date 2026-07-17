import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:anatomy_heatmap/src/body_render_region.dart';
import 'package:anatomy_heatmap/src/data/body_svg_asset.dart';
import 'package:anatomy_heatmap/src/data/body_svg_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  group('public anatomy region contract', () {
    test('exposes stable ordered muscle wire keys and strict parsing', () {
      expect(MuscleRegionKey.values.map((region) => region.wireKey), const [
        'chest',
        'abs',
        'obliques',
        'biceps',
        'triceps',
        'forearm',
        'deltoids',
        'trapezius',
        'upper-back',
        'lats',
        'lower-back',
        'gluteal',
        'hamstring',
        'quadriceps',
        'calves',
        'adductors',
        'tibialis',
        'neck',
        'abductors',
      ]);

      for (final region in MuscleRegionKey.values) {
        expect(muscleRegionKeyFromWire(region.wireKey), region);
        expect(tryMuscleRegionKeyFromWire(region.wireKey), region);
      }
      expect(tryMuscleRegionKeyFromWire('upperBack'), isNull);
      expect(
        () => muscleRegionKeyFromWire('not-a-region'),
        throwsArgumentError,
      );
    });

    test('maps every public muscle region to bundled geometry', () {
      for (final asset in bodySvgAssets) {
        final actual = asset.parts
            .map((part) => part.slug.muscleRegion)
            .nonNulls
            .toSet();
        final expected = MuscleRegionKey.values
            .where((region) => region.isRenderableIn(asset.view))
            .toSet();

        expect(
          actual,
          expected,
          reason: '${asset.gender.name}/${asset.view.name}',
        );
      }
    });

    test('keeps decorative and hand render groups outside muscle contract', () {
      for (final region in const [
        BodyRenderRegion.hands,
        BodyRenderRegion.head,
        BodyRenderRegion.feet,
        BodyRenderRegion.ankles,
        BodyRenderRegion.knees,
        BodyRenderRegion.hair,
      ]) {
        expect(region.muscleRegion, isNull);
      }
    });

    test('muscle highlight identity is public and immutable by default', () {
      final copied = const BodyHighlightData(
        region: MuscleRegionKey.upperBack,
        intensity: 1,
      ).copyWith(intensity: 0.4);

      expect(copied.region, MuscleRegionKey.upperBack);
      expect(copied.intensity, 0.4);
      expect(
        copied.copyWith(region: MuscleRegionKey.chest).region,
        MuscleRegionKey.chest,
      );
    });

    test('barrel omits renderer and business taxonomy exports', () {
      final barrel = File('lib/anatomy_heatmap.dart').readAsStringSync();

      expect(barrel, isNot(contains('body_render_region.dart')));
      expect(barrel, isNot(contains('muscle_to_body_part_adapter.dart')));
      expect(barrel, isNot(contains('BodyPartSlug')));
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

    test('muscle group preset uses public region and hand keys', () {
      const scheme = BodyHeatmapColorScheme.muscleGroups;

      final chest = scheme.fillFor(
        const BodyHighlightData(region: MuscleRegionKey.chest, intensity: 1),
      );
      final quads = scheme.fillFor(
        const BodyHighlightData(
          region: MuscleRegionKey.quadriceps,
          intensity: 1,
        ),
      );
      final index = scheme.fillForHand(
        const HandHighlightData(slug: HandPartSlug.indexFinger, intensity: 1),
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
      expect(
        scheme.muscleRegionHeatColors.keys.toSet(),
        MuscleRegionKey.values.toSet(),
      );
      expect(scheme.handPartHeatColors[HandPartSlug.hand], isNotNull);
    });

    test('per-highlight color overrides the configured region color', () {
      const custom = Color(0xFF123456);
      const scheme = BodyHeatmapColorScheme.muscleGroups;
      final resolved = scheme.fillFor(
        const BodyHighlightData(
          region: MuscleRegionKey.chest,
          intensity: 1,
          color: custom,
        ),
      );

      expect(resolved, custom.withValues(alpha: 0.92));
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
        BodyHeatmapColorScheme.muscleGroupsDark.muscleRegionHeatColors,
        same(BodyHeatmapColorScheme.muscleGroups.muscleRegionHeatColors),
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
      final seededLight = BodyHeatmapColorScheme.fromPreset(
        BodyHeatmapColorPreset.redLoad,
        redLoadSeedColor: blueSeed,
      );
      expect(seededLight.heatColor, blueSeed);
      expect(
        seededLight.inactiveFill,
        BodyHeatmapColorScheme.redLoad.inactiveFill,
      );

      final seededDark = BodyHeatmapColorScheme.redLoadFromSeed(
        blueSeed,
        brightness: Brightness.dark,
      );
      expect(seededDark.heatColor, blueSeed);
      expect(
        seededDark.inactiveFill,
        BodyHeatmapColorScheme.redLoadDark.inactiveFill,
      );
    });

    test('preset color overrides merge without replacing defaults', () {
      const customChest = Color(0xFF6D28D9);
      const customIndex = Color(0xFF14B8A6);

      final scheme =
          BodyHeatmapColorScheme.fromPreset(
            BodyHeatmapColorPreset.muscleGroups,
            brightness: Brightness.dark,
          ).withOverrides(
            inactiveFill: const Color(0xFF101010),
            muscleRegionHeatColors: const {MuscleRegionKey.chest: customChest},
            handPartHeatColors: const {HandPartSlug.indexFinger: customIndex},
          );

      expect(scheme.inactiveFill, const Color(0xFF101010));
      expect(scheme.muscleRegionHeatColors[MuscleRegionKey.chest], customChest);
      expect(
        scheme.muscleRegionHeatColors[MuscleRegionKey.quadriceps],
        BodyHeatmapColorScheme
            .muscleGroupsDark
            .muscleRegionHeatColors[MuscleRegionKey.quadriceps],
      );
      expect(scheme.handPartHeatColors[HandPartSlug.indexFinger], customIndex);

      final replaced = scheme.copyWith(muscleRegionHeatColors: const {});
      expect(replaced.muscleRegionHeatColors, isEmpty);
      expect(replaced.handPartHeatColors, isNotEmpty);
    });
  });

  group('hand tree taxonomy', () {
    test('exposes exact children under the aggregate hand region', () {
      expect(HandPartSlug.hand.children, containsAll(renderedHandPartSlugs));
      expect(HandPartSlug.palm.children, isEmpty);
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
          containsAll([BodyRenderRegion.neck, BodyRenderRegion.trapezius]),
        );
        expect(
          back.parts.map((part) => part.slug),
          contains(BodyRenderRegion.trapezius),
        );
        expect(
          back.parts.map((part) => part.slug),
          isNot(contains(BodyRenderRegion.neck)),
        );

        final lats = back.parts.singleWhere(
          (part) => part.slug == BodyRenderRegion.lats,
        );
        expect(lats.common, isEmpty);
        expect(lats.left, hasLength(1));
        expect(lats.right, hasLength(1));

        final trapezius = back.parts.singleWhere(
          (part) => part.slug == BodyRenderRegion.trapezius,
        );
        expect(trapezius.common, isEmpty);
        expect(trapezius.left, hasLength(2));
        expect(trapezius.right, hasLength(2));

        final upperBack = back.parts.singleWhere(
          (part) => part.slug == BodyRenderRegion.upperBack,
        );
        expect(upperBack.common, isEmpty);
        expect(upperBack.left, hasLength(gender == BodyGender.male ? 2 : 1));
        expect(upperBack.right, hasLength(gender == BodyGender.male ? 2 : 1));

        final lowerBack = back.parts.singleWhere(
          (part) => part.slug == BodyRenderRegion.lowerBack,
        );
        expect(lowerBack.common, isEmpty);
        expect(lowerBack.left, hasLength(2));
        expect(lowerBack.right, hasLength(2));
      }
    });

    test(
      'back taxonomy splits abductors out of gluteal only on back views',
      () {
        for (final gender in BodyGender.values) {
          final front = bodySvgAssetFor(gender, BodyView.front);
          final back = bodySvgAssetFor(gender, BodyView.back);

          expect(
            front.parts.map((part) => part.slug),
            isNot(contains(BodyRenderRegion.abductors)),
          );

          final abductors = back.parts.singleWhere(
            (part) => part.slug == BodyRenderRegion.abductors,
          );
          expect(abductors.common, isEmpty);
          expect(abductors.left, hasLength(1));
          expect(abductors.right, hasLength(1));

          final gluteal = back.parts.singleWhere(
            (part) => part.slug == BodyRenderRegion.gluteal,
          );
          expect(gluteal.common, isEmpty);
          expect(gluteal.left, hasLength(1));
          expect(gluteal.right, hasLength(1));
        }
      },
    );
  });

  testWidgets('upperBack region selects only upper-back geometry', (
    tester,
  ) async {
    final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
    final upperBack = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.upperBack,
    );
    final trapezius = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.trapezius,
    );

    final taps = await _tapBackHeatmap(
      tester,
      highlights: const [
        BodyHighlightData(region: MuscleRegionKey.upperBack, intensity: 1),
      ],
      svgPoints: [
        _pathInteriorPoint(upperBack.left.first),
        _pathInteriorPoint(trapezius.left.last),
      ],
    );

    expect(taps, hasLength(2));
    expect(taps[0].muscleRegion, MuscleRegionKey.upperBack);
    expect(taps[0].muscleHighlight?.region, MuscleRegionKey.upperBack);
    expect(taps[1].muscleRegion, MuscleRegionKey.trapezius);
    expect(taps[1].muscleHighlight, isNull);
  });

  testWidgets(
    'atomic upperBack excludes trapezius while reporting exact tap regions',
    (tester) async {
      final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
      final upperBack = asset.parts.singleWhere(
        (part) => part.slug == BodyRenderRegion.upperBack,
      );
      final trapezius = asset.parts.singleWhere(
        (part) => part.slug == BodyRenderRegion.trapezius,
      );
      final highlight = BodyHighlightData(region: MuscleRegionKey.upperBack);

      final taps = await _tapBackHeatmap(
        tester,
        highlights: [highlight],
        svgPoints: [
          _pathInteriorPoint(upperBack.left.first),
          _pathInteriorPoint(trapezius.left.last),
        ],
      );

      expect(taps, hasLength(2));
      expect(taps[0].muscleRegion, MuscleRegionKey.upperBack);
      expect(taps[0].muscleHighlight?.region, MuscleRegionKey.upperBack);
      expect(taps[1].muscleRegion, MuscleRegionKey.trapezius);
      expect(taps[1].muscleHighlight, isNull);
    },
  );

  testWidgets('atomic region highlights preserve side isolation', (
    tester,
  ) async {
    final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
    final lats = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.lats,
    );

    final taps = await _tapBackHeatmap(
      tester,
      highlights: [
        BodyHighlightData(region: MuscleRegionKey.lats, side: BodySide.left),
      ],
      svgPoints: [
        _pathInteriorPoint(lats.left.single),
        _pathInteriorPoint(lats.right.single),
      ],
    );

    expect(taps, hasLength(2));
    expect(taps[0].muscleHighlight?.region, MuscleRegionKey.lats);
    expect(taps[1].muscleHighlight, isNull);
  });

  testWidgets('trapezius and upperBack highlights remain independent', (
    tester,
  ) async {
    final asset = bodySvgAssetFor(BodyGender.male, BodyView.back);
    final upperBack = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.upperBack,
    );
    final trapezius = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.trapezius,
    );

    const upperBackColor = Color(0xFF00A060);
    const trapeziusColor = Color(0xFF7E22CE);
    final taps = await _tapBackHeatmap(
      tester,
      highlights: const [
        BodyHighlightData(
          region: MuscleRegionKey.upperBack,
          intensity: 1,
          color: upperBackColor,
        ),
        BodyHighlightData(
          region: MuscleRegionKey.trapezius,
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
    expect(taps[0].muscleRegion, MuscleRegionKey.upperBack);
    expect(taps[0].muscleHighlight?.region, MuscleRegionKey.upperBack);
    expect(taps[0].muscleHighlight?.color, upperBackColor);
    expect(taps[1].muscleRegion, MuscleRegionKey.trapezius);
    expect(taps[1].muscleHighlight?.region, MuscleRegionKey.trapezius);
    expect(taps[1].muscleHighlight?.color, trapeziusColor);
  });

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
              BodyHighlightData(region: MuscleRegionKey.chest, intensity: 0.8),
              BodyHighlightData(region: MuscleRegionKey.lats, intensity: 0.6),
              BodyHighlightData(
                region: MuscleRegionKey.upperBack,
                intensity: 0.45,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap callback reports left and right body sides', (tester) async {
    final taps = <AnatomyRegionTap>[];

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
                  region: MuscleRegionKey.chest,
                  side: BodySide.left,
                  intensity: 0.8,
                ),
              ],
              onRegionTap: taps.add,
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

    expect(
      taps.map((tap) => tap.muscleRegion),
      everyElement(MuscleRegionKey.chest),
    );
    expect(
      taps.map((tap) => tap.side),
      containsAll([BodySide.left, BodySide.right]),
    );
    expect(taps.first.muscleHighlight?.side, BodySide.left);
    expect(taps.last.muscleHighlight, isNull);
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
              BodyHighlightData(region: MuscleRegionKey.chest, intensity: 0.8),
              BodyHighlightData(
                region: MuscleRegionKey.gluteal,
                intensity: 0.45,
              ),
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
    ).parts.firstWhere((part) => part.slug == BodyRenderRegion.hands);
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
    final taps = <AnatomyRegionTap>[];

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
              handHighlights: const [
                HandHighlightData(slug: HandPartSlug.hand, intensity: 1),
                HandHighlightData(slug: HandPartSlug.indexFinger, intensity: 0),
              ],
              onRegionTap: taps.add,
            ),
          ),
        ),
      ),
    );

    final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
    final hand = asset.parts.firstWhere(
      (part) => part.slug == BodyRenderRegion.hands,
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

    expect(taps.single.handPart, HandPartSlug.indexFinger);
    expect(taps.single.handHighlight?.slug, HandPartSlug.indexFinger);
    expect(taps.single.handHighlight?.normalizedIntensity, 0);
  });

  testWidgets(
    'full anatomy heatmap lets parent hands zero control collapsed hands',
    (tester) async {
      final taps = <AnatomyRegionTap>[];

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
                handHighlights: const [
                  HandHighlightData(slug: HandPartSlug.hand, intensity: 0),
                  HandHighlightData(
                    slug: HandPartSlug.indexFinger,
                    intensity: 0.95,
                  ),
                ],
                onRegionTap: taps.add,
              ),
            ),
          ),
        ),
      );

      final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
      final hand = asset.parts.firstWhere(
        (part) => part.slug == BodyRenderRegion.hands,
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

      expect(taps.single.handPart, HandPartSlug.hand);
      expect(taps.single.handHighlight?.slug, HandPartSlug.hand);
      expect(taps.single.handHighlight?.normalizedIntensity, 0);
    },
  );

  testWidgets('hidden muscle regions are omitted from public hit testing', (
    tester,
  ) async {
    final taps = <AnatomyRegionTap>[];
    final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
    final chest = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.chest,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 362,
          height: 724,
          child: AnatomyHeatmap(
            gender: BodyGender.male,
            views: const [BodyView.front],
            hiddenMuscleRegions: const {MuscleRegionKey.chest},
            showOutline: false,
            onRegionTap: taps.add,
          ),
        ),
      ),
    );

    final paintFinder = find.byType(CustomPaint).first;
    await tester.tapAt(
      _toGlobal(
        asset,
        tester.getSize(paintFinder),
        tester.getTopLeft(paintFinder),
        _pathInteriorPoint(chest.left.first),
      ),
    );
    await tester.pump();

    expect(taps, isEmpty);
  });

  testWidgets('decorative render groups never leak through public taps', (
    tester,
  ) async {
    final taps = <AnatomyRegionTap>[];
    final asset = bodySvgAssetFor(BodyGender.male, BodyView.front);
    final hair = asset.parts.singleWhere(
      (part) => part.slug == BodyRenderRegion.hair,
    );
    final hairPath = [...hair.common, ...hair.left, ...hair.right].first;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 362,
          height: 724,
          child: AnatomyHeatmap(
            gender: BodyGender.male,
            views: const [BodyView.front],
            showOutline: false,
            onRegionTap: taps.add,
          ),
        ),
      ),
    );

    final paintFinder = find.byType(CustomPaint).first;
    await tester.tapAt(
      _toGlobal(
        asset,
        tester.getSize(paintFinder),
        tester.getTopLeft(paintFinder),
        _pathInteriorPoint(hairPath),
      ),
    );
    await tester.pump();

    expect(taps, isEmpty);
  });

  test('license and third-party notices exist', () {
    expect(File('LICENSE').existsSync(), isTrue);
    expect(File('THIRD_PARTY_NOTICES.md').existsSync(), isTrue);

    final notice = File('THIRD_PARTY_NOTICES.md').readAsStringSync();
    expect(notice, contains('react-native-body-highlighter'));
    expect(notice, contains('MIT License'));
  });
}

Future<List<AnatomyRegionTap>> _tapBackHeatmap(
  WidgetTester tester, {
  required List<BodyHighlightData> highlights,
  required List<ui.Offset> svgPoints,
}) async {
  final taps = <AnatomyRegionTap>[];
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
          onRegionTap: taps.add,
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
