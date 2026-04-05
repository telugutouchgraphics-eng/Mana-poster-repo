import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const List<String> _titles = <String>[
    'Free export preview',
    'Pro export preview',
    'Pro benefits',
  ];

  static const List<String> _descriptions = <String>[
    'Free lo watermark tho export avuthundi.',
    'Pro lo watermark lekunda clean export avuthundi.',
    'Rs.20/month tho fast workflow and clean output pondandi.',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Options'),
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
                  itemCount: _titles.length,
                  onPageChanged: (value) {
                    setState(() {
                      _currentIndex = value;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _ExportSlideCard(
                      title: _titles[index],
                      description: _descriptions[index],
                      watermarkVisible: index != 1,
                      previewBytes: widget.previewBytes,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_titles.length, (index) {
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
                      Navigator.of(context).pop(
                        ExportPaywallDecision.freeWithWatermark,
                      );
                    },
                    child: const Text('Free tho continue (Watermark)'),
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
                          Navigator.of(context).pop(
                            ExportPaywallDecision.upgradeAndExport,
                          );
                        },
                  child: Text(
                    widget.isProUser
                        ? 'Pro already active'
                        : 'Pro ki Upgrade avvandi (Rs.20/month)',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(
                      ExportPaywallDecision.restorePurchase,
                    );
                  },
                  child: const Text('Existing plan ni Restore cheyyandi'),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Note: Live billing test ki Play/App Store tester account required.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                          ? const ColoredBox(
                              color: Color(0xFFF8FAFD),
                              child: Center(
                                child: Text('Preview andubatulo ledu'),
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
