import 'package:anatomy_heatmap/anatomy_heatmap.dart';
import 'package:flutter/material.dart';

void main() => runApp(const HeatmapExampleApp());

class HeatmapExampleApp extends StatelessWidget {
  const HeatmapExampleApp({super.key});

  static const _seedColor = Color(0xFFFF5A4F);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
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
  BodyHeatmapColorPreset _preset = BodyHeatmapColorPreset.muscleGroups;
  HandDetailLevel _handDetailLevel = HandDetailLevel.segments;
  _RedLoadSeed _redLoadSeed = _redLoadSeeds.first;

  static const _redLoadSeeds = [
    _RedLoadSeed('Coral', BodyHeatmapColorScheme.defaultRedLoadSeedColor),
    _RedLoadSeed('Blue', Color(0xFF2563EB)),
    _RedLoadSeed('Green', Color(0xFF16A34A)),
    _RedLoadSeed('Purple', Color(0xFF9333EA)),
  ];

  final Map<MuscleRegionKey, double> _muscleIntensities = {
    MuscleRegionKey.chest: 1,
    MuscleRegionKey.quadriceps: 0.82,
    MuscleRegionKey.lats: 0.56,
    MuscleRegionKey.deltoids: 0.48,
    MuscleRegionKey.forearm: 0.62,
  };

  final Map<HandPartSlug, double> _handIntensities = {
    HandPartSlug.palm: 0.35,
    HandPartSlug.thumb: 0.78,
    HandPartSlug.indexFinger: 0.92,
    HandPartSlug.middleFinger: 0.82,
    HandPartSlug.ringFinger: 0.56,
    HandPartSlug.littleFinger: 0.42,
  };

  List<BodyHighlightData> get _muscleHighlights => [
    for (final entry in _muscleIntensities.entries)
      BodyHighlightData(region: entry.key, intensity: entry.value),
  ];

  List<HandHighlightData> get _handHighlights => [
    for (final entry in _handIntensities.entries)
      HandHighlightData(slug: entry.key, intensity: entry.value),
  ];

  String get _presetLabel {
    return switch (_preset) {
      BodyHeatmapColorPreset.redLoad => 'Red Load',
      BodyHeatmapColorPreset.muscleGroups => 'Muscle Groups',
    };
  }

