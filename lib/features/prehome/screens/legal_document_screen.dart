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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: copy.heroGradient,
                ),
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
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      copy.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.summary,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.lastUpdated,
                    style: const TextStyle(
                      color: Color(0xFFBFDBFE),
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
              style: const TextStyle(
                color: Color(0xFF64748B),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF475569),
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

  List<Color> get heroGradient => _isPrivacy
      ? const <Color>[Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)]
      : const <Color>[Color(0xFF9A3412), Color(0xFFC2410C), Color(0xFFEA580C)];

  String get title => _isPrivacy
      ? strings.localized(
          telugu: 'ప్రైవసీ పాలసీ',
          english: 'Privacy Policy',
          hindi: 'à¤ªà¥à¤°à¤¾à¤‡à¤µà¥‡à¤¸à¥€ à¤ªà¥‰à¤²à¤¿à¤¸à¥€',
          tamil: 'à®¤à®©à®¿à®¯à¯à®°à®¿à®®à¯ˆ à®•à¯Šà®³à¯à®•à¯ˆ',
          kannada: 'à²—à³Œà²ªà³à²¯à²¤à²¾ à²¨à³€à²¤à²¿',
          malayalam: 'à´¸àµà´µà´•à´¾à´°àµà´¯à´¤à´¾ à´¨à´¯à´‚',
        )
      : strings.localized(
          telugu: 'నిబంధనలు మరియు షరతులు',
          english: 'Terms & Conditions',
          hindi: 'à¤¨à¤¿à¤¯à¤® à¤”à¤° à¤¶à¤°à¥à¤¤à¥‡à¤‚',
          tamil: 'à®µà®¿à®¤à®¿à®®à¯à®±à¯ˆà®•à®³à¯ à®®à®±à¯à®±à¯à®®à¯ à®¨à®¿à®ªà®¨à¯à®¤à®©à¯ˆà®•à®³à¯',
          kannada: 'à²¨à²¿à²¯à²®à²—à²³à³ à²®à²¤à³à²¤à³ à²·à²°à²¤à³à²¤à³à²—à²³à³',
          malayalam: 'à´¨à´¿à´¬à´¨àµà´§à´¨à´•à´³àµà´‚ à´µàµà´¯à´µà´¸àµà´¥à´•à´³àµà´‚',
        );

  String get badge => _isPrivacy
      ? strings.localized(
          telugu: 'డేటా రక్షణ',
          english: 'Data Protection',
          hindi: 'à¤¡à¥‡à¤Ÿà¤¾ à¤¸à¥à¤°à¤•à¥à¤·à¤¾',
          tamil: 'à®¤à®°à®µà¯ à®ªà®¾à®¤à¯à®•à®¾à®ªà¯à®ªà¯',
          kannada: 'à²¡à³‡à²Ÿà²¾ à²°à²•à³à²·à²£à³†',
          malayalam: 'à´¡à´¾à´±àµà´± à´¸à´‚à´°à´•àµà´·à´£à´‚',
        )
      : strings.localized(
          telugu: 'వినియోగ నియమాలు',
          english: 'Usage Terms',
          hindi: 'à¤‰à¤ªà¤¯à¥‹à¤— à¤¨à¤¿à¤¯à¤®',
          tamil: 'à®ªà®¯à®©à¯à®ªà®¾à®Ÿà¯à®Ÿà¯ à®µà®¿à®¤à®¿à®•à®³à¯',
          kannada: 'à²¬à²³à²•à³† à²¨à²¿à²¯à²®à²—à²³à³',
          malayalam: 'à´‰à´ªà´¯àµ‹à´— à´¨à´¿à´¬à´¨àµà´§à´¨à´•àµ¾',
        );

  String get summary => _isPrivacy
      ? strings.localized(
          telugu:
              'మీ డేటా, subscriptions, ప్రకటనలు, account deletion మరియు Firebase సేవల వినియోగం గురించి ఈ పేజీ వివరిస్తుంది.',
          english:
              'This page explains how Mana Poster Ai handles your data, subscriptions, ads, account deletion, and Firebase-powered services.',
        )
      : strings.localized(
          telugu:
              'Mana Poster Ai వాడకం, subscriptions, చెల్లింపులు, ప్రకటనలు, ఖాతా బాధ్యతలు మరియు సేవా పరిమితులకు సంబంధించిన నియమాలు ఇక్కడ ఉన్నాయి.',
          english:
              'This page contains the rules for using Mana Poster Ai, including subscriptions, payments, ads, account responsibility, and service limitations.',
        );

  String get lastUpdated => strings.localized(
    telugu: 'చివరి నవీకరణ: 7 మే 2026',
    english: 'Last updated: May 7, 2026',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu: 'ప్రశ్నలు ఉంటే ${AppPublicInfo.supportEmail} కి సంప్రదించండి.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi: 'à¤ªà¥à¤°à¤¶à¥à¤¨ à¤¹à¥‹à¤¨à¥‡ à¤ªà¤° ${AppPublicInfo.supportEmail} à¤ªà¤° à¤¸à¤‚à¤ªà¤°à¥à¤• à¤•à¤°à¥‡à¤‚à¥¤',
    tamil:
        'à®•à¯‡à®³à¯à®µà®¿à®•à®³à¯ à®‡à®°à¯à®¨à¯à®¤à®¾à®²à¯ ${AppPublicInfo.supportEmail}-à® à®¤à¯Šà®Ÿà®°à¯à®ªà¯ à®•à¯Šà®³à¯à®³à¯à®™à¯à®•à®³à¯.',
    kannada: 'à²ªà³à²°à²¶à³à²¨à³†à²—à²³à²¿à²¦à³à²¦à²°à³† ${AppPublicInfo.supportEmail} à²—à³† à²¸à²‚à²ªà²°à³à²•à²¿à²¸à²¿.',
    malayalam:
        'à´šàµ‹à´¦àµà´¯à´™àµà´™àµ¾ à´‰à´£àµà´Ÿàµ†à´™àµà´•à´¿àµ½ ${AppPublicInfo.supportEmail}-àµ½ à´¬à´¨àµà´§à´ªàµà´ªàµ†à´Ÿàµà´•.',
  );

  List<_LegalSection> get _privacySections => <_LegalSection>[
        _LegalSection(
          strings.localized(
            telugu: 'మేము ఏ సమాచారం సేకరిస్తాము',
            english: 'What We Collect',
          ),
          strings.localized(
            telugu:
                'మేము మీ email address, పేరు, Firebase UID, Google Sign-In వివరాలు, profile photo, logo, poster profile details, business name, WhatsApp number, notification token, subscription status మరియు purchase verification కోసం అవసరమైన billing సమాచారాన్ని సేకరిస్తాము.',
            english:
                'We collect your email address, name, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, notification token, subscription status, and billing information needed for purchase verification.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'డేటాను ఎలా ఉపయోగిస్తాము',
            english: 'How We Use Data',
          ),
          strings.localized(
            telugu:
                'ఈ సమాచారాన్ని login, account security, poster personalization, save and export flows, notification delivery, subscription verification, purchase restoration, abuse prevention మరియు customer support కోసం ఉపయోగిస్తాము.',
            english:
                'We use this data for login, account security, poster personalization, save and export flows, notification delivery, subscription verification, purchase restoration, abuse prevention, and customer support.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'Firebase, Analytics మరియు Ads',
            english: 'Firebase, Analytics, and Ads',
          ),
          strings.localized(
            telugu:
                'యాప్ Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing మరియు AdMob ను ఉపయోగిస్తుంది. ఈ సేవలు app performance, crash diagnostics, notifications, billing verification మరియు ad delivery కోసం ఉపయోగించబడతాయి. Personalized లేదా non-personalized ads అందించడానికి AdMob device identifiers, IP address మరియు usage data ను సేకరించవచ్చు.',
            english:
                'The app uses Firebase Authentication, Firestore, Storage, Messaging, Analytics, Crashlytics, Google Sign-In, Google Play Billing, and AdMob. These services support app performance, crash diagnostics, notifications, billing verification, and ad delivery. AdMob may collect device identifiers, IP address, and usage data to provide personalized or non-personalized ads.',
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
                'ఫోటో ఎంపిక, poster saving మరియు optional notifications కోసం మాత్రమే permissions అడుగుతాము. మీరు వీటిని device settings లో మార్చవచ్చు. మీరు upload, export లేదా share చేసే content కు మీరు బాధ్యులు. App కొంత media cache లేదా temporary files ను అవసరం ముగిసిన తర్వాత delete చేయవచ్చు.',
            english:
                'Permissions are requested only for photo selection, poster saving, and optional notifications. You can manage them from device settings. You remain responsible for any content you upload, export, or share. The app may temporarily cache media files and remove them when they are no longer needed.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'Subscriptions మరియు billing',
            english: 'Subscriptions and Billing',
          ),
          strings.localized(
            telugu:
                'Subscription verification కోసం purchase tokens మరియు billing status ను server-side లో process చేయవచ్చు. ప్రస్తుత plan కు ${SubscriptionPlanConfig.trialPriceDisplay} trial ${SubscriptionPlanConfig.trialDays} రోజులు ఉంటుంది. రద్దు చేయకపోతే తరువాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున auto-renew అవుతుంది.',
            english:
                'For subscription verification, purchase tokens and billing status may be processed server-side. The current plan includes a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days. If not cancelled, it renews automatically at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month.',
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
          strings.localized(
            telugu: 'యాప్ వాడకం',
            english: 'Using the App',
          ),
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
                'మీ login వివరాలు భద్రంగా ఉంచాలి. మీరు upload చేసే photos, text, logos లేదా poster materials ను ఉపయోగించే హక్కు మీకే ఉండాలి. చట్టవిరుద్ధం, మోసపూరితం, ద్వేషపూరితం, అసభ్యం లేదా ఇతరుల హక్కులను ఉల్లంఘించే content నిషేధించబడుతుంది.',
            english:
                'You must keep your login details secure. You must have the right to use any photos, text, logos, or poster materials you upload. Illegal, deceptive, hateful, obscene, or infringing content is prohibited.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'Subscriptions మరియు premium access',
            english: 'Subscriptions and Premium Access',
          ),
          strings.localized(
            telugu:
                'ప్రస్తుత subscription plan కు ${SubscriptionPlanConfig.trialPriceDisplay} trial ${SubscriptionPlanConfig.trialDays} రోజులు ఉంటుంది. Trial గడువు లోపు రద్దు చేయకపోతే, తరువాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున auto-renew అవుతుంది. కొన్ని premium templates లేదా premium posters కు ప్రత్యేక ధర లేదా వేర్వేరు access rules ఉండవచ్చు.',
            english:
                'The current subscription plan includes a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days. If you do not cancel within the trial period, the plan auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month. Some premium templates or premium posters may have separate pricing or separate access rules.',
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
            telugu: 'ప్రకటనలు మరియు third-party services',
            english: 'Ads and Third-Party Services',
          ),
          strings.localized(
            telugu:
                'యాప్‌లో AdMob ads చూపించబడవచ్చు. Ads availability, ad skip timing, billing services, Google sign-in, notifications లేదా Firebase services కొన్నిసార్లు third-party providers మీద ఆధారపడవచ్చు. మూడో పక్ష సేవలు నిరంతరంగా అందుబాటులో ఉంటాయని యాప్ హామీ ఇవ్వదు.',
            english:
                'The app may display AdMob ads. Ad availability, ad-skip timing, billing services, Google sign-in, notifications, or Firebase services may depend on third-party providers. The app does not guarantee uninterrupted availability of third-party services.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'Account deletion మరియు device access',
            english: 'Account Deletion and Device Access',
          ),
          strings.localized(
            telugu:
                'యాప్‌లో account deletion request option అందుబాటులో ఉంటుంది. Delete అభ్యర్థన తర్వాత login access, poster profile data మరియు linked app data తొలగించబడవచ్చు. కొన్ని billing లేదా platform-required records పరిమిత కాలం నిల్వ ఉండవచ్చు. అలాగే session controls కారణంగా ఒకే ఖాతా ఒకేసారి ఒక ప్రధాన పరికరంలో మాత్రమే యాక్టివ్‌గా ఉండవచ్చు.',
            english:
                'The app provides an account deletion request option. After deletion, login access, poster profile data, and linked app data may be removed. Some billing or platform-required records may be retained for a limited period. Session controls may also keep one account active on one primary device at a time.',
          ),
        ),
        _LegalSection(
          strings.localized(
            telugu: 'సేవ మార్పులు మరియు బాధ్యత పరిమితి',
            english: 'Service Changes and Limitation of Liability',
          ),
          strings.localized(
            telugu:
                'యాప్ ఫీచర్లు, ధరలు, డిజైన్లు, ప్రకటనలు మరియు ఈ నిబంధనలు సమయానుసారం మారవచ్చు. సాంకేతిక సమస్యలు, platform restrictions లేదా third-party failures వల్ల కొన్ని ఫీచర్లు తాత్కాలికంగా అందుబాటులో లేకపోవచ్చు. చట్టం అనుమతించే పరిమితిలో, పరోక్ష నష్టం, data loss లేదా missed business opportunity కు యాప్ బాధ్యత వహించదు.',
            english:
                'Features, pricing, designs, ads, and these terms may change over time. Some features may become temporarily unavailable because of technical issues, platform restrictions, or third-party failures. To the extent permitted by law, the app is not liable for indirect loss, data loss, or missed business opportunities.',
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

