import 'package:flutter/material.dart';

bool isRemoteImageSource(String source) {
  final uri = Uri.tryParse(source);
  if (uri == null) {
    return false;
  }
  return uri.scheme == 'http' ||
      uri.scheme == 'https' ||
      uri.scheme == 'blob' ||
      uri.scheme == 'data';
}

ImageProvider<Object> editorImageProvider(String source) {
  return NetworkImage(source);
}

Widget buildEditorImage(
  String source, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  double? width,
  double? height,
}) {
  return Image.network(
    source,
    fit: fit,
    alignment: alignment,
    width: width,
    height: height,
  );
}
