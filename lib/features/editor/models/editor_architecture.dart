class EditorFontCatalog {
  const EditorFontCatalog({
    required this.teluguFonts,
    required this.englishFonts,
  });

  final List<String> teluguFonts;
  final List<String> englishFonts;
}

class EditorElementCatalog {
  const EditorElementCatalog({required this.pngCategories});

  final List<String> pngCategories;
}

class EditorSmartGuideConfig {
  const EditorSmartGuideConfig({this.enabled = true, this.snapTolerance = 8});

  final bool enabled;
  final double snapTolerance;
}

class EditorLayerSelectionState {
  const EditorLayerSelectionState({required this.layerIds, this.activeLayerId});

  final List<String> layerIds;
  final String? activeLayerId;
}
