import 'dart:io';

import 'package:flutter/material.dart';

bool isRemoteImageSource(String source) {
  final uri = Uri.tryParse(source);
  if (uri == null) {
    return false;
  }
  return uri.scheme == 'http' || uri.scheme == 'https';
}

ImageProvider<Object> editorImageProvider(String source) {
  if (isRemoteImageSource(source)) {
    return NetworkImage(source);
  }
  return FileImage(File(source));
}

Widget buildEditorImage(
  String source, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  double? width,
  double? height,
}) {
  if (isRemoteImageSource(source)) {
    return Image.network(
      source,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
    );
  }
  return Image.file(
    File(source),
    fit: fit,
    alignment: alignment,
    width: width,
    height: height,
  );
}
