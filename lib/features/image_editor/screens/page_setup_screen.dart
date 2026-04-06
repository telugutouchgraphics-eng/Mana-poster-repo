import 'package:flutter/material.dart';

import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

enum _UnitMode { pixels, inches }

class PageSetupScreen extends StatefulWidget {
  const PageSetupScreen({super.key});

  @override
  State<PageSetupScreen> createState() => _PageSetupScreenState();
}

class _PageSetupScreenState extends State<PageSetupScreen> {
  static const List<EditorPageConfig> _presets = <EditorPageConfig>[
    EditorPageConfig(name: 'Instagram Post', widthPx: 1080, heightPx: 1080),
    EditorPageConfig(name: 'Instagram Story', widthPx: 1080, heightPx: 1920),
    EditorPageConfig(name: 'YouTube Thumbnail', widthPx: 1280, heightPx: 720),
    EditorPageConfig(name: 'Facebook Post', widthPx: 1200, heightPx: 630),
    EditorPageConfig(name: 'WhatsApp Status', widthPx: 1080, heightPx: 1920),
    EditorPageConfig(name: 'A4 Portrait', widthPx: 2480, heightPx: 3508),
    EditorPageConfig(name: 'A4 Landscape', widthPx: 3508, heightPx: 2480),
    EditorPageConfig(name: 'A3 Portrait', widthPx: 3508, heightPx: 4961),
    EditorPageConfig(name: 'A3 Landscape', widthPx: 4961, heightPx: 3508),
  ];

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dpiController = TextEditingController(text: '300');

  int? _selectedPresetIndex;
  _UnitMode _unitMode = _UnitMode.pixels;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _dpiController.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    setState(() {
      _selectedPresetIndex = _selectedPresetIndex == index ? null : index;
    });
  }

  int _parseInt(String input, int fallback) {
    final value = int.tryParse(input.trim());
    return value == null || value <= 0 ? fallback : value;
  }

  double _parseDouble(String input, double fallback) {
    final value = double.tryParse(input.trim());
    return value == null || value <= 0 ? fallback : value;
  }

  EditorPageConfig? _resolveConfig() {
    if (_selectedPresetIndex != null) {
      return _presets[_selectedPresetIndex!];
    }

    if (_widthController.text.trim().isEmpty ||
        _heightController.text.trim().isEmpty) {
      return null;
    }

    if (_unitMode == _UnitMode.pixels) {
      final width = _parseInt(_widthController.text, 1080).clamp(320, 10000);
      final height = _parseInt(_heightController.text, 1080).clamp(320, 10000);
      return EditorPageConfig(
        name: 'Custom ${width}x$height px',
        widthPx: width,
        heightPx: height,
      );
    }

    final widthIn = _parseDouble(_widthController.text, 4);
    final heightIn = _parseDouble(_heightController.text, 4);
    final dpi = _parseDouble(_dpiController.text, 300).clamp(72, 600);
    final widthPx = (widthIn * dpi).round().clamp(320, 10000);
    final heightPx = (heightIn * dpi).round().clamp(320, 10000);
    return EditorPageConfig(
      name: 'Custom ${widthIn}x$heightIn in @${dpi.round()}dpi',
      widthPx: widthPx,
      heightPx: heightPx,
    );
  }

  void _openEditor() {
    final config = _resolveConfig();
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset select cheyyandi lekapothe custom size ivvandi'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageEditorScreen(pageConfig: config),
      ),
    );
  }

  void _skipToEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ImageEditorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = _unitMode == _UnitMode.pixels ? 'px' : 'in';
    final resolved = _resolveConfig();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('Page Setup'),
        actions: <Widget>[
          TextButton(
            onPressed: _skipToEditor,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Choose your canvas',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start with a social preset, print size, or enter exact custom dimensions like Photoshop.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SetupSection(
            title: 'Quick Presets',
            subtitle: 'Social media and print-ready sizes',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(_presets.length, (index) {
                final preset = _presets[index];
                final selected = _selectedPresetIndex == index;
                return _PresetCard(
                  preset: preset,
                  selected: selected,
                  onTap: () => _applyPreset(index),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _SetupSection(
            title: 'Custom Setup',
            subtitle: 'Manual size input in pixels or inches',
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_UnitMode>(
                    segments: const <ButtonSegment<_UnitMode>>[
                      ButtonSegment<_UnitMode>(
                        value: _UnitMode.pixels,
                        label: Text('Pixels'),
                      ),
                      ButtonSegment<_UnitMode>(
                        value: _UnitMode.inches,
                        label: Text('Inches'),
                      ),
                    ],
                    selected: <_UnitMode>{_unitMode},
                    style: const ButtonStyle(
                      side: WidgetStatePropertyAll<BorderSide>(
                        BorderSide(color: Color(0xFFD8E2F0)),
                      ),
                    ),
                    onSelectionChanged: (value) {
                      setState(() => _unitMode = value.first);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StyledInput(
                        controller: _widthController,
                        label: 'Width ($unitLabel)',
                        onChanged: (_) {
                          if (_selectedPresetIndex != null) {
                            setState(() => _selectedPresetIndex = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StyledInput(
                        controller: _heightController,
                        label: 'Height ($unitLabel)',
                        onChanged: (_) {
                          if (_selectedPresetIndex != null) {
                            setState(() => _selectedPresetIndex = null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_unitMode == _UnitMode.inches) ...<Widget>[
                  const SizedBox(height: 12),
                  _StyledInput(
                    controller: _dpiController,
                    label: 'DPI',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.crop_portrait_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        resolved == null ? 'No canvas selected' : resolved.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resolved == null
                            ? 'Skip cheste empty editor open avutundi'
                            : '${resolved.widthPx} x ${resolved.heightPx} px',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openEditor,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Create Canvas'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _skipToEditor,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFD8E2F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Skip & Open Editor'),
          ),
        ],
      ),
    );
  }
}

class _SetupSection extends StatelessWidget {
  const _SetupSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final EditorPageConfig preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewRatio = preset.widthPx / preset.heightPx;
    final portrait = previewRatio < 1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 162,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFDCE4F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE4F0)),
                  ),
                  child: Center(
                    child: Container(
                      width: portrait ? 15 : 22,
                      height: portrait ? 24 : 16,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Color(0xFF1D4ED8),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              preset.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${preset.widthPx} x ${preset.heightPx}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  const _StyledInput({
    required this.controller,
    required this.label,
    this.onChanged,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E2F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E2F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
        ),
      ),
    );
  }
}
