import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:mana_poster/features/image_editor/models/editor_page_config.dart';
import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/models/remote_premium_template.dart';

class PremiumTemplateRemoteService {
  const PremiumTemplateRemoteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  Future<List<RemotePremiumTemplate>> fetchActiveTemplates({
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('premium_templates')
          .where('isActive', isEqualTo: true);
      final normalizedCategory = category?.trim();
      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        query = query.where('category', isEqualTo: normalizedCategory);
      }
      final snapshot = await query.get();

      final templates = <RemotePremiumTemplate>[];
      for (final doc in snapshot.docs) {
        final template = await _mapDocument(doc);
        if (template != null) {
          templates.add(template);
        }
      }
      templates.sort((a, b) {
        final updatedCompare = b.updatedAtMillis.compareTo(a.updatedAtMillis);
        if (updatedCompare != 0) {
          return updatedCompare;
        }
        final createdCompare = b.createdAtMillis.compareTo(a.createdAtMillis);
        if (createdCompare != 0) {
          return createdCompare;
        }
        return b.sortOrder.compareTo(a.sortOrder);
      });
      return templates;
    } catch (_) {
      return const <RemotePremiumTemplate>[];
    }
  }

  Future<RemotePremiumTemplate?> _mapDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final titleEn = (data['titleEn'] as String?)?.trim();
    final previewUrl =
        (data['previewUrl'] as String?)?.trim() ??
        await _resolveStorageUrl(data['previewStoragePath'] as String?);
    final templateDocumentSource =
        (data['templateDocumentUrl'] as String?)?.trim() ??
        await _resolveStorageUrl(
          data['templateDocumentStoragePath'] as String?,
        );
    final productId = (data['productId'] as String?)?.trim();
    final category = (data['category'] as String?)?.trim() ?? '';
    final widthPx = (data['widthPx'] as num?)?.toInt();
    final heightPx = (data['heightPx'] as num?)?.toInt();
    final createdAtMillis =
        _toMillis(data['createdAt']) ?? _toMillis(data['updatedAt']) ?? 0;
    final updatedAtMillis =
        _toMillis(data['updatedAt']) ?? _toMillis(data['createdAt']) ?? 0;
    final personalizationConfig = _parsePersonalizationConfig(data);

    if (titleEn == null ||
        titleEn.isEmpty ||
        previewUrl == null ||
        previewUrl.isEmpty ||
        templateDocumentSource == null ||
        templateDocumentSource.isEmpty ||
        productId == null ||
        productId.isEmpty ||
        widthPx == null ||
        heightPx == null ||
        widthPx <= 0 ||
        heightPx <= 0) {
      return null;
    }

    return RemotePremiumTemplate(
      id: doc.id,
      titleTe: (data['titleTe'] as String?)?.trim() ?? titleEn,
      titleHi: (data['titleHi'] as String?)?.trim() ?? titleEn,
      titleEn: titleEn,
      previewUrl: previewUrl,
      templateDocumentSource: templateDocumentSource,
      productId: productId,
      fallbackProductIds: ((data['fallbackProductIds'] as List?) ?? const [])
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      priceInr: (data['priceInr'] as num?)?.toInt() ?? 499,
      pageConfig: EditorPageConfig(
        name: titleEn,
        widthPx: widthPx,
        heightPx: heightPx,
      ),
      category: category,
      categoryTags: _parseCategoryTags(data, category: category),
      personalizationConfig: personalizationConfig,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis,
    );
  }

  int? _toMillis(Object? raw) {
    if (raw is Timestamp) {
      return raw.millisecondsSinceEpoch;
    }
    if (raw is DateTime) {
      return raw.millisecondsSinceEpoch;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw.trim());
      return parsed?.millisecondsSinceEpoch;
    }
    return null;
  }

  List<String> _parseCategoryTags(
    Map<String, dynamic> data, {
    required String category,
  }) {
    final tags = ((data['categoryTags'] as List?) ?? const <dynamic>[])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    if (category.isNotEmpty) {
      tags.add(category);
    }
    return tags.toList(growable: false);
  }

  CreatorPosterPersonalization? _parsePersonalizationConfig(
    Map<String, dynamic> data,
  ) {
    final nested = data['personalization'] ?? data['personalizationConfig'];
    final Map<String, dynamic> source;
    if (nested is Map<String, dynamic>) {
      source = nested;
    } else if (nested is Map) {
      source = nested.cast<String, dynamic>();
    } else {
      source = data;
    }

    if (source.isEmpty) {
      return null;
    }

    final bool hasPremiumBoardConfig =
        source.containsKey('boardVariant') ||
        source.containsKey('nameScale') ||
        source.containsKey('designationScale') ||
        source.containsKey('phoneScale') ||
        source.containsKey('showStyledNameStrip') ||
        source.containsKey('showStyledDesignationStrip');

    return CreatorPosterPersonalization(
      photoShape: _parsePhotoShape(source['photoShape']),
      photoX: _readDouble(source, 'photoX', 50),
      photoY: _readDouble(source, 'photoY', 45),
      photoScale: _readDouble(source, 'photoScale', 36),
      nameX: _readDouble(source, 'nameX', 50),
      nameY: _readDouble(source, 'nameY', 82),
      showBottomStrip:
          source['showBottomStrip'] as bool? ??
          (hasPremiumBoardConfig ? false : true),
      stripHeight: _readDouble(source, 'stripHeight', 16),
      showWhatsapp:
          source['showWhatsapp'] as bool? ??
          (hasPremiumBoardConfig ? true : true),
      sampleName: (source['sampleName'] as String?)?.trim().isNotEmpty == true
          ? (source['sampleName'] as String).trim()
          : CreatorPosterPersonalization.defaults.sampleName,
      nameScale: _readDouble(source, 'nameScale', 100),
      showStyledNameStrip:
          source['showStyledNameStrip'] as bool? ?? hasPremiumBoardConfig,
      showStyledDesignationStrip:
          source['showStyledDesignationStrip'] as bool? ??
          hasPremiumBoardConfig,
      sampleDesignation: (source['sampleDesignation'] as String? ?? '').trim(),
      designationScale: _readDouble(
        source,
        'designationScale',
        CreatorPosterPersonalization.defaults.designationScale,
      ),
      phoneScale: _readDouble(
        source,
        'phoneScale',
        CreatorPosterPersonalization.defaults.phoneScale,
      ),
      nameStripColor:
          (source['nameStripColor'] as String? ?? '').trim().isNotEmpty
          ? (source['nameStripColor'] as String).trim()
          : CreatorPosterPersonalization.defaults.nameStripColor,
      designationStripColor:
          (source['designationStripColor'] as String? ?? '').trim().isNotEmpty
          ? (source['designationStripColor'] as String).trim()
          : CreatorPosterPersonalization.defaults.designationStripColor,
      boardVariant: source['boardVariant'] is num
          ? (source['boardVariant'] as num).toInt()
          : CreatorPosterPersonalization.defaults.boardVariant,
      photoRenderMode: _parseRenderMode(source['photoRenderMode']),
      edgeStyle: _parseEdgeStyle(source['edgeStyle']),
      showSafeAreas:
          source['showSafeAreas'] as bool? ??
          CreatorPosterPersonalization.defaults.showSafeAreas,
    );
  }

  String _parseRenderMode(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    return value == 'original' ? 'original' : 'cutout';
  }

  String _parseEdgeStyle(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    return value == 'sharp' ? 'sharp' : 'soft_fade';
  }

  String _parsePhotoShape(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    switch (value) {
      case 'circle':
      case 'scallop_circle':
      case 'soft_burst':
      case 'rounded_square':
      case 'vertical_rectangle':
      case 'rounded':
      case 'square':
      case 'hexagon':
      case 'pill':
      case 'oval':
      case 'flower':
      case 'diamond':
      case 'arch':
      case 'shield':
      case 'star':
      case 'blob':
      case 'badge':
      case 'heart':
      case 'sunburst':
      case 'transparent_bottom_fade':
      case 'transparent_clean':
      case 'transparent_soft_round':
      case 'transparent_sharp_round':
      case 'custom_screen_fit':
      case 'custom_board_fit':
      case 'custom_frame_fit':
      case 'custom_polygon_fit':
        return value;
      default:
        return CreatorPosterPersonalization.defaults.photoShape;
    }
  }

  double _readDouble(Map<String, dynamic> data, String key, double fallback) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  Future<String?> _resolveStorageUrl(String? storagePath) async {
    final normalized = storagePath?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    try {
      return await storage.ref(normalized).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