  String get _handDetailLabel {
    return switch (_handDetailLevel) {
      HandDetailLevel.handsOnly => 'Hands Only',
      HandDetailLevel.segments => 'Segments',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final heatmapColorScheme = BodyHeatmapColorScheme.fromPreset(
      _preset,
      brightness: theme.brightness,
      redLoadSeedColor: _redLoadSeed.color,
    );

    return Scaffold(
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
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  SegmentedButton<BodyGender>(
                    segments: const [
                      ButtonSegment(
                        value: BodyGender.male,
                        label: Text('Male'),
                      ),
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
                  PopupMenuButton<BodyHeatmapColorPreset>(
                    initialValue: _preset,
                    onSelected: (preset) {
                      setState(() => _preset = preset);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: BodyHeatmapColorPreset.redLoad,
                          child: Text('Red Load'),
                        ),
                        PopupMenuItem(
                          value: BodyHeatmapColorPreset.muscleGroups,
                          child: Text('Muscle Groups'),
                        ),
                      ];
                    },
                    child: Chip(label: Text('Style: $_presetLabel')),
                  ),
                  PopupMenuButton<HandDetailLevel>(
                    initialValue: _handDetailLevel,
                    onSelected: (level) {
                      setState(() => _handDetailLevel = level);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: HandDetailLevel.handsOnly,
                          child: Text('Hands Only'),
                        ),
                        PopupMenuItem(
                          value: HandDetailLevel.segments,
                          child: Text('Segments'),
                        ),
                      ];
                    },
                    child: Chip(label: Text('Hands: $_handDetailLabel')),
                  ),
                  if (_preset == BodyHeatmapColorPreset.redLoad)
                    PopupMenuButton<_RedLoadSeed>(
                      initialValue: _redLoadSeed,
                      onSelected: (seed) {
                        setState(() => _redLoadSeed = seed);
                      },
                      itemBuilder: (context) {
                        return [
                          for (final seed in _redLoadSeeds)
                            PopupMenuItem(
                              value: seed,
                              child: _SeedColorLabel(seed: seed),
                            ),
                        ];
                      },
                      child: Chip(
                        avatar: _SeedColorDot(color: _redLoadSeed.color),
                        label: Text('Seed: ${_redLoadSeed.label}'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 5,
                child: AnatomyHeatmap(
                  gender: _gender,
                  views: const [BodyView.front, BodyView.back],
                  highlights: _muscleHighlights,
                  handHighlights: _handHighlights,
                  colorScheme: heatmapColorScheme,
                  handDetailLevel: _handDetailLevel,
                  onRegionTap: _handleRegionTap,
                ),
              ),
              const SizedBox(height: 10),
              _SegmentedHandPanel(
                highlights: _handHighlights,
                intensities: _handIntensities,
                colorScheme: heatmapColorScheme,
                onPartTap: _handleHandPartTap,
                onSelect: _showHandIntensitySheet,
              ),
              const SizedBox(height: 12),
              _ActiveMuscleSummary(
                intensities: _muscleIntensities,
                onSelect: _showMuscleIntensitySheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegionTap(AnatomyRegionTap tap) {
    if (tap.handPart != null) {
      _showHandIntensitySheet(tap.handPart!);
      return;
    }
    if (tap.muscleRegion != null) {
      _showMuscleIntensitySheet(tap.muscleRegion!);
    }
  }

  void _handleHandPartTap(HandPartTap tap) {
    _showHandIntensitySheet(tap.slug);
  }

  void _showMuscleIntensitySheet(MuscleRegionKey region) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;
            final value = _muscleIntensities[region] ?? 0;
            final percent = (value * 100).round();

            void update(double next) {
              setState(() {
                if (next <= 0) {
                  _muscleIntensities.remove(region);
                } else {
                  _muscleIntensities[region] = next;
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
                    region.label,
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
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: value,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '$percent%',
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;
            final value = _handIntensities[slug] ?? 0;
            final percent = (value * 100).round();

            void update(double next) {
              setState(() {
                _handIntensities[slug] = next;
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
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: value,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '$percent%',
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

class _RedLoadSeed {
  const _RedLoadSeed(this.label, this.color);

  final String label;
  final Color color;
}

class _SeedColorLabel extends StatelessWidget {
  const _SeedColorLabel({required this.seed});

  final _RedLoadSeed seed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeedColorDot(color: seed.color),
        const SizedBox(width: 8),
        Text(seed.label),
      ],
    );
  }
}

class _SeedColorDot extends StatelessWidget {
  const _SeedColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: const SizedBox.square(dimension: 14),
    );
  }
}

class _SegmentedHandPanel extends StatelessWidget {
  const _SegmentedHandPanel({
    required this.highlights,
    required this.intensities,
    required this.colorScheme,
    required this.onPartTap,
    required this.onSelect,
  });

  final List<HandHighlightData> highlights;
  final Map<HandPartSlug, double> intensities;
  final BodyHeatmapColorScheme colorScheme;
  final ValueChanged<HandPartTap> onPartTap;
  final ValueChanged<HandPartSlug> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
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
                const SizedBox(height: 6),
                SizedBox(
                  height: 76,
                  child: HandPartsHeatmap(
                    views: const [BodyView.front],
                    sides: const [BodySide.left, BodySide.right],
                    highlights: highlights,
                    colorScheme: colorScheme,
                    onPartTap: onPartTap,
                    spacing: 12,
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
    final colors = Theme.of(context).colorScheme;
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
            backgroundColor: colors.surfaceContainerLow,
            side: BorderSide(color: colors.outlineVariant),
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

class _ActiveMuscleSummary extends StatelessWidget {
  const _ActiveMuscleSummary({
    required this.intensities,
    required this.onSelect,
  });

  final Map<MuscleRegionKey, double> intensities;
  final ValueChanged<MuscleRegionKey> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active =
        intensities.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (active.isEmpty) {
      return Text(
        'No active body regions. Tap a region to add activation.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.onSurfaceVariant),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in active)
          ActionChip(
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.36),
            side: BorderSide(color: colors.outlineVariant),
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
