import 'package:flutter/material.dart';

const List<Color> _seedBackgroundColors = <Color>[
  Color(0xFFF4F7FC),
  Color(0xFFFFFFFF),
  Color(0xFFF8FAFC),
  Color(0xFF111827),
  Color(0xFF0F172A),
  Color(0xFF1E293B),
  Color(0xFFFEF3C7),
  Color(0xFFDCFCE7),
  Color(0xFFFFF1F2),
  Color(0xFFF5F3FF),
  Color(0xFFEFF6FF),
  Color(0xFFECFCCB),
  Color(0xFFFAF5FF),
  Color(0xFFFFFBEB),
  Color(0xFFE0F2FE),
  Color(0xFFF1F5F9),
];

List<Color> _buildBackgroundColors(int count) {
  if (count <= _seedBackgroundColors.length) {
    return List<Color>.unmodifiable(_seedBackgroundColors.take(count));
  }
  final colors = <Color>[..._seedBackgroundColors];
  final dynamicCount = count - _seedBackgroundColors.length;
  for (var i = 0; i < dynamicCount; i++) {
    final hue = (i * 360.0 / dynamicCount) % 360;
    final saturation = 0.68 + ((i % 5) * 0.05);
    final lightness = 0.42 + ((i % 4) * 0.08);
    colors.add(
      HSLColor.fromAHSL(
        1,
        hue,
        saturation.clamp(0.45, 0.9),
        lightness.clamp(0.32, 0.78),
      ).toColor(),
    );
  }
  return List<Color>.unmodifiable(colors);
}

final List<Color> editorBackgroundColors = _buildBackgroundColors(50);

const List<List<Color>> editorBackgroundGradients = <List<Color>>[
  <Color>[Color(0xFFFFF3C4), Color(0xFFFFD86B), Color(0xFFFFA351)],
  <Color>[Color(0xFFFFE8B6), Color(0xFFFFC56E), Color(0xFFF97316)],
  <Color>[Color(0xFFFFF0D1), Color(0xFFFFCF91), Color(0xFFE58D2A)],
  <Color>[Color(0xFFFFE7A8), Color(0xFFFBBF24), Color(0xFFDC6803)],
  <Color>[Color(0xFFFFECCF), Color(0xFFF59E0B), Color(0xFFB45309)],
  <Color>[Color(0xFFFFE5C0), Color(0xFFFB923C), Color(0xFFE11D48)],
  <Color>[Color(0xFFFCE7F3), Color(0xFFF472B6), Color(0xFFFB7185)],
  <Color>[Color(0xFFFFF1F2), Color(0xFFFB7185), Color(0xFFF97316)],
  <Color>[Color(0xFFFFF7ED), Color(0xFFFDBA74), Color(0xFFFB7185)],
  <Color>[Color(0xFFFFEDD5), Color(0xFFF97316), Color(0xFFE11D48)],
  <Color>[Color(0xFFFFE4E6), Color(0xFFF43F5E), Color(0xFF7C2D12)],
  <Color>[Color(0xFFFFF1F2), Color(0xFFE11D48), Color(0xFF9F1239)],
  <Color>[Color(0xFFFFF7ED), Color(0xFFFB7185), Color(0xFFB91C1C)],
  <Color>[Color(0xFFFEE2E2), Color(0xFFEF4444), Color(0xFF7F1D1D)],
  <Color>[Color(0xFFFDF2F8), Color(0xFFF43F5E), Color(0xFF9D174D)],
  <Color>[Color(0xFFFFFBEB), Color(0xFFFFE082), Color(0xFFFFB74D)],
  <Color>[Color(0xFFE8F5E9), Color(0xFFB9F6CA), Color(0xFF4DB6AC)],
  <Color>[Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
  <Color>[Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
  <Color>[Color(0xFFF5F3FF), Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
  <Color>[Color(0xFFECFEFF), Color(0xFFCFFAFE), Color(0xFFA5F3FC)],
  <Color>[Color(0xFFFCE7F3), Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
  <Color>[Color(0xFFE9D5FF), Color(0xFFC084FC), Color(0xFFF472B6)],
  <Color>[Color(0xFFF9A8D4), Color(0xFFF97316), Color(0xFFFACC15)],
  <Color>[Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
  <Color>[Color(0xFF22C55E), Color(0xFFFACC15), Color(0xFFEF4444)],
  <Color>[Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
  <Color>[Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF9333EA)],
  <Color>[Color(0xFF38BDF8), Color(0xFF22D3EE), Color(0xFF14B8A6)],
  <Color>[Color(0xFF60A5FA), Color(0xFF818CF8), Color(0xFFA78BFA)],
  <Color>[Color(0xFF312E81), Color(0xFF5B21B6), Color(0xFF7C3AED)],
  <Color>[Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF06B6D4)],
  <Color>[Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
  <Color>[Color(0xFF111827), Color(0xFF1F2937), Color(0xFF374151)],
  <Color>[Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E1B4B)],
  <Color>[Color(0xFF09090B), Color(0xFF27272A), Color(0xFF52525B)],
  <Color>[Color(0xFF0B1020), Color(0xFF172554), Color(0xFF1D4ED8)],
  <Color>[Color(0xFF3F1D0C), Color(0xFF7C2D12), Color(0xFFD97706)],
  <Color>[Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFF59E0B)],
  <Color>[Color(0xFF78350F), Color(0xFFB45309), Color(0xFFEAB308)],
  <Color>[Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFBBF24)],
  <Color>[Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFFB7185)],
  <Color>[Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
  <Color>[Color(0xFF1D4ED8), Color(0xFF0EA5E9), Color(0xFF22D3EE)],
  <Color>[Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
  <Color>[Color(0xFF15803D), Color(0xFF22C55E), Color(0xFF86EFAC)],
  <Color>[Color(0xFF166534), Color(0xFF16A34A), Color(0xFF65A30D)],
  <Color>[Color(0xFF14532D), Color(0xFF15803D), Color(0xFF4ADE80)],
  <Color>[Color(0xFF365314), Color(0xFF65A30D), Color(0xFFA3E635)],
  <Color>[Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  <Color>[Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFC026D3)],
  <Color>[Color(0xFF0EA5E9), Color(0xFF6366F1), Color(0xFF9333EA)],
  <Color>[Color(0xFFEC4899), Color(0xFFF97316), Color(0xFFFB7185)],
  <Color>[Color(0xFFF43F5E), Color(0xFFF97316), Color(0xFFEAB308)],
  <Color>[Color(0xFFFB7185), Color(0xFFFB923C), Color(0xFFFDE047)],
  <Color>[Color(0xFF1D4ED8), Color(0xFF06B6D4), Color(0xFF22C55E)],
  <Color>[Color(0xFF3730A3), Color(0xFF6366F1), Color(0xFF22D3EE)],
  <Color>[Color(0xFF0F766E), Color(0xFF22C55E), Color(0xFF84CC16)],
  <Color>[Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFFFDE047)],
  <Color>[Color(0xFFB91C1C), Color(0xFFE11D48), Color(0xFFF43F5E)],
];
