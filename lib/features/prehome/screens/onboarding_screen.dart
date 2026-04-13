import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/widgets/flow_screen_header.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with AppLanguageStateMixin {
  final PageController _pageController = PageController();
  int _index = 0;

  void _next() {
    final items = context.strings.onboardingItems;
    if (_index == items.length - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await AppFlowService.markOnboardingCompleted();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final items = strings.onboardingItems;

    return Scaffold(
      body: GradientShell(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            FlowScreenHeader(
              title: items[_index].title,
              subtitle: items[_index].desc,
              badge: '02',
            ),
            const SizedBox(height: 14),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _OnboardingIllustration(index: i, colors: item.colors),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFBFDBFE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: PrimaryButton(
                key: ValueKey<int>(_index),
                label: _index == items.length - 1
                    ? strings.onboardingGetStarted
                    : strings.onboardingNext,
                onPressed: _next,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: _skip,
                child: Text(strings.onboardingSkip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.index, required this.colors});

  final int index;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.first.withValues(alpha: 0.16),
            colors.last.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 20,
            left: 20,
            child: _GlowOrb(size: 64, colors: colors),
          ),
          Positioned(
            right: 18,
            top: 28,
            child: _GlowOrb(
              size: 28,
              colors: <Color>[colors.last, colors.first],
            ),
          ),
          Positioned(
            left: 26,
            bottom: 18,
            child: _GlowOrb(
              size: 18,
              colors: <Color>[colors.first, colors.last],
            ),
          ),
          if (index == 0) _TemplatePlacementVisual(colors: colors),
          if (index == 1) _PosterLibraryVisual(colors: colors),
          if (index == 2) _ShareVisual(colors: colors),
        ],
      ),
    );
  }
}

class _TemplatePlacementVisual extends StatelessWidget {
  const _TemplatePlacementVisual({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          right: 34,
          top: 30,
          child: _FloatingBadge(
            icon: Icons.auto_awesome_rounded,
            label: 'Auto',
            colors: colors,
          ),
        ),
        Positioned(left: 22, top: 92, child: _MiniPhotoChip(colors: colors)),
        _PhoneMockup(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors.first.withValues(alpha: 0.9),
                        colors.last.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 22,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                top: 58,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x220F172A),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            const Color(0xFFFDE68A),
                            colors.last.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 46,
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xF9FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'నాగ గోపి',
                    style: TextStyle(
                      color: colors.first,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 102,
                child: Container(
                  width: 44,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PosterLibraryVisual extends StatelessWidget {
  const _PosterLibraryVisual({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 24,
          top: 34,
          child: _PosterMiniCard(
            width: 84,
            height: 118,
            title: 'Festival',
            colors: <Color>[const Color(0xFFF59E0B), const Color(0xFFFB7185)],
            icon: Icons.auto_awesome,
          ),
        ),
        Positioned(
          right: 26,
          top: 54,
          child: _PosterMiniCard(
            width: 90,
            height: 126,
            title: 'Premium',
            colors: colors,
            icon: Icons.workspace_premium_rounded,
            elevated: true,
          ),
        ),
        Positioned(
          left: 74,
          bottom: 28,
          child: _PosterMiniCard(
            width: 92,
            height: 118,
            title: 'Devotional',
            colors: <Color>[const Color(0xFF10B981), const Color(0xFF0EA5E9)],
            icon: Icons.temple_hindu_rounded,
          ),
        ),
        Positioned(
          right: 38,
          bottom: 38,
          child: _PosterMiniCard(
            width: 72,
            height: 98,
            title: 'Birthday',
            colors: <Color>[const Color(0xFFEC4899), const Color(0xFFF97316)],
            icon: Icons.cake_rounded,
          ),
        ),
        Positioned(
          left: 104,
          top: 18,
          child: _FloatingBadge(
            icon: Icons.view_carousel_rounded,
            label: 'Free',
            colors: <Color>[const Color(0xFF0EA5E9), const Color(0xFF2563EB)],
          ),
        ),
      ],
    );
  }
}

class _ShareVisual extends StatelessWidget {
  const _ShareVisual({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          left: 28,
          top: 44,
          child: Container(
            width: 82,
            height: 112,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x160F172A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
        _PhoneMockup(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors.first.withValues(alpha: 0.84),
                        colors.last.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 24,
                right: 22,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0x2FFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                top: 58,
                bottom: 74,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 44,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _ActionBubble(
                      icon: Icons.download_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                    _ActionBubble(
                      icon: Icons.share_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _ActionBubble(
                      icon: Icons.send_rounded,
                      color: const Color(0xFFEC4899),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          top: 36,
          child: _ShareOrbit(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF22C55E),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 48,
          child: _ShareOrbit(
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      height: 208,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _PosterMiniCard extends StatelessWidget {
  const _PosterMiniCard({
    required this.width,
    required this.height,
    required this.title,
    required this.colors,
    required this.icon,
    this.elevated = false,
  });

  final double width;
  final double height;
  final String title;
  final List<Color> colors;
  final IconData icon;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: elevated ? const Color(0x220F172A) : const Color(0x140F172A),
            blurRadius: elevated ? 20 : 14,
            offset: Offset(0, elevated ? 10 : 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x190F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPhotoChip extends StatelessWidget {
  const _MiniPhotoChip({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: <Color>[
            colors.first.withValues(alpha: 0.34),
            colors.last.withValues(alpha: 0.08),
          ],
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _ShareOrbit extends StatelessWidget {
  const _ShareOrbit({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x150F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }
}
