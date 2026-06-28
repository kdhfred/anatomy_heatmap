import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:anatomy_heatmap_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  void setSystemBrightness(WidgetTester tester, Brightness brightness) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  testWidgets('example follows light system theme and stays interactive', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    setSystemBrightness(tester, Brightness.light);

    await tester.pumpWidget(const HeatmapExampleApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    expect(find.text('Anatomy Heatmap'), findsOneWidget);
    expect(find.byType(AnatomyHeatmap), findsOneWidget);
    expect(find.text('Hand detail'), findsOneWidget);
    expect(find.byType(HandPartsHeatmap), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Style: Muscle Groups'), findsOneWidget);
    expect(find.text('Hands: Segments'), findsOneWidget);
    expect(find.textContaining('Chest 100%'), findsOneWidget);
    expect(find.textContaining('Quadriceps 82%'), findsOneWidget);
    expect(find.textContaining('Index 92%'), findsOneWidget);
    expect(find.textContaining('Thumb 78%'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    final heatmap = tester.widget<AnatomyHeatmap>(find.byType(AnatomyHeatmap));
    expect(heatmap.gender, BodyGender.female);
    expect(heatmap.colorScheme, same(BodyHeatmapColorScheme.muscleGroups));
    expect(heatmap.handDetailLevel, HandDetailLevel.segments);

    await tester.tap(find.text('Hands: Segments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hands Only'));
    await tester.pumpAndSettle();

    final handsOnlyHeatmap = tester.widget<AnatomyHeatmap>(
      find.byType(AnatomyHeatmap),
    );
    expect(handsOnlyHeatmap.handDetailLevel, HandDetailLevel.handsOnly);
    expect(find.text('Hands: Hands Only'), findsOneWidget);

    await tester.tap(find.text('Style: Muscle Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red Load'));
    await tester.pumpAndSettle();

    final redLoadHeatmap = tester.widget<AnatomyHeatmap>(
      find.byType(AnatomyHeatmap),
    );
    expect(redLoadHeatmap.colorScheme, same(BodyHeatmapColorScheme.redLoad));
    expect(find.text('Style: Red Load'), findsOneWidget);
    expect(find.text('Seed: Coral'), findsOneWidget);

    await tester.tap(find.text('Seed: Coral'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue').last);
    await tester.pumpAndSettle();

    final blueLoadHeatmap = tester.widget<AnatomyHeatmap>(
      find.byType(AnatomyHeatmap),
    );
    expect(blueLoadHeatmap.colorScheme.heatColor, const Color(0xFF2563EB));
    expect(
      blueLoadHeatmap.colorScheme,
      isNot(same(BodyHeatmapColorScheme.redLoad)),
    );

    await tester.tap(find.textContaining('Chest 100%'));
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('100% activation'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Index 92%'));
    await tester.pumpAndSettle();

    expect(find.text('Index'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('92% finger load'), findsOneWidget);
  });

  testWidgets('example follows dark system theme', (tester) async {
    await setPhoneSurface(tester);
    setSystemBrightness(tester, Brightness.dark);

    await tester.pumpWidget(const HeatmapExampleApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);

    final heatmap = tester.widget<AnatomyHeatmap>(find.byType(AnatomyHeatmap));
    expect(heatmap.colorScheme.inactiveFill, const Color(0xFF242B36));
    expect(heatmap.colorScheme.borderColor, const Color(0xFF64748B));
    expect(heatmap.colorScheme, same(BodyHeatmapColorScheme.muscleGroupsDark));

    final handHeatmap = tester.widget<HandPartsHeatmap>(
      find.byType(HandPartsHeatmap),
    );
    expect(handHeatmap.colorScheme.inactiveFill, const Color(0xFF242B36));

    await tester.tap(find.text('Style: Muscle Groups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red Load'));
    await tester.pumpAndSettle();

    final redLoadHeatmap = tester.widget<AnatomyHeatmap>(
      find.byType(AnatomyHeatmap),
    );
    expect(
      redLoadHeatmap.colorScheme,
      same(BodyHeatmapColorScheme.redLoadDark),
    );
    expect(find.text('Seed: Coral'), findsOneWidget);

    await tester.tap(find.textContaining('Index 92%'));
    await tester.pumpAndSettle();

    expect(find.text('Index'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('92% finger load'), findsOneWidget);
  });

  testWidgets('example hand slider updates full-body hand highlight', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    setSystemBrightness(tester, Brightness.light);

    await tester.pumpWidget(const HeatmapExampleApp());

    await tester.tap(find.textContaining('Index 92%'));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(0);
    await tester.pump();

    final heatmap = tester.widget<AnatomyHeatmap>(find.byType(AnatomyHeatmap));
    final indexHighlight = heatmap.highlights.singleWhere(
      (highlight) =>
          highlight.slug == BodyPartSlug.hands &&
          highlight.handPart == HandPartSlug.indexFinger,
    );

    expect(indexHighlight.intensity, 0);
    expect(find.text('0% finger load'), findsOneWidget);
  });
}
