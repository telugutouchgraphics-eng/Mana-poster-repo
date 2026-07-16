import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/features/prehome/services/community_status_service.dart';

class CommunityStatusUploadScreen extends StatefulWidget {
  const CommunityStatusUploadScreen({super.key});

  @override
  State<CommunityStatusUploadScreen> createState() =>
      _CommunityStatusUploadScreenState();
}

class _CommunityStatusUploadScreenState
    extends State<CommunityStatusUploadScreen> {
  static const List<Color> _backgroundColors = <Color>[
    Color(0xFF4CAF50),
    Color(0xFF009688),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF673AB7),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFFF44336),
    Color(0xFFFF5722),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF424242),
    Color(0xFF212121),
  ];

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  File? _selectedImageFile;
  bool _submitting = false;
  int _backgroundIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.enableSecure());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusTextEditor();
      }
    });
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.disableSecure());
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final strings = context.strings;
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d \u0c2e\u0c4a\u0c2c\u0c48\u0c32\u0c4d \u0c2f\u0c3e\u0c2a\u0c4d\u200c\u0c32\u0c4b \u0c2e\u0c3e\u0c24\u0c4d\u0c30\u0c2e\u0c47 \u0c05\u0c02\u0c26\u0c41\u0c2c\u0c3e\u0c1f\u0c41\u0c32\u0c4b \u0c09\u0c02\u0c26\u0c3f',
              english: 'Status upload is supported on mobile app only',
            ),
          ),
        ),
      );
      return;
    }
    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > CommunityStatusService.maxSourceImageBytes) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c07\u0c2e\u0c47\u0c1c\u0c4d 12MB \u0c32\u0c47\u0c26\u0c3e \u0c26\u0c3e\u0c28\u0c3f\u0c15\u0c02\u0c1f\u0c47 \u0c24\u0c15\u0c4d\u0c15\u0c41\u0c35 \u0c09\u0c02\u0c21\u0c3e\u0c32\u0c3f',
              english: 'Status image must be 12MB or less',
            ),
          ),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImageFile = file;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusTextEditor();
      }
    });
  }

  Future<void> _submit() async {
    final strings = context.strings;
    if (_submitting) {
      return;
    }
    final image = _selectedImageFile;
    final text = _textController.text.trim();
    if (image == null && text.isEmpty) {
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  '\u0c07\u0c2e\u0c47\u0c1c\u0c4d \u0c32\u0c47\u0c26\u0c3e \u0c1f\u0c46\u0c15\u0c4d\u0c38\u0c4d\u0c1f\u0c4d \u0c32\u0c4b \u0c12\u0c15\u0c1f\u0c3f \u0c07\u0c35\u0c4d\u0c35\u0c02\u0c21\u0c3f',
              english: 'Please add an image or text',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await CommunityStatusService.instance.submitStatus(
        imageFile: image,
        text: text,
        backgroundColor: _backgroundColors[_backgroundIndex].toARGB32(),
      );
      if (!mounted) {
        return;
      }
      if (!result.ok) {
        ScaffoldMessenger.of(context).showTopSnackBar(
          AppSnackBar.build(content: Text(_messageFor(result.code))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu:
                  '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d \u0c05\u0c2f\u0c3f\u0c02\u0c26\u0c3f',
              english: 'Status uploaded',
            ),
          ),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _cycleBackground() {
    setState(() {
      _backgroundIndex = (_backgroundIndex + 1) % _backgroundColors.length;
    });
  }

  void _focusTextEditor() {
    if (_submitting) {
      return;
    }
    FocusScope.of(context).requestFocus(_textFocusNode);
    _textFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  String _messageFor(CommunityStatusSubmitCode code) {
    final strings = context.strings;
    return switch (code) {
      CommunityStatusSubmitCode.success => '',
      CommunityStatusSubmitCode.loginRequired => strings.localized(
        telugu:
            '\u0c32\u0c3e\u0c17\u0c3f\u0c28\u0c4d \u0c05\u0c35\u0c38\u0c30\u0c02',
        english: 'Login required',
      ),
      CommunityStatusSubmitCode.regionRequired => strings.localized(
        telugu:
            '\u0c2e\u0c41\u0c02\u0c26\u0c41\u0c17\u0c3e \u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c4d / \u0c2f\u0c42\u0c28\u0c3f\u0c2f\u0c28\u0c4d \u0c1f\u0c46\u0c30\u0c3f\u0c1f\u0c30\u0c40 \u0c0e\u0c02\u0c2a\u0c3f\u0c15 \u0c1a\u0c47\u0c2f\u0c02\u0c21\u0c3f',
        english: 'Please select State/Union Territory first',
      ),
      CommunityStatusSubmitCode.contentRequired => strings.localized(
        telugu:
            '\u0c07\u0c2e\u0c47\u0c1c\u0c4d \u0c32\u0c47\u0c26\u0c3e \u0c1f\u0c46\u0c15\u0c4d\u0c38\u0c4d\u0c1f\u0c4d \u0c05\u0c35\u0c38\u0c30\u0c02',
        english: 'Image or text is required',
      ),
      CommunityStatusSubmitCode.textTooLong => strings.localized(
        telugu:
            '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c1f\u0c46\u0c15\u0c4d\u0c38\u0c4d\u0c1f\u0c4d 300 \u0c05\u0c15\u0c4d\u0c37\u0c30\u0c3e\u0c32 \u0c32\u0c4b\u0c2a\u0c41 \u0c09\u0c02\u0c21\u0c3e\u0c32\u0c3f',
        english: 'Status text must be 300 characters or less',
      ),
      CommunityStatusSubmitCode.imageTooLarge => strings.localized(
        telugu:
            '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c07\u0c2e\u0c47\u0c1c\u0c4d 12MB \u0c32\u0c47\u0c26\u0c3e \u0c26\u0c3e\u0c28\u0c3f\u0c15\u0c02\u0c1f\u0c47 \u0c24\u0c15\u0c4d\u0c15\u0c41\u0c35 \u0c09\u0c02\u0c21\u0c3e\u0c32\u0c3f',
        english: 'Status image must be 12MB or less',
      ),
      CommunityStatusSubmitCode.imageDailyLimitReached => strings.localized(
        telugu:
            '24 గంటల్లో 2 image statuses మాత్రమే పెట్టవచ్చు. Old image status delete చేసి మళ్లీ పెట్టండి.',
        english:
            'You can upload only 2 image statuses in 24 hours. Delete an old image status to upload again.',
      ),
      CommunityStatusSubmitCode.textDailyLimitReached => strings.localized(
        telugu:
            '24 గంటల్లో 5 text statuses మాత్రమే పెట్టవచ్చు. Old text status delete చేసి మళ్లీ పెట్టండి.',
        english:
            'You can upload only 5 text statuses in 24 hours. Delete an old text status to upload again.',
      ),
      CommunityStatusSubmitCode.uploadFailed => strings.localized(
        telugu:
            '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d \u0c05\u0c2a\u0c4d\u200c\u0c32\u0c4b\u0c21\u0c4d \u0c35\u0c3f\u0c2b\u0c32\u0c2e\u0c48\u0c02\u0c26\u0c3f. \u0c2e\u0c33\u0c4d\u0c32\u0c40 \u0c2a\u0c4d\u0c30\u0c2f\u0c24\u0c4d\u0c28\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f.',
        english: 'Status upload failed. Please try again.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final backgroundColor = _backgroundColors[_backgroundIndex];
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final controlsBottom = keyboardInset > 0 ? keyboardInset + 10 : 16.0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0B141A),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _focusTextEditor,
                child: _selectedImageFile == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(color: backgroundColor),
                      )
                    : InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Center(
                          child: Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 6,
              left: 8,
              right: 8,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.localized(
                      telugu: '\u0c38\u0c4d\u0c1f\u0c47\u0c1f\u0c38\u0c4d',
                      english: 'Status',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _submitting ? null : _cycleBackground,
                    icon: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.localized(
                      telugu: '\u0c17\u0c4d\u0c2f\u0c3e\u0c32\u0c30\u0c40',
                      english: 'Gallery',
                    ),
                    onPressed: _submitting ? null : _pickImage,
                    icon: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedImageFile == null)
              Positioned.fill(
                top: 74,
                bottom: 88,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    enabled: !_submitting,
                    autofocus: true,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    cursorColor: const Color(0xFF25D366),
                    enableInteractiveSelection: true,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(
                        CommunityStatusService.maxTextLength,
                      ),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            if (_selectedImageFile != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: 14,
                right: 82,
                bottom: controlsBottom,
                child: TextSelectionTheme(
                  data: TextSelectionTheme.of(context).copyWith(
                    cursorColor: const Color(0xFF25D366),
                    selectionColor: const Color(0x5525D366),
                    selectionHandleColor: const Color(0xFF25D366),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      enabled: !_submitting,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      cursorColor: const Color(0xFF25D366),
                      enableInteractiveSelection: true,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(
                          CommunityStatusService.maxTextLength,
                        ),
                      ],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.localized(
                          telugu:
                              '\u0c15\u0c4d\u0c2f\u0c3e\u0c2a\u0c4d\u0c37\u0c28\u0c4d \u0c30\u0c3e\u0c2f\u0c02\u0c21\u0c3f',
                          english: 'Add a caption',
                        ),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: controlsBottom,
              child: Row(
                children: <Widget>[
                  const Spacer(),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      heroTag: 'upload_status_send',
                      onPressed: _submitting ? null : _submit,
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: const Color(0xFF06251A),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF06251A),
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
