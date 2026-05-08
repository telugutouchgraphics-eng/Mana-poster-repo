import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/assets.dart';
import 'package:onnxruntime/onnxruntime.dart';

class BackgroundRemover {
  BackgroundRemover._internal();

  static final BackgroundRemover _instance = BackgroundRemover._internal();

  static BackgroundRemover get instance => _instance;

  OrtSession? _session;

  final List<double> _mean = [0.485, 0.456, 0.406];
  final List<double> _std = [0.229, 0.224, 0.225];

  int modelSize = 320;

  Future<void> initializeOrt() async {
    try {
      OrtEnv.instance.init();
      await _createSession();
    } catch (error, stackTrace) {
      log(
        'initializeOrt failed: $error',
        name: 'BackgroundRemover',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _createSession() async {
    OrtSessionOptions? sessionOptions;
    try {
      sessionOptions = OrtSessionOptions();
      final rawAssetFile = await rootBundle.load(Assets.modelPath);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      if (kDebugMode) {
        log(
          'ONNX session created successfully. modelAsset=${Assets.modelPath} bytes=${bytes.length}',
          name: 'BackgroundRemover',
        );
      }
    } catch (error, stackTrace) {
      log(
        'Error creating ONNX session: $error asset=${Assets.modelPath}',
        name: 'BackgroundRemover',
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      sessionOptions?.release();
    }
  }

  Future<ui.Image> removeBg(
    Uint8List imageBytes, {
    double threshold = 0.5,
    bool smoothMask = true,
    bool enhanceEdges = true,
  }) async {
    if (_session == null) {
      throw Exception("ONNX session not initialized");
    }

    final originalImage = await decodeImageFromList(imageBytes);
    log(
      'Original image size: ${originalImage.width}x${originalImage.height}',
      name: 'BackgroundRemover',
    );

    final resizedImage = await _resizeImage(originalImage, 320, modelSize);
    final rgbFloats = await _imageToFloatTensor(resizedImage);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(rgbFloats),
      [1, 3, modelSize, modelSize],
    );

    final inputs = {'input.1': inputTensor};
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;
    try {
      runOptions = OrtRunOptions();
      outputs = await _session!.runAsync(runOptions, inputs);
      final outputTensor = outputs?[0]?.value;
      if (outputTensor is List) {
        final mask = outputTensor[0][0];
        final resizedMask = smoothMask
            ? resizeMaskBilinear(mask, originalImage.width, originalImage.height)
            : resizeMaskNearest(mask, originalImage.width, originalImage.height);
        final finalMask = enhanceEdges
            ? await _enhanceMaskEdges(originalImage, resizedMask)
            : resizedMask;
        return await _applyMaskToOriginalSizeImage(
          originalImage,
          finalMask,
          threshold: threshold,
          smooth: smoothMask,
        );
      }
      throw Exception('Unexpected output format from ONNX model.');
    } catch (error, stackTrace) {
      log(
        'OrtSession.runAsync failed: $error inputBytes=${imageBytes.length} modelSize=$modelSize',
        name: 'BackgroundRemover',
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      inputTensor.release();
      runOptions?.release();
      outputs?.forEach((element) => element?.release());
    }
  }

  Future<ui.Image> _resizeImage(
    ui.Image image,
    int targetWidth,
    int targetHeight,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect =
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }

  List resizeMaskNearest(List mask, int originalWidth, int originalHeight) {
    final resizedMask = List.generate(
      originalHeight,
      (_) => List.filled(originalWidth, 0.0),
    );

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final scaledX = x * 320 ~/ originalWidth;
        final scaledY = y * 320 ~/ originalHeight;
        resizedMask[y][x] = mask[scaledY][scaledX];
      }
    }
    return resizedMask;
  }

  List resizeMaskBilinear(List mask, int originalWidth, int originalHeight) {
    final resizedMask = List.generate(
      originalHeight,
      (_) => List.filled(originalWidth, 0.0),
    );

    final maskHeight = mask.length;
    final maskWidth = mask[0].length;

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final srcX = x * maskWidth / originalWidth;
        final srcY = y * maskHeight / originalHeight;

        final x1 = srcX.floor();
        final y1 = srcY.floor();
        final x2 = (x1 + 1).clamp(0, maskWidth - 1);
        final y2 = (y1 + 1).clamp(0, maskHeight - 1);

        final wx = srcX - x1;
        final wy = srcY - y1;

        resizedMask[y][x] = mask[y1][x1] * (1 - wx) * (1 - wy) +
            mask[y1][x2] * wx * (1 - wy) +
            mask[y2][x1] * (1 - wx) * wy +
            mask[y2][x2] * wx * wy;
      }
    }
    return resizedMask;
  }

  Future<List<double>> _imageToFloatTensor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");
    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final floats = List<double>.filled(pixelCount * 3, 0);

