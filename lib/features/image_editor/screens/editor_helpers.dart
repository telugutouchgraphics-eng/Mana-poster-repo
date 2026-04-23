part of 'image_editor_screen.dart';

class _AdjustedPhotoPresentationCache {
  const _AdjustedPhotoPresentationCache();

  static final LinkedHashMap<String, _AdjustedPhotoPresentation> _cache =
      LinkedHashMap<String, _AdjustedPhotoPresentation>();
  static const int _maxEntries = 96;

  static _AdjustedPhotoPresentation resolve({
    required Uint8List bytes,
    required String key,
    required double opacity,
  }) {
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }
    final image = Image.memory(
      bytes,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      fit: BoxFit.contain,
      frameBuilder:
          (BuildContext context, Widget child, int? frame, bool sync) => child,
    );
    final presentation = _AdjustedPhotoPresentation(
      key: key,
      image: image,
      opacity: opacity,
    );
    _cache[key] = presentation;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return presentation;
  }
}

bool _isMatrixFinite(Matrix4 matrix) {
  for (final value in matrix.storage) {
    if (!value.isFinite) {
      return false;
    }
  }
  return true;
}

String _photoBytesSignature(Uint8List bytes) {
  final length = bytes.length;
  if (length == 0) {
    return '0_0';
  }
  final sample = bytes.length > 64 ? 64 : bytes.length;
  var hash = 17;
  for (var i = 0; i < sample; i++) {
    hash = 37 * hash + bytes[i];
  }
  return '${bytes.length}_$hash';
}

Widget _buildAdjustedPhoto({
  required Uint8List bytes,
  required String cacheKey,
  required int? cacheWidth,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  final _ = cacheWidth;
  final presentation = _AdjustedPhotoPresentationCache.resolve(
    bytes: bytes,
    key: cacheKey,
    opacity: 1,
  );
  Widget child = presentation.image;

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1
      ? null
      : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}

// ignore: unused_element
Widget _buildAdjustedRawPhoto({
  required ui.Image image,
  required double brightness,
  required double contrast,
  required double saturation,
  required double blur,
}) {
  Widget child = RawImage(
    image: image,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
  );

  final blurSigma = _mapAdjustBlurToSigma(blur);
  if (blurSigma > 0.01) {
    child = ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }
  final saturationMatrix = saturation == 1
      ? null
      : _saturationMatrix(saturation);
  if (saturationMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(saturationMatrix),
      child: child,
    );
  }
  final brightnessContrastMatrix =
      brightness.abs() < 0.0001 && (contrast - 1).abs() < 0.0001
      ? null
      : _brightnessContrastMatrix(brightness: brightness, contrast: contrast);
  if (brightnessContrastMatrix != null) {
    child = ColorFiltered(
      colorFilter: ColorFilter.matrix(brightnessContrastMatrix),
      child: child,
    );
  }
  return child;
}

