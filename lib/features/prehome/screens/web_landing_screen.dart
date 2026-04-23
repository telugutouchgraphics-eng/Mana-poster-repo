import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/config/home_category_catalog.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  String _selectedCategoryId = HomeCategoryCatalog.all.first.id;

  Future<void> _openUrl(String rawUrl) async {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeCategoryCatalogEntry selectedCategory = HomeCategoryCatalog.all
        .firstWhere(
          (HomeCategoryCatalogEntry item) => item.id == _selectedCategoryId,
          orElse: () => HomeCategoryCatalog.all.first,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7FF),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              onInstall: () => _openUrl(AppPublicInfo.playStoreUrl),
            ),
          ),
          SliverToBoxAdapter(child: _JoyBanner(onChangeLater: () {})),
          SliverToBoxAdapter(
            child: _CategoryChipsSection(
              selectedId: _selectedCategoryId,
              onSelected: (String id) {
                setState(() => _selectedCategoryId = id);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _PosterGallerySection(category: selectedCategory),
          ),
          const SliverToBoxAdapter(child: _AppFeaturesSection()),
          const SliverToBoxAdapter(child: _CreatorFlowSection()),
          const SliverToBoxAdapter(child: _WhyManaPosterSection()),
          SliverToBoxAdapter(
            child: _FooterSection(
              onInstall: () => _openUrl(AppPublicInfo.playStoreUrl),
              onPrivacy: () => _openUrl(AppPublicInfo.privacyPolicyUrl),
              onTerms: () => _openUrl(AppPublicInfo.termsUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({required this.onInstall});

  final VoidCallback onInstall;

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bool compact = MediaQuery.sizeOf(context).width < 760;
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: overlapsContent ? 4 : 0,
      shadowColor: const Color(0x1A111827),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 30),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/branding/mana_poster_logo.png',
                width: 42,
                height: 42,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF6D28D9),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                AppPublicInfo.appName,
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (!compact) ...const <Widget>[
                _HeaderLink(label: 'Categories'),
                _HeaderLink(label: 'Posters'),
                _HeaderLink(label: 'Features'),
                _HeaderLink(label: 'Support'),
              ],
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(compact ? 'Install' : 'Install App'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return oldDelegate.onInstall != onInstall;
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JoyBanner extends StatelessWidget {
  const _JoyBanner({required this.onChangeLater});

  final VoidCallback onChangeLater;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 720;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        width: double.infinity,
        height: compact ? 340 : 460,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F3FF),
            border: Border(bottom: BorderSide(color: Color(0xFFDDD6FE))),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Banner image can be uploaded from admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsSection extends StatelessWidget {
  const _CategoryChipsSection({
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeading(
            eyebrow: 'Categories',
            title: 'All app categories',
            subtitle:
                'These chips come from the app constant category catalog. We can later connect each category to unlimited uploaded posters.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: HomeCategoryCatalog.all
                .map((HomeCategoryCatalogEntry item) {
                  final bool selected = item.id == selectedId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(item.label),
                    avatar: CircleAvatar(
                      backgroundColor: selected
                          ? Colors.white
                          : item.gradient.first,
                      foregroundColor: selected
                          ? const Color(0xFF4C1D95)
                          : Colors.white,
                      child: Text(
                        item.badge.characters.take(1).toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    onSelected: (_) => onSelected(item.id),
                    selectedColor: const Color(0xFF6D28D9),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF6D28D9)
                          : const Color(0xFFDDD6FE),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
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

class _PosterGallerySection extends StatelessWidget {
  const _PosterGallerySection({required this.category});

  final HomeCategoryCatalogEntry category;

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CategoryTitleCard(category: category),
          const SizedBox(height: 16),
          _EmptyPosterGallery(category: category),
          const SizedBox(height: 12),
          const _UploadNote(),
        ],
      ),
    );
  }
}

class _CategoryTitleCard extends StatelessWidget {
  const _CategoryTitleCard({required this.category});

  final HomeCategoryCatalogEntry category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: category.gradient),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              category.badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${category.label} posters',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Unlimited poster uploads can live under each category.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPosterGallery extends StatelessWidget {
  const _EmptyPosterGallery({required this.category});

  final HomeCategoryCatalogEntry category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFB923C)),
      ),
      child: Text(
        '${category.label} posters are empty now. Admin page nunchi real posters upload chesthe ikkada display avtayi.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

class _UploadNote extends StatelessWidget {
  const _UploadNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: const Text(
        'Poster gallery frames use contain-fit layout: square, portrait, landscape, and custom-size uploads will fit without cropping. Admin upload connection can be added next.',
        style: TextStyle(
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w800,
          height: 1.45,
        ),
      ),
    );
  }
}

class _AppFeaturesSection extends StatelessWidget {
  const _AppFeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeading(
            eyebrow: 'App features',
            title: 'Ready-made poster platform features',
            subtitle:
                'Mana Poster lo ready-made posters untayi. User profile details once save cheste posters quick ga share cheyyadaniki ready ga untayi.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.4 : 1.45,
                children: const <Widget>[
                  _FeatureCard(
                    icon: Icons.collections_rounded,
                    title: 'Ready-made poster library',
                    body:
                        'Festival, devotional, birthday, political, and daily use posters ready ga available untayi.',
                    colors: <Color>[Color(0xFF4C1D95), Color(0xFF6D28D9)],
                  ),
                  _FeatureCard(
                    icon: Icons.account_circle_rounded,
                    title: 'Profile-based auto fill',
                    body:
                        'Name, photo, designation, and phone number profile lo upload cheste posters lo automatic ga use avvachu.',
                    colors: <Color>[Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  _FeatureCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Premium templates',
                    body:
                        'Category-wise premium designs and polished poster collections direct ga ready untayi.',
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFF60A5FA)],
                  ),
                  _FeatureCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Unlimited poster uploads',
                    body:
                        'Admin side nunchi category ki unlimited posters upload chesi public landing lo display cheyyachu.',
                    colors: <Color>[Color(0xFF9333EA), Color(0xFF60A5FA)],
                  ),
                  _FeatureCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Single profile, many posters',
                    body:
                        'Oka sari profile details set cheste same details multiple ready-made posters lo use cheyyachu.',
                    colors: <Color>[Color(0xFF60A5FA), Color(0xFF38BDF8)],
                  ),
                  _FeatureCard(
                    icon: Icons.share_rounded,
                    title: 'Download and share',
                    body:
                        'Poster ready ayyaka direct ga WhatsApp, status, and social sharing kosam use cheyyachu.',
                    colors: <Color>[Color(0xFF38BDF8), Color(0xFF6D28D9)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorFlowSection extends StatelessWidget {
  const _CreatorFlowSection();

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF4C1D95),
              Color(0xFF6D28D9),
              Color(0xFF9333EA),
              Color(0xFF0EA5E9),
              Color(0xFFF97316),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 860;
            final Widget copy = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DarkEyebrow('Creator flow'),
                SizedBox(height: 8),
                Text(
                  'Choose poster, auto fill profile, share',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Mana Poster editing-heavy app kaadu. Ready-made poster select chesi profile lo unna details tho fast ga final poster share cheyyadaniki use avutundi.',
                  style: TextStyle(
                    color: Color(0xFFE0F2F1),
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
            final Widget steps = const Column(
              children: <Widget>[
                _FlowStep(number: '01', label: 'Select category'),
                _FlowStep(number: '02', label: 'Choose ready-made poster'),
                _FlowStep(number: '03', label: 'Use saved profile details'),
                _FlowStep(number: '04', label: 'Download/share'),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: copy),
                  const SizedBox(width: 26),
                  Expanded(child: steps),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[copy, const SizedBox(height: 18), steps],
            );
          },
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: <Widget>[
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyManaPosterSection extends StatelessWidget {
  const _WhyManaPosterSection();

  @override
  Widget build(BuildContext context) {
    return _PageBand(
      top: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeading(
            eyebrow: 'Why Mana Poster',
            title: 'Built for frequent poster publishing',
            subtitle:
                'Extra sections that make the page feel complete before we connect admin editing.',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const <Widget>[
              _ReasonPill(icon: Icons.bolt_rounded, label: 'Fast creation'),
              _ReasonPill(
                icon: Icons.language_rounded,
                label: 'Telugu audience',
              ),
              _ReasonPill(
                icon: Icons.category_rounded,
                label: 'Category-first',
              ),
              _ReasonPill(
                icon: Icons.auto_awesome_rounded,
                label: 'Colorful templates',
              ),
              _ReasonPill(
                icon: Icons.mobile_friendly_rounded,
                label: 'Mobile focused',
              ),
              _ReasonPill(
                icon: Icons.campaign_rounded,
                label: 'Campaign ready',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.onInstall,
    required this.onPrivacy,
    required this.onTerms,
  });

  final VoidCallback onInstall;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 68),
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 34),
      color: const Color(0xFF111827),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppPublicInfo.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Colorful Telugu poster creation for every daily, devotional, festival, and campaign need.',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onInstall,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Install App'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                    ),
                  ),
                  TextButton(
                    onPressed: onPrivacy,
                    child: const Text('Privacy'),
                  ),
                  TextButton(onPressed: onTerms, child: const Text('Terms')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBand extends StatelessWidget {
  const _PageBand({required this.child, this.top = 0});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, top, 18, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF6D28D9),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkEyebrow extends StatelessWidget {
  const _DarkEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFFFD166),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
