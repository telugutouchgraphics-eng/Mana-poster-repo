import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen>
    with AppLanguageStateMixin {
  final SubscriptionBackendService _backendService =
      SubscriptionBackendService();
  SubscriptionBackendResult? _backendResult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final result = await _backendService.fetchEntitlement();
    if (!mounted) {
      return;
    }
    setState(() {
      _backendResult = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = _SubscriptionCopy(context.currentLanguage);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
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
      body: SafeArea(
        top: false,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFF7FAFF), Color(0xFFF3F7FD)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xFF6D28D9).withValues(alpha: 0.14),
                        const Color(0xFF6D28D9).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 220,
              left: -55,
              child: IgnorePointer(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xFF16A34A).withValues(alpha: 0.10),
                        const Color(0xFF16A34A).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                _HeroCard(copy: copy, statusLine: _statusLine(copy)),
                const SizedBox(height: 16),
                _FreePlanCard(copy: copy),
                const SizedBox(height: 16),
                _PremiumPlanCard(copy: copy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine(_SubscriptionCopy copy) {
    if (_loading) {
      return copy.statusLoading;
    }

    final result = _backendResult;
    if (result == null) {
      return copy.statusUnknown;
    }

    switch (result.state) {
      case SubscriptionBackendState.verifiedPro:
        return copy.statusActive;
      case SubscriptionBackendState.verifiedFree:
        return copy.statusInactive;
      case SubscriptionBackendState.notConfigured:
        return copy.statusNotConfigured;
      case SubscriptionBackendState.failed:
        return copy.statusUnavailable;
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.copy, required this.statusLine});

  final _SubscriptionCopy copy;
  final String statusLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF4C1D95),
            Color(0xFF6D28D9),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x26FFFFFF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x334C1D95),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'FREE PLAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.heroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.heroSubtitle,
            style: const TextStyle(
              color: Color(0xFFEAF7EE),
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _PricePill(
                  label: copy.trialChipLabel,
                  value: copy.trialChipValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PricePill(
                  label: copy.monthlyChipLabel,
                  value: copy.monthlyChipValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLine,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF5F3FF),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({required this.copy});

  final _SubscriptionCopy copy;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCardShell(
      accentGradient: const LinearGradient(
        colors: <Color>[Color(0xFF60A5FA), Color(0xFF2563EB)],
      ),
      surfaceColor: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: copy.freeSectionTitle,
            iconBg: const Color(0xFFE8EEFF),
            iconColor: const Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 10),
          _SoftNote(
            text: copy.heroSubtitle,
            icon: Icons.info_outline_rounded,
            background: const Color(0xFFF3F7FF),
            foreground: const Color(0xFF1D4ED8),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _PlanMetric(label: copy.trialLabel, value: copy.trialValue),
              _PlanMetric(label: copy.monthlyLabel, value: copy.monthlyValue),
            ],
          ),
          const SizedBox(height: 12),
          ...copy.freePoints.map(_BulletLine.new),
        ],
      ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({required this.copy});

  final _SubscriptionCopy copy;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCardShell(
      accentGradient: const LinearGradient(
        colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      ),
      surfaceColor: const Color(0xFFFBF8FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _SectionTitle(
                  icon: Icons.workspace_premium_rounded,
                  title: copy.premiumSectionTitle,
                  iconBg: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF6D28D9),
                  titleColor: const Color(0xFF2E1065),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  copy.premiumBadge,
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SoftNote(
            text: copy._isTelugu
                ? 'ప్రతి Premium పోస్టర్‌కు విడిగా కొనుగోలు అవసరం.'
                : 'Each Premium poster needs separate purchase.',
            icon: Icons.workspace_premium_rounded,
            background: const Color(0xFFF3E8FF),
            foreground: const Color(0xFF6D28D9),
          ),
          const SizedBox(height: 12),
          ...copy.premiumPoints.map(
            (item) => _BulletLine(
              item,
              textColor: const Color(0xFF4C1D95),
              dotColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCardShell extends StatelessWidget {
  const _SurfaceCardShell({
    required this.accentGradient,
    required this.surfaceColor,
    required this.child,
  });

  final Gradient accentGradient;
  final Color surfaceColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EBF5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(gradient: accentGradient),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftNote extends StatelessWidget {
  const _SoftNote({
    required this.text,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.iconBg,
    required this.iconColor,
    this.titleColor = const Color(0xFF0F172A),
  });

  final IconData icon;
  final String title;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0x7FFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(
    this.text, {
    this.textColor = const Color(0xFF334155),
    this.dotColor = const Color(0xFF1E3A8A),
  });

  final String text;
  final Color textColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(Icons.brightness_1_rounded, size: 7, color: dotColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.8,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCopy {
  const _SubscriptionCopy(this.language);

  final AppLanguage language;

  bool get _isTelugu => language == AppLanguage.telugu;

  String get title => _isTelugu ? 'సబ్‌స్క్రిప్షన్' : 'Subscription';
  String get heroTitle =>
      _isTelugu ? 'Free పోస్టర్ల ప్లాన్' : 'Free posters plan';
  String get heroSubtitle => _isTelugu
      ? 'ఈ ప్లాన్ Free ట్యాబ్ పోస్టర్లకే వర్తిస్తుంది.'
      : 'This plan applies only to Free-tab posters.';
  String get trialChipLabel => _isTelugu ? 'Trial' : 'Trial';
  String get trialChipValue => _isTelugu ? '₹1 / 3 రోజులు' : '₹1 / 3 days';
  String get monthlyChipLabel => _isTelugu ? 'తర్వాత' : 'After trial';
  String get monthlyChipValue => _isTelugu ? '₹149 / నెల' : '₹149 / month';

  String get freeSectionTitle =>
      _isTelugu ? 'Free పోస్టర్ల ప్లాన్' : 'Free posters plan';
  String get trialLabel => _isTelugu ? 'Trial ప్లాన్' : 'Trial plan';
  String get trialValue => _isTelugu ? '₹1 / 3 రోజులు' : '₹1 / 3 days';
  String get monthlyLabel => _isTelugu ? 'Trial తర్వాత' : 'After trial';
  String get monthlyValue =>
      _isTelugu ? '₹149 / నెల (Auto-renewal)' : '₹149 / month (Auto-renewal)';
  List<String> get freePoints => _isTelugu
      ? const <String>[
          'Free పోస్టర్లను పూర్తిగా ఎడిట్ చేసి వాడుకోవచ్చు.',
          'ఈ సబ్‌స్క్రిప్షన్ Premium పోస్టర్లకు వర్తించదు.',
        ]
      : const <String>[
          'Free posters can be fully edited and used.',
          'This subscription does not apply to Premium posters.',
        ];

  String get premiumSectionTitle =>
      _isTelugu ? 'Premium పోస్టర్ల కొనుగోలు' : 'Premium poster purchase';
  String get premiumBadge =>
      _isTelugu ? 'Separate కొనుగోలు' : 'Separate purchase';
  List<String> get premiumPoints => _isTelugu
      ? const <String>[
          'ప్రతి Premium పోస్టర్‌కు వేర్వేరు ధర ఉంటుంది.',
          'కావాల్సిన పోస్టర్‌ను విడిగా కొనుగోలు చేయాలి.',
          'కొనుగోలు చేసిన Premium పోస్టర్‌ను పూర్తిగా customize చేయవచ్చు.',
        ]
      : const <String>[
          'Each Premium poster has separate pricing.',
          'Buy the poster you need separately.',
          'Purchased Premium posters can be fully customized.',
        ];

  String get statusLoading =>
      _isTelugu ? 'ప్లాన్ స్థితి చెక్ అవుతోంది...' : 'Checking plan status...';
  String get statusActive => _isTelugu
      ? 'ప్రస్తుతం మీరు Free plan లో ఉన్నారు.'
      : 'You are currently on Free plan.';
  String get statusInactive => _isTelugu
      ? 'ప్రస్తుతం Trial / Monthly plan active లేదు.'
      : 'Trial / Monthly plan is not active now.';
  String get statusNotConfigured => _isTelugu
      ? 'ప్రస్తుతం ప్లాన్ సమాచారం మాత్రమే చూపిస్తున్నాం.'
      : 'Showing plan information only for now.';
  String get statusUnavailable => _isTelugu
      ? 'ప్రస్తుతం స్థితిని నిర్ధారించలేకపోయాము.'
      : 'Could not confirm status right now.';
  String get statusUnknown => _isTelugu
      ? 'ప్రస్తుతం స్థితి సమాచారం అందుబాటులో లేదు.'
      : 'Status information is not available now.';
}
