import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/models/background_presets.dart';
import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/image_editor/models/editor_stage_background.dart';
import 'package:mana_poster/features/image_editor/services/editor_draft_storage_service.dart';
import 'package:mana_poster/features/image_editor/screens/image_editor_screen_web.dart'
    if (dart.library.io) 'package:mana_poster/features/image_editor/screens/image_editor_screen.dart';

enum _UnitMode { pixels, inches }

enum _SetupBackgroundChoice { white, transparent, color, gradient }

enum _SetupStartChoice { psd, gallery, empty, restoreDraft }

const Color _setupBackdrop = Color(0xFF2A2C31);
const Color _setupSurface = Color(0xFF1C1E23);
const Color _setupSurfaceSoft = Color(0xFF24262B);
const Color _setupBorder = Color(0xFF3A3D45);
const Color _setupTextPrimary = Color(0xFFF1F3F4);
const Color _setupTextSecondary = Color(0xFFBDC1C6);
const Color _setupPurple = Color(0xFF7C6DFF);
const Color _setupPurpleSoft = Color(0xFF4C3FB8);

class PageSetupScreen extends StatefulWidget {
  const PageSetupScreen({super.key});

  @override
  State<PageSetupScreen> createState() => _PageSetupScreenState();
}

class _PageSetupScreenState extends State<PageSetupScreen>
    with AppLanguageStateMixin {
  bool get _showSkipAction => false;

  static const int _minCanvasPx = 320;
  static const int _maxCanvasPx = 10000;
  static const double _minInches = 1;
  static const double _maxInches = 40;
  static const int _minDpi = 72;
  static const int _maxDpi = 600;

  static const List<EditorPageConfig> _presets = <EditorPageConfig>[
    EditorPageConfig(name: '1:1', widthPx: 1080, heightPx: 1080, dpi: 300),
    EditorPageConfig(name: '4:5', widthPx: 1080, heightPx: 1350, dpi: 300),
    EditorPageConfig(name: '9:16', widthPx: 1080, heightPx: 1920, dpi: 300),
    EditorPageConfig(name: '16:9', widthPx: 1920, heightPx: 1080, dpi: 300),
    EditorPageConfig(name: 'A4 Print', widthPx: 2480, heightPx: 3508, dpi: 300),
    EditorPageConfig(
      name: 'Letter Print',
      widthPx: 2550,
      heightPx: 3300,
      dpi: 300,
    ),
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
  final ImagePicker _imagePicker = ImagePicker();
  final EditorDraftStorageService _draftStorageService =
      const EditorDraftStorageService();

  _SetupStartChoice? _selectedStartChoice;
  int? _selectedPresetIndex;
  bool _customSizeSelected = false;
  bool _pickerBusy = false;
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
    if (mounted && _customSizeSelected) {
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
    if (!_customSizeSelected) {
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
    if (!_customSizeSelected) {
      return null;
    }
    if (_customError() != null) {
      return null;
    }
    if (_unitMode == _UnitMode.pixels) {
      return EditorPageConfig(
        name: 'Custom',
        widthPx: _parsePositiveInt(_widthController.text)!,
        heightPx: _parsePositiveInt(_heightController.text)!,
        dpi: _parsePositiveInt(_dpiController.text) ?? 300,
      );
    }
    final widthIn = _parsePositiveDouble(_widthController.text)!;
    final heightIn = _parsePositiveDouble(_heightController.text)!;
    final dpi = _parsePositiveInt(_dpiController.text)!;
    return EditorPageConfig(
      name: 'Custom',
      widthPx: (widthIn * dpi).round().clamp(_minCanvasPx, _maxCanvasPx),
      heightPx: (heightIn * dpi).round().clamp(_minCanvasPx, _maxCanvasPx),
      dpi: dpi,
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

  Future<void> _openEditorWithDesignImport() async {
    if (_pickerBusy) {
      return;
    }
    _pickerBusy = true;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['psd'],
        withData: false,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final pathParts = path.split('.');
      final extension = (picked.extension ?? pathParts.last)
          .trim()
          .toLowerCase()
          .replaceFirst('.', '');
      if (extension != 'psd') {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('Select a PSD file.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageEditorScreen(
            initialStageBackground: const EditorStageBackground.transparent(),
            initialDesignImportPath: path,
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (error.code != 'already_active' && mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: const Text('Could not open the file picker.'),
          ),
        );
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _openEditorFromGallery() async {
    if (_pickerBusy) {
      return;
    }
    _pickerBusy = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (!mounted || picked == null || picked.path.trim().isEmpty) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageEditorScreen(
            initialStageBackground: const EditorStageBackground.transparent(),
            initialDesignImportPath: picked.path,
          ),
        ),
      );
    } on PlatformException catch (error) {
      if (error.code != 'already_active' &&
          error.code != 'camera_access_denied' &&
          error.code != 'photo_access_denied' &&
          error.code != 'photo_access_denied_permanently' &&
          mounted) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(
            content: const Text('Could not open image picker.'),
          ),
        );
      }
    } finally {
      _pickerBusy = false;
    }
  }

  Future<void> _restoreAutosavedDraft() async {
    try {
      final file = await _draftStorageService.getAutosaveFile();
      if (!await file.exists()) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('No autosaved draft found.')),
        );
        return;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('No autosaved draft found.')),
        );
        return;
      }
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('Draft restore failed.')),
        );
        return;
      }
      final layers = decoded['layers'];
      if (layers is! List || layers.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: const Text('No editable draft content.')),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageEditorScreen(initialDraft: decoded),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(content: const Text('Draft restore failed.')),
      );
    }
  }

  void _continueWithSelectedSource() {
    switch (_selectedStartChoice) {
      case _SetupStartChoice.psd:
        unawaited(_openEditorWithDesignImport());
        return;
      case _SetupStartChoice.gallery:
        unawaited(_openEditorFromGallery());
        return;
      case _SetupStartChoice.empty:
        _openEditor();
        return;
      case _SetupStartChoice.restoreDraft:
        unawaited(_restoreAutosavedDraft());
        return;
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final config = _resolveConfig();
    final customError = _customError();
    final unit = _unitMode == _UnitMode.pixels ? 'px' : 'in';
    final previewBackground = _resolveBackground();
    final canStart =
        _selectedStartChoice != null &&
        (_selectedStartChoice != _SetupStartChoice.empty || config != null);

    return Scaffold(
      backgroundColor: _setupBackdrop,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: <Widget>[
                  _SetupIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (_showSkipAction)
                    _SetupIconButton(
                      icon: Icons.skip_next_rounded,
                      tooltip: strings.localized(
                        telugu: 'స్కిప్',
                        english: 'Skip',
                      ),
                      onTap: () {},
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey<String>('page-setup-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 118),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Start with',
                          style: TextStyle(
                            color: _setupTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.58,
                          children: <Widget>[
                            _StartChoiceTile(
                              icon: Icons.layers_outlined,
                              label: 'PSD',
                              accentColor: const Color(0xFF38BDF8),
                              selected:
                                  _selectedStartChoice == _SetupStartChoice.psd,
                              onTap: () => setState(
                                () => _selectedStartChoice =
                                    _SetupStartChoice.psd,
                              ),
                            ),
                            _StartChoiceTile(
                              icon: Icons.photo_library_outlined,
                              label: 'Gallery',
                              accentColor: const Color(0xFF22C55E),
                              selected:
                                  _selectedStartChoice ==
                                  _SetupStartChoice.gallery,
                              onTap: () => setState(
                                () => _selectedStartChoice =
                                    _SetupStartChoice.gallery,
                              ),
                            ),
                            _StartChoiceTile(
                              icon: Icons.note_add_outlined,
                              label: 'Empty Page',
                              accentColor: const Color(0xFFF59E0B),
                              selected:
                                  _selectedStartChoice ==
                                  _SetupStartChoice.empty,
                              onTap: () => setState(
                                () => _selectedStartChoice =
                                    _SetupStartChoice.empty,
                              ),
                            ),
                            _StartChoiceTile(
                              icon: Icons.restore_rounded,
                              label: 'Restore Draft',
                              accentColor: const Color(0xFFEC4899),
                              selected:
                                  _selectedStartChoice ==
                                  _SetupStartChoice.restoreDraft,
                              onTap: () => setState(
                                () => _selectedStartChoice =
                                    _SetupStartChoice.restoreDraft,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedStartChoice ==
                            _SetupStartChoice.empty) ...<Widget>[
                          if (config != null) ...<Widget>[
                            const SizedBox(height: 18),
                            Text(
                              strings.localized(
                                telugu: 'ప్రీవ్యూ',
                                english: 'Preview',
                              ),
                              style: const TextStyle(
                                color: _setupTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _PreviewCard(
                              config: config,
                              background: previewBackground,
                              gradients: _backgroundGradients,
                            ),
                          ],
                          const SizedBox(height: 18),
                          Text(
                            strings.localized(telugu: 'సైజ్', english: 'Size'),
                            style: const TextStyle(
                              color: _setupTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _presets.length + 1,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 2.35,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final isCustom = index == _presets.length;
                              final selected = isCustom
                                  ? _customSizeSelected
                                  : _selectedPresetIndex == index;
                              final preset = isCustom ? null : _presets[index];
                              return _SizePresetTile(
                                title: isCustom
                                    ? strings.localized(
                                        telugu: 'కస్టమ్',
                                        english: 'Custom',
                                      )
                                    : preset!.name,
                                subtitle: isCustom
                                    ? strings.localized(
                                        telugu: 'Manual',
                                        english: 'Manual',
                                      )
                                    : '${preset!.widthPx} × ${preset.heightPx}',
                                selected: selected,
                                onTap: () => setState(() {
                                  _customSizeSelected = isCustom;
                                  _selectedPresetIndex = isCustom
                                      ? null
                                      : index;
                                }),
                              );
                            },
                          ),
                          if (_customSizeSelected) ...<Widget>[
                            const SizedBox(height: 12),
                            Theme(
                              data: theme.copyWith(
                                segmentedButtonTheme: SegmentedButtonThemeData(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) =>
                                              states.contains(
                                                WidgetState.selected,
                                              )
                                              ? _setupPurpleSoft.withValues(
                                                  alpha: 0.56,
                                                )
                                              : _setupSurface,
                                        ),
                                    foregroundColor:
                                        const WidgetStatePropertyAll<Color>(
                                          _setupTextPrimary,
                                        ),
                                    side:
                                        const WidgetStatePropertyAll<
                                          BorderSide
                                        >(BorderSide(color: _setupBorder)),
                                    visualDensity: VisualDensity.compact,
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
                                    fieldKey: const ValueKey<String>(
                                      'page-width-input',
                                    ),
                                    controller: _widthController,
                                    label:
                                        '${strings.localized(telugu: 'వెడల్పు', english: 'Width')} ($unit)',
                                    numberOnly: _unitMode == _UnitMode.pixels,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _Input(
                                    fieldKey: const ValueKey<String>(
                                      'page-height-input',
                                    ),
                                    controller: _heightController,
                                    label:
                                        '${strings.localized(telugu: 'ఎత్తు', english: 'Height')} ($unit)',
                                    numberOnly: _unitMode == _UnitMode.pixels,
                                  ),
                                ),
                              ],
                            ),
                            if (_unitMode == _UnitMode.inches) ...<Widget>[
                              const SizedBox(height: 8),
                              _Input(
                                fieldKey: const ValueKey<String>(
                                  'page-dpi-input',
                                ),
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
                                  color: Color(0xFFFF8A8A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          _BackgroundPickerRow(
                            choice: _backgroundChoice,
                            colorIndex: _selectedBackgroundColorIndex,
                            gradientIndex: _selectedBackgroundGradientIndex,
                            colors: _backgroundColors,
                            gradients: _backgroundGradients,
                            choiceLabel: _backgroundChoiceLabel,
                            onChoiceChanged: (choice) =>
                                setState(() => _backgroundChoice = choice),
                            onColorChanged: (index) => setState(
                              () => _selectedBackgroundColorIndex = index,
                            ),
                            onGradientChanged: (index) => setState(
                              () => _selectedBackgroundGradientIndex = index,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: _setupBackdrop,
                border: Border(top: BorderSide(color: _setupBorder)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canStart ? _continueWithSelectedSource : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _setupPurple,
                        disabledBackgroundColor: _setupSurface,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _setupTextSecondary.withValues(
                          alpha: 0.55,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: canStart ? _setupPurple : _setupBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        strings.localized(
                          telugu: 'డిజైన్ ప్రారంభించండి',
                          english: 'Start Design',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartChoiceTile extends StatelessWidget {
  const _StartChoiceTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = selected
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.34),
            _setupSurfaceSoft,
          )
        : Color.alphaBlend(accentColor.withValues(alpha: 0.16), _setupSurface);
    final borderColor = selected
        ? accentColor
        : accentColor.withValues(alpha: 0.46);
    return Material(
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: selected ? 1.4 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 27,
                color: selected ? Colors.white : accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _setupTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupIconButton extends StatelessWidget {
  const _SetupIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: _setupSurface,
        foregroundColor: _setupTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _setupBorder),
        ),
      ),
      icon: Icon(icon),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.config,
    required this.background,
    required this.gradients,
  });

  final EditorPageConfig config;
  final EditorStageBackground background;
  final List<List<Color>> gradients;

  @override
  Widget build(BuildContext context) {
    final maxPreviewHeight = MediaQuery.sizeOf(context).height * 0.34;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _setupSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _setupBorder),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxPreviewHeight,
            maxWidth: 300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: config.aspectRatio.clamp(0.2, 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background.type == EditorStageBackgroundType.color
                      ? background.color
                      : Colors.white,
                  gradient:
                      background.type == EditorStageBackgroundType.gradient
                      ? LinearGradient(
                          colors:
                              gradients[(background.gradientIndex ?? 0).clamp(
                                0,
                                gradients.length - 1,
                              )],
                        )
                      : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: background.type == EditorStageBackgroundType.transparent
                    ? CustomPaint(
                        painter: _TransparentPreviewPainter(),
                        child: const SizedBox.expand(),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizePresetTile extends StatelessWidget {
  const _SizePresetTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _setupPurpleSoft.withValues(alpha: 0.72)
              : _setupSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _setupPurple : _setupBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _setupTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _setupTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPickerRow extends StatelessWidget {
  const _BackgroundPickerRow({
    required this.choice,
    required this.colorIndex,
    required this.gradientIndex,
    required this.colors,
    required this.gradients,
    required this.choiceLabel,
    required this.onChoiceChanged,
    required this.onColorChanged,
    required this.onGradientChanged,
  });

  final _SetupBackgroundChoice choice;
  final int colorIndex;
  final int gradientIndex;
  final List<Color> colors;
  final List<List<Color>> gradients;
  final String Function(_SetupBackgroundChoice choice) choiceLabel;
  final ValueChanged<_SetupBackgroundChoice> onChoiceChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<int> onGradientChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _SetupBackgroundChoice.values.map((item) {
              final selected = choice == item;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(choiceLabel(item)),
                  selected: selected,
                  onSelected: (_) => onChoiceChanged(item),
                  side: BorderSide(
                    color: selected ? _setupPurple : _setupBorder,
                  ),
                  selectedColor: _setupPurpleSoft.withValues(alpha: 0.56),
                  backgroundColor: _setupSurface,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : _setupTextSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (choice == _SetupBackgroundChoice.color) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(colors.length, (index) {
              return _ColorDot(
                selected: index == colorIndex,
                color: colors[index],
                onTap: () => onColorChanged(index),
              );
            }),
          ),
        ],
        if (choice == _SetupBackgroundChoice.gradient) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(gradients.length, (index) {
              return _GradientDot(
                selected: index == gradientIndex,
                colors: gradients[index],
                onTap: () => onGradientChanged(index),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? _setupPurple
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2.4 : 1,
          ),
        ),
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final bool selected;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 50,
        height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _setupPurple
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2.4 : 1,
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
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.numberOnly,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool numberOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      style: const TextStyle(
        color: _setupTextPrimary,
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
        labelStyle: const TextStyle(color: _setupTextSecondary),
        filled: true,
        fillColor: _setupSurfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _setupBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _setupBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _setupPurple, width: 1.6),
        ),
      ),
    );
  }
}
