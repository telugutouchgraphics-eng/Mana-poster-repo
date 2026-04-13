import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/screens/legal_document_screen.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen>
    with AppLanguageStateMixin {
  static final Uri _playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.telugutouch.manaposter',
  );
  static final Uri _supportUri = Uri(
    scheme: 'mailto',
    path: 'telugutouchgraphics@gmail.com',
    query: 'subject=Mana Poster Support',
  );

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _openLegal(LegalDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(documentType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 980;
    final posters = _posterItems(strings);
    final query = _searchController.text.trim().toLowerCase();
    final visiblePosters = posters
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          return '${item.title} ${item.subtitle} ${item.tag}'
              .toLowerCase()
              .contains(query);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Band(
              background: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFF5F8FF), Color(0xFFEFF6FF)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderBar(
                    onPrivacy: () =>
                        _openLegal(LegalDocumentType.privacyPolicy),
                    onTerms: () =>
                        _openLegal(LegalDocumentType.termsAndConditions),
                    onSupport: () => _open(_supportUri),
                    onDownload: () => _open(_playStoreUri),
                  ),
                  const SizedBox(height: 28),
                  _Hero(
                    strings: strings,
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onDownload: () => _open(_playStoreUri),
                    onSupport: () => _open(_supportUri),
                    desktop: isDesktop,
                  ),
                ],
              ),
            ),
            _Band(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SectionTitle(
                    label: strings.localized(
                      telugu: 'పోస్టర్ విభాగాలు',
                      english: 'Poster categories',
                    ),
                    title: strings.localized(
                      telugu:
                          'ప్రతి section ఇప్పుడు విడిగా, క్లీన్‌గా కనిపిస్తుంది',
                      english: 'Each section now feels clear and separate',
                    ),
                    subtitle: strings.localized(
                      telugu:
                          'Categories, sample posters, support information అన్నీ ఒకే heap లో కాకుండా విడిగా ఉంచాం.',
                      english:
                          'Categories, sample posters, and support information are now separated instead of feeling cramped together.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categoryLabels(strings)
                        .map((label) => _Chip(label: label))
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visiblePosters.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      mainAxisExtent: 260,
                    ),
                    itemBuilder: (context, index) {
                      return _PosterCard(item: visiblePosters[index]);
                    },
                  ),
                ],
              ),
            ),
            _Band(
              backgroundColor: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SectionTitle(
                    label: strings.localized(
                      telugu: 'ఎలా వాడాలి',
                      english: 'How to use',
                    ),
                    title: strings.localized(
                      telugu: 'వెబ్ బ్రౌజింగ్ ఒకటి, Android క్రియేషన్ ఒకటి',
                      english: 'Web browsing and Android creation are separate',
                    ),
                    subtitle: strings.localized(
                      telugu:
                          'ఈ website public showcase కోసం. అసలు poster create/edit flow Android యాప్‌లోనే ఉంటుంది.',
                      english:
                          'This website is for public discovery. Actual poster create/edit flow remains in the Android app.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.6 : 2.35,
                    children: _steps(strings)
                        .map((step) => _InfoCard(step: step))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            _Band(
              background: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF0F766E),
                  Color(0xFF16A34A),
                  Color(0xFF1E3A8A),
                ],
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _LanguageBox(strings: strings)),
                        const SizedBox(width: 18),
                        Expanded(child: _HighlightsBox(strings: strings)),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        _LanguageBox(strings: strings),
                        const SizedBox(height: 18),
                        _HighlightsBox(strings: strings),
                      ],
                    ),
            ),
            _Band(
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SectionTitle(
                    label: strings.localized(
                      telugu: 'సాధారణ సందేహాలు',
                      english: 'FAQ',
                    ),
                    title: strings.localized(
                      telugu:
                          'వెబ్, subscription, premium గురించి short clarity',
                      english:
                          'Short clarity about web, subscription, and premium',
                    ),
                    subtitle: strings.localized(
                      telugu:
                          'Free tab subscription వేరు, premium poster purchase వేరు అనే విషయం కూడా ఇక్కడ clear ga ఉంటుంది.',
                      english:
                          'This also makes it clear that the Free-tab subscription and premium poster purchases are separate.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._faqs(strings).map((item) => _FaqTile(item: item)),
                  const SizedBox(height: 24),
                  _FooterBar(
                    onPrivacy: () =>
                        _openLegal(LegalDocumentType.privacyPolicy),
                    onTerms: () =>
                        _openLegal(LegalDocumentType.termsAndConditions),
                    onSupport: () => _open(_supportUri),
                    onDownload: () => _open(_playStoreUri),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _categoryLabels(AppStrings strings) => <String>[
    strings.localized(telugu: 'శుభోదయం', english: 'Good Morning'),
    strings.localized(telugu: 'పండుగ శుభాకాంక్షలు', english: 'Festival Wishes'),
    strings.localized(
      telugu: 'బిజినెస్ ప్రచారం',
      english: 'Business Promotion',
    ),
    strings.localized(telugu: 'జన్మదిన పోస్టర్లు', english: 'Birthday Posters'),
    strings.localized(telugu: 'ప్రీమియం పోస్టర్లు', english: 'Premium Posters'),
    strings.localized(telugu: 'భక్తి పోస్టర్లు', english: 'Devotional Posters'),
  ];

  List<_PosterItem> _posterItems(AppStrings strings) => <_PosterItem>[
    _PosterItem(
      tag: strings.localized(telugu: 'శుభోదయం', english: 'Good Morning'),
      title: strings.localized(
        telugu: 'రోజువారీ morning wish పోస్టర్లు',
        english: 'Daily morning wish posters',
      ),
      subtitle: strings.localized(
        telugu: 'పేరు, ఫోటోతో ready-to-share looks',
        english: 'Ready-to-share looks with name and photo',
      ),
      colors: const <Color>[Color(0xFF0F9F6E), Color(0xFFA7F3D0)],
    ),
    _PosterItem(
      tag: strings.localized(telugu: 'పండుగ', english: 'Festival'),
      title: strings.localized(
        telugu: 'పండగ రోజులకు festive templates',
        english: 'Festive templates for celebration days',
      ),
      subtitle: strings.localized(
        telugu: 'తెలుగు special occasions కి visual styles',
        english: 'Visual styles for Telugu special occasions',
      ),
      colors: const <Color>[Color(0xFF1E3A8A), Color(0xFFBFDBFE)],
    ),
    _PosterItem(
      tag: strings.localized(telugu: 'బిజినెస్', english: 'Business'),
      title: strings.localized(
        telugu: 'ఆఫర్లు, షాప్, promotion పోస్టర్లు',
        english: 'Offer, shop, and promotion posters',
      ),
      subtitle: strings.localized(
        telugu: 'వ్యాపార పేరు మరియు WhatsApp details తో',
        english: 'With business name and WhatsApp details',
      ),
      colors: const <Color>[Color(0xFFF59E0B), Color(0xFFFDE68A)],
    ),
    _PosterItem(
      tag: strings.localized(telugu: 'ప్రీమియం', english: 'Premium'),
      title: strings.localized(
        telugu: 'వేరుగా కొనాల్సిన premium posters',
        english: 'Premium posters bought separately',
      ),
      subtitle: strings.localized(
        telugu: 'కొన్న తర్వాత పూర్తి customization',
        english: 'Full customization after purchase',
      ),
      colors: const <Color>[Color(0xFF6D28D9), Color(0xFFD8B4FE)],
    ),
    _PosterItem(
      tag: strings.localized(telugu: 'రాజకీయ', english: 'Political'),
      title: strings.localized(
        telugu: 'జయంతి, సభ, event posters',
        english: 'Jayanthi, event, and leader posters',
      ),
      subtitle: strings.localized(
        telugu: 'strong local branding layouts',
        english: 'Strong layouts for local branding',
      ),
      colors: const <Color>[Color(0xFFDC2626), Color(0xFFFECACA)],
    ),
    _PosterItem(
      tag: strings.localized(telugu: 'భక్తి', english: 'Devotional'),
      title: strings.localized(
        telugu: 'దైవ దర్శనం మరియు devotional పోస్టర్లు',
        english: 'Darshan and devotional posters',
      ),
      subtitle: strings.localized(
        telugu: 'రోజువారీ share చేయడానికి clean designs',
        english: 'Clean designs for everyday sharing',
      ),
      colors: const <Color>[Color(0xFF0F766E), Color(0xFFCCFBF1)],
    ),
  ];

  List<_InfoItem> _steps(AppStrings strings) => <_InfoItem>[
    _InfoItem(
      '01',
      strings.localized(
        telugu: 'వెబ్‌లో browse చేయండి',
        english: 'Browse on web',
      ),
      strings.localized(
        telugu: 'categories, sample posters, support, legal details చూడండి.',
        english: 'See categories, sample posters, support, and legal details.',
      ),
    ),
    _InfoItem(
      '02',
      strings.localized(
        telugu: 'Android యాప్‌లో create చేయండి',
        english: 'Create in Android app',
      ),
      strings.localized(
        telugu: 'అసలు poster editing మరియు customization అక్కడ జరుగుతుంది.',
        english: 'Actual poster editing and customization happen there.',
      ),
    ),
    _InfoItem(
      '03',
      strings.localized(telugu: 'షేర్ చేయండి', english: 'Share it'),
      strings.localized(
        telugu: 'పేరు, ఫోటో, business identity తో final poster తీసుకోండి.',
        english:
            'Finish the poster with your name, photo, and business identity.',
      ),
    ),
  ];

  List<_FaqItem> _faqs(AppStrings strings) => <_FaqItem>[
    _FaqItem(
      strings.localized(
        telugu: 'వెబ్‌సైట్‌లోనే poster edit చేయచ్చా?',
        english: 'Can I edit posters directly on the website?',
      ),
      strings.localized(
        telugu:
            'లేదు. ఈ site public showcase కోసం. పూర్తి editing Android యాప్‌లో ఉంటుంది.',
        english:
            'No. This site is for public showcase. Full editing is in the Android app.',
      ),
    ),
    _FaqItem(
      strings.localized(
        telugu: 'Subscription ఏ పోస్టర్లకు వర్తిస్తుంది?',
        english: 'Which posters are covered by subscription?',
      ),
      strings.localized(
        telugu:
            'Subscription Free tab పోస్టర్లకు మాత్రమే. Trial రూ.1 / 3 రోజులు, తర్వాత నెలకు రూ.149.',
        english:
            'Subscription applies only to Free-tab posters. Trial is Rs.1 for 3 days, then Rs.149 monthly.',
      ),
    ),
    _FaqItem(
      strings.localized(
        telugu: 'Premium posters ఎలా పనిచేస్తాయి?',
        english: 'How do premium posters work?',
      ),
      strings.localized(
        telugu:
            'Premium posters subscription లో రావు. ఒక్కో poster ని వేరుగా కొనాలి.',
        english:
            'Premium posters are not part of the subscription. Each poster is purchased separately.',
      ),
    ),
  ];
}

class _Band extends StatelessWidget {
  const _Band({this.backgroundColor, this.background, required this.child});

  final Color? backgroundColor;
  final Gradient? background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: backgroundColor, gradient: background),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 38),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onPrivacy,
    required this.onTerms,
    required this.onSupport,
    required this.onDownload,
  });

  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onSupport;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    final links = <Widget>[
      _TopTextButton(label: 'Privacy', onTap: onPrivacy),
      _TopTextButton(label: 'Terms', onTap: onTerms),
      _TopTextButton(label: 'Support', onTap: onSupport),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _BrandLockup(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ...links,
                    FilledButton(
                      onPressed: onDownload,
                      child: const Text('Android App'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: <Widget>[
                const _BrandLockup(),
                const Spacer(),
                ...links,
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onDownload,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  child: const Text('Download App'),
                ),
              ],
            ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFDCFCE7), Color(0xFFDBEAFE)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/branding/mana_poster_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mana Poster',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Posters for every occasion',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopTextButton extends StatelessWidget {
  const _TopTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onTap, child: Text(label));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.strings,
    required this.controller,
    required this.onChanged,
    required this.onDownload,
    required this.onSupport,
    required this.desktop,
  });

  final AppStrings strings;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onDownload;
  final VoidCallback onSupport;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _Chip(
              label: strings.localized(
                telugu: 'Telugu-first',
                english: 'Telugu-first',
              ),
            ),
            _Chip(
              label: strings.localized(
                telugu: 'Android app',
                english: 'Android app',
              ),
            ),
            _Chip(
              label: strings.localized(
                telugu: 'Free + Premium',
                english: 'Free + Premium',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          strings.localized(
            telugu: 'ఇది full-width public website, app-shell కాదు',
            english:
                'This is now a full-width public website, not an app shell',
          ),
          style: const TextStyle(
            fontSize: 42,
            height: 1.06,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.localized(
            telugu:
                'శుభోదయం పోస్టర్లు, పండుగ శుభాకాంక్షలు, business promotions, devotional పోస్టర్లు మరియు premium purchase model గురించి clean website experience ఇక్కడ ఉంటుంది.',
            english:
                'This gives you a cleaner website experience for good morning posters, festival wishes, business promotions, devotional posters, and the premium purchase model.',
          ),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: strings.localized(
              telugu: 'శుభోదయం, business, premium... వెతకండి',
              english: 'Search good morning, business, premium...',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              icon: const Icon(Icons.android_rounded),
              label: Text(
                strings.localized(
                  telugu: 'Android యాప్',
                  english: 'Android App',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onSupport,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              icon: const Icon(Icons.mail_outline_rounded),
              label: Text(
                strings.localized(telugu: 'సపోర్ట్', english: 'Support'),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.78),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: desktop
          ? Row(
              children: <Widget>[
                Expanded(flex: 11, child: intro),
                const SizedBox(width: 24),
                const Expanded(flex: 8, child: _HeroVisual()),
              ],
            )
          : Column(
              children: <Widget>[
                intro,
                const SizedBox(height: 22),
                const _HeroVisual(),
              ],
            ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: const <Widget>[
          Positioned(
            top: 0,
            right: 0,
            child: _MiniPoster(
              title: 'Good Morning',
              subtitle: 'Fresh daily share',
              colors: <Color>[Color(0xFF0F9F6E), Color(0xFFA7F3D0)],
            ),
          ),
          Positioned(
            top: 98,
            left: 0,
            child: _MiniPoster(
              title: 'Business',
              subtitle: 'Name + WhatsApp',
              colors: <Color>[Color(0xFF1E3A8A), Color(0xFFBFDBFE)],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 28,
            child: _MiniPoster(
              title: 'Festival',
              subtitle: 'Telugu special',
              colors: <Color>[Color(0xFFF59E0B), Color(0xFFFDE68A)],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPoster extends StatelessWidget {
  const _MiniPoster({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Mana Poster',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F766E),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 30,
            height: 1.14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 15.5,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item});

  final _PosterItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(colors: item.colors),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.step});

  final _InfoItem step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFDCFCE7), Color(0xFFDBEAFE)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step.number,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.body,
            style: const TextStyle(
              color: Color(0xFF64748B),
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

class _LanguageBox extends StatelessWidget {
  const _LanguageBox({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final controller = context.languageController;
    final current = context.currentLanguage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.localized(
              telugu: 'సపోర్ట్ ఉన్న భాషలు',
              english: 'Supported languages',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.localized(
              telugu:
                  'తెలుగు-first experience తో పాటు మరిన్ని భాషలు అందుబాటులో ఉన్నాయి.',
              english:
                  'A Telugu-first experience with more supported languages.',
            ),
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppLanguage.values
                .map((language) {
                  final selected = language == current;
                  return InkWell(
                    onTap: () => controller.setLanguage(language),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        strings.languageName(language),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HighlightsBox extends StatelessWidget {
  const _HighlightsBox({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final points = <String>[
      strings.localized(
        telugu: 'రోజువారీ శుభోదయం పోస్టర్లకు ఉపయోగపడుతుంది.',
        english: 'Useful for daily good morning poster sharing.',
      ),
      strings.localized(
        telugu:
            'వ్యాపార పేరు, WhatsApp తో promotion పోస్టర్లు త్వరగా తయారవుతాయి.',
        english:
            'Promotion posters with business name and WhatsApp details are quick to prepare.',
      ),
      strings.localized(
        telugu: 'Premium poster కొన్న తర్వాత full customization చేయొచ్చు.',
        english: 'Purchased premium posters can be fully customized.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.localized(
              telugu: 'ఈ structure ఎందుకు better',
              english: 'Why this structure is better',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(
          item.question,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.onPrivacy,
    required this.onTerms,
    required this.onSupport,
    required this.onDownload,
  });

  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onSupport;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    final buttons = <Widget>[
      _FooterButton(label: 'Privacy Policy', onTap: onPrivacy),
      _FooterButton(label: 'Terms & Conditions', onTap: onTerms),
      _FooterButton(label: 'Support', onTap: onSupport),
      _FooterButton(label: 'Download App', onTap: onDownload),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Mana Poster',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Festival wishes, business promos, devotional posts, and personalized poster discovery.',
                  style: TextStyle(color: Color(0xFFCBD5E1), height: 1.55),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: buttons),
              ],
            )
          : Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mana Poster',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Festival wishes, business promos, devotional posts, and personalized poster discovery.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(spacing: 10, runSpacing: 10, children: buttons),
              ],
            ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

class _PosterItem {
  const _PosterItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String tag;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

class _InfoItem {
  const _InfoItem(this.number, this.title, this.body);

  final String number;
  final String title;
  final String body;
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);

  final String question;
  final String answer;
}
