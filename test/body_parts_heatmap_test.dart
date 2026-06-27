import 'dart:io';
import 'dart:ui' as ui;

import 'package:body_parts_heatmap/body_parts_heatmap.dart';
import 'package:body_parts_heatmap/src/data/body_svg_assets.dart';
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
          child: BodyPartsHeatmap(
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
            child: BodyPartsHeatmap(
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
          child: BodyPartsHeatmap(
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

  test('license and third-party notices exist', () {
    expect(File('LICENSE').existsSync(), isTrue);
    expect(File('THIRD_PARTY_NOTICES.md').existsSync(), isTrue);

    final notice = File('THIRD_PARTY_NOTICES.md').readAsStringSync();
    expect(notice, contains('react-native-body-highlighter'));
    expect(notice, contains('MIT License'));
  });
}
