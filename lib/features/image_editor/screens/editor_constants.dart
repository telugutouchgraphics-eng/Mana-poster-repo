// ignore_for_file: unused_element, unused_field

part of 'image_editor_screen.dart';

enum _CanvasLayerType { photo, text, sticker }

enum _ExportImageFormat { png, pngTransparent, jpg }

enum _BottomPrimaryTool { none, photo, text, background, tools }

enum _BottomInlineMode {
  none,
  layers,
  stickerCategories,
  stickerItems,
  border,
  backgroundBlur,
}

enum _BorderStyle { none, thinWhite, thinBlack, rounded, glow }

const double _topBarHeight = 68;
const double _bottomBarHeight = 92;
const double _cropBarHeight = 132;
const double _adjustBarHeight = 196;
const double _textStyleBarHeight = 252;
const double _canvasChromeInset = 18;

final List<Color> _textColors = List<Color>.unmodifiable(
  editorBackgroundColors.take(50),
);

const List<String> _stickerCategories = <String>[
  'Emojis',
  'Shapes',
  'Hearts',
  'Stars',
  'Festival',
  'Political',
];

const Map<String, List<String>> _stickerCatalog = <String, List<String>>{
  'Emojis': <String>['😀', '😁', '😎', '🥳', '❤️', '✨'],
  'Shapes': <String>['⬛', '⬜', '🔶', '🔷', '🔺', '🔻'],
  'Hearts': <String>['❤️', '💚', '💙', '💜', '🧡', '💕'],
  'Stars': <String>['⭐', '🌟', '✨', '💫', '🔆', '✳️'],
  'Festival': <String>['🎉', '🎊', '🪔', '🪙', '🕯️', '🌸'],
  'Political': politicalLogoElements,
};

final List<List<Color>> _textGradients = List<List<Color>>.unmodifiable(
  editorBackgroundGradients
      .take(50)
      .map((gradient) => List<Color>.unmodifiable(gradient))
      .toList(growable: false),
);

const List<String> _textFontFamilies = <String>[
  'Anek Telugu Condensed Regular',
  'Anek Telugu Condensed Bold',
  'Anek Telugu Condensed Extra Bold',
  'Anek Telugu Condensed Extra Light',
  'Anek Telugu Condensed Light',
  'Anek Telugu Condensed Medium',
  'Noto Sans Telugu Condensed Black',
  'Noto Sans Telugu Condensed Bold',
  'Noto Sans Telugu Condensed Extra Bold',
  'Noto Sans Telugu Condensed Extra Light',
  'Noto Sans Telugu Condensed Light',
  'Aaradhana',
  'Abhilasha',
  'Ajantha',
  'Akshara',
  'Amrutha',
  'Anjali',
  'Anu Subhalekha Two',
  'Anupama Bold',
  'Anupama Extra Bold',
  'Anupama Medium',
  'Anupama Thin',
  'Anusha',
  'Apoorva',
  'Ashwini',
  'Bapu Bold',
  'Bapu Brush',
  'Bapu Script',
  'Bharghava',
  'Bhavya',
  'Brahma',
  'Brahma Script',
  'Chandra Script',
  'Deepika',
  'Dharani',
  'Geetha',
  'Gowthami Black',
  'Gowthami Bold',
  'Gowthami Extra Bold',
  'Gowthami Medium',
  'Gowthami Narrow',
  'Gowthami Thin',
  'Harsha',
  'Hiranya',
  'Jyothi',
  'Kalaanjali',
  'Keerthi Font',
  'Kranthi',
  'Kusuma',
  'Maanasa',
  'Madhubala',
  'Meena Script',
  'Mohini',
  'Natyamayuri',
  'Neelima',
  'Padmini',
  'Pallavi Bold',
  'Pallavi Medium',
  'Pallavi Thin',
  'Prabhava',
  'Pragathi',
  'Pragathi Italic',
  'Pragathi Narrow',
  'Pragathi Special',
  'Preethi',
  'Pridhvi',
  'Priyaanka',
  'Priyaanka Bold',
  'Rachana',
  'Rachana Bold',
  'Ramana Brush',
  'Ramana Script',
  'Ramana Script Medium',
  'Ravali',
  'Reshma',
  'Rohini',
  'Saagari',
  'Sanghavi',
  'Sowmya',
  'Sravya',
  'Subhadra',
  'Suchithra',
  'Sujatha',
  'Suneetha',
  'Supriya',
  'Tejafont',
  'Thripura',
  'Udayam',
  'Vaibhav',
  'Vasantha',
  'Vasundhara',
  'Veenaa',
  'Vikaas',
];

const List<String> _englishTextFontFamilies = <String>[
  'Anton',
  'Archivo Black',
  'Bebas Neue',
  'League Spartan',
  'Montserrat',
  'Playfair Display',
  'Poppins',
  'Rasa',
];
