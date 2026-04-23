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
                  title: Text(strings.localized(telugu: 'PNG', english: 'PNG')),
                  subtitle: Text(
                    strings.localized(
                      telugu: 'పారదర్శక బ్యాక్‌గ్రౌండ్, Remove BG కోసం ఉత్తమం',
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
                      telugu: 'బ్యాక్‌గ్రౌండ్‌తో PNG',
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
                  title: Text(strings.localized(telugu: 'JPG', english: 'JPG')),
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
                  'డిజైన్ లేయర్లు లేవు. అయినా కూడా బ్యాక్‌గ్రౌండ్ మాత్రమే ఎగుమతి చేయాలా?',
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
            PurchaseFlowResult.billingUnavailable =>
              'Billing service అందుబాటులో లేదు. తర్వాత మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.failed =>
              'Restore fail అయ్యింది, మళ్లీ ప్రయత్నించండి',
            PurchaseFlowResult.cancelled => 'Restore process cancel అయింది',
            PurchaseFlowResult.productNotFound =>
              'Restore చేయడానికి product details కనిపించలేదు',
            PurchaseFlowResult.timedOut =>
              'Restore response ఆలస్యం అయింది. కొద్దిసేపటి తర్వాత ప్రయత్నించండి',
            PurchaseFlowResult.nothingToRestore =>
              'Restore చేయడానికి active plan కనిపించలేదు',
            PurchaseFlowResult.success => 'Purchase restore అయ్యింది',
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
          final result = await ImageGallerySaverPlus.saveImage(
            exportedBytes,
            quality: 100,
            name: fileName,
          );
          var isSuccess = _isGallerySaveSuccess(result);
          dynamic finalResult = result;
          if (!isSuccess) {
            final tempDirectory = await getTemporaryDirectory();
            final tempPath =
                '${tempDirectory.path}${Platform.pathSeparator}$fileName';
            final tempFile = File(tempPath);
            await tempFile.writeAsBytes(exportedBytes, flush: true);
            final fallbackResult = await ImageGallerySaverPlus.saveFile(
              tempFile.path,
              name: fileName,
            );
            if (_isGallerySaveSuccess(fallbackResult)) {
              isSuccess = true;
              finalResult = fallbackResult;
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _exportResultMessage(finalResult, isSuccess: isSuccess),
                ),
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
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }
    final requested = await <Permission>[Permission.photos].request();
    return requested.values.any(
      (status) => status.isGranted || status.isLimited,
    );
  }

  bool _isGallerySaveSuccess(dynamic saveResult) {
    if (saveResult is bool) {
      return saveResult;
    }
    if (saveResult is! Map) {
      return false;
    }
    final status = saveResult['isSuccess'] ?? saveResult['success'];
    if (status is bool) {
      return status;
    }
    if (status is num) {
      return status > 0;
    }
    final normalized = status?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  String _exportResultMessage(dynamic saveResult, {required bool isSuccess}) {
    if (isSuccess) {
      return 'Poster gallery లో save అయ్యింది';
    }
    final errorText = saveResult is Map
        ? (saveResult['errorMessage']?.toString() ??
              saveResult['message']?.toString() ??
              saveResult['error']?.toString() ??
              '')
        : '';
    if (errorText.toLowerCase().contains('permission')) {
      return 'Gallery permission ఇవ్వండి, తర్వాత మళ్లీ export చేయండి';
    }
    return 'Export fail అయ్యింది, మళ్లీ ప్రయత్నించండి';
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
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}mana_poster_share.${_exportFileExtension(format)}';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);
      await Share.shareXFiles(<XFile>[
        XFile(file.path),
      ], text: 'Mana Poster తో create చేసిన నా poster');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'షేర్ కాలేదు, మళ్లీ ప్రయత్నించండి',
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
