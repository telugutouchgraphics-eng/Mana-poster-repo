import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum EditorRemoteFontLanguage { telugu, english, hindi }

class EditorRemoteFont {
  const EditorRemoteFont({
    required this.id,
    required this.family,
    required this.displayName,
    required this.language,
    required this.fileUrl,
    required this.extension,
    required this.byteSize,
    required this.sha256,
    required this.sortOrder,
  });

  final String id;
  final String family;
  final String displayName;
  final EditorRemoteFontLanguage language;
  final String fileUrl;
  final String extension;
  final int byteSize;
  final String sha256;
  final int sortOrder;
}

class EditorFontCatalog {
  const EditorFontCatalog({required this.fonts});

  final List<EditorRemoteFont> fonts;

  static const empty = EditorFontCatalog(fonts: <EditorRemoteFont>[]);
}

class EditorFontCatalogService {
  EditorFontCatalogService({FirebaseFirestore? firestore, http.Client? client})
    : _firestoreOverride = firestore,
      _client = client ?? http.Client();

  static const int maxFontBytes = 12 * 1024 * 1024;
  static const int maxAutoRegisteredFonts = 80;

  final FirebaseFirestore? _firestoreOverride;
  final http.Client _client;
  final Set<String> _registeredFamilies = <String>{};

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<EditorFontCatalog> loadCatalog() async {
    if (_firestoreOverride == null && Firebase.apps.isEmpty) {
      return EditorFontCatalog.empty;
    }
    try {
      final cached = await _load(Source.cache);
      if (cached.fonts.isNotEmpty) {
        return cached;
      }
    } catch (_) {}
    return _load(Source.serverAndCache);
  }

  Future<EditorFontCatalog> loadAndRegisterCatalog() async {
    final catalog = await loadCatalog();
    final registered = <EditorRemoteFont>[];
    for (final font in catalog.fonts.take(maxAutoRegisteredFonts)) {
      if (await ensureRegistered(font)) {
        registered.add(font);
      }
    }
    return EditorFontCatalog(fonts: registered);
  }

  Future<bool> ensureRegisteredByFamily(
    String family,
    EditorFontCatalog catalog,
  ) async {
    if (_registeredFamilies.contains(family)) {
      return true;
    }
    for (final font in catalog.fonts) {
      if (font.family == family) {
        return ensureRegistered(font);
      }
    }
    return false;
  }

  Future<bool> ensureRegistered(EditorRemoteFont font) async {
    if (_registeredFamilies.contains(font.family)) {
      return true;
    }
    try {
      final file = await _fontFile(font);
      if (!await _isValid(file, font)) {
        await _download(font, file);
      }
      final bytes = await file.readAsBytes();
      final loader = FontLoader(font.family)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      await loader.load();
      _registeredFamilies.add(font.family);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<EditorFontCatalog> _load(Source source) async {
    final snapshot = await _firestore
        .collection('editorFonts')
        .where('active', isEqualTo: true)
        .get(GetOptions(source: source));
    final fonts = snapshot.docs
        .map((doc) => _fontFromDoc(doc.id, doc.data()))
        .whereType<EditorRemoteFont>()
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return EditorFontCatalog(fonts: fonts);
  }

  EditorRemoteFont? _fontFromDoc(String id, Map<String, dynamic> data) {
    final fileUrl = '${data['fileUrl'] ?? data['downloadUrl'] ?? ''}'.trim();
    if (!fileUrl.startsWith('https://')) {
      return null;
    }
    final extension = '${data['extension'] ?? ''}'.toLowerCase().trim();
    if (extension != 'ttf' && extension != 'otf') {
      return null;
    }
    final byteSize = _asInt(data['byteSize']);
    if (byteSize <= 0 || byteSize > maxFontBytes) {
      return null;
    }
    final family = _safeFamilyName(
      '${data['family'] ?? data['fontFamily'] ?? data['name'] ?? id}',
    );
    if (family.isEmpty) {
      return null;
    }
    return EditorRemoteFont(
      id: id,
      family: family,
      displayName: '${data['displayName'] ?? data['name'] ?? family}'.trim(),
      language: _parseLanguage(data['language']),
      fileUrl: fileUrl,
      extension: extension,
      byteSize: byteSize,
      sha256: '${data['sha256'] ?? ''}'.toLowerCase().trim(),
      sortOrder: _asInt(data['sortOrder']),
    );
  }

  Future<File> _fontFile(EditorRemoteFont font) async {
    final root = await getApplicationSupportDirectory();
    return File(
      '${root.path}${Platform.pathSeparator}editor_fonts'
      '${Platform.pathSeparator}${font.id}.${font.extension}',
    );
  }

  Future<void> _download(EditorRemoteFont font, File target) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.part');
    final request = http.Request('GET', Uri.parse(font.fileUrl));
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw HttpException('Font download failed (${response.statusCode}).');
    }
    final sink = temporary.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        if (received > maxFontBytes) {
          throw const FileSystemException('Font exceeds download limit.');
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
    if (!await _isValid(temporary, font)) {
      try {
        await temporary.delete();
      } catch (_) {}
      throw const FormatException('Downloaded font verification failed.');
    }
    if (await target.exists()) {
      await target.delete();
    }
    await temporary.rename(target.path);
  }

  Future<bool> _isValid(File file, EditorRemoteFont font) async {
    if (!await file.exists()) {
      return false;
    }
    if (await file.length() != font.byteSize) {
      return false;
    }
    if (font.sha256.isEmpty) {
      return true;
    }
    final digest = sha256.convert(await file.readAsBytes()).toString();
    return digest == font.sha256;
  }

  static EditorRemoteFontLanguage _parseLanguage(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    if (normalized == 'english' || normalized == 'en') {
      return EditorRemoteFontLanguage.english;
    }
    if (normalized == 'hindi' || normalized == 'hi') {
      return EditorRemoteFontLanguage.hindi;
    }
    return EditorRemoteFontLanguage.telugu;
  }

  static String _safeFamilyName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(
      RegExp(r'[\u0000-\u001f]'),
      '',
    );
  }

  static int _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  void dispose() => _client.close();
}
