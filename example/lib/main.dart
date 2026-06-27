import 'package:body_parts_heatmap/body_parts_heatmap.dart';
import 'package:flutter/material.dart';

void main() => runApp(const HeatmapExampleApp());

class HeatmapExampleApp extends StatelessWidget {
  const HeatmapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF5A4F),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HeatmapExampleScreen(),
    );
  }
}

class HeatmapExampleScreen extends StatefulWidget {
  const HeatmapExampleScreen({super.key});

  @override
  State<HeatmapExampleScreen> createState() => _HeatmapExampleScreenState();
}

class _HeatmapExampleScreenState extends State<HeatmapExampleScreen> {
  BodyGender _gender = BodyGender.male;

  final Map<BodyPartSlug, double> _intensities = {
    BodyPartSlug.chest: 1,
    BodyPartSlug.quadriceps: 0.82,
    BodyPartSlug.deltoids: 0.48,
    BodyPartSlug.forearm: 0.62,
    BodyPartSlug.hands: 0.52,
  };

  static const Set<BodyPartSlug> _adjustableParts = {
    BodyPartSlug.chest,
    BodyPartSlug.abs,
    BodyPartSlug.obliques,
    BodyPartSlug.biceps,
    BodyPartSlug.triceps,
    BodyPartSlug.forearm,
    BodyPartSlug.hands,
    BodyPartSlug.deltoids,
    BodyPartSlug.trapezius,
    BodyPartSlug.upperBack,
    BodyPartSlug.lowerBack,
    BodyPartSlug.gluteal,
    BodyPartSlug.hamstring,
    BodyPartSlug.quadriceps,
    BodyPartSlug.calves,
    BodyPartSlug.adductors,
    BodyPartSlug.tibialis,
    BodyPartSlug.neck,
  };

  List<BodyHighlightData> get _highlights => [
    for (final entry in _intensities.entries)
      if (entry.value > 0)
        BodyHighlightData(slug: entry.key, intensity: entry.value),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Body Parts Heatmap',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap a muscle, then adjust its activation in the bottom sheet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Center(
                child: SegmentedButton<BodyGender>(
                  segments: const [
                    ButtonSegment(value: BodyGender.male, label: Text('Male')),
                    ButtonSegment(
                      value: BodyGender.female,
                      label: Text('Female'),
                    ),
                  ],
                  selected: {_gender},
                  onSelectionChanged: (selection) {
                    setState(() => _gender = selection.single);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BodyPartsHeatmap(
                  gender: _gender,
                  views: const [BodyView.front, BodyView.back],
                  highlights: _highlights,
                  onPartTap: _handlePartTap,
                ),
              ),
              const SizedBox(height: 16),
              _ActiveMuscleSummary(
                intensities: _intensities,
                onSelect: _showIntensitySheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePartTap(BodyPartTap tap) {
    if (!_adjustableParts.contains(tap.slug)) {
      return;
    }
    _showIntensitySheet(tap.slug);
  }

  void _showIntensitySheet(BodyPartSlug slug) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final value = _intensities[slug] ?? 0;
            final percent = (value * 100).round();

            void update(double next) {
              setState(() {
                if (next <= 0) {
                  _intensities.remove(slug);
                } else {
                  _intensities[slug] = next;
                }
              });
              setSheetState(() {});
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    slug.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$percent% activation',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: value,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '$percent%',
                    activeColor: const Color(0xFFFF5A4F),
                    inactiveColor: const Color(0xFFFFD7D3),
                    onChanged: update,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => update(0),
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActiveMuscleSummary extends StatelessWidget {
  const _ActiveMuscleSummary({
    required this.intensities,
    required this.onSelect,
  });

  final Map<BodyPartSlug, double> intensities;
  final ValueChanged<BodyPartSlug> onSelect;

  @override
  Widget build(BuildContext context) {
    final active =
        intensities.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (active.isEmpty) {
      return Text(
        'No active muscles. Tap a muscle to add activation.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade700),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in active)
          ActionChip(
            backgroundColor: const Color(0xFFFFECEA),
            side: BorderSide(color: Colors.red.shade100),
            onPressed: () => onSelect(entry.key),
            label: Text(
              '${entry.key.label} ${(entry.value * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
