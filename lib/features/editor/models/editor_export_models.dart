enum EditorExportFormat { png, jpg }

class EditorExportOptions {
  const EditorExportOptions({
    this.format = EditorExportFormat.png,
    this.transparentBackground = false,
    this.enableWatermark = false,
    this.pixelRatio = 3,
  });

  final EditorExportFormat format;
  final bool transparentBackground;
  final bool enableWatermark;
  final double pixelRatio;

  EditorExportOptions copyWith({
    EditorExportFormat? format,
    bool? transparentBackground,
    bool? enableWatermark,
    double? pixelRatio,
  }) {
    return EditorExportOptions(
      format: format ?? this.format,
      transparentBackground:
          transparentBackground ?? this.transparentBackground,
      enableWatermark: enableWatermark ?? this.enableWatermark,
      pixelRatio: pixelRatio ?? this.pixelRatio,
    );
  }
}

class EditorExportResult {
  const EditorExportResult({
    required this.filePath,
    required this.bytes,
    required this.mimeType,
  });

  final String filePath;
  final List<int> bytes;
  final String mimeType;
}
