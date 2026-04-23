import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:mana_poster/app/config/landing_page_seed.dart';
import 'package:mana_poster/features/prehome/models/landing_page_config.dart';

class LandingPageConfigService {
  const LandingPageConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<LandingPageConfig> fetchConfig() async {
    try {
      final doc = await firestore
          .collection('websiteConfig')
          .doc('landingPage')
          .get();
      final data = doc.data();
      if (data == null) {
        return LandingPageConfig.fallback();
      }
      final fallback = LandingPageSeed.firestoreLandingPageDocument;
      return LandingPageConfig(
        showHero: _toBool(
          _firstValue(data, const <String>[
            'showHero',
            'hero.enabled',
            'hero.show',
            'sections.hero.enabled',
            'sections.hero.show',
          ]),
          fallback: fallback['showHero'] as bool,
        ),
        showPreview: _toBool(
          _firstValue(data, const <String>[
            'showPreview',
            'preview.enabled',
            'preview.show',
            'sections.preview.enabled',
            'sections.preview.show',
          ]),
          fallback: fallback['showPreview'] as bool,
        ),
        showFeatures: _toBool(
          _firstValue(data, const <String>[
            'showFeatures',
            'features.enabled',
            'features.show',
            'sections.features.enabled',
            'sections.features.show',
          ]),
          fallback: fallback['showFeatures'] as bool,
        ),
        showCategories: _toBool(
          _firstValue(data, const <String>[
            'showCategories',
            'categories.enabled',
            'categories.show',
            'sections.categories.enabled',
            'sections.categories.show',
          ]),
          fallback: fallback['showCategories'] as bool,
        ),
        showDynamicEvents: _toBool(
          _firstValue(data, const <String>[
            'showDynamicEvents',
            'dynamicEvents.enabled',
            'dynamicEvents.show',
            'sections.dynamicEvents.enabled',
            'sections.dynamicEvents.show',
          ]),
          fallback: fallback['showDynamicEvents'] as bool,
        ),
        showPlans: _toBool(
          _firstValue(data, const <String>[
            'showPlans',
            'plans.enabled',
            'plans.show',
            'sections.plans.enabled',
            'sections.plans.show',
          ]),
          fallback: fallback['showPlans'] as bool,
        ),
        showTestimonials: _toBool(
          _firstValue(data, const <String>[
            'showTestimonials',
            'testimonials.enabled',
            'testimonials.show',
            'sections.testimonials.enabled',
            'sections.testimonials.show',
          ]),
          fallback: fallback['showTestimonials'] as bool,
        ),
        showFaq: _toBool(
          _firstValue(data, const <String>[
            'showFaq',
            'faq.enabled',
            'faq.show',
            'sections.faq.enabled',
            'sections.faq.show',
          ]),
          fallback: fallback['showFaq'] as bool,
        ),
        showDownloadCta: _toBool(
          _firstValue(data, const <String>[
            'showDownloadCta',
            'downloadCta.enabled',
            'downloadCta.show',
            'download.enabled',
            'cta.enabled',
            'sections.downloadCta.enabled',
            'sections.download.enabled',
            'sections.cta.enabled',
          ]),
          fallback: fallback['showDownloadCta'] as bool,
        ),
        downloadUrl: _safeUrl(
          _firstString(data, const <String>[
                'downloadUrl',
                'playStoreUrl',
                'appDownloadUrl',
                'links.downloadUrl',
                'links.playStoreUrl',
                'download.url',
                'download.playStoreUrl',
                'downloadCta.url',
                'downloadCta.downloadUrl',
                'cta.downloadUrl',
                'cta.primaryUrl',
                'app.downloadUrl',
              ]) ??
              fallback['downloadUrl'] as String?,
        ),
        watchDemoUrl: _safeUrl(
          _firstString(data, const <String>[
                'watchDemoUrl',
                'demoUrl',
                'videoUrl',
                'links.watchDemoUrl',
                'links.demoUrl',
                'demo.url',
                'demo.videoUrl',
                'cta.watchDemoUrl',
                'cta.demoUrl',
                'hero.watchDemoUrl',
                'hero.demoUrl',
              ]) ??
              fallback['watchDemoUrl'] as String?,
        ),
        supportEmail: _sanitizeText(
          _firstString(data, const <String>[
                'supportEmail',
                'contact.supportEmail',
                'contact.email',
                'support.email',
                'footer.supportEmail',
              ]) ??
              fallback['supportEmail'] as String?,
        ),
        facebookUrl: _safeUrl(
          _firstString(data, const <String>[
                'facebookUrl',
                'social.facebookUrl',
                'social.facebook',
                'social.facebook.url',
                'socialLinks.facebookUrl',
                'socialLinks.facebook',
                'footer.facebookUrl',
              ]) ??
              fallback['facebookUrl'] as String?,
        ),
        instagramUrl: _safeUrl(
          _firstString(data, const <String>[
                'instagramUrl',
                'social.instagramUrl',
                'social.instagram',
                'social.instagram.url',
                'socialLinks.instagramUrl',
                'socialLinks.instagram',
                'footer.instagramUrl',
              ]) ??
              fallback['instagramUrl'] as String?,
        ),
        youtubeUrl: _safeUrl(
          _firstString(data, const <String>[
                'youtubeUrl',
                'youTubeUrl',
                'social.youtubeUrl',
                'social.youtube',
                'social.youtube.url',
                'social.youTubeUrl',
                'socialLinks.youtubeUrl',
                'socialLinks.youtube',
                'footer.youtubeUrl',
              ]) ??
              fallback['youtubeUrl'] as String?,
        ),
        heroEyebrow: _sanitizeText(
          _firstString(data, const <String>['heroEyebrow']) ??
              fallback['heroEyebrow'] as String?,
        ),
        heroTitle: _sanitizeText(
          _firstString(data, const <String>['heroTitle']) ??
              fallback['heroTitle'] as String?,
        ),
        heroSubtitle: _sanitizeText(
          _firstString(data, const <String>['heroSubtitle']) ??
              fallback['heroSubtitle'] as String?,
        ),
        heroPrimaryCtaLabel: _sanitizeText(
          _firstString(data, const <String>['heroPrimaryCtaLabel']) ??
              fallback['heroPrimaryCtaLabel'] as String?,
        ),
        heroSecondaryCtaLabel: _sanitizeText(
          _firstString(data, const <String>['heroSecondaryCtaLabel']) ??
              fallback['heroSecondaryCtaLabel'] as String?,
        ),
        heroHighlightLabel: _sanitizeText(
          _firstString(data, const <String>['heroHighlightLabel']) ??
              fallback['heroHighlightLabel'] as String?,
        ),
        previewEyebrow: _sanitizeText(
          _firstString(data, const <String>['previewEyebrow']) ??
              fallback['previewEyebrow'] as String?,
        ),
        previewTitle: _sanitizeText(
          _firstString(data, const <String>['previewTitle']) ??
              fallback['previewTitle'] as String?,
        ),
        previewSubtitle: _sanitizeText(
          _firstString(data, const <String>['previewSubtitle']) ??
              fallback['previewSubtitle'] as String?,
        ),
        featuresEyebrow: _sanitizeText(
          _firstString(data, const <String>['featuresEyebrow']) ??
              fallback['featuresEyebrow'] as String?,
        ),
        featuresTitle: _sanitizeText(
          _firstString(data, const <String>['featuresTitle']) ??
              fallback['featuresTitle'] as String?,
        ),
        featuresSubtitle: _sanitizeText(
          _firstString(data, const <String>['featuresSubtitle']) ??
              fallback['featuresSubtitle'] as String?,
        ),
        categoriesEyebrow: _sanitizeText(
          _firstString(data, const <String>['categoriesEyebrow']) ??
              fallback['categoriesEyebrow'] as String?,
        ),
        categoriesTitle: _sanitizeText(
          _firstString(data, const <String>['categoriesTitle']) ??
              fallback['categoriesTitle'] as String?,
        ),
        categoriesSubtitle: _sanitizeText(
          _firstString(data, const <String>['categoriesSubtitle']) ??
              fallback['categoriesSubtitle'] as String?,
        ),
        dynamicEventsEyebrow: _sanitizeText(
          _firstString(data, const <String>['dynamicEventsEyebrow']) ??
              fallback['dynamicEventsEyebrow'] as String?,
        ),
        dynamicEventsTitle: _sanitizeText(
          _firstString(data, const <String>['dynamicEventsTitle']) ??
              fallback['dynamicEventsTitle'] as String?,
        ),
        dynamicEventsSubtitle: _sanitizeText(
          _firstString(data, const <String>['dynamicEventsSubtitle']) ??
              fallback['dynamicEventsSubtitle'] as String?,
        ),
        plansEyebrow: _sanitizeText(
          _firstString(data, const <String>['plansEyebrow']) ??
              fallback['plansEyebrow'] as String?,
        ),
        plansTitle: _sanitizeText(
          _firstString(data, const <String>['plansTitle']) ??
              fallback['plansTitle'] as String?,
        ),
        plansSubtitle: _sanitizeText(
          _firstString(data, const <String>['plansSubtitle']) ??
              fallback['plansSubtitle'] as String?,
        ),
        plansPrimaryCtaLabel: _sanitizeText(
          _firstString(data, const <String>['plansPrimaryCtaLabel']) ??
              fallback['plansPrimaryCtaLabel'] as String?,
        ),
        faqEyebrow: _sanitizeText(
          _firstString(data, const <String>['faqEyebrow']) ??
              fallback['faqEyebrow'] as String?,
        ),
        faqTitle: _sanitizeText(
          _firstString(data, const <String>['faqTitle']) ??
              fallback['faqTitle'] as String?,
        ),
        faqSubtitle: _sanitizeText(
          _firstString(data, const <String>['faqSubtitle']) ??
              fallback['faqSubtitle'] as String?,
        ),
        downloadEyebrow: _sanitizeText(
          _firstString(data, const <String>['downloadEyebrow']) ??
              fallback['downloadEyebrow'] as String?,
        ),
        downloadTitle: _sanitizeText(
          _firstString(data, const <String>['downloadTitle']) ??
              fallback['downloadTitle'] as String?,
        ),
        downloadSubtitle: _sanitizeText(
          _firstString(data, const <String>['downloadSubtitle']) ??
              fallback['downloadSubtitle'] as String?,
        ),
        downloadButtonLabel: _sanitizeText(
          _firstString(data, const <String>['downloadButtonLabel']) ??
              fallback['downloadButtonLabel'] as String?,
        ),
        footerTagline: _sanitizeText(
          _firstString(data, const <String>['footerTagline']) ??
              fallback['footerTagline'] as String?,
        ),
        customText: () {
          final raw = data['customText'];
          if (raw is! Map) {
            return const <String, String>{};
          }
          return raw.map<String, String>((dynamic key, dynamic value) {
            return MapEntry(
              key.toString(),
              value is String ? value.trim() : value?.toString() ?? '',
            );
          });
        }(),
      );
    } catch (error, stackTrace) {
      debugPrint('LandingPageConfigService.fetchConfig failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return LandingPageConfig.fallback();
    }
  }

  bool _toBool(Object? value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  String _safeUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return '';
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http' && scheme != 'mailto') {
      return '';
    }
    return value;
  }

  String _sanitizeText(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Object? _firstValue(Map<String, dynamic> data, List<String> paths) {
    for (final path in paths) {
      final value = _valueAtPath(data, path);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String? _firstString(Map<String, dynamic> data, List<String> paths) {
    final value = _firstValue(data, paths);
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  Object? _valueAtPath(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final segment in path.split('.')) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    return current;
  }
}