    for (int i = 0; i < pixelCount; i++) {
      floats[i] = (rgbaBytes[i * 4] / 255.0 - _mean[0]) / _std[0];
      floats[pixelCount + i] =
          (rgbaBytes[i * 4 + 1] / 255.0 - _mean[1]) / _std[1];
      floats[2 * pixelCount + i] =
          (rgbaBytes[i * 4 + 2] / 255.0 - _mean[2]) / _std[2];
    }
    return floats;
  }

  Future<List> _enhanceMaskEdges(ui.Image originalImage, List mask) async {
    final byteData =
        await originalImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");
    final rgbaBytes = byteData.buffer.asUint8List();

    final width = originalImage.width;
    final height = originalImage.height;
    final enhancedMask = List.generate(
      height,
      (y) => List.generate(width, (x) => mask[y][x]),
    );

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idxLeft = (y * width + (x - 1)) * 4;
        final idxRight = (y * width + (x + 1)) * 4;
        final idxUp = ((y - 1) * width + x) * 4;
        final idxDown = ((y + 1) * width + x) * 4;

        final gradR = (rgbaBytes[idxRight] - rgbaBytes[idxLeft]).abs() +
            (rgbaBytes[idxDown] - rgbaBytes[idxUp]).abs();
        final gradG = (rgbaBytes[idxRight + 1] - rgbaBytes[idxLeft + 1]).abs() +
            (rgbaBytes[idxDown + 1] - rgbaBytes[idxUp + 1]).abs();
        final gradB = (rgbaBytes[idxRight + 2] - rgbaBytes[idxLeft + 2]).abs() +
            (rgbaBytes[idxDown + 2] - rgbaBytes[idxUp + 2]).abs();

        final gradMagnitude = (gradR + gradG + gradB) / 3.0;
        if (gradMagnitude > 30) {
          if (mask[y][x] > 0.3 && mask[y][x] < 0.7) {
            double sum = 0;
            int count = 0;
            for (int ny = y - 1; ny <= y + 1; ny++) {
              for (int nx = x - 1; nx <= x + 1; nx++) {
                if (ny >= 0 && ny < height && nx >= 0 && nx < width) {
                  sum += mask[ny][nx];
                  count++;
                }
              }
            }
            final avg = sum / count;
            enhancedMask[y][x] = avg > 0.5
                ? (mask[y][x] + 0.1).clamp(0.0, 1.0)
                : (mask[y][x] - 0.1).clamp(0.0, 1.0);
          }
        }
      }
    }

    return enhancedMask;
  }

  Future<ui.Image> _applyMaskToOriginalSizeImage(
    ui.Image image,
    List mask, {
    double threshold = 0.5,
    bool smooth = true,
  }) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");

    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final outRgbaBytes = Uint8List(4 * pixelCount);

    List smoothedMask = mask;
    if (smooth) {
      smoothedMask = _smoothMask(mask, 3);
    }

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final i = y * image.width + x;
        final maskValue = smoothedMask[y][x] as double;
        final int alpha;

        if (maskValue > threshold + 0.05) {
          alpha = 255;
        } else if (maskValue < threshold - 0.05) {
          alpha = 0;
        } else {
          alpha = ((maskValue - (threshold - 0.05)) / 0.1 * 255)
              .round()
              .clamp(0, 255);
        }

        outRgbaBytes[i * 4] = rgbaBytes[i * 4];
        outRgbaBytes[i * 4 + 1] = rgbaBytes[i * 4 + 1];
        outRgbaBytes[i * 4 + 2] = rgbaBytes[i * 4 + 2];
        outRgbaBytes[i * 4 + 3] = alpha;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      outRgbaBytes,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  List _smoothMask(List mask, int kernelSize) {
    final height = mask.length;
    final width = mask[0].length;
    final smoothed = List.generate(
      height,
      (_) => List.filled(width, 0.0),
    );

    final halfKernel = kernelSize ~/ 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0.0;
        int count = 0;
        for (int ky = -halfKernel; ky <= halfKernel; ky++) {
          for (int kx = -halfKernel; kx <= halfKernel; kx++) {
            final ny = y + ky;
            final nx = x + kx;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              sum += mask[ny][nx] as double;
              count++;
            }
          }
        }
        smoothed[y][x] = sum / count;
      }
    }
    return smoothed;
  }

  Future<Uint8List> addBackground({
    required Uint8List image,
    required Color bgColor,
  }) async {
    final decodedImage = img.decodeImage(image)!;
    final newImage =
        img.Image(width: decodedImage.width, height: decodedImage.height);
    img.fill(
      newImage,
      color: img.ColorRgb8(
        (bgColor.r * 255.0).round().clamp(0, 255),
        (bgColor.g * 255.0).round().clamp(0, 255),
        (bgColor.b * 255.0).round().clamp(0, 255),
      ),
    );
    img.compositeImage(newImage, decodedImage);
    final jpegBytes = img.encodeJpg(newImage);
    return jpegBytes.buffer.asUint8List();
  }

  void dispose() {
    _session?.release();
    _session = null;
  }
}
