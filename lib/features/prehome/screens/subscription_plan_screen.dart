import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({
    super.key,
    this.triggerRestoreOnOpen = false,
  });

  final bool triggerRestoreOnOpen;

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen>
    with AppLanguageStateMixin {
  static const String _premiumPlanProductId = String.fromEnvironment(
    'MANA_POSTER_PREMIUM_PLAN_PRODUCT_ID',
    defaultValue: 'mana_poster_premium_monthly_149',
  );
  static const String _premiumPlanLegacyProductId = String.fromEnvironment(
    'MANA_POSTER_PREMIUM_PLAN_LEGACY_PRODUCT_ID',
    defaultValue: 'mana_poster_premium_monthly_149_legacy',
  );

  final SubscriptionBackendService _backendService =
      SubscriptionBackendService();
  final ProPurchaseGateway _freePlanGateway = InAppPurchaseGateway(
    productId: _premiumPlanProductId,
    fallbackProductIds: const <String>[
      _premiumPlanLegacyProductId,
      PurchaseProductIds.proMonthly20,
      PurchaseProductIds.proMonthlyLegacy,
    ],
  );
  final ProPurchaseGateway _premiumPlanGateway = InAppPurchaseGateway(
    productId: _premiumPlanProductId,
    fallbackProductIds: const <String>[
      _premiumPlanLegacyProductId,
      PurchaseProductIds.proMonthly20,
      PurchaseProductIds.proMonthlyLegacy,
    ],
  );
  final ProPurchaseGateway _restoreGateway = InAppPurchaseGateway(
    productId: _premiumPlanProductId,
    fallbackProductIds: const <String>[
      _premiumPlanProductId,
      _premiumPlanLegacyProductId,
      PurchaseProductIds.proMonthly20,
      PurchaseProductIds.proMonthlyLegacy,
    ],
  );

  SubscriptionBackendResult? _backendResult;
  bool _loading = true;
  bool _busyFree = false;
  bool _busyPremium = false;
  bool _busyRestore = false;

  bool get _isBusy => _loading || _busyFree || _busyPremium || _busyRestore;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
    if (widget.triggerRestoreOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_restoreSubscriptions());
      });
    }
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

  Future<void> _subscribeFreePlan() async {
    if (_isBusy) {
      return;
    }
    setState(() => _busyFree = true);
    try {
      final outcome = await _freePlanGateway.purchaseMonthlyPro();
      final activated = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'Free poster subscription activate ayyindi',
          english: 'Free poster subscription activated',
        ),
      );
      if (!mounted || !activated) {
        return;
      }
      AppNavigator.openHome();
    } finally {
      if (mounted) {
        setState(() => _busyFree = false);
      }
    }
  }

  Future<void> _subscribePremiumPlan() async {
    if (_isBusy) {
      return;
    }
    setState(() => _busyPremium = true);
    try {
      final outcome = await _premiumPlanGateway.purchaseMonthlyPro();
      final activated = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'Premium subscription activate ayyindi',
          english: 'Premium subscription activated',
        ),
      );
      if (!mounted || !activated) {
        return;
      }
      AppNavigator.openHome();
    } finally {
      if (mounted) {
        setState(() => _busyPremium = false);
      }
    }
  }

  Future<void> _restoreSubscriptions() async {
    if (_isBusy) {
      return;
    }
    setState(() => _busyRestore = true);
    try {
      final outcome = await _restoreGateway.restorePurchases();
      final restored = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'Subscription restore ayyindi',
          english: 'Subscription restored',
        ),
      );
      if (!mounted || !restored) {
        return;
      }
      AppNavigator.openHome();
    } finally {
      if (mounted) {
        setState(() => _busyRestore = false);
      }
    }
  }

  Future<bool> _finalizeOutcome(
    PurchaseFlowOutcome outcome, {
    required String successMessage,
  }) async {
    if (!mounted) {
      return false;
    }
    final messenger = ScaffoldMessenger.of(context);

    if (outcome.result != PurchaseFlowResult.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForPurchaseResult(outcome.result))),
      );
      return false;
    }

    if (!_backendService.isConfigured) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      await _loadStatus();
      return true;
    }

    final evidence = outcome.evidence;
    if (evidence == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _t(
              telugu: 'Verification data dorakaledu. Restore try cheyyandi',
              english: 'Verification data is missing. Try restore.',
            ),
          ),
        ),
      );
      return false;
    }

    final verifyResult = await _backendService.verifyPurchase(evidence: evidence);
    if (!mounted) {
      return false;
    }

    if (!verifyResult.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            verifyResult.message?.isNotEmpty == true
                ? 'Verification fail: ${verifyResult.message}'
                : _t(
                    telugu: 'Subscription verification fail ayyindi',
                    english: 'Subscription verification failed',
                  ),
          ),
        ),
      );
      return false;
    }

    await _loadStatus();
    if (!mounted) {
      return false;
    }
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    return true;
  }

  String _messageForPurchaseResult(PurchaseFlowResult result) {
    return switch (result) {
      PurchaseFlowResult.cancelled =>
        _t(telugu: 'Payment cancel chesaru', english: 'Payment was cancelled'),
      PurchaseFlowResult.failed =>
        _t(telugu: 'Payment fail ayyindi', english: 'Payment failed'),
      PurchaseFlowResult.billingUnavailable => _t(
        telugu: 'Billing service andubatulo ledu',
        english: 'Billing service is unavailable',
      ),
      PurchaseFlowResult.productNotFound => _t(
        telugu: 'Store product dorakaledu. Product id check cheyyandi',
        english: 'Store product not found. Check product id.',
      ),
      PurchaseFlowResult.timedOut => _t(
        telugu: 'Payment response timeout ayyindi. Malli try cheyyandi',
        english: 'Payment response timed out. Please try again.',
      ),
      PurchaseFlowResult.nothingToRestore => _t(
        telugu: 'Restore cheyadaniki subscription dorakaledu',
        english: 'No subscription found to restore',
      ),
      PurchaseFlowResult.success => '',
    };
  }

  String _statusLine() {
    if (_loading) {
      return _t(
        telugu: 'Plan status check avuthondi...',
        english: 'Checking plan status...',
      );
    }
    final result = _backendResult;
    if (result == null) {
      return _t(
        telugu: 'Status info andubatulo ledu',
        english: 'Status information unavailable',
      );
    }

    return switch (result.state) {
      SubscriptionBackendState.verifiedPro => _t(
        telugu: 'Active subscription undi',
        english: 'Subscription is active',
      ),
      SubscriptionBackendState.verifiedFree => _t(
        telugu: 'Subscription active ledu',
        english: 'Subscription is not active',
      ),
      SubscriptionBackendState.notConfigured => _t(
        telugu: 'Plan info mode lo undi',
        english: 'Plan info mode',
      ),
      SubscriptionBackendState.failed => _t(
        telugu: 'Status check fail ayyindi',
        english: 'Status check failed',
      ),
    };
  }

  String _t({required String telugu, required String english}) {
    return context.strings.localized(telugu: telugu, english: english);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            Text(
              _statusLine(),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _PlanSection(
              title: _t(
                telugu: 'Free poster plan (Trial + Monthly)',
                english: 'Free poster plan (Trial + Monthly)',
              ),
              buttonLabel: _t(
                telugu: 'Subscribe Free plan',
                english: 'Subscribe Free plan',
              ),
              onTap: _subscribeFreePlan,
              busy: _busyFree,
              accent: const Color(0xFF1D4ED8),
            ),
            const SizedBox(height: 24),
            _PlanSection(
              title: _t(telugu: 'Premium plan', english: 'Premium plan'),
              buttonLabel: _t(
                telugu: 'Subscribe Premium plan',
                english: 'Subscribe Premium plan',
              ),
              onTap: _subscribePremiumPlan,
              busy: _busyPremium,
              accent: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _busyRestore ? null : _restoreSubscriptions,
              icon: _busyRestore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore_rounded),
              label: Text(
                _t(
                  telugu: 'సబ్‌స్క్రిప్షన్లు రిస్టోర్ చేయండి',
                  english: 'Restore subscriptions',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.buttonLabel,
    required this.onTap,
    required this.busy,
    required this.accent,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool busy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(buttonLabel),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}

