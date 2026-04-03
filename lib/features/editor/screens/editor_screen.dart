import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mana_poster/features/editor/controllers/editor_controller.dart';
import 'package:mana_poster/features/editor/models/editor_export_models.dart';
import 'package:mana_poster/features/editor/services/editor_draft_service.dart';
import 'package:mana_poster/features/editor/services/editor_export_service.dart';
import 'package:mana_poster/features/editor/widgets/editor_bottom_panel.dart';
import 'package:mana_poster/features/editor/widgets/editor_layers_sheet.dart';
import 'package:mana_poster/features/editor/widgets/editor_stage_area.dart';
import 'package:mana_poster/features/editor/widgets/editor_top_bar.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller;
  final EditorExportService _exportService = const EditorExportService();
  final EditorDraftService _draftService = const EditorDraftService();
  final PermissionService _permissionService = PermissionService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _stageBoundaryKey = GlobalKey();
  bool _textEditorOpen = false;
  bool _layersSheetOpen = false;
  bool _isExporting = false;
  bool _isPickingPhoto = false;
  bool _isPickingBackground = false;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
    _controller.addListener(_handleControllerEvents);
    _enterEditorFullscreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreLatestDraft();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerEvents);
    _exitEditorFullscreen();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerEvents() {
    if (_controller.consumePendingPhotoPickerRequest()) {
      _pickPhotoFromGallery();
    }

    if (_controller.consumePendingBackgroundImagePickerRequest()) {
      _pickBackgroundImageFromGallery();
    }

    if (_controller.consumePendingLayersPanelRequest()) {
      _openLayersPanel();
    }

    final layerId = _controller.consumePendingFullScreenTextEditorLayerId();
    if (layerId == null || !mounted || _textEditorOpen) {
      return;
    }
    _openFullScreenTextEditor(layerId);
  }

  Future<void> _openLayersPanel() async {
    if (!mounted || _layersSheetOpen) {
      return;
    }
    _layersSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditorLayersSheet(controller: _controller),
    );
    _layersSheetOpen = false;
  }

  Future<void> _openFullScreenTextEditor(String layerId) async {
    String? existingText;
    for (final layer in _controller.textLayers) {
      if (layer.id == layerId) {
        existingText = layer.text;
        break;
      }
    }

    if (existingText == null) {
      return;
    }
    final initialText = existingText;

    _textEditorOpen = true;
    final result = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        opaque: false,
        pageBuilder: (routeContext, animation, secondaryAnimation) =>
            _FullScreenTextEditor(initialText: initialText),
      ),
    );
    _textEditorOpen = false;

    if (result != null && result.trim().isNotEmpty) {
      _controller.updateTextLayerContent(layerId, result);
    }
  }

  Future<void> _restoreLatestDraft() async {
    final payload = await _draftService.loadLatestDraft();
    if (!mounted || payload == null) {
      return;
    }
    try {
      _controller.applyDraftPayload(payload);
    } catch (_) {
      // Ignore invalid/legacy draft payloads and keep current editor state.
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    if (!mounted || _isPickingPhoto) {
      return;
    }

    _isPickingPhoto = true;
    try {
      final status = await _permissionService.requestSingle(
        AppPermissionType.photos,
      );

      if (status.isGranted || status.isLimited) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        if (!mounted || pickedFile == null || pickedFile.path.trim().isEmpty) {
          return;
        }
        await _controller.addPhotoToStage(pickedFile.path);
        return;
      }

      if (!mounted) {
        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        _showPermissionSettingsMessage();
        return;
      }

      _showResultMessage(
        'Gallery permission ఇవ్వలేదు. అవసరమైతే తర్వాత settings లో enable చేసుకోవచ్చు.',
      );
    } catch (_) {
      if (mounted) {
        _showResultMessage('Gallery ఓపెన్ కాలేదు. మళ్లీ ప్రయత్నించండి.');
      }
    } finally {
      _isPickingPhoto = false;
    }
  }

  Future<void> _pickBackgroundImageFromGallery() async {
    if (!mounted || _isPickingBackground) {
      return;
    }

    _isPickingBackground = true;
    try {
      final status = await _permissionService.requestSingle(
        AppPermissionType.photos,
      );

      if (status.isGranted || status.isLimited) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        if (!mounted || pickedFile == null || pickedFile.path.trim().isEmpty) {
          return;
        }
        _controller.setStageImageBackground(pickedFile.path);
        return;
      }

      if (!mounted) {
        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        _showPermissionSettingsMessage();
        return;
      }

      _showResultMessage(
        'Gallery permission ఇవ్వలేదు. అవసరమైతే తర్వాత settings లో enable చేసుకోవచ్చు.',
      );
    } catch (_) {
      if (mounted) {
        _showResultMessage(
          'Background image open కాలేదు. మళ్లీ ప్రయత్నించండి.',
        );
      }
    } finally {
      _isPickingBackground = false;
    }
  }

  void _showPermissionSettingsMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Gallery access settings లో allow చేయాలి.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              _permissionService.openSettings();
            },
          ),
        ),
      );
  }

  void _enterEditorFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitEditorFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _onSave() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var options = const EditorExportOptions();
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Text(
                      'ఎక్స్‌పోర్ట్ ఎంపికలు',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'స్టేజ్ మాత్రమే సేవ్ లేదా షేర్ అవుతుంది.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<EditorExportFormat>(
                      segments: const <ButtonSegment<EditorExportFormat>>[
                        ButtonSegment(
                          value: EditorExportFormat.png,
                          label: Text('PNG'),
                        ),
                        ButtonSegment(
                          value: EditorExportFormat.jpg,
                          label: Text('JPG'),
                        ),
                      ],
                      selected: <EditorExportFormat>{options.format},
                      onSelectionChanged: (selection) {
                        setState(() {
                          options = options.copyWith(format: selection.first);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Transparent Export'),
                      subtitle: const Text(
                        'PNG కి మాత్రమే మంచిగా పని చేస్తుంది',
                      ),
                      value: options.transparentBackground,
                      onChanged: options.format == EditorExportFormat.jpg
                          ? null
                          : (value) {
                              setState(() {
                                options = options.copyWith(
                                  transparentBackground: value,
                                );
                              });
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Watermark Ready'),
                      subtitle: const Text('Future slot only'),
                      value: options.enableWatermark,
                      onChanged: (value) {
                        setState(() {
                          options = options.copyWith(enableWatermark: value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: _isExporting
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await _handleExportAction(
                                    action: _ExportAction.saveToDevice,
                                    options: options,
                                  );
                                },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Save to device'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _isExporting
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await _handleExportAction(
                                    action: _ExportAction.share,
                                    options: options,
                                  );
                                },
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _isExporting
                              ? null
                              : () async {
                                  Navigator.of(context).pop();
                                  await _handleExportAction(
                                    action: _ExportAction.saveDraft,
                                    options: options,
                                  );
                                },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save draft'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleExportAction({
    required _ExportAction action,
    required EditorExportOptions options,
  }) async {
    if (_isExporting || !mounted) {
      return;
    }
    setState(() => _isExporting = true);
    _showExportLoading();
    try {
      if (action == _ExportAction.saveDraft) {
        final path = await _draftService.saveDraft(
          _controller.buildDraftPayload(),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pop();
        _showResultMessage('Draft saved: $path');
        return;
      }

      _controller.setStageExportMode(
        enabled: true,
        transparentBackground: options.transparentBackground,
      );
      await WidgetsBinding.instance.endOfFrame;
      final renderObject =
          _stageBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw StateError('Stage not ready for export.');
      }
      final result = await _exportService.exportStage(
        boundary: renderObject,
        options: options,
      );
      _controller.setStageExportMode(enabled: false);

      if (action == _ExportAction.saveToDevice) {
        await _exportService.saveToDevice(result);
        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pop();
        _showResultMessage('Poster saved successfully');
        return;
      }

      await _exportService.share(result);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      _showResultMessage('Poster ready to share');
    } catch (error) {
      _controller.setStageExportMode(enabled: false);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showResultMessage('Export failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: <Widget>[
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'ఎక్స్‌పోర్ట్ అవుతోంది...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResultMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return EditorTopBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  onUndo: _controller.undo,
                  onRedo: _controller.redo,
                  onLayers: _controller.requestLayersPanel,
                  onDelete: _controller.deleteSelectedLayer,
                  onSave: _onSave,
                  canUndo: _controller.canUndo,
                  canRedo: _controller.canRedo,
                  hasSelection: _controller.hasSelectedEditableLayer,
                );
              },
            ),
            Expanded(
              child: RepaintBoundary(
                key: _stageBoundaryKey,
                child: EditorStageArea(controller: _controller),
              ),
            ),
            EditorBottomPanel(controller: _controller),
          ],
        ),
      ),
    );
  }
}

enum _ExportAction { saveToDevice, share, saveDraft }

class _FullScreenTextEditor extends StatefulWidget {
  const _FullScreenTextEditor({required this.initialText});

  final String initialText;

  @override
  State<_FullScreenTextEditor> createState() => _FullScreenTextEditorState();
}

class _FullScreenTextEditorState extends State<_FullScreenTextEditor> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xE6FFFFFF),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'టెక్స్ట్ ఎడిట్ చేయండి',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_textController.text),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _textController,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'ఇక్కడ టెక్స్ట్ టైప్ చేయండి',
                  border: InputBorder.none,
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                'Telugu, Hindi, English typing supported',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
