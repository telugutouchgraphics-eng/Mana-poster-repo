part of 'image_editor_screen.dart';

// ignore_for_file: unused_element

extension _EditorExportState on _ImageEditorScreenState {
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _debugLogStack(String message, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    debugPrintStack(stackTrace: stackTrace);
  }

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
        text: 'Mana Poster Ai',
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
    required int dpi,
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
          return _withPngDpiMetadata(byteData.buffer.asUint8List(), dpi: dpi);
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
          return _withJpegDpiMetadata(
            Uint8List.fromList(img.encodeJpg(encoded, quality: 100)),
            dpi: dpi,
          );
        case _ExportImageFormat.psd:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (byteData == null) {
            throw Exception('PSD conversion failed');
          }
          return compute(_encodeFlattenedPsdFromRgba, <String, Object?>{
            'width': image.width,
            'height': image.height,
            'rgba': byteData.buffer.asUint8List(),
          });
        case _ExportImageFormat.pdf:
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            throw Exception('PDF conversion failed');
          }
          final pngBytes = byteData.buffer.asUint8List();
          final document = pw.Document();
          final pageWidth = image.width.toDouble();
          final pageHeight = image.height.toDouble();
          document.addPage(
            pw.Page(
              pageFormat: pdf.PdfPageFormat(pageWidth, pageHeight),
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) => pw.SizedBox(
                width: pageWidth,
                height: pageHeight,
                child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.fill),
              ),
            ),
          );
          return document.save();
      }
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List> _imageToRawRgbaBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw Exception('Raw RGBA conversion failed');
      }
      return Uint8List.fromList(byteData.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List> _captureLayeredPsdExportBytes({
    required double devicePixelRatio,
  }) async {
    final originalLayers = List<_CanvasLayer>.of(_layers);
    final originalSelectedLayerId = _selectedLayerId;
    final originalTransparentCapture = _isTransparentExportCapture;
    final targetLayers = originalLayers
        .where((layer) => !layer.isHidden)
        .toList(growable: false);
    if (targetLayers.isEmpty) {
      throw Exception('No visible layers to export as PSD');
    }

    final payloadLayers = <Map<String, Object?>>[];
    Uint8List? mergedRgba;
    int? exportWidth;
    int? exportHeight;
    try {
      await ScreenSecurityService.disableSecure();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final mergedImage = await _captureStageImage(
        pixelRatio: _exportPixelRatio(devicePixelRatio),
      );
      if (mergedImage == null) {
        throw Exception('Export boundary not ready');
      }
      final normalizedMerged = await _normalizeExportImageSize(mergedImage);
      exportWidth = normalizedMerged.width;
      exportHeight = normalizedMerged.height;
      mergedRgba = await _imageToRawRgbaBytes(normalizedMerged);

      if (_hasVisibleExportBackground()) {
        setState(() {
          _layers
            ..clear()
            ..addAll(
              originalLayers.map((layer) => layer.copyWith(isHidden: true)),
            );
          _selectedLayerId = null;
          _isTransparentExportCapture = false;
        });
        await _waitForRenderedFrame();
        final backgroundImage = await _captureStageImage(
          pixelRatio: _exportPixelRatio(devicePixelRatio),
        );
        if (backgroundImage != null) {
          final normalizedBackground = await _normalizeExportImageSize(
            backgroundImage,
          );
          payloadLayers.add(<String, Object?>{
            'name': 'Background',
            'rgba': await _imageToRawRgbaBytes(normalizedBackground),
          });
        }
      }

      for (final targetLayer in targetLayers) {
        if (!mounted) {
          throw Exception('PSD export cancelled');
        }
        final isolatedLayers = originalLayers
            .map(
              (layer) => layer.copyWith(
                isHidden: layer.id != targetLayer.id || targetLayer.isHidden,
              ),
            )
            .toList(growable: false);
        setState(() {
          _layers
            ..clear()
            ..addAll(isolatedLayers);
          _selectedLayerId = targetLayer.id;
          _isTransparentExportCapture = true;
        });
        await _waitForRenderedFrame();
        final layerImage = await _captureStageImage(
          pixelRatio: _exportPixelRatio(devicePixelRatio),
        );
        if (layerImage == null) {
          continue;
        }
        final normalizedLayer = await _normalizeExportImageSize(layerImage);
        final layerRgba = await _imageToRawRgbaBytes(normalizedLayer);
        payloadLayers.add(<String, Object?>{
          'name': _exportLayerName(targetLayer),
          'rgba': layerRgba,
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _layers
            ..clear()
            ..addAll(originalLayers);
          _selectedLayerId = originalSelectedLayerId;
          _isTransparentExportCapture = originalTransparentCapture;
        });
        await _waitForRenderedFrame();
      } else {
        _layers
          ..clear()
          ..addAll(originalLayers);
        _selectedLayerId = originalSelectedLayerId;
        _isTransparentExportCapture = originalTransparentCapture;
      }
    }

    if (payloadLayers.isEmpty) {
      throw Exception('PSD export failed');
    }
    return compute(_encodeLayeredPsdFromRgbaPayload, <String, Object?>{
      'width': exportWidth,
      'height': exportHeight,
      'mergedRgba': mergedRgba,
      'layers': payloadLayers,
    });
  }

  bool _hasVisibleExportBackground() {
    return (_canvasBackgroundColor.a * 255.0).round().clamp(0, 255) > 0 ||
        _canvasBackgroundGradientIndex >= 0 ||
        _stageBackgroundImageBytes != null;
  }

  String _exportLayerName(_CanvasLayer layer) {
    final customName = layer.layerName.trim();
    if (customName.isNotEmpty) {
      return customName;
    }
    if (layer.isText) {
      final text = layer.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text.length > 31 ? text.substring(0, 31) : text;
      }
      return 'Text Layer';
    }
    if (layer.isSticker) {
      return 'Sticker Layer';
    }
    return 'Photo Layer';
  }

  int _exportDpi({_ExportImageFormat? format}) {
    final config = _effectiveExportPageConfig;
    if (config == null) {
      return 300;
    }
    final targetSize = _exportTargetPixelSize(format: format);
    final scale = targetSize == null
        ? 1.0
        : targetSize.width / math.max(1, config.widthPx);
    return (config.dpi * scale).round().clamp(72, 600).toInt();
  }

  Future<ui.Image> _normalizeExportImageSize(
    ui.Image source, {
    _ExportImageFormat? format,
  }) async {
    final config = _effectiveExportPageConfig;
    final targetSize = _exportTargetPixelSize(format: format);
    if (config == null || targetSize == null) {
      return source;
    }
    if (source.width == targetSize.width &&
        source.height == targetSize.height) {
      return source;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      Rect.fromLTWH(
        0,
        0,
        targetSize.width.toDouble(),
        targetSize.height.toDouble(),
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
    final resized = await recorder.endRecording().toImage(
      targetSize.width,
      targetSize.height,
    );
    source.dispose();
    return resized;
  }

  ({int width, int height})? _exportTargetPixelSize({
    _ExportImageFormat? format,
  }) {
    final config = _effectiveExportPageConfig;
    if (config == null) {
      return null;
    }
    final shouldBoostRaster =
        format == _ExportImageFormat.png ||
        format == _ExportImageFormat.pngTransparent ||
        format == _ExportImageFormat.jpg;
    return _calculateExportTargetPixelSize(
      widthPx: config.widthPx,
      heightPx: config.heightPx,
      shouldBoostRaster: shouldBoostRaster,
      preservePixels: _preserveDesignExportPixels && _designPageConfig != null,
    );
  }

  EditorPageConfig? get _effectiveExportPageConfig =>
      _designPageConfig ?? widget.pageConfig;

  Uint8List _withPngDpiMetadata(Uint8List bytes, {required int dpi}) {
    if (bytes.length < 33 ||
        bytes[0] != 0x89 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x4E ||
        bytes[3] != 0x47) {
      return bytes;
    }
    final pixelsPerMeter = (dpi / 0.0254).round();
    final chunk = BytesBuilder();
    final length = ByteData(4)..setUint32(0, 9);
    final data = ByteData(9)
      ..setUint32(0, pixelsPerMeter)
      ..setUint32(4, pixelsPerMeter)
      ..setUint8(8, 1);
    final type = Uint8List.fromList(<int>[0x70, 0x48, 0x59, 0x73]); // pHYs
    final crcInput = BytesBuilder()
      ..add(type)
      ..add(data.buffer.asUint8List());
    final crc = ByteData(4)..setUint32(0, _crc32(crcInput.toBytes()));
    chunk
      ..add(length.buffer.asUint8List())
      ..add(type)
      ..add(data.buffer.asUint8List())
      ..add(crc.buffer.asUint8List());

    final output = BytesBuilder()
      ..add(bytes.sublist(0, 33))
      ..add(chunk.toBytes())
      ..add(bytes.sublist(33));
    return output.toBytes();
  }

  Uint8List _withJpegDpiMetadata(Uint8List bytes, {required int dpi}) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes;
    }
    final normalizedDpi = dpi.clamp(1, 65535).toInt();
    final segment = Uint8List(18);
    segment[0] = 0xFF;
    segment[1] = 0xE0;
    segment[2] = 0x00;
    segment[3] = 0x10;
    segment[4] = 0x4A;
    segment[5] = 0x46;
    segment[6] = 0x49;
    segment[7] = 0x46;
    segment[8] = 0x00;
    segment[9] = 0x01;
    segment[10] = 0x02;
    segment[11] = 0x01;
    segment[12] = (normalizedDpi >> 8) & 0xFF;
    segment[13] = normalizedDpi & 0xFF;
    segment[14] = (normalizedDpi >> 8) & 0xFF;
    segment[15] = normalizedDpi & 0xFF;
    segment[16] = 0;
    segment[17] = 0;

    var insertOffset = 2;
    if (bytes.length > 20 &&
        bytes[2] == 0xFF &&
        bytes[3] == 0xE0 &&
        bytes[6] == 0x4A &&
        bytes[7] == 0x46 &&
        bytes[8] == 0x49 &&
        bytes[9] == 0x46) {
      final oldLength = (bytes[4] << 8) | bytes[5];
      insertOffset = 2 + 2 + oldLength;
    }
    final output = BytesBuilder()
      ..add(bytes.sublist(0, 2))
      ..add(segment)
      ..add(bytes.sublist(insertOffset));
    return output.toBytes();
  }

  int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (0xEDB88320 ^ (crc >> 1)) : (crc >> 1);
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  Future<void> _handleDownloadTap() async {
    if (_isCropMode) {
      return;
    }
    if (_isExporting) {
      return;
    }
    final hasAccess = await _ensureExportActionAccess('download');
    if (!mounted || !hasAccess) {
      return;
    }
    final canProceed = await _confirmExportIfCanvasEmpty();
    if (!mounted || !canProceed) {
      return;
    }
    final format = _defaultExportFormat();
    await _performExport(format: format);
  }

  Future<void> _handleExportTap() async {
    if (_isCropMode || _isExporting || _isCommitWorkerBusy) {
      return;
    }
    final hasAccess = await _ensureExportActionAccess('export');
    if (!mounted || !hasAccess) {
      return;
    }
    final canProceed = await _confirmExportIfCanvasEmpty();
    if (!mounted || !canProceed) {
      return;
    }
    final format = await _pickExportFormat();
    if (!mounted || format == null) {
      return;
    }
    await _performExport(format: format);
  }

  Future<void> _handleShareTap() async {
    if (_isCropMode || _isSharing || _isExporting || _isCommitWorkerBusy) {
      return;
    }
    final hasAccess = await _ensureExportActionAccess('share');
    if (!mounted || !hasAccess) {
      return;
    }
    final canProceed = await _confirmExportIfCanvasEmpty();
    if (!mounted || !canProceed) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    final format = _defaultExportFormat();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final shareBoundaryNotReadyMessage = strings.localized(
      telugu: 'షేర్ ప్రాంతం సిద్ధంగా లేదు',
      english: 'Share boundary not ready',
    );
    final shareInProgressMessage = strings.localized(
      telugu: 'షేర్ ఇప్పటికే జరుగుతోంది',
      english: 'Share is already in progress',
    );
    try {
      final sharedBytes = await _runQueuedCommitJob<Uint8List>(
        jobKey: 'share_${DateTime.now().microsecondsSinceEpoch}',
        label: strings.localized(
          telugu: 'పోస్టర్ షేర్ అవుతోంది',
          english: 'Sharing poster',
        ),
        detail: strings.localized(
          telugu: 'ఫైనల్ అవుట్‌పుట్‌ను రెండర్ చేసి షేర్ చేస్తోంది',
          english: 'Rendering and sharing the final output',
        ),
        onStart: () {
          _isSharing = true;
        },
        onFinish: () {
          _isSharing = false;
          _isTransparentExportCapture = false;
          unawaited(ScreenSecurityService.enableSecure());
        },
        operation: () async {
          await _prepareCanvasForFinalExport();
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
          await ScreenSecurityService.disableSecure();
          await WidgetsBinding.instance.endOfFrame;
          await Future<void>.delayed(const Duration(milliseconds: 80));
          final image = await _captureStageImage(
            pixelRatio: _exportPixelRatio(devicePixelRatio, format: format),
          );
          if (image == null) {
            throw Exception(shareBoundaryNotReadyMessage);
          }
          final preparedImage = await _normalizeExportImageSize(
            image,
            format: format,
          );
          final bytes = await _encodeExportImageBytes(
            preparedImage,
            format: format == _ExportImageFormat.pngTransparent
                ? _ExportImageFormat.png
                : format,
            dpi: _exportDpi(format: format),
          );
          await _shareLatestPoster(
            bytes,
            format: format,
            recheckAccess: false,
            bypassSharingGuard: true,
            manageSharingState: false,
          );
          return bytes;
        },
      );
      if (sharedBytes == null && mounted) {
        messenger.showTopSnackBar(
          AppSnackBar.build(content: Text(shareInProgressMessage)),
        );
      }
    } catch (error, stackTrace) {
      _debugLogStack('editor share outer failed: $error', stackTrace);
      if (!mounted) {
        return;
      }
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (BuildContext context) {
        final strings = context.strings;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: _editorChromeSurfaceStrong.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ListTileTheme(
              data: const ListTileThemeData(
                iconColor: Color(0xFF38BDF8),
                textColor: _editorChromeTextPrimary,
                titleTextStyle: TextStyle(
                  color: _editorChromeTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                subtitleTextStyle: TextStyle(
                  color: _editorChromeTextSecondary,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  ListTile(
                    iconColor: const Color(0xFF38BDF8),
                    textColor: _editorChromeTextPrimary,
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
                    iconColor: const Color(0xFF38BDF8),
                    textColor: _editorChromeTextPrimary,
                    leading: const Icon(Icons.crop_square_rounded),
                    title: Text(
                      strings.localized(
                        telugu: 'బ్యాక్‌గ్రౌండ్‌తో పిఎన్‌జి',
                        english: 'PNG with Background',
                      ),
                    ),
                    subtitle: Text(
                      strings.localized(
                        telugu:
                            'పోస్టర్ లేదా స్టేజ్ బ్యాక్‌గ్రౌండ్ కూడా ఉంటుంది',
                        english: 'Includes poster/stage background',
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_ExportImageFormat.png),
                  ),
                  ListTile(
                    iconColor: const Color(0xFF38BDF8),
                    textColor: _editorChromeTextPrimary,
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
                  ListTile(
                    iconColor: const Color(0xFF38BDF8),
                    textColor: _editorChromeTextPrimary,
                    leading: const Icon(Icons.layers_rounded),
                    title: Text(
                      strings.localized(telugu: 'పీఎస్డీ', english: 'PSD'),
                    ),
                    subtitle: Text(
                      strings.localized(
                        telugu: 'ఫోటోషాప్ ఫైల్',
                        english: 'Photoshop file',
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_ExportImageFormat.psd),
                  ),
                  ListTile(
                    iconColor: const Color(0xFF38BDF8),
                    textColor: _editorChromeTextPrimary,
                    leading: const Icon(Icons.picture_as_pdf_rounded),
                    title: Text(
                      strings.localized(telugu: 'పీడీఎఫ్', english: 'PDF'),
                    ),
                    subtitle: Text(
                      strings.localized(
                        telugu: 'అసలు రేషియోతో ప్రింట్ ఫైల్',
                        english: 'Print file with original ratio',
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_ExportImageFormat.pdf),
                  ),
                ],
              ),
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
          backgroundColor: _editorChromeSurfaceStrong.withValues(alpha: 0.75),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
            ),
          ),
          titleTextStyle: const TextStyle(
            color: _editorChromeTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          contentTextStyle: const TextStyle(
            color: _editorChromeTextSecondary,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
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

  Rect _currentStageLogicalRect() {
    final canvasSize = _lastCanvasSize;
    final workspaceSize = Size(canvasSize.width, canvasSize.height);
    final hasPageSelection = _pageAspectRatio != null;
    final stageSize = hasPageSelection
        ? _fitPageSize(
            workspaceSize: workspaceSize,
            aspectRatio: _pageAspectRatio!,
            preferFullWidth: widget.preferFullWidthCanvas,
          )
        : workspaceSize;
    return Rect.fromCenter(
      center: Offset(canvasSize.width / 2, canvasSize.height / 2),
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
      Paint()..filterQuality = FilterQuality.high,
    );
    final cropped = await recorder.endRecording().toImage(
      outputWidth,
      outputHeight,
    );
    source.dispose();
    return cropped;
  }

  Future<ui.Image?> _captureStageImage({required double pixelRatio}) async {
    final originalWorkspaceZoom = _workspaceZoom;
    final originalWorkspacePan = _workspacePan;
    final shouldResetWorkspaceForExport =
        (_workspaceZoom - 1).abs() > 0.0001 ||
        _workspacePan.distanceSquared > 0.0001;
    setState(() {
      _isCapturingStage = true;
      if (shouldResetWorkspaceForExport) {
        _workspaceZoom = 1;
        _workspacePan = Offset.zero;
      }
    });
    try {
      if (shouldResetWorkspaceForExport) {
        await _waitForRenderedFrame();
      }
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
          if (shouldResetWorkspaceForExport) {
            _workspaceZoom = originalWorkspaceZoom;
            _workspacePan = originalWorkspacePan;
          }
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
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    final exportPermissionMessage = context.strings.localized(
      telugu: 'గ్యాలరీ అనుమతి ఇవ్వండి, తర్వాత మళ్లీ ఎగుమతి చేయండి',
      english: 'Allow gallery permission and try exporting again',
    );
    final exportBoundaryMessage = context.strings.localized(
      telugu: 'ఎగుమతి ప్రాంతం సిద్ధంగా లేదు',
      english: 'Export boundary not ready',
    );
    final exportSaveFailedMessage = context.strings.localized(
      telugu: 'ఫైల్ సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి',
      english: 'File save failed. Please try again.',
    );
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    try {
      final exportedBytes = await _runQueuedCommitJob<Uint8List>(
        jobKey: 'export_${DateTime.now().microsecondsSinceEpoch}',
        label: strings.localized(
          telugu: 'పోస్టర్ ఎగుమతి అవుతోంది',
          english: 'Exporting poster',
        ),
        detail: strings.localized(
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
          await _prepareCanvasForFinalExport();
          File? tempFile;
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
          final exportedBytes = format == _ExportImageFormat.psd
              ? await _captureLayeredPsdExportBytes(
                  devicePixelRatio: devicePixelRatio,
                )
              : await (() async {
                  await ScreenSecurityService.disableSecure();
                  await WidgetsBinding.instance.endOfFrame;
                  await Future<void>.delayed(const Duration(milliseconds: 80));
                  final image = await _captureStageImage(
                    pixelRatio: _exportPixelRatio(
                      devicePixelRatio,
                      format: format,
                    ),
                  );
                  if (image == null) {
                    throw Exception(exportBoundaryMessage);
                  }
                  _debugLog(
                    'editor export capture size=${image.width}x${image.height}, '
                    'target=${_exportTargetPixelSize(format: format)?.width}x'
                    '${_exportTargetPixelSize(format: format)?.height}, '
                    'pixelRatio=${_exportPixelRatio(devicePixelRatio, format: format).toStringAsFixed(3)}',
                  );
                  final shouldHaveTransparentBackground =
                      format == _ExportImageFormat.pngTransparent;
                  final preparedImage = await _normalizeExportImageSize(
                    image,
                    format: format,
                  );
                  _debugLog(
                    'editor export normalized size=${preparedImage.width}x${preparedImage.height}',
                  );
                  return _encodeExportImageBytes(
                    preparedImage,
                    format: shouldHaveTransparentBackground
                        ? _ExportImageFormat.png
                        : format,
                    dpi: _exportDpi(format: format),
                  );
                })();
          final fileName =
              'mana_poster_${DateTime.now().millisecondsSinceEpoch}.${_exportFileExtension(format)}';
          final tempDirectory = await getTemporaryDirectory();
          final tempPath =
              '${tempDirectory.path}${Platform.pathSeparator}$fileName';
          try {
            tempFile = File(tempPath);
            await tempFile.writeAsBytes(exportedBytes, flush: true);
            _debugLog('editor export bytes=${exportedBytes.length}');
            final mimeType = _exportMimeType(format);
            final saveResult =
                format == _ExportImageFormat.pdf ||
                    format == _ExportImageFormat.psd
                ? await MediaExportService.saveFileToDownloadsDetailed(
                    tempFile.path,
                    fileName: fileName,
                    mimeType: mimeType,
                  )
                : await MediaExportService.saveImageFileToGalleryDetailed(
                    tempFile.path,
                    fileName: fileName,
                    mimeType: mimeType,
                  );
            _debugLog(
              'editor export save result: success=${saveResult.success}, code=${saveResult.code}, message=${saveResult.message}',
            );
            if (saveResult.success && !kIsWeb) {
              await PosterDownloadsService.recordCopyFromFile(
                tempFile.path,
                suggestedFileName: fileName,
              );
            }
            if (mounted) {
              final isSuccess = saveResult.success;
              messenger.showTopSnackBar(
                AppSnackBar.build(
                  content: Text(
                    _exportResultMessage(
                      isSuccess: isSuccess,
                      saveResult: saveResult,
                      permissionDeniedMessage: exportPermissionMessage,
                      captureFailedMessage: exportBoundaryMessage,
                      saveFailedMessage: exportSaveFailedMessage,
                    ),
                  ),
                  action: isSuccess
                      ? SnackBarAction(
                          label: strings.localized(
                            telugu: 'షేర్',
                            english: 'Share',
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
          } catch (error, stackTrace) {
            _debugLogStack('editor export failed: $error', stackTrace);
            rethrow;
          } finally {
            if (tempFile != null) {
              unawaited(_deleteTempFile(tempFile));
            }
          }
          return exportedBytes;
        },
      );
      if (exportedBytes == null && mounted) {
        messenger.showTopSnackBar(
          AppSnackBar.build(
            content: Text(
              strings.localized(
                telugu: 'ఎగుమతి ఇప్పటికే జరుగుతోంది',
                english: 'Export is already in progress',
              ),
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      _debugLogStack('editor export outer failed: $error', stackTrace);
      if (!mounted) {
        return;
      }
      messenger.showTopSnackBar(
        AppSnackBar.build(
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

  String _exportResultMessage({
    required bool isSuccess,
    MediaExportResult? saveResult,
    required String permissionDeniedMessage,
    required String captureFailedMessage,
    required String saveFailedMessage,
  }) {
    if (isSuccess) {
      return 'Poster saved to gallery';
    }
    switch (saveResult?.code) {
      case 'permission_denied':
        return permissionDeniedMessage;
      case 'capture_failed':
        return captureFailedMessage;
      case 'file_missing':
      case 'write_failed':
      case 'open_output_failed':
      case 'media_insert_failed':
      case 'directory_create_failed':
      case 'save_failed':
      case 'platform_exception':
      case 'empty_result':
        return saveFailedMessage;
      default:
        return 'Export failed. Please try again.';
    }
  }

  Future<void> _prepareCanvasForFinalExport() async {
    if (_selectedTextFocusNode.hasFocus || _isTextTypingScreenOpen) {
      _commitSelectedTextContentEdit();
      if (_selectedTextFocusNode.hasFocus) {
        _selectedTextFocusNode.unfocus();
      }
      if (mounted) {
        setState(() {
          _isTextTypingScreenOpen = false;
          _showTextControls = false;
        });
      } else {
        _isTextTypingScreenOpen = false;
        _showTextControls = false;
      }
      await _waitForRenderedFrame();
    }
  }

  double _exportPixelRatio(
    double devicePixelRatio, {
    _ExportImageFormat? format,
  }) {
    final Rect stageRect = _currentStageLogicalRect();
    final double logicalW = stageRect.width;
    final double logicalH = stageRect.height;
    return _calculateExportPixelRatioForStage(
      logicalWidth: logicalW,
      logicalHeight: logicalH,
      devicePixelRatio: devicePixelRatio,
      targetSize: _exportTargetPixelSize(format: format),
      preservePixels: _preserveDesignExportPixels && _designPageConfig != null,
    );
  }

  Future<void> _shareLatestPoster(
    Uint8List imageBytes, {
    required _ExportImageFormat format,
    bool recheckAccess = true,
    bool bypassSharingGuard = false,
    bool manageSharingState = true,
  }) async {
    if (_isSharing && !bypassSharingGuard) {
      return;
    }
    if (recheckAccess) {
      final hasAccess = await _ensureExportActionAccess('share_latest');
      if (!mounted || !hasAccess) {
        return;
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings;
    final box = context.findRenderObject() as RenderBox?;

    if (manageSharingState) {
      setState(() {
        _isSharing = true;
      });
    }
    File? tempShareFile;
    try {
      await ScreenSecurityService.disableSecure();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      _debugLog('editor share bytes=${imageBytes.length}');
      if (!mounted) {
        return;
      }
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}mana_poster_share.${_exportFileExtension(format)}';
      final file = File(filePath);
      tempShareFile = file;
      await file.writeAsBytes(imageBytes, flush: true);
      await MediaExportService.shareImageFile(
        file.path,
        mimeType: _exportMimeType(format),
        text: 'Mana Poster Ai',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error, stackTrace) {
      _debugLogStack('editor share failed: $error', stackTrace);
      if (!mounted) {
        return;
      }
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            strings.localized(
              telugu: 'Share fail ayindi, malli prayatninchandi',
              english: 'Share failed, please try again',
            ),
          ),
        ),
      );
    } finally {
      if (manageSharingState && mounted) {
        setState(() {
          _isSharing = false;
        });
      }
      if (tempShareFile != null) {
        unawaited(_deleteTempFile(tempShareFile));
      }
      await ScreenSecurityService.enableSecure();
    }
  }

  Future<void> _deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      _debugLogStack('temp file cleanup failed: $error', stackTrace);
    }
  }

  String _exportFileExtension(_ExportImageFormat format) {
    switch (format) {
      case _ExportImageFormat.jpg:
        return 'jpg';
      case _ExportImageFormat.psd:
        return 'psd';
      case _ExportImageFormat.pdf:
        return 'pdf';
      case _ExportImageFormat.png:
      case _ExportImageFormat.pngTransparent:
        return 'png';
    }
  }

  String _exportMimeType(_ExportImageFormat format) {
    switch (format) {
      case _ExportImageFormat.jpg:
        return 'image/jpeg';
      case _ExportImageFormat.psd:
        return 'image/vnd.adobe.photoshop';
      case _ExportImageFormat.pdf:
        return 'application/pdf';
      case _ExportImageFormat.png:
      case _ExportImageFormat.pngTransparent:
        return 'image/png';
    }
  }
}
