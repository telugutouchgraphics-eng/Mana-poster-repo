import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class EditorAssetCategory {
  const EditorAssetCategory({required this.id, required this.name, required this.sortOrder});
  final String id;
  final String name;
  final int sortOrder;
}

class EditorRemoteAsset {
  const EditorRemoteAsset({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.kind,
    required this.value,
    required this.fileUrl,
    required this.thumbnailUrl,
    required this.extension,
    required this.byteSize,
    required this.sha256,
    required this.sortOrder,
  });
  final String id;
  final String categoryId;
  final String name;
  final String kind;
  final String value;
  final String fileUrl;
  final String thumbnailUrl;
  final String extension;
  final int byteSize;
  final String sha256;
  final int sortOrder;
}

class EditorAssetCatalog {
  const EditorAssetCatalog({required this.categories, required this.assets});
  final List<EditorAssetCategory> categories;
  final List<EditorRemoteAsset> assets;
  static const empty = EditorAssetCatalog(categories: [], assets: []);
}

class EditorAssetCatalogService {
  EditorAssetCatalogService({FirebaseFirestore? firestore, http.Client? client})
      : _firestoreOverride = firestore,
        _client = client ?? http.Client();

  final FirebaseFirestore? _firestoreOverride;
  final http.Client _client;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<EditorAssetCatalog> loadCatalog() async {
    if (_firestoreOverride == null && Firebase.apps.isEmpty) {
      return EditorAssetCatalog.empty;
    }
    try {
      final cached = await _load(Source.cache);
      if (cached.categories.isNotEmpty) return cached;
    } catch (_) {}
    return _load(Source.serverAndCache);
  }

  Future<EditorAssetCatalog> refreshCatalog() => _load(Source.serverAndCache);

  Future<EditorAssetCatalog> _load(Source source) async {
    final results = await Future.wait([
      _firestore.collection('editorAssetCategories').where('active', isEqualTo: true).get(GetOptions(source: source)),
      _firestore.collection('editorAssets').where('active', isEqualTo: true).get(GetOptions(source: source)),
    ]);
    final categories = results[0].docs.map((doc) {
      final data = doc.data();
      return EditorAssetCategory(id: doc.id, name: '${data['name'] ?? 'Assets'}', sortOrder: _asInt(data['sortOrder']));
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final categoryIds = categories.map((item) => item.id).toSet();
    final assets = results[1].docs.map((doc) {
      final data = doc.data();
      return EditorRemoteAsset(
        id: doc.id,
        categoryId: '${data['categoryId'] ?? ''}',
        name: '${data['name'] ?? 'Asset'}',
        kind: '${data['kind'] ?? 'file'}',
        value: '${data['value'] ?? ''}',
        fileUrl: '${data['fileUrl'] ?? ''}',
        thumbnailUrl: '${data['thumbnailUrl'] ?? data['fileUrl'] ?? ''}',
        extension: '${data['extension'] ?? 'png'}'.toLowerCase(),
        byteSize: _asInt(data['byteSize']),
        sha256: '${data['sha256'] ?? ''}'.toLowerCase(),
        sortOrder: _asInt(data['sortOrder']),
      );
    }).where((item) =>
        categoryIds.contains(item.categoryId) &&
        ((item.kind == 'text' && item.value.isNotEmpty) ||
            (item.kind != 'text' && item.fileUrl.startsWith('https://')))).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return EditorAssetCatalog(categories: categories, assets: assets);
  }

  Future<String?> localPath(EditorRemoteAsset asset) async {
    final file = await _assetFile(asset);
    if (!await file.exists()) return null;
    if (await _isValid(file, asset)) return file.path;
    await file.delete().catchError((_) => file);
    return null;
  }

  Future<String> download(EditorRemoteAsset asset, {void Function(double progress)? onProgress}) async {
    final existing = await localPath(asset);
    if (existing != null) { onProgress?.call(1); return existing; }
    final target = await _assetFile(asset);
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.part');
    final request = http.Request('GET', Uri.parse(asset.fileUrl));
    final response = await _client.send(request).timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) throw HttpException('Download failed (${response.statusCode}).');
    final sink = temporary.openWrite();
    var received = 0;
    final expected = response.contentLength ?? asset.byteSize;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > 12 * 1024 * 1024) throw const FileSystemException('Asset exceeds download limit.');
        sink.add(chunk);
        if (expected > 0) onProgress?.call((received / expected).clamp(0, 1));
      }
    } finally { await sink.close(); }
    if (!await _isValid(temporary, asset)) {
      await temporary.delete().catchError((_) => temporary);
      throw const FormatException('Downloaded asset verification failed.');
    }
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
    onProgress?.call(1);
    return target.path;
  }

  Future<File> _assetFile(EditorRemoteAsset asset) async {
    final root = await getApplicationSupportDirectory();
    final extension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(asset.extension) ? asset.extension : 'png';
    return File('${root.path}${Platform.pathSeparator}editor_assets${Platform.pathSeparator}${asset.id}.$extension');
  }

  Future<bool> _isValid(File file, EditorRemoteAsset asset) async {
    if (asset.byteSize > 0 && await file.length() != asset.byteSize) return false;
    if (asset.sha256.isEmpty) return true;
    final digest = sha256.convert(await file.readAsBytes()).toString();
    return digest == asset.sha256;
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  void dispose() => _client.close();
}
