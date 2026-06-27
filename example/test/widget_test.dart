import 'package:body_parts_heatmap/body_parts_heatmap.dart';
import 'package:body_parts_heatmap_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example shows white scaffold and interactive heatmap', (
    tester,
  ) async {
    await tester.pumpWidget(const HeatmapExampleApp());

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
    expect(find.text('Body Parts Heatmap'), findsOneWidget);
    expect(find.byType(BodyPartsHeatmap), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.textContaining('Chest 100%'), findsOneWidget);
    expect(find.textContaining('Quadriceps 82%'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    final heatmap = tester.widget<BodyPartsHeatmap>(
      find.byType(BodyPartsHeatmap),
    );
    expect(heatmap.gender, BodyGender.female);

    await tester.tap(find.textContaining('Chest 100%'));
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('100% activation'), findsOneWidget);
  });
}
