import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/background_presets.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/models/editor_stage_background.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

enum _UnitMode { pixels, inches }

enum _SetupBackgroundChoice { white, transparent, color, gradient }

class PageSetupScreen extends StatefulWidget {
  const PageSetupScreen({super.key});

  @override
  State<PageSetupScreen> createState() => _PageSetupScreenState();
}

class _PageSetupScreenState extends State<PageSetupScreen>
    with AppLanguageStateMixin {
  static const int _minCanvasPx = 320;
  static const int _maxCanvasPx = 10000;
  static const double _minInches = 1;
  static const double _maxInches = 40;
  static const int _minDpi = 72;
  static const int _maxDpi = 600;

  static const List<EditorPageConfig> _presets = <EditorPageConfig>[
    EditorPageConfig(name: '1:1', widthPx: 1080, heightPx: 1080),
    EditorPageConfig(name: '4:5', widthPx: 1080, heightPx: 1350),
    EditorPageConfig(name: '9:16', widthPx: 1080, heightPx: 1920),
    EditorPageConfig(name: '16:9', widthPx: 1920, heightPx: 1080),
  ];

  static final List<Color> _backgroundColors = <Color>[
    editorBackgroundColors[1],
    editorBackgroundColors[13],
    editorBackgroundColors[7],
    editorBackgroundColors[10],
    editorBackgroundColors[9],
    editorBackgroundColors[8],
    editorBackgroundColors[3],
    editorBackgroundColors[14],
    editorBackgroundColors[15],
  ];

  static final List<List<Color>> _backgroundGradients = <List<Color>>[
    editorBackgroundGradients[18],
    editorBackgroundGradients[16],
    editorBackgroundGradients[21],
    editorBackgroundGradients[19],
    editorBackgroundGradients[28],
    editorBackgroundGradients[20],
    editorBackgroundGradients[24],
    editorBackgroundGradients[43],
  ];

  static const List<int> _backgroundGradientPresetIndices = <int>[
    18,
    16,
    21,
    19,
    28,
    20,
    24,
    43,
  ];

  static const List<Color> _stripColors = <Color>[
    Color(0xFFE0F2FE),
    Color(0xFFDCFCE7),
    Color(0xFFFCE7F3),
    Color(0xFFFEF3C7),
    Color(0xFFEDE9FE),
  ];

  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dpiController = TextEditingController(
    text: '300',
  );

  int? _selectedPresetIndex = 0;
  _UnitMode _unitMode = _UnitMode.pixels;
  _SetupBackgroundChoice _backgroundChoice = _SetupBackgroundChoice.white;
  int _selectedBackgroundColorIndex = 1;
  int _selectedBackgroundGradientIndex = 5;

  @override
  void initState() {
    super.initState();
    _widthController.addListener(_onInputChanged);
    _heightController.addListener(_onInputChanged);
    _dpiController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _dpiController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted && _selectedPresetIndex == null) {
      setState(() {});
    }
  }

  int? _parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return (parsed == null || parsed <= 0) ? null : parsed;
  }

  String _backgroundChoiceLabel(_SetupBackgroundChoice choice) {
    final strings = context.strings;
    return switch (choice) {
      _SetupBackgroundChoice.white =>
        strings.localized(telugu: 'తెలుపు', english: 'White'),
      _SetupBackgroundChoice.transparent =>
        strings.localized(telugu: 'పారదర్శకం', english: 'Transparent'),
      _SetupBackgroundChoice.color =>
        strings.localized(telugu: 'రంగు', english: 'Color'),
      _SetupBackgroundChoice.gradient =>
        strings.localized(telugu: 'గ్రేడియెంట్', english: 'Gradient'),
    };
  }

  double? _parsePositiveDouble(String value) {
    final parsed = double.tryParse(value.trim());
    return (parsed == null || parsed <= 0) ? null : parsed;
  }

  String? _customError() {
    if (_selectedPresetIndex != null) {
      return null;
    }
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();
    if (widthText.isEmpty || heightText.isEmpty) {
      return 'Enter width and height for custom size.';
    }
    if (_unitMode == _UnitMode.pixels) {
      final width = _parsePositiveInt(widthText);
      final height = _parsePositiveInt(heightText);
      if (width == null || height == null) {
        return 'Width and height must be whole numbers.';
      }
      if (width < _minCanvasPx ||
          width > _maxCanvasPx ||
          height < _minCanvasPx ||
          height > _maxCanvasPx) {
        return 'Pixel size must be between $_minCanvasPx and $_maxCanvasPx.';
      }
      return null;
    }
    final widthIn = _parsePositiveDouble(widthText);
    final heightIn = _parsePositiveDouble(heightText);
    final dpi = _parsePositiveInt(_dpiController.text);
    if (widthIn == null || heightIn == null || dpi == null) {
      return 'Enter valid inches and DPI values.';
    }
    if (widthIn < _minInches ||
        widthIn > _maxInches ||
        heightIn < _minInches ||
        heightIn > _maxInches) {
      return 'Inches must be between $_minInches and $_maxInches.';
    }
    if (dpi < _minDpi || dpi > _maxDpi) {
      return 'DPI must be between $_minDpi and $_maxDpi.';
    }
    final widthPx = (widthIn * dpi).round();
    final heightPx = (heightIn * dpi).round();
    if (widthPx < _minCanvasPx ||
        widthPx > _maxCanvasPx ||
        heightPx < _minCanvasPx ||
        heightPx > _maxCanvasPx) {
      return 'Converted pixel size is out of range.';
    }
    return null;
  }

  EditorPageConfig? _resolveConfig() {
    if (_selectedPresetIndex != null) {
      return _presets[_selectedPresetIndex!];
    }
    if (_customError() != null) {
      return null;
    }
    if (_unitMode == _UnitMode.pixels) {
      return EditorPageConfig(
        name: 'Custom',
        widthPx: _parsePositiveInt(_widthController.text)!,
        heightPx: _parsePositiveInt(_heightController.text)!,
      );
    }
    final widthIn = _parsePositiveDouble(_widthController.text)!;
    final heightIn = _parsePositiveDouble(_heightController.text)!;
    final dpi = _parsePositiveInt(_dpiController.text)!;
    return EditorPageConfig(
      name: 'Custom',
      widthPx: (widthIn * dpi).round().clamp(_minCanvasPx, _maxCanvasPx),
      heightPx: (heightIn * dpi).round().clamp(_minCanvasPx, _maxCanvasPx),
    );
  }

  EditorStageBackground _resolveBackground() {
    return switch (_backgroundChoice) {
      _SetupBackgroundChoice.white => const EditorStageBackground.white(),
      _SetupBackgroundChoice.transparent =>
        const EditorStageBackground.transparent(),
      _SetupBackgroundChoice.color => EditorStageBackground.color(
        _backgroundColors[_selectedBackgroundColorIndex],
      ),
      _SetupBackgroundChoice.gradient => EditorStageBackground.gradient(
        _backgroundGradientPresetIndices[_selectedBackgroundGradientIndex],
      ),
    };
  }

  void _openEditor() {
    final error = _customError();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final config = _resolveConfig();
    if (config == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageEditorScreen(
          pageConfig: config,
          initialStageBackground: _resolveBackground(),
        ),
      ),
    );
  }

  void _skipToEditor() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ImageEditorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final config = _resolveConfig() ?? _presets.first;
    final customError = _customError();
    final unit = _unitMode == _UnitMode.pixels ? 'px' : 'in';
    final previewBackground = _resolveBackground();

    return Scaffold(
      backgroundColor: const Color(0xFF081126),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          strings.localized(telugu: 'New Poster', english: 'New Poster'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _skipToEditor,
            child: Text(
              strings.localized(telugu: 'స్కిప్', english: 'Skip'),
              style: const TextStyle(
                color: Color(0xFFCCFBF1),
                fontWeight: FontWeight.w700,
              ),
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
                    Color(0xFF11203D),
                    Color(0xFF0D2C3A),
                    Color(0xFF1A2443),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF472B6).withValues(alpha: 0.14),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                strings.localized(
                  telugu: 'పోస్టర్ వర్క్‌స్పేస్',
                  english: 'Poster workspace',
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.localized(
                  telugu:
                      'పేజీ సైజ్ ఎంచుకోండి, మొదటి బ్యాక్‌గ్రౌండ్ పెట్టండి, తర్వాత ఎడిటర్ ఓపెన్ చేయండి.',
                  english:
                      'Choose a page size, set the starting background, and open the editor.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFDCFCE7),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _SectionHeading(
                title: strings.localized(
                  telugu: 'క్యాన్వాస్ సైజ్',
                  english: 'Canvas Size',
                ),
                subtitle: strings.localized(
                  telugu:
                      'ప్రీసెట్ సైజులు లైట్ స్ట్రిప్స్‌గా కనిపిస్తాయి. కస్టమ్ సైజ్ ఫ్లెక్సిబుల్ లేఅవుట్ మరియు ప్రింట్ ఎగుమతికి ఉపయోగపడుతుంది.',
                  english:
                      'Preset sizes appear as light strips. Custom size works for flexible layouts and print export.',
                ),
              ),
              const SizedBox(height: 12),
              ...List<Widget>.generate(_presets.length + 1, (index) {
                final isCustom = index == _presets.length;
                final selected = isCustom
                    ? _selectedPresetIndex == null
                    : _selectedPresetIndex == index;
                final label = isCustom
                    ? strings.localized(telugu: 'కస్టమ్', english: 'Custom')
                    : _presets[index].name;
                final subtitle = isCustom
                    ? strings.localized(
                        telugu: 'మీ లేఅవుట్ కోసం ఫ్లెక్సిబుల్ సైజ్',
                        english: 'Flexible size for your own layout',
                      )
                    : '${_presets[index].widthPx} x ${_presets[index].heightPx} px';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionStrip(
                    title: label,
                    subtitle: subtitle,
                    color: _stripColors[index % _stripColors.length],
                    selected: selected,
                    onTap: () => setState(
                      () => _selectedPresetIndex = isCustom ? null : index,
                    ),
                  ),
                );
              }),
              if (_selectedPresetIndex == null) ...<Widget>[
                const SizedBox(height: 8),
                Theme(
                  data: theme.copyWith(
                    segmentedButtonTheme: SegmentedButtonThemeData(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) =>
                                  states.contains(WidgetState.selected)
                                  ? const Color(0xFF0EA5E9)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                        foregroundColor: const WidgetStatePropertyAll<Color>(
                          Colors.white,
                        ),
                        side: WidgetStateProperty.resolveWith<BorderSide?>(
                          (Set<WidgetState> states) => BorderSide(
                            color: states.contains(WidgetState.selected)
                                ? const Color(0xFF67E8F9)
                                : Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: SegmentedButton<_UnitMode>(
                    segments: <ButtonSegment<_UnitMode>>[
                      ButtonSegment<_UnitMode>(
                        value: _UnitMode.pixels,
                        label: Text(
                          strings.localized(telugu: 'పిక్సెల్స్', english: 'Pixels'),
                        ),
                      ),
                      ButtonSegment<_UnitMode>(
                        value: _UnitMode.inches,
                        label: Text(
                          strings.localized(telugu: 'ఇంచులు', english: 'Inches'),
                        ),
                      ),
                    ],
                    selected: <_UnitMode>{_unitMode},
                    onSelectionChanged: (value) =>
                        setState(() => _unitMode = value.first),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Input(
                        controller: _widthController,
                        label:
                            '${strings.localized(telugu: 'వెడల్పు', english: 'Width')} ($unit)',
                        numberOnly: _unitMode == _UnitMode.pixels,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Input(
                        controller: _heightController,
                        label:
                            '${strings.localized(telugu: 'ఎత్తు', english: 'Height')} ($unit)',
                        numberOnly: _unitMode == _UnitMode.pixels,
                      ),
                    ),
                  ],
                ),
                if (_unitMode == _UnitMode.inches) ...<Widget>[
                  const SizedBox(height: 10),
                  _Input(
                    controller: _dpiController,
                    label: 'DPI',
                    numberOnly: true,
                  ),
                ],
                if (customError != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    customError,
                    style: const TextStyle(
                      color: Color(0xFFFECACA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 18),
              _SectionHeading(
                title: strings.localized(
                  telugu: 'బ్యాక్‌గ్రౌండ్',
                  english: 'Background',
                ),
                subtitle: strings.localized(
                  telugu:
                      'ప్రతి ఎంపిక బాక్స్ కార్డుల బదులు సాఫ్ట్ స్ట్రిప్‌గా కనిపిస్తుంది.',
                  english:
                      'Each option is shown as a soft strip instead of boxed cards.',
                ),
              ),
              const SizedBox(height: 12),
              ..._SetupBackgroundChoice.values.map((choice) {
                final selected = _backgroundChoice == choice;
                final color = switch (choice) {
                  _SetupBackgroundChoice.white => const Color(0xFFF8FAFC),
                  _SetupBackgroundChoice.transparent => const Color(0xFFE0F2FE),
                  _SetupBackgroundChoice.color => const Color(0xFFDCFCE7),
                  _SetupBackgroundChoice.gradient => const Color(0xFFFCE7F3),
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionStrip(
                    title: _backgroundChoiceLabel(choice),
                    subtitle: strings.localized(
                      telugu: 'దీనిని మొదటి బ్యాక్‌గ్రౌండ్‌గా వాడేందుకు ట్యాప్ చేయండి',
                      english: 'Tap to use this as your starting background',
                    ),
                    color: color,
                    selected: selected,
                    onTap: () => setState(() => _backgroundChoice = choice),
                  ),
                );
              }),
              if (_backgroundChoice == _SetupBackgroundChoice.color) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(_backgroundColors.length, (
                    index,
                  ) {
                    final selected = index == _selectedBackgroundColorIndex;
                    return InkWell(
                      onTap: () => setState(
                        () => _selectedBackgroundColorIndex = index,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _backgroundColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF5EEAD4)
                                : Colors.white.withValues(alpha: 0.18),
                            width: selected ? 2.4 : 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              if (_backgroundChoice == _SetupBackgroundChoice.gradient) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(
                    _backgroundGradients.length,
                    (index) {
                      final selected = index == _selectedBackgroundGradientIndex;
                      return InkWell(
                        onTap: () => setState(
                          () => _selectedBackgroundGradientIndex = index,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 64,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _backgroundGradients[index],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFDE68A)
                                  : Colors.white.withValues(alpha: 0.16),
                              width: selected ? 2.4 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _SectionHeading(
                title: strings.localized(telugu: 'ప్రివ్యూ', english: 'Preview'),
                subtitle: '${config.widthPx} x ${config.heightPx} px',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 156,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: config.aspectRatio.clamp(0.2, 5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            previewBackground.type ==
                                EditorStageBackgroundType.color
                            ? previewBackground.color
                            : Colors.white,
                        gradient:
                            previewBackground.type ==
                                EditorStageBackgroundType.gradient
                            ? LinearGradient(
                                colors:
                                    _backgroundGradients[(previewBackground
                                                .gradientIndex ??
                                            0)
                                        .clamp(
                                          0,
                                          _backgroundGradients.length - 1,
                                        )],
                              )
                            : null,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          previewBackground.type ==
                              EditorStageBackgroundType.transparent
                          ? CustomPaint(
                              painter: _TransparentPreviewPainter(),
                              child: const SizedBox.expand(),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _resolveConfig() != null ? _openEditor : null,
                child: Text(
                  strings.localized(
                    telugu: 'Start Design',
                    english: 'Start Design',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFFBFDBFE),
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SelectionStrip extends StatelessWidget {
  const _SelectionStrip({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.95)
                  : color.withValues(alpha: 0.95),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x220F172A),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: const Color(0xFF0F172A),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransparentPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 12.0;
    final light = Paint()..color = const Color(0xFFF8FAFC);
    final dark = Paint()..color = const Color(0xFFE2E8F0);
    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final isDark = ((x / tileSize).floor() + (y / tileSize).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.numberOnly,
  });

  final TextEditingController controller;
  final String label;
  final bool numberOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      keyboardType: numberOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: numberOnly
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ]
          : <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}$|^\d*$'),
              ),
            ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFCCFBF1)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF5EEAD4), width: 1.6),
        ),
      ),
    );
  }
}
