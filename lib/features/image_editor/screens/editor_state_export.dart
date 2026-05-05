part of 'image_editor_screen.dart';

// ignore_for_file: unused_element

extension _EditorExportState on _ImageEditorScreenState {
  Future<ui.Image?> _loadWatermarkLogo() async {
    final existing = _watermarkLogoImage;
    if (existing != null) {
      return existing;
    }

    try {
      final assetData = await rootBundle.load(
        'assets/branding/mana_poster_logo.png',
      );
      final codec = await ui.instantiateImageCodec(
        assetData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      _watermarkLogoImage = frame.image;
      return _watermarkLogoImage;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image> _buildWatermarkedImage(
    ui.Image sourceImage, {
    required bool includeWatermark,
  }) async {
    if (!includeWatermark) {
      return sourceImage;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    canvas.drawImage(sourceImage, Offset.zero, paint);
    final logoImage = await _loadWatermarkLogo();

    final watermarkText = TextPainter(
      text: const TextSpan(
        text: 'Mana Poster',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = 14.0;
    const logoSize = 26.0;
    const logoGap = 8.0;
    final textStartOffset = logoImage == null ? 0.0 : logoSize + logoGap;
    final contentHeight = math.max(
      watermarkText.height,
      logoImage == null ? 0.0 : logoSize,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        sourceImage.width -
            watermarkText.width -
            (padding * 2) -
            textStartOffset,
        sourceImage.height - contentHeight - (padding * 2),
        watermarkText.width + (padding * 2) + textStartOffset,
        contentHeight + (padding * 2),
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
    if (logoImage != null) {
      final logoTop = rect.top + ((rect.height - logoSize) / 2);
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(
          0,
          0,
          logoImage.width.toDouble(),
          logoImage.height.toDouble(),
        ),
        Rect.fromLTWH(rect.left + padding, logoTop, logoSize, logoSize),
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }
    watermarkText.paint(
      canvas,
      Offset(
        rect.left + padding + textStartOffset,
        rect.top + ((rect.height - watermarkText.height) / 2) - 1,
      ),
    );

    final picture = recorder.endRecording();
    final output = await picture.toImage(sourceImage.width, sourceImage.height);
    sourceImage.dispose();
    return output;
  }

  Future<Uint8List> _encodeExportImageBytes(
    ui.Image image, {
    required _ExportImageFormat format,
  }) async {
    try {
      switch (format) {
        case _ExportImageFormat.png:
        case _ExportImageFormat.pngTransparent:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            throw Exception('PNG conversion failed');
          }
          return byteData.buffer.asUint8List();
        case _ExportImageFormat.jpg:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (byteData == null) {
            throw Exception('JPG conversion failed');
          }
          final encoded = img.Image.fromBytes(
            width: image.width,
            height: image.height,
            bytes: byteData.buffer,
            order: img.ChannelOrder.rgba,
          );
          return Uint8List.fromList(img.encodeJpg(encoded, quality: 95));
      }
    } finally {
      image.dispose();
    }
  }

  Future<void> _handleExportTap() async {
    if (_isCropMode) {
      return;
    }
    if (_isExporting) {
      return;
    }
    final canProceed = await _confirmExportIfCanvasEmpty();
    if (!canProceed) {
      return;
    }
    final format = _defaultExportFormat();
    await _performExport(format: format);
  }

  _ExportImageFormat _defaultExportFormat() {
    final transparentStage =
        (_canvasBackgroundColor.a * 255.0).round().clamp(0, 255) == 0 &&
        _canvasBackgroundGradientIndex < 0 &&
        _stageBackgroundImageBytes == null;
    return transparentStage
        ? _ExportImageFormat.pngTransparent
        : _ExportImageFormat.png;
  }

  Future<_ExportImageFormat?> _pickExportFormat() async {
    return showModalBottomSheet<_ExportImageFormat>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        final strings = context.strings;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.image_rounded),
                  title: Text(
                    strings.localized(telugu: 'పిఎన్‌జి', english: 'PNG'),
                  ),
                  subtitle: Text(
                    strings.localized(
                      telugu:
                          'పారదర్శక బ్యాక్‌గ్రౌండ్, బ్యాక్‌గ్రౌండ్ తీసేయడానికి ఉత్తమం',
                      english: 'Transparent background, best for Remove BG',
                    ),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ExportImageFormat.pngTransparent),
                ),
                ListTile(
                  leading: const Icon(Icons.crop_square_rounded),
                  title: Text(
                    strings.localized(
                      telugu: 'బ్యాక్‌గ్రౌండ్‌తో పిఎన్‌జి',
                      english: 'PNG with Background',
                    ),
                  ),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'పోస్టర్ లేదా స్టేజ్ బ్యాక్‌గ్రౌండ్ కూడా ఉంటుంది',
                      english: 'Includes poster/stage background',
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportImageFormat.png),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_rounded),
                  title: Text(
                    strings.localized(telugu: 'జేపీజీ', english: 'JPG'),
                  ),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'చిన్న ఫైల్ సైజ్',
                      english: 'Smaller file size',
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_ExportImageFormat.jpg),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmExportIfCanvasEmpty() async {
    if (_layers.isNotEmpty) {
      return true;
    }

    final strings = context.strings;
    final freshDecision = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            strings.localized(
              telugu: 'క్యాన్వాస్ ఖాళీగా ఉంది',
              english: 'Canvas is empty',
            ),
          ),
          content: Text(
            strings.localized(
              telugu:
                  'డిజైన్ లేయర్లు ఏవీ లేవు. బ్యాక్‌గ్రౌండ్ మాత్రమే ఎక్స్‌పోర్ట్ చేయాలనుకుంటున్నారా?',
              english:
                  'There are no design layers. Do you still want to export only the background?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                strings.localized(telugu: 'వద్దు', english: 'Cancel'),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                strings.localized(
                  telugu: 'అవును, ఎగుమతి చేయి',
                  english: 'Yes, export',
                ),
              ),
            ),
          ],
        );
      },
    );
    return freshDecision ?? false;
  }

  /*
  Future<bool> _handlePaywallAction({
    required Uint8List? previewBytes,
    required bool forExport,
  }) async {
    if (!mounted) {
      return false;
    }
    final decision = await Navigator.of(context).push<ExportPaywallDecision>(
      MaterialPageRoute<ExportPaywallDecision>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ExportPaywallScreen(
          previewBytes: previewBytes,
          isProUser: _isProUser,
          forExport: forExport,
        ),
      ),
    );
    if (!mounted ||
        decision == null ||
        decision == ExportPaywallDecision.cancel) {
      return false;
    }

    if (decision == ExportPaywallDecision.freeWithWatermark) {
      return forExport;
    }
    if (decision == ExportPaywallDecision.upgradeAndExport) {
      final outcome = await _purchaseGateway.purchaseMonthlyPro();
      final result = outcome.result;
      if (!mounted) {
        return false;
      }
      if (result == PurchaseFlowResult.success) {
        final isActivated = await _verifyEntitlementAfterPurchase(
          outcome.evidence,
        );
        if (!mounted) {
          return false;
        }
        if (!isActivated) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'ప్రో విజయవంతంగా యాక్టివ్ అయింది',
                english: 'Pro activated successfully',
              ),
            ),
          ),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            PurchaseFlowResult.cancelled => context.strings.localized(
              telugu: 'పేమెంట్ రద్దు చేశారు',
              english: 'Payment cancelled',
            ),
            PurchaseFlowResult.failed => context.strings.localized(
              telugu: 'పేమెంట్ విఫలమైంది',
              english: 'Payment failed',
            ),
            PurchaseFlowResult.billingUnavailable => context.strings.localized(
              telugu: 'బిల్లింగ్ సర్వీస్ అందుబాటులో లేదు. కొద్దిసేపటికి మళ్లీ ప్రయత్నించండి',
              english: 'Billing service unavailable. Please try again shortly',
            ),
            PurchaseFlowResult.productNotFound => context.strings.localized(
              telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్ స్టోర్‌లో కనిపించలేదు. సపోర్ట్‌ని సంప్రదించండి',
              english: 'Subscription plan not found in the store. Contact support',
            ),
            PurchaseFlowResult.timedOut => context.strings.localized(
              telugu: 'పేమెంట్ స్పందన ఆలస్యం అయింది. కొనుగోలు చరిత్ర చూసి మళ్లీ ప్రయత్నించండి',
              english: 'Payment response timed out. Check purchase history and try again',
            ),
            PurchaseFlowResult.nothingToRestore => context.strings.localized(
              telugu: 'రిస్టోర్ చేయడానికి కొనుగోలు కనిపించలేదు',
              english: 'No purchase found to restore',
            ),
            PurchaseFlowResult.success => '',
          }),
        ),
      );
      return false;
    }
    if (decision == ExportPaywallDecision.restorePurchase) {
      final restoreOutcome = await _purchaseGateway.restorePurchases();
      final restoreResult = restoreOutcome.result;
      if (!mounted) {
        return false;
      }
      if (restoreResult == PurchaseFlowResult.success) {
        final isActivated = await _verifyEntitlementAfterPurchase(
          restoreOutcome.evidence,
        );
        if (!mounted) {
          return false;
        }
        if (!isActivated) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'కొనుగోలు రిస్టోర్ అయింది',
                english: 'Purchase restored',
              ),
            ),
          ),
        );
        return forExport;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (restoreResult) {
            PurchaseFlowResult.billingUnavailable => context.strings.localized(
              telugu:
                  'బిల్లింగ్ సేవ ప్రస్తుతం అందుబాటులో లేదు. దయచేసి కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి',
              english: 'Billing service is unavailable. Please try again later.',
              hindi:
                  'बिलिंग सेवा अभी उपलब्ध नहीं है। कृपया थोड़ी देर बाद फिर से प्रयास करें।',
              tamil:
                  'பில்லிங் சேவை தற்போது கிடைக்கவில்லை. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.',
              kannada:
                  'ಬಿಲ್ಲಿಂಗ್ ಸೇವೆ ಈಗ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'ബില്ലിംഗ് സേവനം ഇപ്പോൾ ലഭ്യമല്ല. കുറച്ച് സമയത്തിന് ശേഷം വീണ്ടും ശ്രമിക്കുക.',
            ),
            PurchaseFlowResult.failed => context.strings.localized(
              telugu: 'రీస్టోర్ విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి',
              english: 'Restore failed. Please try again.',
              hindi: 'रिस्टोर विफल हुआ। कृपया फिर से प्रयास करें।',
              tamil: 'ரிஸ்டோர் தோல்வியடைந்தது. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.',
              kannada: 'ರಿಸ್ಟೋರ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'റിസ്റ്റോർ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
            ),
            PurchaseFlowResult.cancelled => context.strings.localized(
              telugu: 'రీస్టోర్ ప్రక్రియ రద్దు అయింది',
              english: 'Restore process was cancelled',
              hindi: 'रिस्टोर प्रक्रिया रद्द हो गई',
              tamil: 'ரிஸ்டோர் செயல்முறை ரத்து செய்யப்பட்டது',
              kannada: 'ರಿಸ್ಟೋರ್ ಪ್ರಕ್ರಿಯೆ ರದ್ದಾಯಿತು',
              malayalam: 'റിസ്റ്റോർ പ്രക്രിയ റദ്ദാക്കി',
            ),
            PurchaseFlowResult.productNotFound => context.strings.localized(
              telugu: 'రీస్టోర్‌కు అవసరమైన ప్రోడక్ట్ వివరాలు కనిపించలేదు',
              english: 'Product details needed for restore were not found',
              hindi: 'रिस्टोर के लिए जरूरी प्रोडक्ट विवरण नहीं मिले',
              tamil: 'ரிஸ்டோருக்கு தேவையான தயாரிப்பு விவரங்கள் கிடைக்கவில்லை',
              kannada: 'ರಿಸ್ಟೋರ್‌ಗೆ ಬೇಕಾದ ಉತ್ಪನ್ನ ವಿವರಗಳು ಸಿಗಲಿಲ್ಲ',
              malayalam: 'റിസ്റ്റോറിന് ആവശ്യമായ പ്രൊഡക്റ്റ് വിശദാംശങ്ങൾ ലഭിച്ചില്ല',
            ),
            PurchaseFlowResult.timedOut => context.strings.localized(
              telugu:
                  'రీస్టోర్ స్పందన ఆలస్యమైంది. దయచేసి కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి',
              english: 'Restore response timed out. Please try again later.',
              hindi:
                  'रिस्टोर प्रतिक्रिया में समय लग गया। कृपया थोड़ी देर बाद फिर से प्रयास करें।',
              tamil:
                  'ரிஸ்டோர் பதில் நேரம் முடிந்தது. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.',
              kannada:
                  'ರಿಸ್ಟೋರ್ ಪ್ರತಿಕ್ರಿಯೆಗೆ ಸಮಯ ಮೀರಿದೆ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'റിസ്റ്റോർ പ്രതികരണം വൈകി. കുറച്ച് സമയത്തിന് ശേഷം വീണ്ടും ശ്രമിക്കുക.',
            ),
            PurchaseFlowResult.nothingToRestore => context.strings.localized(
              telugu: 'రీస్టోర్ చేయడానికి యాక్టివ్ ప్లాన్ కనిపించలేదు',
              english: 'No active plan found to restore',
              hindi: 'रिस्टोर करने के लिए कोई एक्टिव प्लान नहीं मिला',
              tamil: 'ரிஸ்டோர் செய்ய எந்த செயலில் உள்ள திட்டமும் கிடைக்கவில்லை',
              kannada: 'ರಿಸ್ಟೋರ್ ಮಾಡಲು ಯಾವುದೇ ಸಕ್ರಿಯ ಪ್ಲಾನ್ ಸಿಗಲಿಲ್ಲ',
              malayalam: 'റിസ്റ്റോർ ചെയ്യാൻ സജീവ പ്ലാൻ കണ്ടെത്താനായില്ല',
            ),
            PurchaseFlowResult.success => context.strings.localized(
              telugu: 'కొనుగోలు రీస్టోర్ అయింది',
              english: 'Purchase restored',
              hindi: 'खरीदारी रिस्टोर हो गई',
              tamil: 'வாங்குதல் ரிஸ்டோர் செய்யப்பட்டது',
              kannada: 'ಖರೀದಿ ರಿಸ್ಟೋರ್ ಆಯಿತು',
              malayalam: 'വാങ്ങൽ റിസ്റ്റോർ ചെയ്തു',
            ),
          }),
        ),
      );
      return false;
    }
    return false;
  }

  */
  Rect _currentStageLogicalRect() {
    final canvasSize = _lastCanvasSize;
    const topInset = _canvasChromeInset;
    const bottomInset = _canvasChromeInset;
    final workspaceHeight = math.max(
      0.0,
      canvasSize.height - topInset - bottomInset,
    );
    final workspaceSize = Size(canvasSize.width, workspaceHeight);
    final hasPageSelection = _pageAspectRatio != null;
    final stageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: _pageAspectRatio!,
          )
        : workspaceSize;
    return Rect.fromCenter(
      center: Offset(canvasSize.width / 2, topInset + (workspaceHeight / 2)),
      width: stageSize.width,
      height: stageSize.height,
    );
  }

  Future<ui.Image> _cropImageToVisibleStage(
    ui.Image source, {
    required double pixelRatio,
  }) async {
    final stageRect = _currentStageLogicalRect();
    final srcRect = Rect.fromLTWH(
      stageRect.left * pixelRatio,
      stageRect.top * pixelRatio,
      stageRect.width * pixelRatio,
      stageRect.height * pixelRatio,
    );
    final outputWidth = srcRect.width.round().clamp(1, source.width);
    final outputHeight = srcRect.height.round().clamp(1, source.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      srcRect,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint(),
    );
    final cropped = await recorder.endRecording().toImage(
      outputWidth,
      outputHeight,
    );
    source.dispose();
    return cropped;
  }

  Future<ui.Image?> _captureStageImage({required double pixelRatio}) async {
    setState(() {
      _isCapturingStage = true;
    });
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        await _waitForRenderedFrame();
        if (!mounted) {
          return null;
        }
        final boundary =
            _stageRepaintKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) {
          continue;
        }
        try {
          final captured = await boundary.toImage(pixelRatio: pixelRatio);
          return _cropImageToVisibleStage(captured, pixelRatio: pixelRatio);
        } catch (_) {
          if (attempt == 1) {
            rethrow;
          }
        }
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingStage = false;
        });
      }
    }
  }

  Future<void> _waitForRenderedFrame() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (mounted) {
      await binding.endOfFrame;
    }
  }

  Future<void> _performExport({required _ExportImageFormat format}) async {
    if (_isExporting || _isCommitWorkerBusy) {
      return;
    }
    final exportPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి ఇవ్వండి, తర్వాత మళ్లీ ఎగుమతి చేయండి',
      english: 'Allow gallery permission and try exporting again',
    );
    final exportBoundaryMessage = context.strings.localized(
      telugu: 'ఎగుమతి ప్రాంతం సిద్ధంగా లేదు',
      english: 'Export boundary not ready',
    );
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    try {
      final exportedBytes = await _runQueuedCommitJob<Uint8List>(
        jobKey: 'export_${DateTime.now().microsecondsSinceEpoch}',
        label: context.strings.localized(
          telugu: 'పోస్టర్ ఎగుమతి అవుతోంది',
          english: 'Exporting poster',
        ),
        detail: context.strings.localized(
          telugu: 'ఫైనల్ అవుట్‌పుట్‌ను రెండర్ చేసి సేవ్ చేస్తోంది',
          english: 'Rendering and saving the final output',
        ),
        onStart: () {
          _isExporting = true;
        },
        onFinish: () {
          _isExporting = false;
          _isTransparentExportCapture = false;
          unawaited(ScreenSecurityService.enableSecure());
        },
        operation: () async {
          if (format == _ExportImageFormat.pngTransparent) {
            if (mounted) {
              setState(() {
                _isTransparentExportCapture = true;
              });
            } else {
              _isTransparentExportCapture = true;
            }
            await _waitForRenderedFrame();
          }
          final hasPermission = await _ensureGallerySavePermission();
          if (!hasPermission) {
            throw Exception(exportPermissionMessage);
          }
          await ScreenSecurityService.disableSecure();
          await WidgetsBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 80));
          final image = await _captureStageImage(
            pixelRatio: _exportPixelRatio(devicePixelRatio),
          );
          if (image == null) {
            throw Exception(exportBoundaryMessage);
          }
          final shouldHaveTransparentBackground =
              format == _ExportImageFormat.pngTransparent;
          final exportedBytes = await _encodeExportImageBytes(
            image,
            format: shouldHaveTransparentBackground
                ? _ExportImageFormat.png
                : format,
          );
          final fileName =
              'mana_poster_${DateTime.now().millisecondsSinceEpoch}.${_exportFileExtension(format)}';
          final tempDirectory = await getTemporaryDirectory();
          final tempPath =
              '${tempDirectory.path}${Platform.pathSeparator}$fileName';
          final tempFile = File(tempPath);
          await tempFile.writeAsBytes(exportedBytes, flush: true);
          debugPrint('editor export bytes=${exportedBytes.length}');
          final isSuccess = await MediaExportService.saveImageFileToGallery(
            tempFile.path,
            fileName: fileName,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_exportResultMessage(isSuccess: isSuccess)),
                action: isSuccess
                    ? SnackBarAction(
                        label: context.strings.localized(
                          telugu: _isSharing ? 'షేర్ అవుతోంది...' : 'షేర్',
                          english: _isSharing ? 'Sharing...' : 'Share',
                        ),
                        onPressed: _isSharing
                            ? () {}
                            : () => _shareLatestPoster(
                                exportedBytes,
                                format: format,
                              ),
                      )
                    : null,
              ),
            );
          }
          return exportedBytes;
        },
      );
      if (exportedBytes == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.localized(
                telugu: 'ఎగుమతి ఇప్పటికే జరుగుతోంది',
                english: 'Export is already in progress',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    if (Platform.isAndroid &&
        !(await MediaExportService.needsGalleryPermission())) {
      return true;
    }
    final permission = Platform.isAndroid
        ? Permission.storage
        : Permission.photos;
    final photosStatus = await permission.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[permission].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  String _exportResultMessage({required bool isSuccess}) {
    if (isSuccess) {
      return 'Poster saved to gallery';
    }
    return 'Export failed. Please try again.';
  }

  double _exportPixelRatio(double devicePixelRatio) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // Keep quality high on regular devices, and only slightly cap on very large surfaces.
    if (shortestSide >= 720) {
      return devicePixelRatio.clamp(1.0, 2.7);
    }
    return devicePixelRatio.clamp(1.0, 3.0);
  }

  Future<void> _shareLatestPoster(
    Uint8List imageBytes, {
    required _ExportImageFormat format,
  }) async {
    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });
    try {
      await ScreenSecurityService.disableSecure();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      debugPrint('editor share bytes=${imageBytes.length}');
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}mana_poster_share.${_exportFileExtension(format)}';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);
      await MediaExportService.shareImageFile(
        file.path,
        text: 'Mana Poster',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error, stackTrace) {
      debugPrint('editor share failed: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Share fail ayindi, malli prayatninchandi',
              english: 'Share failed, please try again',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
      await ScreenSecurityService.enableSecure();
    }
  }

  String _exportFileExtension(_ExportImageFormat format) {
    switch (format) {
      case _ExportImageFormat.jpg:
        return 'jpg';
      case _ExportImageFormat.png:
      case _ExportImageFormat.pngTransparent:
        return 'png';
    }
  }
}
