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
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Page Setup',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _skipToEditor,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.72),
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFF7F8FF),
                    Color(0xFFF8FBFF),
                    Color(0xFFFFF7FB),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0xFF93C5FD).withValues(alpha: 0.22),
                      const Color(0xFF93C5FD).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -70,
            top: 80,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      const Color(0xFFF9A8D4).withValues(alpha: 0.18),
                      const Color(0xFFF9A8D4).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF2F7FF).withValues(alpha: 0.93),
                      const Color(0xFFFFF4FA).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xE5DDE8F7)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x090F172A),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Creative canvas setup',
                        style: TextStyle(
                          color: Color(0xFF5B21B6),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose your canvas',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start fast with joyful social presets or enter exact dimensions for print and custom designs.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        height: 1.45,
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF4F8FF).withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xE3DFE7F5)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Color(0xFF60A5FA),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.crop_portrait_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Create Canvas'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _skipToEditor,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  foregroundColor: const Color(0xFF334155),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF6FAFF).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xE3DFE8F6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x070F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? <Color>[
                    const Color(0xFFEFF6FF),
                    const Color(0xFFF5F3FF),
                  ]
                : <Color>[
                    Colors.white,
                    const Color(0xFFF8FBFF),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : const Color(0xFFDCE4F0),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x123B82F6),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
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
                            ? const Color(0xFF6366F1)
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
                    color: Color(0xFF6366F1),
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
        fillColor: Colors.white.withValues(alpha: 0.84),
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
