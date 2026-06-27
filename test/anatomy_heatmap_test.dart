import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:anatomy_heatmap/src/data/body_svg_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  group('MuscleToBodyPartAdapter', () {
    test('maps seeded aliases correctly', () {
      final adapter = MuscleToBodyPartAdapter();

      final result = adapter.mapPrimarySecondary(
        primaryMuscles: ['Pectoralis', 'Lats', 'Finger Flexors'],
        secondaryMuscles: ['Rotator Cuff', 'Soleus', 'Obliques'],
      );

      expect(result.primary, contains(BodyPartSlug.chest));
      expect(result.primary, contains(BodyPartSlug.upperBack));
      expect(result.primary, contains(BodyPartSlug.forearm));
      expect(result.primary, contains(BodyPartSlug.hands));
      expect(result.secondary, contains(BodyPartSlug.deltoids));
      expect(result.secondary, contains(BodyPartSlug.calves));
      expect(result.secondary, contains(BodyPartSlug.obliques));
      expect(result.unmapped, isEmpty);
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
              BodyHighlightData(slug: BodyPartSlug.chest, intensity: 0.8),
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

  testWidgets('full anatomy heatmap reports hand child segments', (
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
                BodyHighlightData(slug: BodyPartSlug.hands, intensity: 0.2),
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
    expect(taps.single.highlight?.normalizedIntensity, 0.95);
  });

  test('license and third-party notices exist', () {
    expect(File('LICENSE').existsSync(), isTrue);
    expect(File('THIRD_PARTY_NOTICES.md').existsSync(), isTrue);

    final notice = File('THIRD_PARTY_NOTICES.md').readAsStringSync();
    expect(notice, contains('react-native-body-highlighter'));
    expect(notice, contains('MIT License'));
  });
}
