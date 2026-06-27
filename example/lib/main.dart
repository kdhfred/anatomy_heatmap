import 'package:anatomy_heatmap/anatomy_heatmap.dart';
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

  final Map<BodyPartSlug, double> _bodyIntensities = {
    BodyPartSlug.chest: 1,
    BodyPartSlug.quadriceps: 0.82,
    BodyPartSlug.deltoids: 0.48,
    BodyPartSlug.forearm: 0.62,
  };

  final Map<HandPartSlug, double> _handIntensities = {
    HandPartSlug.palm: 0.35,
    HandPartSlug.thumb: 0.78,
    HandPartSlug.indexFinger: 0.92,
    HandPartSlug.middleFinger: 0.82,
    HandPartSlug.ringFinger: 0.56,
    HandPartSlug.littleFinger: 0.42,
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

  List<BodyHighlightData> get _bodyHighlights => [
    for (final entry in _bodyIntensities.entries)
      if (entry.value > 0)
        BodyHighlightData(slug: entry.key, intensity: entry.value),
    for (final entry in _handIntensities.entries)
      if (entry.value > 0)
        BodyHighlightData(
          slug: BodyPartSlug.hands,
          handPart: entry.key,
          intensity: entry.value,
        ),
  ];

  List<HandHighlightData> get _handHighlights => [
    for (final entry in _handIntensities.entries)
      if (entry.value > 0)
        HandHighlightData(slug: entry.key, intensity: entry.value),
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
                'Anatomy Heatmap',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap a muscle or finger, then adjust activation in the bottom sheet.',
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
                flex: 5,
                child: AnatomyHeatmap(
                  gender: _gender,
                  views: const [BodyView.front, BodyView.back],
                  highlights: _bodyHighlights,
                  onPartTap: _handlePartTap,
                ),
              ),
              const SizedBox(height: 10),
              _SegmentedHandPanel(
                highlights: _handHighlights,
                intensities: _handIntensities,
                onPartTap: _handleHandPartTap,
                onSelect: _showHandIntensitySheet,
              ),
              const SizedBox(height: 12),
              _ActiveBodySummary(
                intensities: _bodyIntensities,
                onSelect: _showIntensitySheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePartTap(BodyPartTap tap) {
    if (tap.slug == BodyPartSlug.hands && tap.handPart != null) {
      _showHandIntensitySheet(tap.handPart!);
      return;
    }
    if (!_adjustableParts.contains(tap.slug)) {
      return;
    }
    _showIntensitySheet(tap.slug);
  }

  void _handleHandPartTap(HandPartTap tap) {
    _showHandIntensitySheet(tap.slug);
  }

  void _showIntensitySheet(BodyPartSlug slug) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final value = _bodyIntensities[slug] ?? 0;
            final percent = (value * 100).round();

            void update(double next) {
              setState(() {
                if (next <= 0) {
                  _bodyIntensities.remove(slug);
                } else {
                  _bodyIntensities[slug] = next;
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

  void _showHandIntensitySheet(HandPartSlug slug) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final value = _handIntensities[slug] ?? 0;
            final percent = (value * 100).round();

            void update(double next) {
              setState(() {
                if (next <= 0) {
                  _handIntensities.remove(slug);
                } else {
                  _handIntensities[slug] = next;
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
                    '$percent% finger load',
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

class _SegmentedHandPanel extends StatelessWidget {
  const _SegmentedHandPanel({
    required this.highlights,
    required this.intensities,
    required this.onPartTap,
    required this.onSelect,
  });

  final List<HandHighlightData> highlights;
  final Map<HandPartSlug, double> intensities;
  final ValueChanged<HandPartTap> onPartTap;
  final ValueChanged<HandPartSlug> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF9),
        border: Border.all(color: const Color(0xFFFFD7D3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Hand detail',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 108,
                  child: HandPartsHeatmap(
                    views: const [BodyView.front],
                    sides: const [BodySide.left, BodySide.right],
                    highlights: highlights,
                    onPartTap: onPartTap,
                    spacing: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: _HandSegmentSummary(
              intensities: intensities,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandSegmentSummary extends StatelessWidget {
  const _HandSegmentSummary({
    required this.intensities,
    required this.onSelect,
  });

  final Map<HandPartSlug, double> intensities;
  final ValueChanged<HandPartSlug> onSelect;

  @override
  Widget build(BuildContext context) {
    final active =
        intensities.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in active)
          ActionChip(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
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

class _ActiveBodySummary extends StatelessWidget {
  const _ActiveBodySummary({required this.intensities, required this.onSelect});

  final Map<BodyPartSlug, double> intensities;
  final ValueChanged<BodyPartSlug> onSelect;

  @override
  Widget build(BuildContext context) {
    final active =
        intensities.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (active.isEmpty) {
      return Text(
        'No active body regions. Tap a region to add activation.',
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
