import 'package:flutter/material.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

enum LegalDocumentType { privacyPolicy, termsAndConditions }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.documentType});

  final LegalDocumentType documentType;

  @override
  Widget build(BuildContext context) {
    final copy = _LegalCopy(context.strings, documentType);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          copy.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: GradientShell(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      copy.badge,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.lastUpdated,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...copy.sections.map((section) => _SectionCard(section: section)),
            const SizedBox(height: 8),
            Text(
              copy.footer,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

class _LegalCopy {
  const _LegalCopy(this.strings, this.documentType);

  final AppStrings strings;
  final LegalDocumentType documentType;

  bool get _isPrivacy => documentType == LegalDocumentType.privacyPolicy;

  String get title => _isPrivacy
      ? strings.localized(
          telugu: 'ప్రైవసీ పాలసీ',
          english: 'Privacy Policy',
          hindi: 'प्राइवेसी पॉलिसी',
          tamil: 'தனியுரிமை கொள்கை',
          kannada: 'ಗೌಪ್ಯತಾ ನೀತಿ',
          malayalam: 'സ്വകാര്യതാ നയം',
        )
      : strings.localized(
          telugu: 'నిబంధనలు మరియు షరతులు',
          english: 'Terms & Conditions',
          hindi: 'नियम और शर्तें',
          tamil: 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
          kannada: 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',
          malayalam: 'നിബന്ധനകളും വ്യവസ്ഥകളും',
        );

  String get badge => _isPrivacy
      ? strings.localized(
          telugu: 'డేటా రక్షణ',
          english: 'Data Protection',
          hindi: 'डेटा सुरक्षा',
          tamil: 'தரவு பாதுகாப்பு',
          kannada: 'ಡೇಟಾ ರಕ್ಷಣೆ',
          malayalam: 'ഡാറ്റ സംരക്ഷണം',
        )
      : strings.localized(
          telugu: 'వినియోగ నియమాలు',
          english: 'Usage Terms',
          hindi: 'उपयोग नियम',
          tamil: 'பயன்பாட்டு விதிகள்',
          kannada: 'ಬಳಕೆ ನಿಯಮಗಳು',
          malayalam: 'ഉപയോഗ നിബന്ധനകൾ',
        );

  String get summary => _isPrivacy
      ? strings.localized(
          telugu:
              'మీ డేటా, subscriptions, ప్రకటనలు, account deletion మరియు Firebase సేవల వినియోగం గురించి ఈ పేజీ వివరిస్తుంది.',
          english:
              'This page explains how Mana Poster Ai handles your data, subscriptions, editor assets, Telugu fonts, background removal, ads, account deletion, and Firebase-powered services.',
        )
      : strings.localized(
          telugu:
              'Mana Poster Ai వాడకం, subscriptions, చెల్లింపులు, ప్రకటనలు, ఖాతా బాధ్యతలు మరియు సేవా పరిమితులకు సంబంధించిన నియమాలు ఇక్కడ ఉన్నాయి.',
          english:
              'This page contains the rules for using Mana Poster Ai, including subscriptions, editor tools, premium assets, payments, ads, account responsibility, and service limitations.',
        );

  String get lastUpdated => strings.localized(
    telugu: 'చివరి నవీకరణ: 23 జూలై 2026',
    english: 'Last updated: July 23, 2026',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu: 'ప్రశ్నలు ఉంటే ${AppPublicInfo.supportEmail} కి సంప్రదించండి.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi: 'प्रश्न होने पर ${AppPublicInfo.supportEmail} पर संपर्क करें।',
    tamil:
        'கேள்விகள் இருந்தால் ${AppPublicInfo.supportEmail}-ஐ தொடர்பு கொள்ளுங்கள்.',
    kannada: 'ಪ್ರಶ್ನೆಗಳಿದ್ದರೆ ${AppPublicInfo.supportEmail} ಗೆ ಸಂಪರ್ಕಿಸಿ.',
    malayalam:
        'ചോദ്യങ്ങൾ ഉണ്ടെങ്കിൽ ${AppPublicInfo.supportEmail}-ൽ ബന്ധപ്പെടുക.',
  );

  List<_LegalSection> get _privacySections => <_LegalSection>[
    _LegalSection(
      strings.localized(
        telugu: 'మేము ఏ సమాచారం సేకరిస్తాము',
        english: 'What We Collect',
      ),
      strings.localized(
        telugu:
            'మేము మీ email address, పేరు, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, selected State/Union Territory, selected app language, selected political party categories, notification token, subscription status, referral code, referral attribution details, purchase verification కోసం అవసరమైన billing information, editor asset download/cache records, ad consent/status signals, support/report details మరియు app operate చేయడానికి అవసరమైన technical diagnostics ను collect/process చేయవచ్చు.',
        english:
            'We collect your email address, name, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, selected State/Union Territory, selected app language, selected political party categories, notification token, subscription status, referral code, referral attribution details, billing information needed for purchase verification, editor asset download/cache records, ad consent/status signals, support/report details, and technical diagnostics needed to operate the app.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'డేటాను ఎలా ఉపయోగిస్తాము',
        english: 'How We Use Data',
      ),
      strings.localized(
        telugu:
            'ఈ సమాచారాన్ని login, account security, region-based language selection, relevant poster categories చూపించడం, poster personalization, editor asset delivery, asset download access, save/export flows, PSD/TIFF import support, background removal, notification delivery, subscription verification, purchase restoration, rewarded-ad access checks, referral rewards, abuse prevention మరియు customer support కోసం ఉపయోగిస్తాము.',
        english:
            'We use this data for login, account security, region-based language selection, showing relevant poster categories, poster personalization, editor asset delivery, asset download access, save and export flows, PSD/TIFF import support, background removal, notification delivery, subscription verification, purchase restoration, rewarded-ad access checks, referral rewards, abuse prevention, and customer support.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ప్రాంతం, భాష మరియు రాజకీయ వర్గాల ఎంపికలు',
        english: 'Region, Language, and Political Category Choices',
      ),
      strings.localized(
        telugu:
            'మీరు State/Union Territory ఎంచుకున్నప్పుడు యాప్ ఆ ప్రాంతానికి సంబంధించిన primary language ను apply చేయవచ్చు. మీరు ఎంచుకున్న ప్రాంతం, language మరియు political party category preferences ను local device లో మరియు signed-in account తో sync చేయడానికి server లో save చేయవచ్చు. ఇవి home categories, dashboard uploads matching, personalization మరియు support కోసం ఉపయోగించబడతాయి. మీరు settings/profile లో ఈ ఎంపికలను మార్చవచ్చు.',
        english:
            'When you select a State or Union Territory, the app may apply the primary language for that region. Your selected region, language, and political party category preferences may be saved locally and synced with your signed-in account. These choices are used for home categories, dashboard upload matching, personalization, and support. You can update these choices from settings/profile.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ పోస్టర్ అప్లోడ్లు మరియు సమీక్ష',
        english: 'Community Uploads and Review',
      ),
      strings.localized(
        telugu:
            'Users manager review కోసం image, quote text లేదా image + quote రెండూ submit చేయవచ్చు. Upload చేసిన media, quote text, selected region, selected/user-corrected category, political party category where applicable, upload time, applicable visibility date, review status, rejection reason, contribution share/download counts మరియు related moderation history ను process చేయవచ్చు. Quote-only submissions raw text గా publish అవుతాయని హామీ లేదు; manager quote ను reference గా తీసుకుని poster image create/customize చేసి సరైన category లో upload చేయవచ్చు. Approved poster selected లేదా manager-corrected category లో ఇతర users కు కనిపించవచ్చు. Pending, rejected లేదా policy-violating uploads ను review, reject, edit, delay, remove లేదా retain చేయడానికి managers/admins కు హక్కు ఉంటుంది.',
        english:
            'Users may submit an image, quote text, or both for manager review. We may process the uploaded media, quote text, selected region, selected or manager-corrected category, political party category where applicable, upload time, applicable visibility date, review status, rejection reason, contribution share/download counts, and related moderation history. Quote-only submissions are not guaranteed to be published as raw text; a manager may use the quote as reference, create or customize a poster image, and upload it to the appropriate category. Approved posters may become visible to other users in the selected or manager-corrected category. Managers and admins may review, reject, edit, delay, remove, or retain pending, rejected, or policy-violating uploads as part of moderation and record-keeping.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ స్టేటస్, రిప్లైలు మరియు 24 గంటల నిల్వ',
        english: 'Community Status, Replies, and 24-Hour Retention',
      ),
      strings.localized(
        telugu:
            'యాప్‌లోని Status feature ద్వారా user text status, image status లేదా image + caption status upload చేయవచ్చు. ఒక user 24 గంటల active window లో 5 text statuses మరియు 2 image/image + caption statuses వరకు మాత్రమే ఉంచగలడు; పాత active status delete అయితే లేదా expire అయితే ఆ limit మళ్లీ available అవుతుంది. Image + caption status image status limit లోనే లెక్కించబడుతుంది. Abuse prevention, storage cost, performance, moderation లేదా security కారణాల వల్ల ఈ limits మారవచ్చు. Status visibility user ఎంచుకున్న State/Union Territory మరియు religion preference ఆధారంగా పరిమితం చేయబడుతుంది; అంటే status సాధారణంగా అదే region మరియు same/compatible religion scope లో ఉన్న signed-in users కు మాత్రమే చూపబడుతుంది. Status upload సమయంలో status text, caption, background color, compressed image file, image storage path, user ID, user display name, user photo URL, region ID/name, religion preference, created time, expiry time, view count, like count, reaction count, viewers map, likes map, reactions map మరియు related technical metadata process చేయవచ్చు.\n\nImage status upload అయినప్పుడు file size తగ్గించడానికి app-side compression చేయవచ్చు. Compression storage/bandwidth cost తగ్గించడానికి మరియు fast loading కోసం ఉంటుంది; original image ను తప్పనిసరిగా permanent archive గా retain చేస్తామని హామీ లేదు. Status media backend storage లో temporary గా save అవుతుంది. ప్రతి status కు 24 గంటల expiry time set చేయబడుతుంది. Expired statuses backend scheduled cleanup ద్వారా Firestore document, related comments/replies subcollection మరియు uploaded status image storage file నుండి permanent deletion కోసం process చేయబడతాయి. Cleanup scheduled basis లో run అవుతుంది కాబట్టి exact second కు delete అవుతుందని హామీ లేదు; సాధారణంగా expiry తర్వాత next cleanup cycle లో remove అవుతుంది.\n\nOther users owner status కు reply/comment పంపవచ్చు. Reply/comment లో commenter user ID, display name, comment text, status ID, status owner ID మరియు created time save చేయవచ్చు. Status owner మాత్రమే తన status replies screen లో replies చూడగలిగేలా app access design చేయబడింది; commenter తన own reply access/use కోసం limited records ఉండవచ్చు. Comments public feed comments గా ఉద్దేశించబడలేదు; అవి status owner కు response/feedback purpose కోసం మాత్రమే. Comments abusive, illegal, hateful, threatening, sexually explicit, misleading, spam, impersonation, copyright/trademark infringing, election/political misuse లేదా privacy-violating content కలిగి ఉండకూడదు. Policy violation, safety issue, legal request, abuse investigation లేదా technical requirement ఉంటే comments/status records review, restrict, delete, retain or disclose చేయాల్సి రావచ్చు.\n\nStatus viewer లో view counts, likes, reactions మరియు replies app experience కోసం process అవుతాయి. A user status tap/open చేస్తే view record update కావచ్చు. Like/reaction పంపితే account-level reaction data map లో update అవుతుంది. These interactions are not anonymous to the backend because fraud prevention, abuse prevention, count accuracy, security, moderation and user safety కోసం user-linked records అవసరం కావచ్చు.',
        english:
            'The in-app Status feature allows a user to upload a text status, an image status, or an image with a caption. A user may keep up to 5 text statuses and 2 image/image + caption statuses active within a 24-hour active window; deleting an old active status or waiting for expiry frees that limit again. An image with a caption counts toward the image status limit. These limits may change for abuse prevention, storage cost control, performance, moderation, or security reasons. Status visibility is limited based on the user-selected State/Union Territory and religion preference; generally, a status is shown only to signed-in users in the same region and same or compatible religion scope. If the user enables optional location access, we use Android native location permission and store only approximate city, district, state, country code, update time, and a random feed seed to prioritize nearby statuses, show area-relevant banners, support area-targeted admin push notifications, and provide privacy-safe admin insights. We do not store or display exact GPS latitude/longitude for this feature. Denying location permission does not block normal app use. When a status is uploaded, we may process the status text, caption, background color, compressed image file, image storage path, user ID, user display name, user photo URL, region ID/name, religion preference, approximate location fields if enabled, created time, expiry time, view count, like count, reaction count, viewers map, likes map, reactions map, and related technical metadata.\n\nWhen an image status is uploaded, the app may compress the file to reduce file size. Compression is used to reduce storage/bandwidth cost and improve loading speed; we do not promise to retain the original image as a permanent archive. Status media is stored temporarily in backend storage. Each status is assigned a 24-hour expiry time. Expired statuses are processed by backend scheduled cleanup for permanent deletion of the Firestore document, related comments/replies subcollection, and uploaded status image storage file. Because cleanup runs on a schedule, deletion is not guaranteed at the exact second of expiry; it normally occurs in the next cleanup cycle after expiry.\n\nOther users may send a reply/comment to a status owner. A reply/comment may store the commenter user ID, display name, comment text, status ID, status owner ID, and created time. The app is designed so that only the status owner can view replies for their own status in the replies screen; limited records may also remain available for the commenter\'s own use or enforcement. Comments are not intended as public feed comments; they are for response/feedback to the status owner only. Comments must not contain abusive, illegal, hateful, threatening, sexually explicit, misleading, spam, impersonation, copyright/trademark infringing, election/political misuse, or privacy-violating content. If there is a policy violation, safety issue, legal request, abuse investigation, or technical requirement, comments/status records may need to be reviewed, restricted, deleted, retained, or disclosed.\n\nThe status viewer processes view counts, likes, reactions, and replies for the app experience. If a user taps/opens a status, a view record may be updated. If a user sends a like/reaction, account-level reaction data may be updated in backend maps. These interactions are not anonymous to the backend because user-linked records may be required for fraud prevention, abuse prevention, count accuracy, security, moderation, and user safety.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Firebase, Analytics మరియు Ads',
        english: 'Firebase, Analytics, and Ads',
      ),
      strings.localized(
        telugu:
            'యాప్ Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing మరియు AdMob ను ఉపయోగిస్తుంది. ఈ సేవలు app performance, crash diagnostics, notifications, billing verification, premium asset delivery మరియు ad delivery కోసం ఉపయోగించబడతాయి. Personalized లేదా non-personalized ads, అలాగే paid subscription లేకుండా కొన్ని editor actions unlock చేసే rewarded ads చూపించడానికి AdMob device identifiers, IP address, consent status మరియు usage data ను process చేయవచ్చు.',
        english:
            'The app uses Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing, and AdMob. These services support app performance, crash diagnostics, notifications, billing verification, premium asset delivery, and ad delivery. AdMob may collect device identifiers, IP address, consent status, and usage data to provide personalized or non-personalized ads, including rewarded ads that may unlock selected editor actions without a paid subscription.',
      ),
    ),
    _LegalSection(
      strings.localized(telugu: 'డేటా షేరింగ్', english: 'Data Sharing'),
      strings.localized(
        telugu:
            'మేము personal data ను అమ్మము. Data essential service providers, lawful authorities, billing/review partners లేదా legal/security obligations కోసం అవసరమైనప్పుడు మాత్రమే share చేయవచ్చు.',
        english:
            'We do not sell personal data. Data may be shared only with essential service providers, lawful authorities, or where reasonably necessary for billing, moderation, fraud prevention, security, or legal compliance.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'పిల్లల గోప్యత',
        english: 'Children\'s Privacy',
      ),
      strings.localized(
        telugu: 'ఈ యాప్ 13 సంవత్సరాల లోపు పిల్లల కోసం ఉద్దేశించబడలేదు.',
        english: 'This app is not intended for children under the age of 13.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఫోటోలు, permissions మరియు storage',
        english: 'Photos, Permissions, and Storage',
      ),
      strings.localized(
        telugu:
            'Photo selection, poster saving, status image selection, PSD/TIFF import, local export మరియు optional notifications కోసం మాత్రమే permissions అడుగుతాము. మీరు వీటిని device settings లో మార్చవచ్చు. మీరు upload, import, export, status గా use, comment/reply లేదా share చేసే content కు మీరు బాధ్యులు. App media files, downloaded premium assets, brush resources, previews, export files మరియు temporary cache ను అవసరం మేరకు save చేసి, అవసరం ముగిసిన తర్వాత remove చేయవచ్చు. Status images upload ముందు compress చేయబడవచ్చు; temporary compressed files device లేదా backend processing పూర్తయ్యాక remove చేయవచ్చు.',
        english:
            'Permissions are requested only for photo selection, poster saving, status image selection, PSD/TIFF import, local export, and optional notifications. You can manage them from device settings. You remain responsible for any content you upload, import, export, use as a status, comment/reply to, or share. The app may temporarily cache media files, downloaded premium assets, brush resources, previews, and export files, and may remove temporary files when they are no longer needed. Status images may be compressed before upload; temporary compressed files may be removed after device or backend processing is complete.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Editor processing, assets మరియు downloads',
        english: 'Editor Processing, Assets, and Downloads',
      ),
      strings.localized(
        telugu:
            'Editor లో PSD/TIFF import, photo editing, brushes, layer effects, Telugu fonts, premium assets మరియు background removal tools ఉపయోగించవచ్చు. Premium assets backend/dashboard నుండి categories గా అందించబడవచ్చు. Asset thumbnail app లో కనిపిస్తుంది; user download/import చేసినప్పుడు asset device cache లో save కావచ్చు. Admins assets/categories ను update, remove లేదా replace చేయవచ్చు.',
        english:
            'The editor may support PSD/TIFF import, photo editing, brushes, layer effects, Telugu fonts, premium assets, and background removal tools. Premium assets may be delivered from the backend/admin dashboard by category. Asset thumbnails may be shown in the app, and downloaded/imported assets may be saved in device cache for faster reuse. Admins may update, remove, replace, or reorganize assets and categories over time. Background removal and other editor processing may run on-device where supported or through configured app services when needed for the requested feature.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Subscriptions మరియు billing',
        english: 'Subscriptions and Billing',
      ),
      strings.localized(
        telugu:
            'Subscription verification కోసం purchase tokens, product IDs, entitlement status మరియు billing status ను server-side లో process చేయవచ్చు. Mana Poster Ai లో వేర్వేరు Google Play Billing plans ఉండవచ్చు: App Pro (${SubscriptionPlanConfig.trialPriceDisplay} ${SubscriptionPlanConfig.trialDays} రోజులకు, cancel చేయకపోతే తర్వాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}), Editor Pro (premium editor assets, Telugu fonts, background removal కోసం నెలకు ₹99), yearly all-access (available ఉన్న చోట App Pro + Editor Pro benefits కలిపి సంవత్సరానికి ₹699). Plan availability, prices, taxes, grace periods, renewal behavior Google Play ద్వారా control అవుతాయి మరియు country/platform ఆధారంగా మారవచ్చు.',
        english:
            'For subscription verification, purchase tokens, product IDs, entitlement status, and billing status may be processed server-side. Mana Poster Ai may offer separate Play Billing plans, including App Pro (${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days, then ${SubscriptionPlanConfig.monthlyPriceDisplay} per month unless cancelled), Editor Pro (₹99 per month for premium editor assets, Telugu fonts, and background removal), and yearly all-access (₹699 per year where available, covering App Pro and Editor Pro benefits). Plan availability, prices, taxes, grace periods, and renewal behavior are controlled through Google Play and may vary by country or platform.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'మీ ఎంపికలు మరియు account deletion',
        english: 'Your Choices and Account Deletion',
      ),
      strings.localized(
        telugu:
            'మీరు optional notifications మరియు permissions ను off చేయవచ్చు. యాప్‌లో account deletion request option అందుబాటులో ఉంటుంది. Users complete data deletion ను in-app deletion option ద్వారా లేదా support ను సంప్రదించడం ద్వారా request చేయవచ్చు. Account delete చేసిన తర్వాత login access, poster profile details మరియు linked app data తొలగించబడవచ్చు. కొన్ని billing, tax, anti-fraud లేదా platform-required records పరిమిత కాలం నిల్వ ఉండవచ్చు. మరిన్ని వివరాలు: ${AppPublicInfo.accountDeletionUrl}',
        english:
            'You can turn off optional notifications and permissions. The app provides an in-app account deletion request option. Users can request complete data deletion using the in-app deletion option or by contacting support. After deletion, login access, poster profile details, and linked app data may be removed. Some billing, tax, anti-fraud, or platform-required records may be retained for a limited period. More details: ${AppPublicInfo.accountDeletionUrl}',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రిపోర్టింగ్ మరియు అపరిచిత/అనుచిత కంటెంట్',
        english: 'Reporting and Abusive Content',
      ),
      strings.localized(
        telugu:
            'అపరిచిత, దుర్వినియోగ, కాపీరైట్ ఉల్లంఘన, impersonation లేదా spam పోస్టర్ కనిపిస్తే, app లో available support/report option లేదా ${AppPublicInfo.supportEmail} ద్వారా report చేయవచ్చు. Complaints, moderation decisions, review evidence మరియు limited enforcement records ను abuse prevention, legal compliance మరియు safety కోసం retain చేయవచ్చు.',
        english:
            'If you see abusive, infringing, impersonating, deceptive, or spam content, you can report it using the app support/report option or by emailing ${AppPublicInfo.supportEmail}. Complaints, moderation decisions, review evidence, and limited enforcement records may be retained for abuse prevention, legal compliance, and user safety.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సంప్రదింపు సమాచారం',
        english: 'Contact Information',
      ),
      strings.localized(
        telugu:
            'ప్రైవసీ, billing, data usage లేదా account deletion సహాయం కోసం ${AppPublicInfo.supportEmail} కు ఇమెయిల్ చేయండి.',
        english:
            'For privacy, billing, data usage, or account deletion support, email ${AppPublicInfo.supportEmail}.',
      ),
    ),
  ];

  List<_LegalSection> get _termsSections => <_LegalSection>[
    _LegalSection(
      strings.localized(telugu: 'యాప్ వాడకం', english: 'Using the App'),
      strings.localized(
        telugu:
            'Mana Poster Ai వ్యక్తిగత, వ్యాపార మరియు ప్రచార పోస్టర్లు రూపొందించడానికి ఉద్దేశించబడింది. యాప్‌ను చట్టబద్ధంగా మరియు బాధ్యతతో మాత్రమే ఉపయోగించాలి.',
        english:
            'Mana Poster Ai is intended for personal, business, and promotional poster creation. You must use the app lawfully and responsibly.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ఖాతా మరియు కంటెంట్ బాధ్యత',
        english: 'Account and Content Responsibility',
      ),
      strings.localized(
        telugu:
            'మీ login వివరాలు భద్రంగా ఉంచాలి. మీరు upload చేసే photos, quote text, status images, status captions, status replies/comments, videos, logos లేదా poster materials ను ఉపయోగించే హక్కు మీకే ఉండాలి. మీరు submit చేసే quote లేదా image ను review, edit/customize, category correction మరియు app లో publication కోసం Mana Poster Ai ఉపయోగించడానికి non-exclusive permission ఇస్తారు. మీరు status గా upload చేసే text/image/caption ను selected region/religion scope లో చూపడానికి temporary permission ఇస్తారు. మీరు status reply/comment పంపితే, ఆ reply/comment status owner కు చూపడానికి మరియు safety/moderation/security purposes కోసం process చేయడానికి permission ఇస్తారు. చట్టవిరుద్ధం, మోసపూరితం, ద్వేషపూరితం, అసభ్యం, threatening, harassment, privacy-violating లేదా ఇతరుల హక్కులను ఉల్లంఘించే content నిషేధించబడుతుంది. యాప్‌లో ఇతర users కు కనిపించే posters/videos publication కు ముందు review చేయబడతాయి; statuses/replies short-lived అయినప్పటికీ policy/security review కు లోబడి ఉంటాయి.',
        english:
            'You must keep your login details secure. You must have the right to use any photos, quote text, status images, status captions, status replies/comments, videos, logos, or poster materials you upload. By submitting a quote or image, you give Mana Poster Ai non-exclusive permission to review, edit/customize, correct the category, and publish the resulting poster in the app. By uploading text/image/caption as a status, you give temporary permission to show it within the selected region/religion scope. By sending a status reply/comment, you give permission to show that reply/comment to the status owner and to process it for safety, moderation, and security purposes. Illegal, deceptive, hateful, obscene, threatening, harassing, privacy-violating, or infringing content is prohibited. Posters or videos shown to other users in the app are reviewed before publication; statuses/replies are short-lived but remain subject to policy and security review.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రాజకీయ వర్గాలు మరియు ప్రజా గుర్తులు',
        english: 'Political Categories and Public Symbols',
      ),
      strings.localized(
        telugu:
            'Political party categories, party names, party symbols/logos, State/Union Territory emblems మరియు public identifiers యాప్‌లో category navigation, regional relevance మరియు poster discovery కోసం మాత్రమే చూపించబడవచ్చు. ఇవి Mana Poster Ai ద్వారా endorsement, affiliation, sponsorship లేదా political claim గా పరిగణించరాదు. Users రాజకీయ లేదా public-interest content తయారు చేసే సమయంలో వర్తించే laws, election rules, platform policies, copyright/trademark rights మరియు factual accuracy కి బాధ్యత వహించాలి.',
        english:
            'Political party categories, party names, party symbols/logos, State/Union Territory emblems, and public identifiers may be shown only for category navigation, regional relevance, and poster discovery. They do not imply endorsement, affiliation, sponsorship, or any political claim by Mana Poster Ai. Users creating political or public-interest content are responsible for complying with applicable laws, election rules, platform policies, copyright/trademark rights, and factual accuracy.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Subscriptions మరియు premium access',
        english: 'Subscriptions and Premium Access',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai లో multiple subscription plans ఉండవచ్చు. App Pro కి ${SubscriptionPlanConfig.trialPriceDisplay} trial ${SubscriptionPlanConfig.trialDays} రోజులు ఉండవచ్చు; cancel చేయకపోతే తరువాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున renew అవుతుంది. Editor Pro premium editor assets, Telugu fonts మరియు background removal కోసం నెలకు ₹99 గా ఉండవచ్చు. Yearly all-access plan available ఉన్న చోట App Pro మరియు Editor Pro benefits కలిపి సంవత్సరానికి ₹699 గా ఉండవచ్చు. Active benefits purchased plan, successful Google Play verification, country availability మరియు current product configuration మీద ఆధారపడతాయి.',
        english:
            'Mana Poster Ai may offer multiple subscription plans. App Pro may include a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days and then renew at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month unless cancelled. Editor Pro may provide premium editor assets, Telugu fonts, and background removal for ₹99 per month. A yearly all-access plan may provide App Pro and Editor Pro benefits together for ₹699 per year where available. Active benefits depend on the plan purchased, successful Google Play verification, country availability, and current product configuration.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Editor tools మరియు asset license',
        english: 'Editor Tools and Asset License',
      ),
      strings.localized(
        telugu:
            'Editor లో premium assets, Telugu fonts, background removal, PSD/TIFF import, brushes, layer effects, text tools, erase tools మరియు export tools అందుబాటులో ఉండవచ్చు. Download చేసిన assets ను app లో poster/design creation కోసం మాత్రమే ఉపయోగించాలి. Asset files ను resell, redistribute, extract, republish, package లేదా standalone library గా share చేయడం నిషేధం. Third-party images, PSD files, fonts, logos లేదా copyrighted material import చేస్తే వాటి rights user బాధ్యత.',
        english:
            'The editor may include premium assets, Telugu fonts, background removal, PSD/TIFF import, brushes, layer effects, text tools, erase tools, and export tools. Downloaded assets are licensed for creating posters/designs inside Mana Poster Ai only. You must not resell, redistribute, extract, republish, package, or share asset files as a standalone asset library. If you import third-party images, PSD files, fonts, logos, or copyrighted material, you are responsible for having the required rights. Export quality may depend on source file quality, selected canvas size, device capability, memory limits, and the export settings used.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'రీఫండ్, రద్దు, ఆటో రీన్యువల్',
        english: 'Refund, Cancellation, and Auto-Renewal',
      ),
      strings.localized(
        telugu:
            'Subscription cancellation సాధారణంగా మీ Play Store లేదా App Store subscription settings లో చేయాలి. రద్దు చేసిన తర్వాత ప్రస్తుత billing period ముగిసే వరకు access కొనసాగవచ్చు. Refund eligibility ను Google Play లేదా Apple policies నిర్ణయిస్తాయి.',
        english:
            'Subscription cancellation is generally managed through your Play Store or App Store subscription settings. After cancelling, access may continue until the current billing period ends. Refund eligibility is determined by Google Play or Apple policies.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Referral Rewards',
        english: 'Referral Rewards',
      ),
      strings.localized(
        telugu:
            'Mana Poster Ai referral reward ఒక promotional benefit మాత్రమే. ఇది cash, wallet balance, gift card, payout లేదా transferable benefit కాదు. ఒక user తన referral code లేదా referral link ను ఇతరులకు share చేయవచ్చు. Referred user ఆ referral code/link ద్వారా app లో చేరి, valid account తో login అయి, ₹149 monthly subscription ను successful గా purchase చేసి, server-side billing verification complete అయిన తర్వాత మాత్రమే referral count పెరుగుతుంది. Install, signup, app open, trial-only access, failed payment, cancelled payment, refunded payment, chargeback, duplicate purchase, test purchase, sandbox purchase, unsupported SKU లేదా verification fail అయిన purchase referral count గా పరిగణించబడదు.\n\nప్రస్తుతం 15 valid paid referrals complete అయితే referrer account కు 30 days premium reward ఇవ్వబడుతుంది. Reward automatic paid subscription కాదు, auto-renew అవదు, cash value ఉండదు, refund లేదా encashment కు eligible కాదు. Referrer కు ఇప్పటికే paid subscription active గా ఉంటే, reward generally current paid access ముగిసిన తర్వాత లేదా system-calculated eligible time నుండి apply కావచ్చు, zodat paid days lose కాకుండా ఉంటుంది. Reward period పూర్తయిన తర్వాత premium access continue కావాలంటే user normal subscription కొనసాగించాలి లేదా కొత్త valid referral cycle complete చేయాలి.\n\nSame referred user ఒకసారి మాత్రమే count అవుతాడు. Self-referral, same person multiple accounts create చేయడం, device/account farming, fake payments, recycled accounts, shared payment tokens, manipulated install referrer, automated signups, misleading invitations, spam, abuse, fraud, refund abuse లేదా platform policy violation strictly prohibited. Mana Poster Ai suspected misuse ఉన్నప్పుడు referral count, reward eligibility, reward access లేదా linked accounts ను review, hold, reverse, suspend లేదా remove చేయవచ్చు. Fraud/abuse investigation లో కొన్ని anti-fraud records పరిమిత కాలం retain చేయవచ్చు.\n\nReferral rewards backend verification మీద ఆధారపడతాయి. Network delay, Play Billing/App Store delay, Firebase delay, account mismatch, product mismatch, stale attribution, server outage లేదా policy/security review కారణంగా count లేదా reward update ఆలస్యమవచ్చు. App లో కనిపించే progress informational మాత్రమే; final eligibility Mana Poster Ai server records మరియు verified billing status ఆధారంగా నిర్ణయించబడుతుంది. Mana Poster Ai referral rules, required referral count, reward duration, eligibility criteria, fraud checks, availability లేదా program continuation ను business, legal, security లేదా platform policy అవసరాలకు అనుగుణంగా మార్చవచ్చు, pause చేయవచ్చు లేదా stop చేయవచ్చు. Already earned valid rewards ను unfair గా remove చేయకుండా reasonable effort చేస్తాము, కానీ fraud, refund, chargeback, billing reversal, technical error లేదా policy/legal requirement ఉంటే correction చేయవచ్చు.\n\nReferral code share చేసే user truthful invitation మాత్రమే చేయాలి. Mana Poster Ai official offer ను తప్పుగా represent చేయడం, guaranteed income అని చెప్పడం, unauthorized ads/spam చేయడం, third-party brand/platform rules ఉల్లంఘించడం లేదా ఇతరుల personal data misuse చేయడం నిషేధం. Referral reward గురించి dispute ఉంటే ${AppPublicInfo.supportEmail} కు contact చేయాలి. Review కోసం user UID, referral code, subscribed account, purchase verification status మరియు relevant timestamps అవసరం కావచ్చు.',
        english:
            'The Mana Poster Ai referral reward is a promotional benefit only. It is not cash, wallet balance, a gift card, a payout, or a transferable benefit. A user may share their referral code or referral link with others. A referral is counted only when the referred user joins through that referral code/link, signs in with a valid account, successfully purchases the ₹149 monthly subscription, and the purchase is verified by Mana Poster Ai server-side billing verification. Installs, signups, app opens, trial-only access, failed payments, cancelled payments, refunded payments, chargebacks, duplicate purchases, test purchases, sandbox purchases, unsupported SKUs, or purchases that fail verification do not count as paid referrals.\n\nCurrently, 15 valid paid referrals earn 30 days of premium access for the referring account. The reward is not an automatic paid subscription, does not auto-renew, has no cash value, and is not eligible for refund, payout, or encashment. If the referring user already has active paid subscription access, the reward may generally be applied after the current paid access ends or from the system-calculated eligible time so that paid days are not lost. After the reward period ends, premium access continues only if the user maintains a normal subscription or completes another valid referral cycle.\n\nThe same referred user can be counted only once. Self-referrals, creating multiple accounts for the same person, device/account farming, fake payments, recycled accounts, shared payment tokens, manipulated install referrers, automated signups, misleading invitations, spam, abuse, fraud, refund abuse, or platform policy violations are strictly prohibited. If misuse is suspected, Mana Poster Ai may review, hold, reverse, suspend, or remove referral counts, reward eligibility, reward access, or linked accounts. Some anti-fraud records may be retained for a limited period for fraud and abuse investigation.\n\nReferral rewards depend on backend verification. Count or reward updates may be delayed because of network delay, Play Billing/App Store delay, Firebase delay, account mismatch, product mismatch, stale attribution, server outage, or policy/security review. Progress shown in the app is informational; final eligibility is determined from Mana Poster Ai server records and verified billing status. Mana Poster Ai may change, pause, or stop the referral program, including the required referral count, reward duration, eligibility criteria, fraud checks, or availability, to meet business, legal, security, or platform policy requirements. We will make reasonable efforts not to unfairly remove valid rewards already earned, but corrections may be made for fraud, refunds, chargebacks, billing reversals, technical errors, or legal/policy requirements.\n\nUsers sharing referral codes must make truthful invitations only. Misrepresenting the official Mana Poster Ai offer, claiming guaranteed income, running unauthorized ads/spam, violating third-party brand/platform rules, or misusing another person\'s personal data is prohibited. For referral reward disputes, contact ${AppPublicInfo.supportEmail}. Review may require user UID, referral code, subscribed account, purchase verification status, and relevant timestamps.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'ప్రకటనలు మరియు third-party services',
        english: 'Ads and Third-Party Services',
      ),
      strings.localized(
        telugu:
            'యాప్‌లో AdMob ads చూపించబడవచ్చు. Paid subscription లేకుండా కొన్ని premium editor actions unlock చేయడానికి rewarded ads చూపించవచ్చు. Rewarded-ad access paid subscription కాదు, auto-renew కాదు, device state, ad availability, network, policy లేదా fraud checks కారణంగా పరిమితం కావచ్చు. Ads availability, ad skip timing, billing services, Google sign-in, notifications లేదా Firebase services కొన్నిసార్లు third-party providers మీద ఆధారపడవచ్చు. మూడో పక్ష సేవలు నిరంతరంగా అందుబాటులో ఉంటాయని యాప్ హామీ ఇవ్వదు.',
        english:
            'The app may display AdMob ads, including rewarded ads that can unlock selected premium editor actions without a paid subscription. Rewarded-ad access is not a paid subscription, does not auto-renew, and may be limited by device state, ad availability, network, policy, or fraud checks. Ad availability, ad-skip timing, billing services, Google sign-in, notifications, or Firebase services may depend on third-party providers. The app does not guarantee uninterrupted availability of third-party services.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Account deletion మరియు device access',
        english: 'Account Deletion and Device Access',
      ),
      strings.localized(
        telugu:
            'యాప్‌లో account deletion request option అందుబాటులో ఉంటుంది. Delete అభ్యర్థన తర్వాత login access, poster profile data మరియు linked app data తొలగించబడవచ్చు. కొన్ని billing లేదా platform-required records పరిమిత కాలం నిల్వ ఉండవచ్చు.',
        english:
            'The app provides an account deletion request option. After deletion, login access, poster profile data, and linked app data may be removed. Some billing or platform-required records may be retained for a limited period.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ అప్లోడ్లు, మోడరేషన్ మరియు రిపోర్టింగ్',
        english: 'Community Uploads, Moderation, and Reporting',
      ),
      strings.localized(
        telugu:
            'Users manager review కోసం image, quote text లేదా రెండూ submit చేయవచ్చు. Quote text optional; manager దాన్ని copy/reference గా తీసుకుని poster image create/customize చేసి user selected category లేదా అవసరమైతే correct related category లో publish చేయవచ్చు. Dashboard లో manager ఎంచుకున్న final category app లో poster కనిపించే category గా ఉపయోగించబడుతుంది. Publication guarantee లేదు. Copyright లేకుండా third-party content upload చేయడం, ఇతరులుగా నటించడం, abusive/offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims లేదా rights లేని material నిషేధించబడుతుంది. Managers/admins uploads ను approve, reject, customize, delay, unpublish లేదా remove చేయవచ్చు. Rejected uploads కు reason ఇవ్వవచ్చు. Abuse లేదా infringement report చేయడానికి app support flow లేదా ${AppPublicInfo.supportEmail} ఉపయోగించవచ్చు.',
        english:
            'Users may submit an image, quote text, or both for manager review. Quote text is optional; a manager may copy or use it as reference to create/customize a poster image and publish it in the user-selected category or, when needed, a corrected related category. The final category selected in the dashboard is the category where the poster appears in the app. Publication is not guaranteed. Uploading third-party content without rights, impersonation, abusive or offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims, or material you do not have rights to use is prohibited. Managers and admins may approve, reject, customize, delay, unpublish, or remove uploads. Rejected uploads may include a reason. Abusive or infringing content can be reported through the app support flow or by emailing ${AppPublicInfo.supportEmail}.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ స్టేటస్, రిప్లైలు మరియు తాత్కాలిక కంటెంట్',
        english: 'Community Status, Replies, and Temporary Content',
      ),
      strings.localized(
        telugu:
            'Status feature short-lived community sharing కోసం మాత్రమే. User text, image లేదా image + caption status upload చేయవచ్చు. ఒక user 24 గంటల active window లో 5 text statuses మరియు 2 image/image + caption statuses వరకు మాత్రమే active గా ఉంచగలడు; పాత active status delete అయితే లేదా expire అయితే ఆ quota మళ్లీ free అవుతుంది. Image + caption status image status limit లోనే count అవుతుంది. Status సాధారణంగా user selected State/Union Territory మరియు religion preference ఆధారంగా same/compatible scope లో ఉన్న users కు మాత్రమే కనిపిస్తుంది. Region/religion filtering app experience మరియు safety కోసం ఉంటుంది; user తప్పుగా region/religion select చేస్తే visibility కూడా దాని ఆధారంగా మారవచ్చు. Status upload అయిన content 24 గంటల expiry తో backend లో save అవుతుంది మరియు scheduled cleanup ద్వారా status document, related replies/comments మరియు status image permanent deletion కోసం process చేయబడుతుంది. Exact second deletion guarantee లేదు; cleanup next scheduled cycle లో జరగవచ్చు.\n\nStatus image upload ముందు app file size తగ్గించడానికి compression చేయవచ్చు. Compression వల్ల storage/bandwidth తగ్గుతుంది; original full-size image retain చేయబడుతుందని హామీ లేదు. User status open చేసినప్పుడు view count update కావచ్చు. Other users like/reaction/reply ఇవ్వవచ్చు. Status owner replies screen లో replies చదవవచ్చు; reply text app UIలో 2 lines previewగా కనిపించి Read more ద్వారా expand కావచ్చు. Reply/comment పంపిన user తన మాటలకి బాధ్యుడు. Private, confidential, financial, medical, legal, password, OTP, address, personal ID, sensitive political/religious targeting లేదా ఇతరుల private information status/replyలో పెట్టకూడదు.\n\nMana Poster Ai status, replies, likes, reactions లేదా views ను public endorsement, official communication లేదా guaranteed delivery channel గా treat చేయదు. Network delay, moderation, security checks, backend cleanup, device issue, app update, account restriction లేదా policy enforcement వల్ల status/reply send, view, count, delete లేదా display behavior మారవచ్చు. Users abusive, illegal, spam, privacy-violating, impersonation, copyright/trademark issue లేదా deceptive political content ఉన్న status/reply ను in-app report option ద్వారా report చేయవచ్చు; report reason, optional details, reported content preview, reporter UID మరియు moderation metadata safety/legal review కోసం retain చేయవచ్చు. Abuse, spam, harassment, impersonation, copyright/trademark issue, illegal political misuse, misinformation risk, user safety concern, law enforcement request లేదా legal obligation ఉంటే Mana Poster Ai status/replies ను restrict, remove, preserve, review, disclose or disable చేయవచ్చు. Repeat misuse account restrictions కు దారితీయవచ్చు.',
        english:
            'The Status feature is intended only for short-lived community sharing. A user may upload a text, image, or image + caption status. A user may keep up to 5 text statuses and 2 image/image + caption statuses active within a 24-hour active window; deleting an old active status or waiting for expiry frees the quota again. An image + caption status counts toward the image status limit. A status is generally visible only to users in the same or compatible scope based on the selected State/Union Territory and religion preference. Region/religion filtering is used for app experience and safety; if a user selects the wrong region/religion, visibility may change accordingly. Optional location access may be used only to prioritize nearby city/district statuses, show area-relevant banners, support area-targeted admin push notifications, and show aggregate admin insights. Exact GPS coordinates are not stored or shown in dashboards; approximate city/district/state fields may be stored with the user/status/report records when enabled. Status content is stored in the backend with a 24-hour expiry and is processed by scheduled cleanup for permanent deletion of the status document, related replies/comments, and status image. Exact-second deletion is not guaranteed; cleanup may occur in the next scheduled cycle.\n\nBefore upload, status images may be compressed by the app to reduce file size. Compression reduces storage/bandwidth usage; the original full-size image is not guaranteed to be retained. When a user opens a status, a view count may be updated. Other users may send likes, reactions, and replies. The status owner can read replies in the replies screen; reply text may appear as a 2-line preview in the app UI and expand through Read more. The replying user is responsible for their message. Do not post private, confidential, financial, medical, legal, password, OTP, address, personal ID, sensitive political/religious targeting, or another person\'s private information in a status or reply.\n\nMana Poster Ai does not treat statuses, replies, likes, reactions, or views as public endorsements, official communications, or guaranteed delivery channels. Status/reply sending, viewing, counting, deletion, or display behavior may change because of network delay, moderation, security checks, backend cleanup, device issue, app update, account restriction, or policy enforcement. Users may report abusive, illegal, spam, privacy-violating, impersonating, copyright/trademark infringing, or deceptive political status/reply content through the in-app report option; report reason, optional details, reported content preview, reporter UID, and moderation metadata may be retained for safety and legal review. If there is abuse, spam, harassment, impersonation, copyright/trademark issue, illegal political misuse, misinformation risk, user safety concern, law enforcement request, or legal obligation, Mana Poster Ai may restrict, remove, preserve, review, disclose, or disable statuses/replies. Repeated misuse may lead to account restrictions.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'డివైస్ యాక్సెస్ మరియు సెషన్స్',
        english: 'Device Access and Sessions',
      ),
      strings.localized(
        telugu:
            'ఖాతా భద్రత కోసం ఒకే ఖాతా ఒకేసారి ఒక primary device session పై మాత్రమే కొనసాగవచ్చు. అదే ఖాతా మరొక primary device పై activate అయితే పాత session sign out కావచ్చు. ఇది account misuse మరియు unauthorized access ను తగ్గించడానికి ఉపయోగించబడుతుంది.',
        english:
            'For account security, one account may remain active on only one primary device session at a time. If the same account is activated on another primary device, the previous session may be signed out. This helps reduce account misuse and unauthorized access.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సేవ మార్పులు మరియు బాధ్యత పరిమితి',
        english: 'Service Changes and Limitation of Liability',
      ),
      strings.localized(
        telugu:
            'యాప్ features, prices, designs, assets, fonts, ads, editor tools మరియు ఈ terms సమయానుసారం మారవచ్చు. Backend assets/categories add, remove, replace, rename లేదా reorganize కావచ్చు. Technical issues, platform restrictions, ad-fill issues, billing verification delay, backend maintenance, device limits లేదా third-party failures వల్ల కొన్ని features తాత్కాలికంగా అందుబాటులో లేకపోవచ్చు. చట్టం అనుమతించే పరిమితిలో indirect loss, data loss, low-quality source files వల్ల export quality loss లేదా missed business opportunity కు యాప్ బాధ్యత వహించదు.',
        english:
            'Features, pricing, designs, assets, fonts, ads, editor tools, and these terms may change over time. Backend assets and categories may be added, removed, replaced, renamed, or reorganized. Some features may become temporarily unavailable because of technical issues, platform restrictions, ad-fill issues, billing verification delay, backend maintenance, device limits, or third-party failures. To the extent permitted by law, the app is not liable for indirect loss, data loss, export quality loss caused by low-quality source files, or missed business opportunities.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'సంప్రదింపు సమాచారం',
        english: 'Contact Information',
      ),
      strings.localized(
        telugu:
            'Terms, billing, subscriptions, account deletion లేదా legal ప్రశ్నల కోసం ${AppPublicInfo.supportEmail} కు ఇమెయిల్ చేయండి.',
        english:
            'For terms, billing, subscriptions, account deletion, or legal questions, email ${AppPublicInfo.supportEmail}.',
      ),
    ),
  ];
}
