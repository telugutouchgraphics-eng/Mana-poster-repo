import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';

enum SubscriptionPlanMode { appPlan, editorPlan }

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({
    super.key,
    this.triggerRestoreOnOpen = false,
    this.startPurchaseOnOpen = false,
    this.mode = SubscriptionPlanMode.appPlan,
  });

  const SubscriptionPlanScreen.editorPro({
    super.key,
    this.triggerRestoreOnOpen = false,
    this.startPurchaseOnOpen = false,
  }) : mode = SubscriptionPlanMode.editorPlan;

  final bool triggerRestoreOnOpen;
  final bool startPurchaseOnOpen;
  final SubscriptionPlanMode mode;

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen>
    with AppLanguageStateMixin, WidgetsBindingObserver {
  late final SubscriptionBackendService _backendService;
  late final ProPurchaseGateway _purchaseGateway;

  AppLanguage _languageSnapshot = AppLanguage.telugu;
  SubscriptionBackendResult? _backendResult;
  ProductDetails? _selectedProduct;
  bool _loading = true;
  bool _busyFree = false;
  bool _busyRestore = false;
  bool _didAutoStartPurchase = false;
  bool _didAutoTriggerRestore = false;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  DateTime _screenShownAt = DateTime.now();
  DateTime? _lastStoreFlowAttemptAt;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  bool get _isBusy => _loading || _busyFree || _busyRestore;
  bool get _isSubscriptionActive => _backendResult?.hasAccess == true;
  bool get _isSubscriptionExpired => _backendResult?.isExpired == true;
  bool get _canSubscribe => !_isSubscriptionActive;
  AppStrings get _strings => AppStrings(_languageSnapshot);
  bool get _isEditorPlan => widget.mode == SubscriptionPlanMode.editorPlan;
  Set<String> get _productIdsToQuery => _isEditorPlan
      ? EditorSubscriptionPlanConfig.resolvedProductIds()
      : SubscriptionPlanConfig.resolvedPremiumProductIds();
  String get _monthlyFallbackPrice => _isEditorPlan
      ? EditorSubscriptionPlanConfig.monthlyPriceDisplay
      : SubscriptionPlanConfig.monthlyPriceDisplay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _languageSnapshot = context.currentLanguage;
  }

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _backendService = _isEditorPlan
        ? SubscriptionBackendService.editor()
        : SubscriptionBackendService.app();
    _purchaseGateway = _isEditorPlan
        ? InAppPurchaseGateway(
            productId: EditorSubscriptionPlanConfig.productId,
            fallbackProductIds:
                EditorSubscriptionPlanConfig.resolvedProductIds().toList(
                  growable: false,
                ),
            preferredBasePlanId: EditorSubscriptionPlanConfig.monthlyBasePlanId,
            preferredOfferId: EditorSubscriptionPlanConfig.trialOfferId,
          )
        : InAppPurchaseGateway();
    WidgetsBinding.instance.addObserver(this);
    _screenShownAt = DateTime.now();
    unawaited(_purchaseGateway.initialize());
    unawaited(prewarmSubscriptionVideoPrompts());
    SubscriptionBackendService.entitlementNotifier.addListener(
      _handleEntitlementChanged,
    );
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.unprotectScreen());
    WidgetsBinding.instance.removeObserver(this);
    if (_purchaseGateway.isPurchaseFlowActive) {
      unawaited(_purchaseGateway.abandonPendingPurchaseFlow());
    }
    SubscriptionBackendService.entitlementNotifier.removeListener(
      _handleEntitlementChanged,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  void _handleEntitlementChanged() {
    final latest = SubscriptionBackendService.entitlementNotifier.value;
    if (!mounted || latest == null) {
      return;
    }
    setState(() {
      _backendResult = latest;
    });
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final wait = await Future.wait<Object?>(<Future<Object?>>[
        _loadStoreProduct(),
        _backendService.fetchEntitlement(forceRefresh: true),
      ]);
      final product = wait[0] as ProductDetails?;
      final result = wait[1] as SubscriptionBackendResult;
      if (!mounted) {
        return;
      }
      setState(() {
        _backendResult = result;
        _selectedProduct = product;
        _loading = false;
      });
      if (product != null) {
        _logSelectedProduct(product);
      }
      if (widget.triggerRestoreOnOpen && !_didAutoTriggerRestore) {
        _didAutoTriggerRestore = true;
        unawaited(_runDeferredAutoAction(_restoreSubscriptions));
        return;
      }
      if (widget.startPurchaseOnOpen &&
          !_didAutoStartPurchase &&
          _canSubscribe) {
        _didAutoStartPurchase = true;
        unawaited(_runDeferredAutoAction(_subscribeFreePlan));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _backendResult ??= const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Unable to load subscription status right now.',
        );
      });
    }
  }

  Future<void> _refreshStatus() async {
    await _loadStatus();
  }

  Future<void> _runDeferredAutoAction(Future<void> Function() action) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    if (!_canSafelyLaunchStoreFlow()) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) {
        return;
      }
    }
    if (!_canSafelyLaunchStoreFlow()) {
      return;
    }
    await action();
  }

  bool _canSafelyLaunchStoreFlow() {
    if (!mounted) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return false;
    }
    if (_appLifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    final sinceShown = DateTime.now().difference(_screenShownAt);
    if (sinceShown < const Duration(milliseconds: 800)) {
      return false;
    }
    final lastAttemptAt = _lastStoreFlowAttemptAt;
    if (lastAttemptAt != null &&
        DateTime.now().difference(lastAttemptAt) < const Duration(seconds: 3)) {
      return false;
    }
    return true;
  }

  Future<bool> _prepareForStoreFlow() async {
    await _purchaseGateway.initialize();
    if (!_canSafelyLaunchStoreFlow()) {
      return false;
    }
    _lastStoreFlowAttemptAt = DateTime.now();
    return true;
  }

  Future<ProductDetails?> _loadStoreProduct() async {
    try {
      final store = InAppPurchase.instance;
      final available = await store.isAvailable();
      if (!available) {
        return null;
      }
      final ids = _productIdsToQuery;
      var response = await store.queryProductDetails(ids);
      if (response.productDetails.isEmpty) {
        for (final id in ids) {
          final retry = await store.queryProductDetails(<String>{id});
          if (retry.productDetails.isNotEmpty) {
            response = retry;
            break;
          }
        }
      }
      if (response.productDetails.isEmpty) {
        return null;
      }
      for (final id in ids) {
        try {
          return response.productDetails.firstWhere((item) => item.id == id);
        } catch (_) {
          continue;
        }
      }
      return response.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  void _logSelectedProduct(ProductDetails selectedDetails) {
    _debugLog('productId=${selectedDetails.id}');
    _debugLog(
      'isGooglePlayProduct=${selectedDetails is GooglePlayProductDetails}',
    );
    if (selectedDetails is GooglePlayProductDetails) {
      final offers = selectedDetails.productDetails.subscriptionOfferDetails;
      _debugLog('offersCount=${offers?.length ?? 0}');
      if (offers != null && offers.isNotEmpty) {
        _debugLog('offerToken=${offers.first.offerIdToken}');
      }
    }
  }

  ProPurchaseGateway _purchaseGatewayForBasePlan(String? basePlanId) {
    if (basePlanId == null || basePlanId.isEmpty) {
      return _purchaseGateway;
    }
    final isEditorBasePlan =
        basePlanId == EditorSubscriptionPlanConfig.monthlyBasePlanId ||
        basePlanId == EditorSubscriptionPlanConfig.yearlyBasePlanId;
    if (!isEditorBasePlan) {
      return _purchaseGateway;
    }
    return InAppPurchaseGateway(
      productId: EditorSubscriptionPlanConfig.productId,
      fallbackProductIds: EditorSubscriptionPlanConfig.resolvedProductIds()
          .toList(growable: false),
      preferredBasePlanId: basePlanId,
      preferredOfferId: '',
    );
  }

  Future<void> _subscribeFreePlan({String? editorBasePlanId}) async {
    if (_isBusy || !_canSubscribe) {
      return;
    }
    final purchaseGateway = _purchaseGatewayForBasePlan(editorBasePlanId);
    await purchaseGateway.initialize();
    if (!await _prepareForStoreFlow()) {
      return;
    }
    var shouldShowThanksPrompt = false;
    setState(() => _busyFree = true);
    try {
      final outcome = await purchaseGateway.purchaseMonthlyPro();
      if (!mounted) {
        return;
      }
      final activated = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'సబ్‌స్క్రిప్షన్ యాక్టివ్ అయింది',
          english: 'Subscription activated',
          hindi: 'सब्सक्रिप्शन सक्रिय हो गया',
          tamil: 'சந்தா செயல்படுத்தப்பட்டது',
          kannada: 'ಚಂದಾದಾರಿಕೆ ಸಕ್ರಿಯವಾಗಿದೆ',
          malayalam: 'സബ്സ്ക്രിപ്ഷൻ സജീവമായി',
        ),
      );
      if (!mounted) {
        return;
      }
      if (activated) {
        shouldShowThanksPrompt = true;
      }
    } finally {
      if (mounted) {
        setState(() => _busyFree = false);
      }
    }
    if (!mounted) {
      return;
    }
    if (shouldShowThanksPrompt) {
      await _showThanksPromptOnce();
      if (!mounted) {
        return;
      }
      AppNavigator.openHome();
    }
  }

  Future<void> _restoreSubscriptions() async {
    if (_isBusy) {
      return;
    }
    if (!await _prepareForStoreFlow()) {
      return;
    }
    setState(() => _busyRestore = true);
    try {
      final outcome = await _purchaseGateway.restorePurchases();
      if (!mounted) {
        return;
      }
      if (outcome.result == PurchaseFlowResult.nothingToRestore) {
        final fallback = await _backendService.fetchFreshEntitlementWithRetry();
        if (!mounted) {
          return;
        }
        if (fallback.hasAccess) {
          await _refreshEntitlementAfterRestore();
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showTopSnackBar(
            AppSnackBar.build(
              content: Text(
                _t(
                  telugu: 'బ్యాక్‌ఎండ్ నుంచి యాక్టివ్ ప్లాన్ రిస్టోర్ అయింది',
                  english: 'An active plan was restored from the backend',
                  hindi: 'बैकएंड से सक्रिय प्लान बहाल हो गया',
                  tamil:
                      'பின்தளத்திலிருந்து செயலிலுள்ள திட்டம் மீட்டெடுக்கப்பட்டது',
                  kannada: 'ಬ್ಯಾಕೆಂಡ್‌ನಿಂದ ಸಕ್ರಿಯ ಯೋಜನೆ ಮರುಸ್ಥಾಪನೆಯಾಯಿತು',
                  malayalam: 'ബാക്ക്എൻഡിൽ നിന്ന് സജീവ പ്ലാൻ പുനഃസ്ഥാപിച്ചു',
                ),
              ),
            ),
          );
          await _showThanksPromptOnce();
          if (!mounted) {
            return;
          }
          AppNavigator.openHome();
          return;
        }
      }
      final restored = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'సబ్‌స్క్రిప్షన్ రిస్టోర్ అయింది',
          english: 'Subscription restored',
          hindi: 'सब्सक्रिप्शन बहाल हो गया',
          tamil: 'சந்தா மீட்டெடுக்கப்பட்டது',
          kannada: 'ಚಂದಾದಾರಿಕೆಯನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ',
          malayalam: 'സബ്സ്ക്രിപ്ഷൻ പുനഃസ്ഥാപിച്ചു',
        ),
      );
      if (!mounted || !restored) {
        return;
      }
      await _showThanksPromptOnce();
      if (!mounted) {
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
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(_messageForPurchaseResult(outcome.result)),
        ),
      );
      return false;
    }

    if (!_backendService.isConfigured) {
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            _t(
              telugu:
                  'సబ్‌స్క్రిప్షన్ వెరిఫికేషన్ సర్వర్ అందుబాటులో లేదు. దయచేసి తర్వాత మళ్లీ ప్రయత్నించండి.',
              english:
                  'Subscription verification is unavailable. Please try again later.',
              hindi:
                  'सदस्यता सत्यापन उपलब्ध नहीं है। कृपया बाद में फिर प्रयास करें।',
              tamil:
                  'சந்தா சரிபார்ப்பு கிடைக்கவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.',
              kannada:
                  'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'സബ്സ്ക്രിപ്ഷൻ സ്ഥിരീകരണം ലഭ്യമല്ല. പിന്നീട് വീണ്ടും ശ്രമിക്കുക.',
            ),
          ),
        ),
      );
      return false;
    }

    final evidence = outcome.evidence;
    if (evidence == null) {
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            _t(
              telugu: 'వెరిఫికేషన్ డేటా లేదు. రిస్టోర్ ప్రయత్నించండి.',
              english: 'Verification data is missing. Try restore.',
              hindi: 'वेरिफिकेशन डेटा नहीं है। रिस्टोर करें।',
              tamil: 'சரிபார்ப்பு தரவு இல்லை. மீட்டெடுக்க முயற்சிக்கவும்.',
              kannada: 'ಪರಿಶೀಲನಾ ಡೇಟಾ ಇಲ್ಲ. ಮರುಸ್ಥಾಪಿಸಲು ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'സ്ഥിരീകരണ ഡാറ്റ ഇല്ല. റിസ്റ്റോർ ചെയ്യുക.',
            ),
          ),
        ),
      );
      return false;
    }

    final verifyResult = await _verifyPurchaseWithRetry(evidence);
    if (!mounted) {
      return false;
    }

    if (!verifyResult.hasAccess) {
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            verifyResult.message?.isNotEmpty == true
                ? '${_t(telugu: 'వెరిఫికేషన్ విఫలమైంది', english: 'Verification failed', hindi: 'सत्यापन विफल हुआ', tamil: 'சரிபார்ப்பு தோல்வியடைந்தது', kannada: 'ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು', malayalam: 'പരിശോധന പരാജയപ്പെട്ടു')}: ${verifyResult.message}'
                : _t(
                    telugu: 'సబ్‌స్క్రిప్షన్ వెరిఫికేషన్ విఫలమైంది',
                    english: 'Subscription verification failed',
                    hindi: 'सब्सक्रिप्शन सत्यापन विफल हुआ',
                    tamil: 'சந்தா சரிபார்ப்பு தோல்வியடைந்தது',
                    kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
                    malayalam: 'സബ്സ്ക്രിപ്ഷൻ പരിശോധന പരാജയപ്പെട്ടു',
                  ),
          ),
        ),
      );
      return false;
    }

    await evidence.completeStorePurchase();
    final refreshed = await _refreshEntitlementAfterRestore();
    if (!mounted) {
      return false;
    }
    if (!refreshed.hasAccess) {
      messenger.showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            _t(
              telugu:
                  'రీస్టోర్ అయినా ప్రో యాక్సెస్ ఇంకా అప్డేట్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english:
                  'Restore succeeded, but Pro access is not updated yet. Please try again.',
              hindi:
                  'रिस्टोर सफल हुआ, लेकिन प्रो एक्सेस अभी अपडेट नहीं हुआ। कृपया फिर से प्रयास करें।',
              tamil:
                  'ரிஸ்டோர் வெற்றியானது, ஆனால் Pro அணுகல் இன்னும் புதுப்பிக்கப்படவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada:
                  'ರಿಸ್ಟೋರ್ ಯಶಸ್ವಿಯಾಗಿದೆ, ಆದರೆ Pro ಪ್ರವೇಶ ಇನ್ನೂ ಅಪ್‌ಡೇಟ್ ಆಗಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'റിസ്റ്റോർ വിജയിച്ചു, പക്ഷേ Pro ആക്സസ് ഇനിയും അപ്ഡേറ്റ് ആയിട്ടില്ല. വീണ്ടും ശ്രമിക്കുക.',
            ),
          ),
        ),
      );
      return false;
    }
    messenger.showTopSnackBar(AppSnackBar.build(content: Text(successMessage)));
    return true;
  }

  Future<SubscriptionBackendResult> _refreshEntitlementAfterRestore() async {
    final refreshed = await _backendService.fetchFreshEntitlementWithRetry();
    if (!mounted) {
      return refreshed;
    }
    setState(() {
      _backendResult = refreshed;
    });
    return refreshed;
  }

  Future<SubscriptionBackendResult> _verifyPurchaseWithRetry(
    PurchaseVerificationEvidence evidence,
  ) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 6),
    ];

    SubscriptionBackendResult? lastResult;
    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      lastResult = await _backendService.verifyPurchase(evidence: evidence);
      if (lastResult.hasAccess) {
        return lastResult;
      }
    }
    return lastResult ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
  }

  Future<void> _showThanksPromptOnce() async {
    final result = _backendResult;
    if (result == null) {
      await showSubscriptionThanksVideoPromptIfAvailable(context);
      return;
    }

    final identity = _buildThanksPromptIdentity(result);
    if (identity == null) {
      await showSubscriptionThanksVideoPromptIfAvailable(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenIdentity = prefs.getString(_thanksPromptSeenKey(result));
    if (seenIdentity == identity) {
      return;
    }
    if (!mounted) {
      return;
    }

    await showSubscriptionThanksVideoPromptIfAvailable(context);
    if (!mounted) {
      return;
    }
    await prefs.setString(_thanksPromptSeenKey(result), identity);
  }

  String _thanksPromptSeenKey(SubscriptionBackendResult result) {
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final identityScope = authUid.isNotEmpty ? authUid : latestOrderId;
    final resolvedScope = identityScope.isNotEmpty ? identityScope : 'anon';
    return 'subscription_thanks_video_seen_v1_$resolvedScope';
  }

  String? _buildThanksPromptIdentity(SubscriptionBackendResult result) {
    if (!result.hasAccess) {
      return null;
    }
    final latestOrderId = result.latestOrderId?.trim() ?? '';
    final subscriptionState = result.subscriptionState?.trim() ?? '';
    final startEpoch =
        result.startDate?.millisecondsSinceEpoch.toString() ?? '';
    final expiryEpoch =
        result.expiryTime?.millisecondsSinceEpoch.toString() ?? '';
    final identity = <String>[
      latestOrderId,
      subscriptionState,
      startEpoch,
      expiryEpoch,
    ].where((value) => value.isNotEmpty).join('|');
    return identity.isEmpty ? null : identity;
  }

  String _messageForPurchaseResult(PurchaseFlowResult result) {
    return switch (result) {
      PurchaseFlowResult.cancelled => _t(
        telugu: 'చెల్లింపు రద్దు అయింది',
        english: 'Payment was cancelled',
        hindi: 'भुगतान रद्द कर दिया गया',
        tamil: 'பணம் செலுத்தல் ரத்து செய்யப்பட்டது',
        kannada: 'ಪಾವತಿ ರದ್ದುಗೊಂಡಿತು',
        malayalam: 'പേയ്മെന്റ് റദ്ദാക്കി',
      ),
      PurchaseFlowResult.pending => _t(
        telugu:
            'చెల్లింపు పెండింగ్‌లో ఉంది. Google Play నిర్ధారించిన తర్వాత ప్రో యాక్సెస్ యాక్టివ్ అవుతుంది.',
        english:
            'Payment is pending. Pro access will unlock after Google Play confirms it.',
        hindi:
            'भुगतान लंबित है। Google Play पुष्टि के बाद Pro access सक्रिय होगा।',
        tamil:
            'பணம் நிலுவையில் உள்ளது. Google Play உறுதிப்படுத்திய பிறகு Pro அணுகல் திறக்கும்.',
        kannada:
            'ಪಾವತಿ ಬಾಕಿಯಿದೆ. Google Play ದೃಢೀಕರಿಸಿದ ನಂತರ Pro ಪ್ರವೇಶ ಸಕ್ರಿಯವಾಗುತ್ತದೆ.',
        malayalam:
            'പേയ്മെന്റ് പെൻഡിംഗിലാണ്. Google Play സ്ഥിരീകരിച്ചതിന് ശേഷം Pro ആക്സസ് തുറക്കും.',
      ),
      PurchaseFlowResult.purchaseInProgress => _t(
        telugu: 'మరొక చెల్లింపు ఇప్పటికే కొనసాగుతోంది.',
        english: 'Another payment is already in progress.',
        hindi: 'एक और भुगतान पहले से चल रहा है।',
        tamil: 'மற்றொரு பணம் செலுத்தல் ஏற்கனவே நடைபெறுகிறது.',
        kannada: 'ಇನ್ನೊಂದು ಪಾವತಿ ಈಗಾಗಲೇ ನಡೆಯುತ್ತಿದೆ.',
        malayalam: 'മറ്റൊരു പേയ്മെന്റ് ഇതിനകം നടക്കുന്നു.',
      ),
      PurchaseFlowResult.failed => _t(
        telugu: 'చెల్లింపు విఫలమైంది',
        english: 'Payment failed',
        hindi: 'भुगतान विफल हुआ',
        tamil: 'பணம் செலுத்தல் தோல்வியடைந்தது',
        kannada: 'ಪಾವತಿ ವಿಫಲವಾಯಿತು',
        malayalam: 'പേയ്മെന്റ് പരാജയപ്പെട്ടു',
      ),
      PurchaseFlowResult.billingUnavailable => _t(
        telugu: 'బిల్లింగ్ సర్వీస్ అందుబాటులో లేదు',
        english: 'Billing service is unavailable',
        hindi: 'बिलिंग सेवा उपलब्ध नहीं है',
        tamil: 'பில்லிங் சேவை கிடைக்கவில்லை',
        kannada: 'ಬಿಲ್ಲಿಂಗ್ ಸೇವೆ ಲಭ್ಯವಿಲ್ಲ',
        malayalam: 'ബില്ലിംഗ് സേവനം ലഭ്യമല്ല',
      ),
      PurchaseFlowResult.productNotFound => _t(
        telugu: 'స్టోర్ ప్రోడక్ట్ కనిపించలేదు. ప్రోడక్ట్ ఐడీ చూడండి.',
        english: 'Store product not found. Check product id.',
        hindi: 'स्टोर उत्पाद नहीं मिला। प्रोडक्ट आईडी जांचें।',
        tamil:
            'ஸ்டோர் தயாரிப்பு கிடைக்கவில்லை. தயாரிப்பு ஐடியை சரிபார்க்கவும்.',
        kannada: 'ಸ್ಟೋರ್ ಉತ್ಪನ್ನ ಸಿಗಲಿಲ್ಲ. ಉತ್ಪನ್ನ ಐಡಿಯನ್ನು ಪರಿಶೀಲಿಸಿ.',
        malayalam:
            'സ്റ്റോർ ഉൽപ്പന്നം കണ്ടെത്തിയില്ല. ഉൽപ്പന്ന ഐഡി പരിശോധിക്കുക.',
      ),
      PurchaseFlowResult.timedOut => _t(
        telugu: 'చెల్లింపు ప్రతిస్పందన టైమ్ అవుట్ అయింది. మళ్లీ ప్రయత్నించండి.',
        english: 'Payment response timed out. Please try again.',
        hindi: 'भुगतान प्रतिक्रिया समय समाप्त हो गया। फिर से प्रयास करें।',
        tamil:
            'பணம் செலுத்தும் பதில் நேரம் முடிந்தது. மீண்டும் முயற்சிக்கவும்.',
        kannada: 'ಪಾವತಿ ಪ್ರತಿಕ್ರಿಯೆ ಸಮಯ ಮೀರಿದೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
        malayalam: 'പേയ്മെന്റ് പ്രതികരണം സമയപരിധി കഴിഞ്ഞു. വീണ്ടും ശ്രമിക്കുക.',
      ),
      PurchaseFlowResult.nothingToRestore => _t(
        telugu: 'రిస్టోర్ చేయడానికి సబ్‌స్క్రిప్షన్ కనిపించలేదు',
        english: 'No subscription found to restore',
        hindi: 'बहाल करने के लिए कोई सब्सक्रिप्शन नहीं मिला',
        tamil: 'மீட்டெடுக்க எந்த சந்தாவும் கிடைக்கவில்லை',
        kannada: 'ಮರುಸ್ಥಾಪಿಸಲು ಯಾವುದೇ ಚಂದಾದಾರಿಕೆ ಸಿಗಲಿಲ್ಲ',
        malayalam: 'പുനഃസ്ഥാപിക്കാൻ സബ്സ്ക്രിപ്ഷൻ കണ്ടെത്തിയില്ല',
      ),
      PurchaseFlowResult.success => '',
    };
  }

  String _statusLine() {
    if (_loading) {
      return _t(
        telugu: 'ప్లాన్ స్థితి చెక్ అవుతోంది...',
        english: 'Checking plan status...',
        hindi: 'प्लान स्थिति जांची जा रही है...',
        tamil: 'திட்ட நிலை சரிபார்க்கப்படுகிறது...',
        kannada: 'ಯೋಜನೆಯ ಸ್ಥಿತಿಯನ್ನು ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
        malayalam: 'പ്ലാൻ നില പരിശോധിക്കുന്നു...',
      );
    }
    final result = _backendResult;
    if (result == null) {
      return _t(
        telugu: 'స్థితి సమాచారం అందుబాటులో లేదు',
        english: 'Status information unavailable',
        hindi: 'स्थिति जानकारी उपलब्ध नहीं है',
        tamil: 'நிலை தகவல் கிடைக்கவில்லை',
        kannada: 'ಸ್ಥಿತಿ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ',
        malayalam: 'സ്ഥിതി വിവരങ്ങൾ ലഭ്യമല്ല',
      );
    }

    return switch (result.state) {
      SubscriptionBackendState.verifiedPro => _subscriptionStatusLabel(),
      SubscriptionBackendState.verifiedFree =>
        _isSubscriptionExpired
            ? _t(
                telugu: 'సబ్‌స్క్రిప్షన్ గడువు ముగిసింది',
                english: 'Subscription expired',
                hindi: 'सब्सक्रिप्शन समाप्त हो गया',
                tamil: 'சந்தா காலாவதியானது',
                kannada: 'ಚಂದಾದಾರಿಕೆ ಅವಧಿ ಮುಗಿದಿದೆ',
                malayalam: 'സബ്സ്ക്രിപ്ഷൻ കാലഹരണപ്പെട്ടു',
              )
            : _t(
                telugu: 'సబ్‌స్క్రిప్షన్ యాక్టివ్‌లో లేదు',
                english: 'Subscription is not active',
                hindi: 'सब्सक्रिप्शन सक्रिय नहीं है',
                tamil: 'சந்தா செயலிலில்லை',
                kannada: 'ಚಂದಾದಾರಿಕೆ ಸಕ್ರಿಯವಾಗಿಲ್ಲ',
                malayalam: 'സബ്സ്ക്രിപ്ഷൻ സജീവമല്ല',
              ),
      SubscriptionBackendState.notConfigured => _t(
        telugu: 'ప్లాన్ సమాచారం మోడ్',
        english: 'Plan info mode',
        hindi: 'प्लान जानकारी मोड',
        tamil: 'திட்ட தகவல் நிலை',
        kannada: 'ಯೋಜನೆ ಮಾಹಿತಿ ಮೋಡ್',
        malayalam: 'പ്ലാൻ വിവര മോഡ്',
      ),
      SubscriptionBackendState.failed => _t(
        telugu: 'స్థితి చెక్ విఫలమైంది',
        english: 'Status check failed',
        hindi: 'स्थिति जांच विफल हुई',
        tamil: 'நிலை சரிபார்ப்பு தோல்வியடைந்தது',
        kannada: 'ಸ್ಥಿತಿ ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
        malayalam: 'സ്ഥിതി പരിശോധന പരാജയപ്പെട്ടു',
      ),
    };
  }

  String _subscriptionStatusLabel() {
    if (_isSubscriptionActive) {
      return _t(
        telugu: 'యాక్టివ్',
        english: 'Active',
        hindi: 'सक्रिय',
        tamil: 'செயலில்',
        kannada: 'ಸಕ್ರಿಯ',
        malayalam: 'സജീവം',
      );
    }
    if (_isSubscriptionExpired) {
      final expiry = _backendResult?.expiryTime;
      final formatted = expiry == null ? null : _formatDate(expiry);
      return _t(
        telugu: formatted == null
            ? 'గడువు ముగిసింది'
            : 'గడువు ముగిసిన తేదీ: $formatted',
        english: formatted == null ? 'Expired' : 'Expired on: $formatted',
        hindi: formatted == null ? 'समाप्त' : 'समाप्ति तिथि: $formatted',
        tamil: formatted == null ? 'காலாவதி' : 'காலாவதியான தேதி: $formatted',
        kannada: formatted == null
            ? 'ಅವಧಿ ಮುಗಿದಿದೆ'
            : 'ಅವಧಿ ಮುಗಿದ ದಿನಾಂಕ: $formatted',
        malayalam: formatted == null
            ? 'കാലാവധി കഴിഞ്ഞു'
            : 'കാലാവധി കഴിഞ്ഞ തീയതി: $formatted',
      );
    }
    return _t(
      telugu: 'యాక్టివ్‌లో లేదు',
      english: 'Not active',
      hindi: 'सक्रिय नहीं',
      tamil: 'செயலில் இல்லை',
      kannada: 'ಸಕ್ರಿಯವಿಲ್ಲ',
      malayalam: 'സജീവമല്ല',
    );
  }

  String? _subscriptionStartLine() {
    final startDate = _backendResult?.startDate;
    if (startDate == null) {
      return null;
    }
    final formatted = _formatDate(startDate);
    return _t(
      telugu: 'సబ్‌స్క్రైబ్ చేసిన తేదీ: $formatted',
      english: 'Subscribed on: $formatted',
      hindi: 'सदस्यता शुरू हुई: $formatted',
      tamil: 'சந்தா தொடங்கிய தேதி: $formatted',
      kannada: 'ಚಂದಾದಾರಿಕೆ ಆರಂಭವಾದ ದಿನಾಂಕ: $formatted',
      malayalam: 'സബ്സ്ക്രൈബ് ചെയ്ത തീയതി: $formatted',
    );
  }

  String? _subscriptionExpiryLine() {
    final expiryDate = _backendResult?.expiryTime;
    if (expiryDate == null) {
      return null;
    }
    final bool showNextPaymentDate =
        _isSubscriptionActive && (_backendResult?.autoRenewing == true);
    final DateTime displayDate = showNextPaymentDate
        ? (_stableDisplayRenewalDate() ?? expiryDate)
        : expiryDate;
    final formatted = _formatDate(displayDate);
    if (showNextPaymentDate) {
      return _t(
        telugu: 'తదుపరి చెల్లింపు తేదీ: $formatted',
        english: 'Next payment date: $formatted',
        hindi: 'अगली भुगतान तिथि: $formatted',
        tamil: 'அடுத்த கட்டண தேதி: $formatted',
        kannada: 'ಮುಂದಿನ ಪಾವತಿ ದಿನಾಂಕ: $formatted',
        malayalam: 'അടുത്ത പേയ്മെന്റ് തീയതി: $formatted',
      );
    }
    return _t(
      telugu: 'గడువు ముగిసే తేదీ: $formatted',
      english: 'Expires on: $formatted',
      hindi: 'समाप्ति तिथि: $formatted',
      tamil: 'காலாவதி தேதி: $formatted',
      kannada: 'ಅವಧಿ ಮುಗಿಯುವ ದಿನಾಂಕ: $formatted',
      malayalam: 'കാലാവധി തീരുന്ന തീയതി: $formatted',
    );
  }

  DateTime? _stableDisplayRenewalDate() {
    final result = _backendResult;
    if (result == null) {
      return null;
    }
    if (!_isSubscriptionActive || result.autoRenewing != true) {
      return null;
    }
    final normalizedProductId = result.productId?.trim();
    if (normalizedProductId == null ||
        !_productIdsToQuery.contains(normalizedProductId)) {
      return null;
    }
    final startDate = result.startDate;
    if (startDate == null) {
      return null;
    }
    return _addCalendarMonth(startDate);
  }

  DateTime _addCalendarMonth(DateTime value) {
    final year = value.year + (value.month == DateTime.december ? 1 : 0);
    final month = value.month == DateTime.december ? 1 : value.month + 1;
    final day = value.day.clamp(1, _daysInMonth(year, month));
    return DateTime(
      year,
      month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  int _daysInMonth(int year, int month) {
    if (month == DateTime.december) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  Color get _statusColor {
    if (_isSubscriptionActive) {
      return const Color(0xFF15803D);
    }
    if (_isSubscriptionExpired) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF64748B);
  }

  Color get _statusBackgroundColor {
    if (_isSubscriptionActive) {
      return const Color(0xFFF0FDF4);
    }
    if (_isSubscriptionExpired) {
      return const Color(0xFFFFFBEB);
    }
    return const Color(0xFFF8FAFC);
  }

  Color get _statusBorderColor {
    if (_isSubscriptionActive) {
      return const Color(0xFF86EFAC);
    }
    if (_isSubscriptionExpired) {
      return const Color(0xFFFCD34D);
    }
    return const Color(0xFFE2E8F0);
  }

  String _formatDate(DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }

  String _t({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
  }) {
    if (_isEditorPlan) {
      return english;
    }
    return _strings.localized(
      telugu: telugu,
      english: english,
      hindi: hindi,
      tamil: tamil,
      kannada: kannada,
      malayalam: malayalam,
    );
  }

  String get _monthlyPriceLabel {
    final price = _selectedProduct?.price.trim() ?? '';
    return price.isNotEmpty ? price : _monthlyFallbackPrice;
  }

  String get _trialPriceLabel => SubscriptionPlanConfig.trialPriceDisplay;

  int get _trialDays => SubscriptionPlanConfig.trialDays;

  String get _trialOfferBody => _t(
    telugu:
        'ఈ ప్లాన్ రూ.4 తో 3 రోజుల ట్రయల్‌గా ప్రారంభమవుతుంది. ఈ సమయంలో మీరు రద్దు చేయవచ్చు.',
    english:
        'The plan starts with a $_trialPriceLabel trial for $_trialDays days. You can cancel within this period.',
    hindi:
        'यह प्लान 3 दिनों के लिए Rs.4 ट्रायल से शुरू होता है। इस अवधि में आप रद्द कर सकते हैं।',
    tamil:
        'இந்த திட்டம் Rs.4 க்கு 3 நாள் சோதனையாக தொடங்கும். இந்த காலத்தில் நீங்கள் ரத்து செய்யலாம்.',
    kannada:
        'ಈ ಯೋಜನೆ Rs.4 ಗೆ 3 ದಿನಗಳ ಟ್ರಯಲ್‌ನೊಂದಿಗೆ ಆರಂಭವಾಗುತ್ತದೆ. ಈ ಅವಧಿಯಲ್ಲಿ ನೀವು ರದ್ದುಗೊಳಿಸಬಹುದು.',
    malayalam:
        'ഈ പ്ലാൻ Rs.4യ്ക്ക് 3 ദിവസത്തെ ട്രയലായി തുടങ്ങുന്നു. ഈ സമയത്ത് നിങ്ങൾക്ക് റദ്ദാക്കാം.',
  );

  String get _alreadyActiveLabel => _t(
    telugu: 'ఇప్పటికే యాక్టివ్',
    english: 'Already Active',
    hindi: 'पहले से सक्रिय',
    tamil: 'ஏற்கனவே செயலில் உள்ளது',
    kannada: 'ಈಗಾಗಲೇ ಸಕ್ರಿಯವಾಗಿದೆ',
    malayalam: 'ഇതിനകം ആക്റ്റീവാണ്',
  );

  String get _appPlanDetailsTitle => _t(
    telugu: 'మీ ప్లాన్ వివరాలు',
    english: 'Your plan details',
    hindi: 'आपके प्लान विवरण',
    tamil: 'உங்கள் திட்ட விவரங்கள்',
    kannada: 'ನಿಮ್ಮ ಯೋಜನೆಯ ವಿವರಗಳು',
    malayalam: 'നിങ്ങളുടെ പ്ലാൻ വിവരങ്ങൾ',
  );

  String get _subscribeAppProLabel => _t(
    telugu: 'App Pro సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe App Pro',
    hindi: 'App Pro सब्सक्राइब करें',
    tamil: 'App Pro சந்தா எடுக்கவும்',
    kannada: 'App Pro ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'App Pro സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
  );

  String get _allAccessYearlyTitle => _t(
    telugu: 'All Access వార్షిక ప్లాన్',
    english: 'All Access Yearly',
    hindi: 'All Access वार्षिक',
    tamil: 'All Access ஆண்டு திட்டம்',
    kannada: 'All Access ವಾರ್ಷಿಕ',
    malayalam: 'All Access വാർഷികം',
  );

  String get _allAccessTitle => _t(
    telugu: 'All Access',
    english: 'All Access',
    hindi: 'All Access',
    tamil: 'All Access',
    kannada: 'All Access',
    malayalam: 'All Access',
  );

  String get _appEditorTogetherSubtitle => _t(
    telugu: 'App Pro + Editor Pro కలిపి',
    english: 'App Pro + Editor Pro together',
    hindi: 'App Pro + Editor Pro साथ में',
    tamil: 'App Pro + Editor Pro ஒன்றாக',
    kannada: 'App Pro + Editor Pro ಒಟ್ಟಿಗೆ',
    malayalam: 'App Pro + Editor Pro ഒരുമിച്ച്',
  );

  String get _allAccessBundleSubtitle => _t(
    telugu: 'App Pro + Editor Pro బండిల్',
    english: 'App Pro + Editor Pro bundle',
    hindi: 'App Pro + Editor Pro बंडल',
    tamil: 'App Pro + Editor Pro பண்டில்',
    kannada: 'App Pro + Editor Pro ಬಂಡಲ್',
    malayalam: 'App Pro + Editor Pro ബണ്ടിൽ',
  );

  String get _yearlyPriceLabel =>
      '${EditorSubscriptionPlanConfig.yearlyPriceDisplay} / ${_t(telugu: 'సంవత్సరం', english: 'year', hindi: 'वर्ष', tamil: 'ஆண்டு', kannada: 'ವರ್ಷ', malayalam: 'വർഷം')}';

  String get _editorMonthlyPriceLabel =>
      '${EditorSubscriptionPlanConfig.monthlyPriceDisplay} / ${_t(telugu: 'నెల', english: 'month', hindi: 'माह', tamil: 'மாதம்', kannada: 'ತಿಂಗಳು', malayalam: 'മാസം')}';

  String get _subscribeYearlyLabel => _t(
    telugu: 'వార్షికంగా సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe Yearly',
    hindi: 'वार्षिक सब्सक्राइब करें',
    tamil: 'ஆண்டு சந்தா எடுக்கவும்',
    kannada: 'ವಾರ್ಷಿಕವಾಗಿ ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'വാർഷികമായി സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
  );

  String get _editorProTitle => _t(
    telugu: 'Editor Pro',
    english: 'Editor Pro',
    hindi: 'Editor Pro',
    tamil: 'Editor Pro',
    kannada: 'Editor Pro',
    malayalam: 'Editor Pro',
  );

  String get _editorOnlySubtitle => _t(
    telugu: 'ఎడిటర్ ప్రీమియం టూల్స్ మాత్రమే',
    english: 'Only editor premium tools',
    hindi: 'केवल एडिटर प्रीमियम टूल्स',
    tamil: 'எடிட்டர் பிரீமியம் கருவிகள் மட்டும்',
    kannada: 'ಎಡಿಟರ್ ಪ್ರೀಮಿಯಂ ಟೂಲ್‌ಗಳು ಮಾತ್ರ',
    malayalam: 'എഡിറ്റർ പ്രീമിയം ടൂളുകൾ മാത്രം',
  );

  String get _premiumAssetsLabel => _t(
    telugu: 'ప్రీమియం Assets',
    english: 'Premium Assets',
    hindi: 'प्रीमियम Assets',
    tamil: 'பிரீமியம் Assets',
    kannada: 'ಪ್ರೀಮಿಯಂ Assets',
    malayalam: 'പ്രീമിയം Assets',
  );

  String get _teluguLegacyFontsLabel => _t(
    telugu: 'తెలుగు లెగసీ ఫాంట్స్',
    english: 'Telugu legacy fonts',
    hindi: 'तेलुगु लेगेसी फॉन्ट्स',
    tamil: 'தெலுங்கு லெகசி எழுத்துருக்கள்',
    kannada: 'ತೆಲುಗು ಲೆಗಸಿ ಫಾಂಟ್‌ಗಳು',
    malayalam: 'తెలുങ്ക് ലെഗസി ഫോണ്ടുകൾ',
  );

  String get _removeBgToolLabel => _t(
    telugu: 'Remove BG టూల్',
    english: 'Remove BG tool',
    hindi: 'Remove BG टूल',
    tamil: 'Remove BG கருவி',
    kannada: 'Remove BG ಟೂಲ್',
    malayalam: 'Remove BG ടൂൾ',
  );

  String get _doesNotIncludeAppProLabel => _t(
    telugu: 'App Pro సబ్‌స్క్రిప్షన్ ఇందులో ఉండదు',
    english: 'Does not include App Pro subscription',
    hindi: 'इसमें App Pro सब्सक्रिप्शन शामिल नहीं है',
    tamil: 'இதில் App Pro சந்தா இல்லை',
    kannada: 'ಇದು App Pro ಚಂದಾದಾರಿಕೆಯನ್ನು ಒಳಗೊಂಡಿಲ್ಲ',
    malayalam: 'ഇതിൽ App Pro സബ്‌സ്‌ക്രിപ്ഷൻ ഉൾപ്പെടില്ല',
  );

  String get _subscribeEditorProLabel => _t(
    telugu: 'Editor Pro సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe Editor Pro',
    hindi: 'Editor Pro सब्सक्राइब करें',
    tamil: 'Editor Pro சந்தா எடுக்கவும்',
    kannada: 'Editor Pro ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'Editor Pro സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
  );

  String get _includesAppProFeaturesLabel => _t(
    telugu: 'App Pro ఫీచర్స్ ఉంటాయి',
    english: 'Includes App Pro features',
    hindi: 'App Pro फीचर्स शामिल हैं',
    tamil: 'App Pro அம்சங்கள் அடங்கும்',
    kannada: 'App Pro ವೈಶಿಷ್ಟ್ಯಗಳು ಒಳಗೊಂಡಿವೆ',
    malayalam: 'App Pro ഫീച്ചറുകൾ ഉൾപ്പെടും',
  );

  String get _includesEditorProToolsLabel => _t(
    telugu: 'అన్ని Editor Pro టూల్స్ ఉంటాయి',
    english: 'Includes all Editor Pro tools',
    hindi: 'सभी Editor Pro टूल्स शामिल हैं',
    tamil: 'அனைத்து Editor Pro கருவிகளும் அடங்கும்',
    kannada: 'ಎಲ್ಲಾ Editor Pro ಟೂಲ್‌ಗಳು ಒಳಗೊಂಡಿವೆ',
    malayalam: 'എല്ലാ Editor Pro ടൂളുകളും ഉൾപ്പെടും',
  );

  String get _yearlyAutoRenewingBundleLabel => _t(
    telugu: 'ఒకే వార్షిక auto-renewing బండిల్ ప్లాన్',
    english: 'One yearly auto-renewing bundle plan',
    hindi: 'एक वार्षिक auto-renewing बंडल प्लान',
    tamil: 'ஒரு ஆண்டு auto-renewing பண்டில் திட்டம்',
    kannada: 'ಒಂದು ವಾರ್ಷಿಕ auto-renewing ಬಂಡಲ್ ಯೋಜನೆ',
    malayalam: 'ഒരു വാർഷിക auto-renewing ബണ്ടിൽ പ്ലാൻ',
  );

  String get _yearlyAutoRenewingPlanLabel => _t(
    telugu: 'ఒకే వార్షిక auto-renewing ప్లాన్',
    english: 'One yearly auto-renewing plan',
    hindi: 'एक वार्षिक auto-renewing प्लान',
    tamil: 'ஒரு ஆண்டு auto-renewing திட்டம்',
    kannada: 'ಒಂದು ವಾರ್ಷಿಕ auto-renewing ಯೋಜನೆ',
    malayalam: 'ഒരു വാർഷിക auto-renewing പ്ലാൻ',
  );

  String get _includesPosterAccessLabel => _t(
    telugu: 'పోస్టర్ share/download access ఉంటుంది',
    english: 'Includes poster share and download access',
    hindi: 'पोस्टर शेयर और डाउनलोड access शामिल है',
    tamil: 'போஸ்டர் பகிர்வு மற்றும் பதிவிறக்க access அடங்கும்',
    kannada: 'ಪೋಸ್ಟರ್ share ಮತ್ತು download access ಒಳಗೊಂಡಿದೆ',
    malayalam: 'പോസ്റ്റർ share/download access ഉൾപ്പെടും',
  );

  String get _includesEditorPremiumLabel => _t(
    telugu: 'ప్రీమియం editor assets, Telugu fonts, Remove BG ఉంటాయి',
    english: 'Includes premium editor assets, Telugu fonts, and Remove BG',
    hindi: 'प्रीमियम editor assets, Telugu fonts और Remove BG शामिल हैं',
    tamil: 'பிரீமியம் editor assets, Telugu fonts மற்றும் Remove BG அடங்கும்',
    kannada: 'ಪ್ರೀಮಿಯಂ editor assets, Telugu fonts ಮತ್ತು Remove BG ಒಳಗೊಂಡಿವೆ',
    malayalam: 'പ്രീമിയം editor assets, Telugu fonts, Remove BG ഉൾപ്പെടും',
  );

  String get _bestForBothLabel => _t(
    telugu: 'Home posters మరియు editor tools రెండూ వాడితే best option',
    english: 'Best option if you use both home posters and editor tools',
    hindi:
        'Home posters और editor tools दोनों उपयोग करने वालों के लिए best option',
    tamil:
        'Home posters மற்றும் editor tools இரண்டும் பயன்படுத்தினால் சிறந்த தேர்வு',
    kannada: 'Home posters ಮತ್ತು editor tools ಎರಡನ್ನೂ ಬಳಸಿದರೆ ಉತ್ತಮ ಆಯ್ಕೆ',
    malayalam:
        'Home posters, editor tools രണ്ടും ഉപയോഗിക്കുന്നവർക്ക് മികച്ച ഓപ്ഷൻ',
  );

  String get _bestValueForBothLabel => _t(
    telugu: 'రెండూ అవసరమైన users కి best value',
    english: 'Best value for users who need both',
    hindi: 'दोनों चाहिए वाले users के लिए best value',
    tamil: 'இரண்டும் தேவைப்படும் users க்கு best value',
    kannada: 'ಎರಡೂ ಬೇಕಾದ users ಗೆ best value',
    malayalam: 'രണ്ടും ആവശ്യമായ users ന് best value',
  );

  String get _subscribeAllAccessLabel => _t(
    telugu: 'All Access సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe All Access',
    hindi: 'All Access सब्सक्राइब करें',
    tamil: 'All Access சந்தா எடுக்கவும்',
    kannada: 'All Access ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'All Access സബ്‌സ്‌ക്രൈബ് ചെയ്യുക',
  );

  String get _editorPlanHeroSubtitle => _t(
    telugu:
        'Editor Pro monthly లేదా app + editor కోసం All Access yearly ఎంచుకోండి.',
    english:
        'Choose Editor Pro monthly, or All Access yearly for app + editor together.',
    hindi:
        'Editor Pro monthly चुनें या app + editor के लिए All Access yearly लें।',
    tamil:
        'Editor Pro monthly அல்லது app + editor க்கு All Access yearly தேர்வு செய்யவும்.',
    kannada:
        'Editor Pro monthly ಅಥವಾ app + editor ಗಾಗಿ All Access yearly ಆಯ್ಕೆಮಾಡಿ.',
    malayalam:
        'Editor Pro monthly അല്ലെങ്കിൽ app + editor നായി All Access yearly തിരഞ്ഞെടുക്കുക.',
  );

  String get _billingNoticeText {
    if (_isEditorPlan) {
      return _t(
        telugu:
            'Editor Pro నెలకు ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}. All Access సంవత్సరానికి ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} తో App Pro + Editor Pro రెండూ ఉంటాయి. Subscription auto-renew అవుతుంది; Play Store లో ఎప్పుడైనా cancel చేయవచ్చు.',
        english:
            'Editor Pro is ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} per month. All Access is ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} per year and includes both App Pro and Editor Pro. Subscriptions auto-renew and can be cancelled anytime in the Play Store.',
        hindi:
            'Editor Pro ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} प्रति माह है। All Access ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} प्रति वर्ष है और इसमें App Pro + Editor Pro दोनों शामिल हैं। Subscription auto-renew होता है और Play Store में कभी भी cancel किया जा सकता है।',
        tamil:
            'Editor Pro மாதம் ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}. All Access ஆண்டு ${EditorSubscriptionPlanConfig.yearlyPriceDisplay}; இதில் App Pro + Editor Pro இரண்டும் அடங்கும். Subscription auto-renew ஆகும்; Play Store-ல் எப்போது வேண்டுமானாலும் cancel செய்யலாம்.',
        kannada:
            'Editor Pro ತಿಂಗಳಿಗೆ ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}. All Access ವರ್ಷಕ್ಕೆ ${EditorSubscriptionPlanConfig.yearlyPriceDisplay}; ಇದರಲ್ಲಿ App Pro + Editor Pro ಎರಡೂ ಒಳಗೊಂಡಿವೆ. Subscription auto-renew ಆಗುತ್ತದೆ; Play Store ನಲ್ಲಿ ಯಾವಾಗ ಬೇಕಾದರೂ cancel ಮಾಡಬಹುದು.',
        malayalam:
            'Editor Pro മാസം ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}. All Access വർഷം ${EditorSubscriptionPlanConfig.yearlyPriceDisplay}; App Pro + Editor Pro രണ്ടും ഉൾപ്പെടും. Subscription auto-renew ചെയ്യും; Play Store-ൽ എപ്പോൾ വേണമെങ്കിലും cancel ചെയ്യാം.',
      );
    }
    return _t(
      telugu:
          'App Pro ${SubscriptionPlanConfig.trialPriceDisplay} తో ${SubscriptionPlanConfig.trialDays} రోజుల trial గా ప్రారంభమవుతుంది. Trial తర్వాత నెలకు $_monthlyPriceLabel తో auto-renew అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజుల్లో cancel చేస్తే నెలసరి ఛార్జ్ వర్తించదు.',
      english:
          'App Pro starts with a ${SubscriptionPlanConfig.trialPriceDisplay} trial for ${SubscriptionPlanConfig.trialDays} days. After the trial, it auto-renews at $_monthlyPriceLabel per month. Cancel within ${SubscriptionPlanConfig.trialDays} days to avoid the monthly charge.',
      hindi:
          'App Pro ${SubscriptionPlanConfig.trialPriceDisplay} में ${SubscriptionPlanConfig.trialDays} दिनों के trial से शुरू होता है। Trial के बाद यह $_monthlyPriceLabel प्रति माह auto-renew होता है। मासिक शुल्क से बचने के लिए ${SubscriptionPlanConfig.trialDays} दिनों में cancel करें।',
      tamil:
          'App Pro ${SubscriptionPlanConfig.trialPriceDisplay}க்கு ${SubscriptionPlanConfig.trialDays} நாள் trial ஆக தொடங்கும். Trialக்கு பிறகு மாதம் $_monthlyPriceLabel auto-renew ஆகும். மாத கட்டணத்தை தவிர்க்க ${SubscriptionPlanConfig.trialDays} நாட்களில் cancel செய்யவும்.',
      kannada:
          'App Pro ${SubscriptionPlanConfig.trialPriceDisplay} ಗೆ ${SubscriptionPlanConfig.trialDays} ದಿನಗಳ trial ಆಗಿ ಆರಂಭವಾಗುತ್ತದೆ. Trial ನಂತರ ತಿಂಗಳಿಗೆ $_monthlyPriceLabel auto-renew ಆಗುತ್ತದೆ. ಮಾಸಿಕ ಶುಲ್ಕ ತಪ್ಪಿಸಲು ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಲ್ಲಿ cancel ಮಾಡಿ.',
      malayalam:
          'App Pro ${SubscriptionPlanConfig.trialPriceDisplay}യ്ക്ക് ${SubscriptionPlanConfig.trialDays} ദിവസത്തെ trial ആയി തുടങ്ങും. Trial കഴിഞ്ഞാൽ മാസം $_monthlyPriceLabel auto-renew ചെയ്യും. മാസചാർജ് ഒഴിവാക്കാൻ ${SubscriptionPlanConfig.trialDays} ദിവസത്തിനുള്ളിൽ cancel ചെയ്യുക.',
    );
  }

  List<Widget> _buildPlanCards(List<String> appPlanDetails) {
    if (!_isEditorPlan) {
      return <Widget>[
        _PlanSection(
          title: _appPlanDetailsTitle,
          details: appPlanDetails,
          monthlyPrice: _monthlyFallbackPrice,
          buttonLabel: _isSubscriptionActive
              ? _alreadyActiveLabel
              : _subscribeAppProLabel,
          onTap: () => unawaited(_subscribeFreePlan()),
          busy: _busyFree,
          accent: const Color(0xFF1D4ED8),
          enabled: _canSubscribe,
        ),
        const SizedBox(height: 14),
        _PlanChoiceCard(
          title: _allAccessYearlyTitle,
          subtitle: _appEditorTogetherSubtitle,
          price: _yearlyPriceLabel,
          details: <String>[
            _includesPosterAccessLabel,
            _includesEditorPremiumLabel,
            _yearlyAutoRenewingBundleLabel,
            _bestForBothLabel,
          ],
          buttonLabel: _isSubscriptionActive
              ? _alreadyActiveLabel
              : _subscribeYearlyLabel,
          busy: _busyFree,
          enabled: _canSubscribe,
          accent: const Color(0xFF9333EA),
          onTap: () => unawaited(
            _subscribeFreePlan(
              editorBasePlanId: EditorSubscriptionPlanConfig.yearlyBasePlanId,
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      _PlanChoiceCard(
        title: _editorProTitle,
        subtitle: _editorOnlySubtitle,
        price: _editorMonthlyPriceLabel,
        details: <String>[
          _premiumAssetsLabel,
          _teluguLegacyFontsLabel,
          _removeBgToolLabel,
          _doesNotIncludeAppProLabel,
        ],
        buttonLabel: _isSubscriptionActive
            ? _alreadyActiveLabel
            : _subscribeEditorProLabel,
        busy: _busyFree,
        enabled: _canSubscribe,
        accent: const Color(0xFF1D4ED8),
        onTap: () => unawaited(_subscribeFreePlan()),
      ),
      const SizedBox(height: 14),
      _PlanChoiceCard(
        title: _allAccessTitle,
        subtitle: _allAccessBundleSubtitle,
        price: _yearlyPriceLabel,
        details: <String>[
          _includesAppProFeaturesLabel,
          _includesEditorProToolsLabel,
          _yearlyAutoRenewingPlanLabel,
          _bestValueForBothLabel,
        ],
        buttonLabel: _isSubscriptionActive
            ? _alreadyActiveLabel
            : _subscribeAllAccessLabel,
        busy: _busyFree,
        enabled: _canSubscribe,
        accent: const Color(0xFF9333EA),
        onTap: () => unawaited(
          _subscribeFreePlan(
            editorBasePlanId: EditorSubscriptionPlanConfig.yearlyBasePlanId,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isEditorPlan = _isEditorPlan;
    final pageBackground = isEditorPlan
        ? const Color(0xFF070A12)
        : Colors.white;
    final titleColor = isEditorPlan ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isEditorPlan
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);
    final appBarForeground = isEditorPlan
        ? Colors.white
        : const Color(0xFF0F172A);
    final List<String> planDetails = <String>[
      _trialOfferBody,
      _t(
        telugu: 'పోస్టర్ share/download ఫీచర్స్ అన్‌లాక్ అవుతాయి.',
        english: 'Unlock poster share and download features.',
        hindi: 'पोस्टर share/download फीचर्स अनलॉक होते हैं।',
        tamil: 'போஸ்டர் share/download அம்சங்கள் திறக்கும்.',
        kannada: 'ಪೋಸ್ಟರ್ share/download ವೈಶಿಷ್ಟ್ಯಗಳು unlock ಆಗುತ್ತವೆ.',
        malayalam: 'പോസ്റ്റർ share/download ഫീച്ചറുകൾ unlock ചെയ്യും.',
      ),
      _t(
        telugu:
            '3 రోజుల తర్వాత ప్లాన్ $_monthlyPriceLabel నెలసరి ధరతో ఆటో రిన్యువల్ అవుతుంది',
        english:
            'After 3 days, the active plan becomes $_monthlyPriceLabel per month (auto-renewal)',
        hindi:
            '3 दिनों के बाद प्लान $_monthlyPriceLabel प्रति माह पर ऑटो-रिन्यू होगा',
        tamil:
            '3 நாட்களுக்கு பிறகு திட்டம் $_monthlyPriceLabel மாதாந்திர கட்டணத்தில் தானாக புதுப்பிக்கும்',
        kannada:
            '3 ದಿನಗಳ ನಂತರ ಯೋಜನೆ $_monthlyPriceLabel ಪ್ರತಿ ತಿಂಗಳು ಸ್ವಯಂ ನವೀಕರಿಸುತ್ತದೆ',
        malayalam:
            '3 ദിവസങ്ങൾക്ക് ശേഷം പ്ലാൻ $_monthlyPriceLabel മാസംതോറും ഓട്ടോ റിന്യൂവാകും',
      ),
      _t(
        telugu: 'నెలసరి ఛార్జ్ రాకుండా 3 రోజుల్లో cancel చేయవచ్చు.',
        english: 'Cancel within 3 days to avoid the monthly charge.',
        hindi: 'मासिक शुल्क से बचने के लिए 3 दिनों में cancel कर सकते हैं।',
        tamil: 'மாத கட்டணத்தை தவிர்க்க 3 நாட்களில் cancel செய்யலாம்.',
        kannada: 'ಮಾಸಿಕ ಶುಲ್ಕ ತಪ್ಪಿಸಲು 3 ದಿನಗಳಲ್ಲಿ cancel ಮಾಡಬಹುದು.',
        malayalam: 'മാസചാർജ് ഒഴിവാക്കാൻ 3 ദിവസത്തിനുള്ളിൽ cancel ചെയ്യാം.',
      ),
      _t(
        telugu: 'ఈ ప్లాన్‌లో premium editor assets లేదా Telugu fonts ఉండవు.',
        english:
            'This plan does not include premium editor assets or Telugu fonts.',
        hindi:
            'इस प्लान में premium editor assets या Telugu fonts शामिल नहीं हैं।',
        tamil:
            'இந்த திட்டத்தில் premium editor assets அல்லது Telugu fonts இல்லை.',
        kannada: 'ಈ ಯೋಜನೆಯಲ್ಲಿ premium editor assets ಅಥವಾ Telugu fonts ಇಲ್ಲ.',
        malayalam:
            'ഈ പ്ലാനിൽ premium editor assets അല്ലെങ്കിൽ Telugu fonts ഇല്ല.',
      ),
    ];
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: appBarForeground),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            children: <Widget>[
              if (isEditorPlan) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF151A2E), Color(0xFF0B1020)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFFACC15),
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Premium editor tools for every design',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                _isEditorPlan
                    ? _editorProTitle
                    : _t(
                        telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్',
                        english: 'Subscription Plan',
                        hindi: 'सब्सक्रिप्शन प्लान',
                        tamil: 'சந்தா திட்டம்',
                        kannada: 'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ',
                        malayalam: 'സബ്സ്ക്രിപ്ഷൻ പ്ലാൻ',
                      ),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ).copyWith(color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditorPlan
                    ? _editorPlanHeroSubtitle
                    : _t(
                        telugu:
                            'రూ.4 trial తో మొదలుపెట్టి poster share/download unlock చేయండి.',
                        english:
                            'Start with a $_trialPriceLabel trial and unlock poster sharing and downloads.',
                        hindi:
                            '$_trialPriceLabel trial से शुरू करें और poster share/download unlock करें।',
                        tamil:
                            '$_trialPriceLabel trial மூலம் தொடங்கி poster share/download unlock செய்யவும்.',
                        kannada:
                            '$_trialPriceLabel trial ಮೂಲಕ ಪ್ರಾರಂಭಿಸಿ poster share/download unlock ಮಾಡಿ.',
                        malayalam:
                            '$_trialPriceLabel trial ഉപയോഗിച്ച് തുടങ്ങി poster share/download unlock ചെയ്യുക.',
                      ),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ).copyWith(color: subtitleColor),
              ),
              const SizedBox(height: 16),
              _SubscriptionStatusCard(
                label: _subscriptionStatusLabel(),
                helper: _statusLine(),
                startLine: _subscriptionStartLine(),
                expiryLine: _subscriptionExpiryLine(),
                statusColor: _statusColor,
                backgroundColor: _statusBackgroundColor,
                borderColor: _statusBorderColor,
              ),
              const SizedBox(height: 14),
              ..._buildPlanCards(planDetails),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.restore_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t(
                          telugu:
                              'Purchase చేసిన plan కనిపించకపోతే restore చేయండి.',
                          english:
                              'Restore if a purchased plan is not showing.',
                          hindi: 'खरीदा हुआ plan नहीं दिखे तो restore करें।',
                          tamil:
                              'வாங்கிய plan தெரியவில்லை என்றால் restore செய்யவும்.',
                          kannada: 'ಖರೀದಿಸಿದ plan ಕಾಣಿಸದಿದ್ದರೆ restore ಮಾಡಿ.',
                          malayalam:
                              'വാങ്ങിയ plan കാണുന്നില്ലെങ്കിൽ restore ചെയ്യുക.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busyRestore ? null : _restoreSubscriptions,
                      child: _busyRestore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _t(
                                telugu: 'Restore',
                                english: 'Restore',
                                hindi: 'Restore',
                                tamil: 'Restore',
                                kannada: 'Restore',
                                malayalam: 'Restore',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _billingNoticeText,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  const _SubscriptionStatusCard({
    required this.label,
    required this.helper,
    required this.startLine,
    required this.expiryLine,
    required this.statusColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final String helper;
  final String? startLine;
  final String? expiryLine;
  final Color statusColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                helper,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (startLine case final line?) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              line,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (expiryLine case final line?) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              line,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.title,
    required this.details,
    required this.monthlyPrice,
    required this.buttonLabel,
    required this.onTap,
    required this.busy,
    required this.accent,
    required this.enabled,
  });

  final String title;
  final List<String> details;
  final String monthlyPrice;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool busy;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color bulletAccent = enabled ? accent : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                monthlyPrice,
                style: TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CompactPriceLine(
            title: context.strings.localized(
              telugu: 'ట్రయల్',
              english: 'Trial',
              hindi: 'ट्रायल',
              tamil: 'சோதனை',
              kannada: 'ಪ್ರಯೋಗ',
              malayalam: 'ട്രയൽ',
            ),
            value: SubscriptionPlanConfig.trialValueDisplay,
            accent: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: bulletAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: bulletAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _SubscriptionActionButton(
              label: buttonLabel,
              busy: busy,
              enabled: enabled,
              accent: accent,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChoiceCard extends StatelessWidget {
  const _PlanChoiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.details,
    required this.buttonLabel,
    required this.busy,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final List<String> details;
  final String buttonLabel;
  final bool busy;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bulletAccent = enabled ? accent : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white,
            accent.withValues(alpha: 0.045),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 21,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  price,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ...details.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: bulletAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: bulletAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _SubscriptionActionButton(
              label: buttonLabel,
              busy: busy,
              enabled: enabled,
              accent: accent,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionActionButton extends StatelessWidget {
  const _SubscriptionActionButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy || !enabled ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? accent : const Color(0xFFCBD5E1),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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
          : FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }
}

class _CompactPriceLine extends StatelessWidget {
  const _CompactPriceLine({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
