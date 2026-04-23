import 'package:flutter/material.dart';

enum EditorStageBackgroundType { white, transparent, color, gradient }

@immutable
class EditorStageBackground {
  const EditorStageBackground._({
    required this.type,
    this.color,
    this.gradientIndex,
  });

  const EditorStageBackground.white()
    : this._(type: EditorStageBackgroundType.white);

  const EditorStageBackground.transparent()
    : this._(type: EditorStageBackgroundType.transparent);

  const EditorStageBackground.color([Color color = const Color(0xFFF8FAFC)])
    : this._(type: EditorStageBackgroundType.color, color: color);

  const EditorStageBackground.gradient([int gradientIndex = 17])
    : this._(
        type: EditorStageBackgroundType.gradient,
        gradientIndex: gradientIndex,
      );

  final EditorStageBackgroundType type;
  final Color? color;
  final int? gradientIndex;
}
