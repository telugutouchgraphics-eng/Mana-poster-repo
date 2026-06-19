import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/background_presets.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/models/editor_stage_background.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen_web.dart'
    if (dart.library.io) 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

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

  double? _parsePositiveDouble(String value) {
    final parsed = double.tryParse(value.trim());
    return (parsed == null || parsed <= 0) ? null : parsed;
  }

  String _backgroundChoiceLabel(_SetupBackgroundChoice choice) {
    final strings = context.strings;
    return switch (choice) {
      _SetupBackgroundChoice.white => strings.localized(
        telugu: 'తెలుపు',
        english: 'White',
      ),
      _SetupBackgroundChoice.transparent => strings.localized(
        telugu: 'పారదర్శకం',
        english: 'Transparent',
      ),
      _SetupBackgroundChoice.color => strings.localized(
        telugu: 'రంగు',
        english: 'Color',
      ),
      _SetupBackgroundChoice.gradient => strings.localized(
        telugu: 'గ్రేడియెంట్',
        english: 'Gradient',
      ),
    };
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
      ).showTopSnackBar(AppSnackBar.build(content: Text(error)));
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
    final canStart = _resolveConfig() != null;

    return Scaffold(
      body: GradientShell(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF8FAFC),
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF14B8A6),
                                    Color(0xFF38BDF8),
                                    Color(0xFFA78BFA),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _skipToEditor,
                            child: Text(
                              strings.localized(
                                telugu: 'స్కిప్',
                                english: 'Skip',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF0EA5E9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        strings.localized(
                          telugu: 'కొత్త పోస్టర్',
                          english: 'New Poster',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.localized(
                          telugu:
                              'సైజ్, బ్యాక్‌గ్రౌండ్ ఎంచుకుని డిజైన్ ప్రారంభించండి.',
                          english:
                              'Pick size and background, then start your design.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        strings.localized(
                          telugu: 'పేజీ సెటప్',
                          english: 'Page Setup',
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.localized(
                          telugu:
                              'సైజ్, బ్యాక్‌గ్రౌండ్ ఎంచుకుని స్టార్ట్ చేయండి.',
                          english: 'Pick size and background, then start.',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        strings.localized(telugu: 'సైజ్', english: 'Size'),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(_presets.length + 1, (
                          index,
                        ) {
                          final isCustom = index == _presets.length;
                          final selected = isCustom
                              ? _selectedPresetIndex == null
                              : _selectedPresetIndex == index;
                          final label = isCustom
                              ? strings.localized(
                                  telugu: 'కస్టమ్',
                                  english: 'Custom',
                                )
                              : _presets[index].name;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => setState(
                              () => _selectedPresetIndex = isCustom
                                  ? null
                                  : index,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFFCBD5E1),
                            ),
                            selectedColor: const Color(0xFFE0F2FE),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            showCheckmark: false,
                          );
                        }),
                      ),
                      if (_selectedPresetIndex == null) ...<Widget>[
                        const SizedBox(height: 14),
                        Theme(
                          data: theme.copyWith(
                            segmentedButtonTheme: SegmentedButtonThemeData(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) =>
                                          states.contains(WidgetState.selected)
                                          ? const Color(0xFFE0F2FE)
                                          : Colors.white,
                                    ),
                                foregroundColor:
                                    const WidgetStatePropertyAll<Color>(
                                      Color(0xFF0F172A),
                                    ),
                                side: const WidgetStatePropertyAll<BorderSide>(
                                  BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          ),
                          child: SegmentedButton<_UnitMode>(
                            segments: <ButtonSegment<_UnitMode>>[
                              ButtonSegment<_UnitMode>(
                                value: _UnitMode.pixels,
                                label: Text(
                                  strings.localized(
                                    telugu: 'పిక్సెల్స్',
                                    english: 'Pixels',
                                  ),
                                ),
                              ),
                              ButtonSegment<_UnitMode>(
                                value: _UnitMode.inches,
                                label: Text(
                                  strings.localized(
                                    telugu: 'ఇంచులు',
                                    english: 'Inches',
                                  ),
                                ),
                              ),
                            ],
                            selected: <_UnitMode>{_unitMode},
                            onSelectionChanged: (value) =>
                                setState(() => _unitMode = value.first),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          const SizedBox(height: 8),
                          Text(
                            customError,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      Text(
                        strings.localized(
                          telugu: 'బ్యాక్‌గ్రౌండ్',
                          english: 'Background',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _SetupBackgroundChoice.values.map((choice) {
                          final selected = _backgroundChoice == choice;
                          return ChoiceChip(
                            label: Text(_backgroundChoiceLabel(choice)),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _backgroundChoice = choice),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF14B8A6)
                                  : const Color(0xFFCBD5E1),
                            ),
                            selectedColor: const Color(0xFFECFEFF),
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      if (_backgroundChoice ==
                          _SetupBackgroundChoice.color) ...<Widget>[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List<Widget>.generate(
                            _backgroundColors.length,
                            (index) {
                              final selected =
                                  index == _selectedBackgroundColorIndex;
                              return InkWell(
                                onTap: () => setState(
                                  () => _selectedBackgroundColorIndex = index,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _backgroundColors[index],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFFCBD5E1),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (_backgroundChoice ==
                          _SetupBackgroundChoice.gradient) ...<Widget>[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List<Widget>.generate(
                            _backgroundGradients.length,
                            (index) {
                              final selected =
                                  index == _selectedBackgroundGradientIndex;
                              return InkWell(
                                onTap: () => setState(
                                  () =>
                                      _selectedBackgroundGradientIndex = index,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 56,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _backgroundGradients[index],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFFCBD5E1),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            strings.localized(
                              telugu: 'ప్రీవ్యూ',
                              english: 'Preview',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${config.widthPx} x ${config.heightPx} px',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
                                color: const Color(0xFFD7E2EE),
                              ),
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
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: strings.localized(
                          telugu: 'డిజైన్ ప్రారంభించండి',
                          english: 'Start Design',
                        ),
                        onPressed: canStart ? _openEditor : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
      ),
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
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF0EA5E9), width: 1.6),
        ),
      ),
    );
  }
}
