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
          hindi: 'à¤ªà¥à¤°à¤¾à¤‡à¤µà¥‡à¤¸à¥€ à¤ªà¥‰à¤²à¤¿à¤¸à¥€',
          tamil: 'à®¤à®©à®¿à®¯à¯à®°à®¿à®®à¯ˆ à®•à¯Šà®³à¯à®•à¯ˆ',
          kannada: 'à²—à³Œà²ªà³à²¯à²¤à²¾ à²¨à³€à²¤à²¿',
          malayalam: 'à´¸àµà´µà´•à´¾à´°àµà´¯à´¤à´¾ à´¨à´¯à´‚',
        )
      : strings.localized(
          telugu: 'నిబంధనలు మరియు షరతులు',
          english: 'Terms & Conditions',
          hindi: 'à¤¨à¤¿à¤¯à¤® à¤”à¤° à¤¶à¤°à¥à¤¤à¥‡à¤‚',
          tamil:
              'à®µà®¿à®¤à®¿à®®à¯à®±à¯ˆà®•à®³à¯ à®®à®±à¯à®±à¯à®®à¯ à®¨à®¿à®ªà®¨à¯à®¤à®©à¯ˆà®•à®³à¯',
          kannada:
              'à²¨à²¿à²¯à²®à²—à²³à³ à²®à²¤à³à²¤à³ à²·à²°à²¤à³à²¤à³à²—à²³à³',
          malayalam:
              'à´¨à´¿à´¬à´¨àµà´§à´¨à´•à´³àµà´‚ à´µàµà´¯à´µà´¸àµà´¥à´•à´³àµà´‚',
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
    telugu: 'చివరి నవీకరణ: 21 మే 2026',
    english: 'Last updated: May 21, 2026',
  );

  List<_LegalSection> get sections =>
      _isPrivacy ? _privacySections : _termsSections;

  String get footer => strings.localized(
    telugu: 'ప్రశ్నలు ఉంటే ${AppPublicInfo.supportEmail} కి సంప్రదించండి.',
    english: 'For questions, contact ${AppPublicInfo.supportEmail}.',
    hindi:
        'à¤ªà¥à¤°à¤¶à¥à¤¨ à¤¹à¥‹à¤¨à¥‡ à¤ªà¤° ${AppPublicInfo.supportEmail} à¤ªà¤° à¤¸à¤‚à¤ªà¤°à¥à¤• à¤•à¤°à¥‡à¤‚à¥¤',
    tamil:
        'à®•à¯‡à®³à¯à®µà®¿à®•à®³à¯ à®‡à®°à¯à®¨à¯à®¤à®¾à®²à¯ ${AppPublicInfo.supportEmail}-à® à®¤à¯Šà®Ÿà®°à¯à®ªà¯ à®•à¯Šà®³à¯à®³à¯à®™à¯à®•à®³à¯.',
    kannada:
        'à²ªà³à²°à²¶à³à²¨à³†à²—à²³à²¿à²¦à³à²¦à²°à³† ${AppPublicInfo.supportEmail} à²—à³† à²¸à²‚à²ªà²°à³à²•à²¿à²¸à²¿.',
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
            'మేము మీ email address, పేరు, Firebase UID, Google Sign-In వివరాలు, profile photo, logo, poster profile details, business name, WhatsApp number, notification token, subscription status, referral code, referral attribution details మరియు purchase verification కోసం అవసరమైన billing సమాచారాన్ని సేకరిస్తాము.',
        english:
            'We collect your email address, name, Firebase UID, Google Sign-In details, profile photo, logo, poster profile details, business name, WhatsApp number, notification token, subscription status, referral code, referral attribution details, and billing information needed for purchase verification.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'డేటాను ఎలా ఉపయోగిస్తాము',
        english: 'How We Use Data',
      ),
      strings.localized(
        telugu:
            'ఈ సమాచారాన్ని login, account security, poster personalization, save and export flows, notification delivery, subscription verification, purchase restoration, referral rewards, abuse prevention మరియు customer support కోసం ఉపయోగిస్తాము.',
        english:
            'We use this data for login, account security, poster personalization, save and export flows, notification delivery, subscription verification, purchase restoration, referral rewards, abuse prevention, and customer support.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'కమ్యూనిటీ పోస్టర్ అప్లోడ్లు మరియు సమీక్ష',
        english: 'Community Uploads and Review',
      ),
      strings.localized(
        telugu:
            'Users poster images ను manager review కోసం upload చేయవచ్చు. Upload చేసిన image, selected category, upload time, applicable visibility date, review status, rejection reason, share/download contribution counts మరియు related moderation history ను process చేయవచ్చు. Approved upload related category లో ఇతర users కు కనిపించవచ్చు. Pending, rejected లేదా policy-violating uploads ను review, reject, remove లేదా retain చేయడానికి managers/admins కు హక్కు ఉంటుంది.',
        english:
            'Users may upload poster images for manager review. We may process the uploaded image, selected category, upload time, applicable visibility date, review status, rejection reason, contribution share/download counts, and related moderation history. Approved uploads may become visible to other users in the related category. Managers and admins may review, reject, remove, or retain pending, rejected, or policy-violating uploads as part of moderation and record-keeping.',
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
        telugu: 'డేటా షేరింగ్',
        english: 'Data Sharing',
      ),
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
            'మీ login వివరాలు భద్రంగా ఉంచాలి. మీరు upload చేసే photos, text, logos లేదా poster materials ను ఉపయోగించే హక్కు మీకే ఉండాలి. చట్టవిరుద్ధం, మోసపూరితం, ద్వేషపూరితం, అసభ్యం లేదా ఇతరుల హక్కులను ఉల్లంఘించే content నిషేధించబడుతుంది. యాప్‌లో ఇతర users కు కనిపించే posters publication కు ముందు review చేయబడతాయి.',
        english:
            'You must keep your login details secure. You must have the right to use any photos, text, logos, or poster materials you upload. Illegal, deceptive, hateful, obscene, or infringing content is prohibited. Posters shown to other users in the app are reviewed before publication.',
      ),
    ),
    _LegalSection(
      strings.localized(
        telugu: 'Subscriptions మరియు premium access',
        english: 'Subscriptions and Premium Access',
      ),
      strings.localized(
        telugu:
            'ప్రస్తుత subscription plan కు ${SubscriptionPlanConfig.trialPriceDisplay} trial ${SubscriptionPlanConfig.trialDays} రోజులు ఉంటుంది. Trial గడువు లోపు రద్దు చేయకపోతే, తరువాత నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} చొప్పున auto-renew అవుతుంది. ప్రస్తుత app access మరియు premium features ఈ subscription plan ప్రకారమే అందించబడతాయి.',
        english:
            'The current subscription plan includes a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days. If you do not cancel within the trial period, the plan auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay} per month. Current app access and premium features are provided under this subscription plan.',
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
            'Users manager review కోసం posters upload చేయవచ్చు. Copyright లేకుండా third-party content upload చేయడం, ఇతరులుగా నటించడం, abusive/offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims లేదా rights లేని material నిషేధించబడుతుంది. Managers/admins uploads ను approve, reject, customize, delay, unpublish లేదా remove చేయవచ్చు. Rejected uploads కు reason ఇవ్వవచ్చు. Abuse లేదా infringement report చేయడానికి app support flow లేదా ${AppPublicInfo.supportEmail} ఉపయోగించవచ్చు.',
        english:
            'Users may upload posters for manager review. Uploading third-party content without rights, impersonation, abusive or offensive content, deceptive political misuse, spam uploads, repeated low-quality uploads, illegal notices, fake claims, or material you do not have rights to use is prohibited. Managers and admins may approve, reject, customize, delay, unpublish, or remove uploads. Rejected uploads may include a reason. Abusive or infringing content can be reported through the app support flow or by emailing ${AppPublicInfo.supportEmail}.',
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
