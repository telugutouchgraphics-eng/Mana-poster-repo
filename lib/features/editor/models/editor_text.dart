import 'package:flutter/material.dart';

import 'package:mana_poster/features/editor/models/editor_stage.dart';

class EditorTextLayer {
  const EditorTextLayer({
    required this.id,
    required this.name,
    required this.text,
    required this.offset,
    required this.rotation,
    required this.scale,
    required this.zIndex,
    required this.style,
    this.isLocked = false,
    this.isFlipped = false,
    this.isFlippedVertical = false,
    this.blendMode = LayerBlendModeOption.normal,
    this.isVisible = true,
  });

  final String id;
  final String name;
  final String text;
  final Offset offset;
  final double rotation;
  final double scale;
  final int zIndex;
  final EditorTextStyleConfig style;
  final bool isLocked;
  final bool isFlipped;
  final bool isFlippedVertical;
  final LayerBlendModeOption blendMode;
  final bool isVisible;

  EditorTextLayer copyWith({
    String? id,
    String? name,
    String? text,
    Offset? offset,
    double? rotation,
    double? scale,
    int? zIndex,
    EditorTextStyleConfig? style,
    bool? isLocked,
    bool? isFlipped,
    bool? isFlippedVertical,
    LayerBlendModeOption? blendMode,
    bool? isVisible,
  }) {
    return EditorTextLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      text: text ?? this.text,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      style: style ?? this.style,
      isLocked: isLocked ?? this.isLocked,
      isFlipped: isFlipped ?? this.isFlipped,
      isFlippedVertical: isFlippedVertical ?? this.isFlippedVertical,
      blendMode: blendMode ?? this.blendMode,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class EditorTextStyleConfig {
  const EditorTextStyleConfig({
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.opacity,
    this.gradientColors,
    this.backgroundHighlightColor,
    this.strokeColor,
    this.strokeWidth = 0,
    this.shadow = const Shadow(color: Colors.transparent),
    this.isBold = false,
    this.isItalic = false,
    this.alignment = TextAlign.center,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.curve = 0,
  });

  final String fontFamily;
  final double fontSize;
  final Color color;
  final double opacity;
  final List<Color>? gradientColors;
  final Color? backgroundHighlightColor;
  final Color? strokeColor;
  final double strokeWidth;
  final Shadow shadow;
  final bool isBold;
  final bool isItalic;
  final TextAlign alignment;
  final double letterSpacing;
  final double lineHeight;
  final double curve;

  EditorTextStyleConfig copyWith({
    String? fontFamily,
    double? fontSize,
    Color? color,
    double? opacity,
    List<Color>? gradientColors,
    bool clearGradient = false,
    Color? backgroundHighlightColor,
    bool clearBackgroundHighlight = false,
    Color? strokeColor,
    double? strokeWidth,
    Shadow? shadow,
    bool? isBold,
    bool? isItalic,
    TextAlign? alignment,
    double? letterSpacing,
    double? lineHeight,
    double? curve,
  }) {
    return EditorTextStyleConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      gradientColors: clearGradient
          ? null
          : (gradientColors ?? this.gradientColors),
      backgroundHighlightColor: clearBackgroundHighlight
          ? null
          : (backgroundHighlightColor ?? this.backgroundHighlightColor),
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      shadow: shadow ?? this.shadow,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      alignment: alignment ?? this.alignment,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      curve: curve ?? this.curve,
    );
  }
}

const EditorTextStyleConfig kDefaultEditorTextStyle = EditorTextStyleConfig(
  fontFamily: 'Anek Telugu Condensed Regular',
  fontSize: 34,
  color: Color(0xFF111827),
  opacity: 1,
);
