import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mana_poster/app/localization/app_language.dart';

enum ExportPaywallDecision {
  cancel,
  freeWithWatermark,
  upgradeAndExport,
  restorePurchase,
}

class ExportPaywallScreen extends StatefulWidget {
  const ExportPaywallScreen({
    super.key,
    required this.previewBytes,
    required this.isProUser,
    required this.forExport,
  });

  final Uint8List? previewBytes;
  final bool isProUser;
  final bool forExport;

  @override
  State<ExportPaywallScreen> createState() => _ExportPaywallScreenState();
}

class _ExportPaywallScreenState extends State<ExportPaywallScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final titles = <String>[
      strings.localized(
        telugu: 'ఫ్రీ ఎగుమతి ప్రివ్యూ',
        english: 'Free export preview',
      ),
      strings.localized(
        telugu: 'ప్రో ఎగుమతి ప్రివ్యూ',
        english: 'Pro export preview',
      ),
      strings.localized(
        telugu: 'ప్రో ప్రయోజనాలు',
        english: 'Pro benefits',
      ),
    ];
    final descriptions = <String>[
      strings.localized(
        telugu: 'ఫ్రీలో వాటర్‌మార్క్‌తో ఎగుమతి అవుతుంది.',
        english: 'Free exports include a watermark.',
      ),
      strings.localized(
        telugu: 'ప్రోలో వాటర్‌మార్క్ లేకుండా క్లియర్ ఎగుమతి అవుతుంది.',
        english: 'Pro exports are clean and watermark-free.',
      ),
      strings.localized(
        telugu: 'నెలకు రూ.20తో వేగమైన వర్క్‌ఫ్లో మరియు క్లీన్ అవుట్‌పుట్ పొందండి.',
        english: 'Get a faster workflow and clean output for Rs.20/month.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.localized(
            telugu: 'ఎగుమతి ఎంపికలు',
            english: 'Export Options',
          ),
        ),
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(ExportPaywallDecision.cancel);
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: titles.length,
                  onPageChanged: (value) {
                    setState(() {
                      _currentIndex = value;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _ExportSlideCard(
                      title: titles[index],
                      description: descriptions[index],
                      watermarkVisible: index != 1,
                      previewBytes: widget.previewBytes,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(titles.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              if (widget.forExport) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(
                        context,
                      ).pop(ExportPaywallDecision.freeWithWatermark);
                    },
                    child: Text(
                      strings.localized(
                        telugu: 'ఫ్రీతో కొనసాగించండి (వాటర్‌మార్క్)',
                        english: 'Continue Free (Watermark)',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isProUser
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.of(
                            context,
                          ).pop(ExportPaywallDecision.upgradeAndExport);
                        },
                  child: Text(
                    widget.isProUser
                        ? strings.localized(
                            telugu: 'ప్రో ఇప్పటికే యాక్టివ్‌లో ఉంది',
                            english: 'Pro already active',
                          )
                        : strings.localized(
                            telugu: 'ప్రోకి అప్‌గ్రేడ్ అవ్వండి (రూ.20/నెల)',
                            english: 'Upgrade to Pro (Rs.20/month)',
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(
                      context,
                    ).pop(ExportPaywallDecision.restorePurchase);
                  },
                  child: Text(
                    strings.localized(
                      telugu: 'ఉన్న ప్లాన్‌ను రిస్టోర్ చేయండి',
                      english: 'Restore Existing Plan',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.localized(
                  telugu:
                      'గమనిక: లైవ్ బిల్లింగ్ టెస్ట్ కోసం Play/App Store టెస్టర్ అకౌంట్ అవసరం.',
                  english:
                      'Note: A Play/App Store tester account is required for live billing tests.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportSlideCard extends StatelessWidget {
  const _ExportSlideCard({
    required this.title,
    required this.description,
    required this.watermarkVisible,
    required this.previewBytes,
  });

  final String title;
  final String description;
  final bool watermarkVisible;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: previewBytes == null
                          ? ColoredBox(
                              color: const Color(0xFFF8FAFD),
                              child: Center(
                                child: Text(
                                  context.strings.localized(
                                    telugu: 'ప్రివ్యూ అందుబాటులో లేదు',
                                    english: 'Preview unavailable',
                                  ),
                                ),
                              ),
                            )
                          : Image.memory(
                              previewBytes!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.low,
                              cacheWidth: 960,
                            ),
                    ),
                  ),
                  if (watermarkVisible)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'assets/branding/mana_poster_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Mana Poster',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
