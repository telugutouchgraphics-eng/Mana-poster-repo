import 'package:flutter/material.dart';

enum EditorToolId {
  photo,
  text,
  background,
  elements,
  stickers,
  draw,
  shapes,
  crop,
  adjust,
  filters,
  removeBg,
  borderFrame,
  layers,
  transparency,
  shadow,
  blend,
  flip,
  rotate,
  duplicate,
  lock,
}

class EditorToolDefinition {
  const EditorToolDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.subOptions,
  });

  final EditorToolId id;
  final String label;
  final IconData icon;
  final List<String> subOptions;
}

const List<EditorToolDefinition> kEditorTools = <EditorToolDefinition>[
  EditorToolDefinition(
    id: EditorToolId.photo,
    label: 'ఫోటో',
    icon: Icons.add_a_photo_outlined,
    subOptions: <String>['గ్యాలరీ', 'కెమెరా', 'ఫిట్', 'కట్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.text,
    label: 'టెక్స్ట్',
    icon: Icons.text_fields_rounded,
    subOptions: <String>['చేర్చు', 'ఫాంట్స్', 'స్టైల్', 'అలైన్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.background,
    label: 'బ్యాక్‌గ్రౌండ్',
    icon: Icons.wallpaper_outlined,
    subOptions: <String>['కలర్', 'గ్రేడియంట్', 'ఫోటో', 'ప్యాటర్న్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.elements,
    label: 'ఎలిమెంట్స్',
    icon: Icons.auto_awesome_mosaic_outlined,
    subOptions: <String>['PNG', 'షేప్స్', 'సింబల్స్', 'సెర్చ్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.stickers,
    label: 'స్టికర్స్',
    icon: Icons.emoji_emotions_outlined,
    subOptions: <String>['ట్రెండింగ్', 'ఫెస్టివల్', 'లవ్', 'కిడ్స్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.draw,
    label: 'డ్రా',
    icon: Icons.brush_outlined,
    subOptions: <String>['బ్రష్', 'ఇరేసర్', 'సైజ్', 'ఓపాసిటీ'],
  ),
  EditorToolDefinition(
    id: EditorToolId.shapes,
    label: 'షేప్స్',
    icon: Icons.category_outlined,
    subOptions: <String>['రెక్ట్', 'సర్కిల్', 'లైన్', 'స్టార్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.crop,
    label: 'క్రాప్',
    icon: Icons.crop_outlined,
    subOptions: <String>['ఫ్రీ', '1:1', '4:5', '16:9'],
  ),
  EditorToolDefinition(
    id: EditorToolId.adjust,
    label: 'అడ్జస్ట్',
    icon: Icons.tune_rounded,
    subOptions: <String>['బ్రైట్‌నెస్', 'కాంట్రాస్ట్', 'సాచ్యురేషన్', 'షార్ప్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.filters,
    label: 'ఫిల్టర్స్',
    icon: Icons.filter_alt_outlined,
    subOptions: <String>['క్లాసిక్', 'వైబ్రంట్', 'వార్మ్', 'కూల్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.removeBg,
    label: 'రిమూవ్ BG',
    icon: Icons.auto_fix_high_outlined,
    subOptions: <String>['ఆటో', 'రిఫైన్', 'ఎడ్జ్', 'రిస్టోర్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.borderFrame,
    label: 'బోర్డర్/ఫ్రేమ్',
    icon: Icons.crop_square_outlined,
    subOptions: <String>['బోర్డర్', 'ఫ్రేమ్', 'కలర్', 'విడ్త్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.layers,
    label: 'లేయర్స్',
    icon: Icons.layers_outlined,
    subOptions: <String>['ఎంచుకోండి', 'ఫ్రంట్', 'బ్యాక్', 'హైడ్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.transparency,
    label: 'ట్రాన్స్‌పరెన్సీ',
    icon: Icons.opacity_outlined,
    subOptions: <String>['0%', '25%', '50%', '100%'],
  ),
  EditorToolDefinition(
    id: EditorToolId.shadow,
    label: 'షాడో',
    icon: Icons.gradient_outlined,
    subOptions: <String>['సాఫ్ట్', 'హార్డ్', 'ఆఫ్‌సెట్', 'బ్లర్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.blend,
    label: 'బ్లెండ్',
    icon: Icons.blur_on_outlined,
    subOptions: <String>['నార్మల్', 'మల్టిప్లై', 'స్క్రీన్', 'ఓవర్లే'],
  ),
  EditorToolDefinition(
    id: EditorToolId.flip,
    label: 'ఫ్లిప్',
    icon: Icons.flip_outlined,
    subOptions: <String>['హొరిజాంటల్', 'వెర్టికల్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.rotate,
    label: 'రొటేట్',
    icon: Icons.rotate_right_outlined,
    subOptions: <String>['ఎడమ', 'కుడి', 'ఫ్రీ'],
  ),
  EditorToolDefinition(
    id: EditorToolId.duplicate,
    label: 'డూప్లికేట్',
    icon: Icons.copy_all_outlined,
    subOptions: <String>['లేయర్ డూప్లికేట్', 'సెలెక్ట్ డూప్లికేట్'],
  ),
  EditorToolDefinition(
    id: EditorToolId.lock,
    label: 'లాక్',
    icon: Icons.lock_outline_rounded,
    subOptions: <String>['లాక్', 'అన్‌లాక్'],
  ),
];
