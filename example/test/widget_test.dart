import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:anatomy_heatmap_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example shows white scaffold and interactive heatmap', (
    tester,
  ) async {
    await tester.pumpWidget(const HeatmapExampleApp());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
    expect(find.text('Anatomy Heatmap'), findsOneWidget);
    expect(find.byType(AnatomyHeatmap), findsOneWidget);
    expect(find.text('Hand detail'), findsOneWidget);
    expect(find.byType(HandPartsHeatmap), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.textContaining('Chest 100%'), findsOneWidget);
    expect(find.textContaining('Quadriceps 82%'), findsOneWidget);
    expect(find.textContaining('Index 92%'), findsOneWidget);
    expect(find.textContaining('Thumb 78%'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    final heatmap = tester.widget<AnatomyHeatmap>(find.byType(AnatomyHeatmap));
    expect(heatmap.gender, BodyGender.female);

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
}
