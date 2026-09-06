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
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/widgets/subscription_exit_video_prompt.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({
    super.key,
    this.triggerRestoreOnOpen = false,
    this.startPurchaseOnOpen = false,
  });

  final bool triggerRestoreOnOpen;
  final bool startPurchaseOnOpen;

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
  bool _busyYearly = false;
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

  bool get _isBusy => _loading || _busyFree || _busyYearly || _busyRestore;
  bool get _isSubscriptionActive => _backendResult?.hasAccess == true;
  bool get _isSubscriptionExpired => _backendResult?.isExpired == true;
  bool get _canSubscribe => !_isSubscriptionActive;
  AppStrings get _strings => AppStrings(_languageSnapshot);
  bool get _isEditorPlan => false;
  Set<String> get _productIdsToQuery =>
      SubscriptionPlanConfig.resolvedPremiumProductIds();
  String get _monthlyFallbackPrice =>
      SubscriptionPlanConfig.monthlyPriceDisplay;
  String get _yearlyFallbackPrice => SubscriptionPlanConfig.yearlyPriceDisplay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _languageSnapshot = context.currentLanguage;
  }

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _backendService = SubscriptionBackendService.app();
    _purchaseGateway = InAppPurchaseGateway();
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

  ProPurchaseGateway _purchaseGatewayForBasePlan() {
    return _purchaseGateway;
  }

  Future<void> _subscribeFreePlan() async {
    if (_isBusy || !_canSubscribe) {
      return;
    }
    final purchaseGateway = _purchaseGatewayForBasePlan();
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

  Future<void> _subscribeYearlyPlan() async {
    if (_isBusy || !_canSubscribe) {
      return;
    }
    await _purchaseGateway.initialize();
    if (!await _prepareForStoreFlow()) {
      return;
    }
    var shouldShowThanksPrompt = false;
    setState(() => _busyYearly = true);
    try {
      final outcome = await _purchaseGateway.purchaseYearlyPro();
      if (!mounted) {
        return;
      }
      final activated = await _finalizeOutcome(
        outcome,
        successMessage: _t(
          telugu: 'సంవత్సర ప్లాన్ యాక్టివ్ అయింది',
          english: 'Yearly plan activated',
          hindi: 'Yearly plan activated',
          tamil: 'Yearly plan activated',
          kannada: 'Yearly plan activated',
          malayalam: 'Yearly plan activated',
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
        setState(() => _busyYearly = false);
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
                ? '${_t(
                    telugu: 'వెరిఫికేషన్ విఫలమైంది',
                    english: 'Verification failed',
                    hindi: 'सत्यापन विफल हुआ',
                    tamil: 'சரிபார்ப்பு தோல்வியடைந்தது',
                    kannada: 'ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
                    malayalam: 'പരിശോധന പരാജയപ്പെട്ടു',
                    marathi: 'पडताळणी अयशस्वी झाली',
                    gujarati: 'ચકાસણી નિષ્ફળ રહી',
                    bengali: 'যাচাইকরণ ব্যর্থ হয়েছে',
                    punjabi: 'ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
                    odia: 'ଯାଞ୍ଚ ବିଫଳ ହେଲା',
                    assamese: 'যাচাইকৰণ ব্যৰ্থ হ\'ল',
                    konkani: 'पडताळणी अपेशी थारली',
                    nepali: 'प्रमाणीकरण असफल भयो',
                    meitei: 'Verification failed',
                    mizo: 'Enfiah theih loh',
                    kashmiri: 'تصدیق گٔیہ ناکام',
                    ladakhi: 'བདེན་དཔྱོད་ཕམ་སོང་།',
                  )}: ${verifyResult.message}'
                : _t(
                    telugu: 'సబ్‌స్క్రిప్షన్ వెరిఫికేషన్ విఫలమైంది',
                    english: 'Subscription verification failed',
                    hindi: 'सब्सक्रिप्शन सत्यापन विफल हुआ',
                    tamil: 'சந்தா சரிபார்ப்பு தோல்வியடைந்தது',
                    kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
                    malayalam: 'സബ്സ്ക്രിപ്ഷൻ പരിശോധന പരാജയപ്പെട്ടു',
                    marathi: 'सदस्यता पडताळणी अयशस्वी झाली',
                    gujarati: 'સબ્સ્ક્રિપ્શન ચકાસણી નિષ્ફળ રહી',
                    bengali: 'সাবস্ক্রিপশন যাচাইকরণ ব্যর্থ হয়েছে',
                    punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
                    odia: 'ସବସ୍କ୍ରିପସନ୍ ଯାଞ୍ଚ ବିଫଳ ହେଲା',
                    assamese: 'গ্ৰাহকভুক্তি পৰীক্ষা ব্যৰ্থ হ\'ল',
                    konkani: 'वर्गणी पडताळणी अपेशी थारली',
                    nepali: 'सदस्यता प्रमाणीकरण असफल भयो',
                    meitei: 'Subscription verification failed',
                    mizo: 'Subscription enfiah theih loh',
                    kashmiri: 'سبسکرپشن تصدیق گٔیہ ناکام',
                    ladakhi: 'མཁོ་སྤྲོད་བདེན་དཔྱོད་ཕམ་སོང་།',
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
    unawaited(NotificationService.updateSubscriptionTopicStatus(isPro: true));
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
        marathi: formatted == null ? 'कालबाह्य' : 'समाप्ती तारीख: $formatted',
        gujarati: formatted == null ? 'સમાપ્ત' : 'સમાપ્તિ તારીખ: $formatted',
        bengali: formatted == null ? 'মেয়াদ উত্তীর্ণ' : 'মেয়াদ শেষ: $formatted',
        punjabi: formatted == null ? 'ਮਿਆਦ ਪੁੱਗੀ' : 'ਮਿਆਦ ਪੁੱਗਣ ਦੀ ਮਿਤੀ: $formatted',
        odia: formatted == null ? 'ଅବଧି ସମାପ୍ତ' : 'ସମାପ୍ତି ତାରିଖ: $formatted',
        assamese: formatted == null ? 'ম্যাদ উকলিল' : 'ম্যাদ উকলি যোৱাৰ তাৰিখ: $formatted',
        konkani: formatted == null ? 'मुदत सोंपली' : 'मुदत सोंपपाची तारीख: $formatted',
        nepali: formatted == null ? 'समाप्त भयो' : 'समाप्ति मिति: $formatted',
        meitei: formatted == null ? 'Expired' : 'Expired on: $formatted',
        mizo: formatted == null ? 'Hun a ral' : 'Tawp ni: $formatted',
        kashmiri: formatted == null ? 'ختم' : 'ختم گژھنُک تاریخ: $formatted',
        ladakhi: formatted == null ? 'དུས་ཚོད་རྫོགས།' : 'དུས་ཚོད་རྫོགས་པའི་ཚེས་གྲངས: $formatted',
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
      marathi: 'सदस्यता घेतल्याची तारीख: $formatted',
      gujarati: 'સબ્સ્ક્રાઇબ તારીખ: $formatted',
      bengali: 'সাবস্ক্রিপশনের তারিখ: $formatted',
      punjabi: 'ਸਬਸਕ੍ਰਾਈਬ ਕਰਨ ਦੀ ਮਿਤੀ: $formatted',
      odia: 'ସବସ୍କ୍ରାଇବ୍ ତାରିଖ: $formatted',
      assamese: 'চাবস্ক্ৰাইব কৰা তাৰিখ: $formatted',
      konkani: 'वर्गणी सुरू जाल्ली तारीख: $formatted',
      nepali: 'सदस्यता लिएको मिति: $formatted',
      meitei: 'Subscribed on: $formatted',
      mizo: 'Ziak luh ni: $formatted',
      kashmiri: 'سبسکرائب کرنہٕ آمُت تاریخ: $formatted',
      ladakhi: 'མངགས་ཉོ་བྱས་པའི་ཚེས་གྲངས: $formatted',
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
        marathi: 'पुढील देयक तारीख: $formatted',
        gujarati: 'આગામી ચુકવણી તારીખ: $formatted',
        bengali: 'পরবর্তী অর্থপ্রদানের তারিখ: $formatted',
        punjabi: 'ਅਗਲੀ ਅਦਾਇਗੀ ਮਿਤੀ: $formatted',
        odia: 'ପରବର୍ତ୍ତୀ ପେମେଣ୍ଟ ତାରିଖ: $formatted',
        assamese: 'পৰৱৰ্তী পৰিশোধ তাৰিখ: $formatted',
        konkani: 'फुडल्या पेमेंटाची तारीख: $formatted',
        nepali: 'अर्को भुक्तानी मिति: $formatted',
        meitei: 'Next payment date: $formatted',
        mizo: 'Pawisa chawi leh hun: $formatted',
        kashmiri: 'بییِہ ادائیگی ہُنٛد تاریخ: $formatted',
        ladakhi: 'རྗེས་མའི་དངུལ་སྤྲོད་ཚེས་གྲངས: $formatted',
      );
    }
    return _t(
      telugu: 'గడువు ముగిసే తేదీ: $formatted',
      english: 'Expires on: $formatted',
      hindi: 'समाप्ति तिथि: $formatted',
      tamil: 'காலாவதி தேதி: $formatted',
      kannada: 'ಅವಧಿ ಮುಗಿಯುವ ದಿನಾಂಕ: $formatted',
      malayalam: 'കാലാവധി തീരുന്ന തീയതി: $formatted',
      marathi: 'समाप्ती तारीख: $formatted',
      gujarati: 'સમાપ્તિ તારીખ: $formatted',
      bengali: 'মেয়াদ শেষ হওয়ার তারিখ: $formatted',
      punjabi: 'ਮਿਆਦ ਪੁੱਗਣ ਦੀ ਮਿਤੀ: $formatted',
      odia: 'ସମାପ୍ତି ତାରିଖ: $formatted',
      assamese: 'ম্যাদ উকলি যোৱাৰ তাৰিখ: $formatted',
      konkani: 'मुदत सोंपपाची तारीख: $formatted',
      nepali: 'समाप्ति मिति: $formatted',
      meitei: 'Expires on: $formatted',
      mizo: 'Tawp ni: $formatted',
      kashmiri: 'ختم گژھنُک تاریخ: $formatted',
      ladakhi: 'དུས་ཚོད་རྫོགས་པའི་ཚེས་གྲངས: $formatted',
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

  static final Map<String, Map<AppLanguage, String>> _subDictionary = <String, Map<AppLanguage, String>>{
    'Subscription activated': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ యాక్టివ్ అయింది',
      AppLanguage.english: 'Subscription activated',
      AppLanguage.hindi: 'सब्सक्रिप्शन सक्रिय हो गया',
      AppLanguage.tamil: 'சந்தா செயல்படுத்தப்பட்டது',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆ ಸಕ್ರಿಯವಾಗಿದೆ',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ സജീവമായി',
      AppLanguage.marathi: 'सदस्यता सक्रिय झाली',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન સક્રિય થયું',
      AppLanguage.bengali: 'সাবস্ক্রিপশন সক্রিয় হয়েছে',
      AppLanguage.punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਕਿਰਿਆਸ਼ੀਲ ਹੋ ਗਈ',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ ହେଲା',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বন সক্ৰিয় হ’ল',
      AppLanguage.konkani: 'वर्गणी सुरू जाली',
      AppLanguage.nepali: 'सदस्यता सक्रिय भयो',
      AppLanguage.meitei: 'Subscription active oikhre',
      AppLanguage.mizo: 'Subscription a nung tawh',
      AppLanguage.kashmiri: 'سبسکرپشن گٔیہٕ چالوٗ',
      AppLanguage.ladakhi: 'མངགས་ཉོ་ནུས་ལྡན་དུ་གྱུར།',
    },
    'Yearly plan activated': <AppLanguage, String>{
      AppLanguage.telugu: 'సంవత్సర ప్లాన్ యాక్టివ్ అయింది',
      AppLanguage.english: 'Yearly plan activated',
      AppLanguage.hindi: 'वार्षिक प्लान सक्रिय हो गया',
      AppLanguage.tamil: 'வருடாந்திர திட்டம் செயல்படுத்தப்பட்டது',
      AppLanguage.kannada: 'ವಾರ್ಷಿಕ ಯೋಜನೆ ಸಕ್ರಿಯವಾಗಿದೆ',
      AppLanguage.malayalam: 'വാർഷിക പ്ലാൻ സജീവമായി',
      AppLanguage.marathi: 'वार्षिक प्लॅन सक्रिय झाला',
      AppLanguage.gujarati: 'વાર્ષિક પ્લાન સક્રિય થયો',
      AppLanguage.bengali: 'বার্ষিক প্ল্যান সক্রিয় হয়েছে',
      AppLanguage.punjabi: 'ਸਾਲਾਨਾ ਪਲਾਨ ਕਿਰਿਆਸ਼ੀਲ ਹੋ ਗਿਆ',
      AppLanguage.odia: 'ବାର୍ଷିକ ପ୍ଲାନ୍ ସକ୍ରିୟ ହେଲା',
      AppLanguage.assamese: 'বাৰ্ষিক প্লেন সক্ৰিয় হ’ল',
      AppLanguage.konkani: 'वर्सुकी प्लॅन सुरू जालो',
      AppLanguage.nepali: 'वार्षिक योजना सक्रिय भयो',
      AppLanguage.meitei: 'Yearly plan active oikhre',
      AppLanguage.mizo: 'Kum khat plan a nung tawh',
      AppLanguage.kashmiri: 'سالانہ پلان گوو چالوٗ',
      AppLanguage.ladakhi: 'ལོ་རེའི་འཆར་གཞི་ནུས་ལྡན་དུ་གྱུར།',
    },
    'An active plan was restored from the backend': <AppLanguage, String>{
      AppLanguage.telugu: 'బ్యాక్‌ఎండ్ నుంచి యాక్టివ్ ప్లాన్ రిస్టోర్ అయింది',
      AppLanguage.english: 'An active plan was restored from the backend',
      AppLanguage.hindi: 'बैकएंड से सक्रिय प्लान बहाल हो गया',
      AppLanguage.tamil: 'பின்தளத்திலிருந்து செயலிலுள்ள திட்டம் மீட்டெடுக்கப்பட்டது',
      AppLanguage.kannada: 'ಬ್ಯಾಕೆಂಡ್‌ನಿಂದ ಸಕ್ರಿಯ ಯೋಜನೆ ಮರುಸ್ಥಾಪನೆಯಾಯಿತು',
      AppLanguage.malayalam: 'ബാക്ക്എൻഡിൽ നിന്ന് സജീവ പ്ലാൻ പുനഃസ്ഥാപിച്ചു',
      AppLanguage.marathi: 'बॅकएंडवरून सक्रिय प्लॅन पुनर्संचयित केला',
      AppLanguage.gujarati: 'બેકએન્ડમાંથી સક્રિય પ્લાન પુનઃસ્થાપિત થયો',
      AppLanguage.bengali: 'ব্যাকএন্ড থেকে সক্রিয় প্ল্যান পুনরুদ্ধার করা হয়েছে',
      AppLanguage.punjabi: 'ਬੈਕਐਂਡ ਤੋਂ ਕਿਰਿਆਸ਼ੀਲ ਪਲਾਨ ਰੀਸਟੋਰ ਹੋ ਗਿਆ',
      AppLanguage.odia: 'ବ୍ୟାକଏଣ୍ଡରୁ ସକ୍ରିୟ ପ୍ଲାନ୍ ପୁନରୁଦ୍ଧାର ହେଲା',
      AppLanguage.assamese: 'বেকএণ্ডৰ পৰা সক্ৰিয় প্লেন পুনৰুদ্ধাৰ কৰা হ’ল',
      AppLanguage.konkani: 'बॅकएंडांतल्यान चालू प्लॅन परत मेळ्ळो',
      AppLanguage.nepali: 'ब्याकइन्डबाट सक्रिय योजना पुनर्स्थापना गरियो',
      AppLanguage.meitei: 'Backend dagi active plan restore toukhre',
      AppLanguage.mizo: 'Backend atangin plan la let a ni',
      AppLanguage.kashmiri: 'بیک اینڈ پیٹھہٕ آو چالوٗ پلان بحال کرنہٕ',
      AppLanguage.ladakhi: 'Backend ནས་ནུས་ལྡན་འཆར་གཞི་ཕྱིར་གསོའི་བྱས།',
    },
    'Subscription restored': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ రిస్టోర్ అయింది',
      AppLanguage.english: 'Subscription restored',
      AppLanguage.hindi: 'सब्सक्रिप्शन बहाल हो गया',
      AppLanguage.tamil: 'சந்தா மீட்டெடுக்கப்பட்டது',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆಯನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ പുനഃസ്ഥാപിച്ചു',
      AppLanguage.marathi: 'सदस्यता पुनर्संचयित झाली',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન પુનઃસ્થાપિત થયું',
      AppLanguage.bengali: 'সাবস্ক্রিপশন পুনরুদ্ধার করা হয়েছে',
      AppLanguage.punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਰੀਸਟੋਰ ਕੀਤੀ ਗਈ',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ପୁନରୁଦ୍ଧାର ହେଲା',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বন পুনৰুদ্ধাৰ হ’ল',
      AppLanguage.konkani: 'वर्गणी परत मेळ्ळी',
      AppLanguage.nepali: 'सदस्यता पुनर्स्थापना भयो',
      AppLanguage.meitei: 'Subscription restore toukhre',
      AppLanguage.mizo: 'Subscription la let a ni',
      AppLanguage.kashmiri: 'سبسکرپشن گٔیہٕ بحال',
      AppLanguage.ladakhi: 'མངགས་ཉོ་ཕྱིར་གསོའི་བྱས།',
    },
    'Subscription verification is unavailable. Please try again later.': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ వెరిఫికేషన్ సర్వర్ అందుబాటులో లేదు. దయచేసి తర్వాత మళ్లీ ప్రయత్నించండి.',
      AppLanguage.english: 'Subscription verification is unavailable. Please try again later.',
      AppLanguage.hindi: 'सदस्यता सत्यापन उपलब्ध नहीं है। कृपया बाद में फिर प्रयास करें।',
      AppLanguage.tamil: 'சந்தா சரிபார்ப்பு கிடைக்கவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ സ്ഥിരീകരണം ലഭ്യമല്ല. പിന്നീട് വീണ്ടും ശ്രമിക്കുക.',
      AppLanguage.marathi: 'सदस्यता पडताळणी अनुपलब्ध आहे. कृपया नंतर पुन्हा प्रयत्न करा.',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન ચકાસણી અનુપલબ્ધ છે. કૃપા કરીને પછીથી ફરી પ્રયાસ કરો.',
      AppLanguage.bengali: 'সাবস্ক্রিপশন যাচাইকরণ অনুপলબ્ધ। অনুগ্রহ করে পরে আবার চেষ্টা করুন।',
      AppLanguage.punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਤਸਦੀਕ ਉਪਲਬਧ ਨਹੀਂ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਬਾਅਦ ਵਿੱਚ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ଯାଞ୍ଚ ଅନୁପଲବ୍ଧ। ଦୟାକରି ପରେ ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বন সত্যাপন উপলব্ধ নহয়। অনুগ্ৰহ কৰি পিছত পুনৰ চেষ্টা কৰক।',
      AppLanguage.konkani: 'वर्गणी पडताळणी उपलब्ध ना. उपकार करून मागीर प्रयत्न करात.',
      AppLanguage.nepali: 'सदस्यता प्रमाणीकरण अनुपलब्ध छ। कृपया पछि पुन: प्रयास गर्नुहोस्।',
      AppLanguage.meitei: 'Subscription verification phangde. Thengna amuk hanna hotnabiyu.',
      AppLanguage.mizo: 'Subscription fiah theih a ni rih lo. Nakinah ti nawn leh rawh.',
      AppLanguage.kashmiri: 'سبسکرپشن تصدیق چھُ نہٕ دستِیاب۔ مہربٲنی کٔرتھ پتہٕ کٔریو کوشِش۔',
      AppLanguage.ladakhi: 'མངགས་ཉོ་ཞིབ་བཤེར་མི་ཐོབ། རྗེས་སུ་ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    },
    'Verification data is missing. Try restore.': <AppLanguage, String>{
      AppLanguage.telugu: 'వెరిఫికేషన్ డేటా లేదు. రిస్టోర్ ప్రయత్నించండి.',
      AppLanguage.english: 'Verification data is missing. Try restore.',
      AppLanguage.hindi: 'वेरिफिकेशन डेटा नहीं है। रिस्टोर करें।',
      AppLanguage.tamil: 'சரிபார்ப்பு தரவு இல்லை. மீட்டெடுக்க முயற்சிக்கவும்.',
      AppLanguage.kannada: 'ಪರಿಶೀಲನಾ ಡೇಟಾ ಇಲ್ಲ. ಮರುಸ್ಥಾಪಿಸಲು ಪ್ರಯತ್ನಿಸಿ.',
      AppLanguage.malayalam: 'സ്ഥിരീകരണ ഡാറ്റ ഇല്ല. റിസ്റ്റോർ ചെയ്യുക.',
      AppLanguage.marathi: 'पडताळणी डेटा गहाळ आहे. रिस्टोअर करा.',
      AppLanguage.gujarati: 'ચકાસણી ડેટા ગુમ છે. પુનઃસ્થાપિત કરવાનો પ્રયાસ કરો.',
      AppLanguage.bengali: 'যাচাইকরণ ডেটা অনুপস্থিত। পুনরুদ্ধার করার চেষ্টা করুন।',
      AppLanguage.punjabi: 'ਤਸਦੀਕ ਡਾਟਾ ਗਾਇਬ ਹੈ। ਰੀਸਟੋਰ ਕਰਨ ਦੀ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      AppLanguage.odia: 'ଯାଞ୍ଚ ତଥ୍ୟ ନାହିଁ। ରିଷ୍ଟୋର୍ ଚେଷ୍ଟା କରନ୍ତୁ।',
      AppLanguage.assamese: 'সত্যাপন তথ্য নাই। পুনৰুদ্ধাৰৰ চেষ্টা কৰক।',
      AppLanguage.konkani: 'पडताळणी डेटा ना. परत मेळोवपाचो प्रयत्न करात.',
      AppLanguage.nepali: 'प्रमाणीकरण डेटा हराइरहेको छ। पुनर्स्थापना प्रयास गर्नुहोस्।',
      AppLanguage.meitei: 'Verification data leite. Restore toubiyu.',
      AppLanguage.mizo: 'Fiahna data a kim lo. La let leh rawh.',
      AppLanguage.kashmiri: 'تصدیقی ڈیٹا چھُ غائب۔ ری سٹور کٔریو۔',
      AppLanguage.ladakhi: 'ཞིབ་བཤེར་གཞི་གྲངས་མེད། ཕྱིར་གསོའི་འབད་བརྩོན་གནང།',
    },
    'Verification failed': <AppLanguage, String>{
      AppLanguage.telugu: 'వెరిఫికేషన్ విఫలమైంది',
      AppLanguage.english: 'Verification failed',
      AppLanguage.hindi: 'सत्यापन विफल हुआ',
      AppLanguage.tamil: 'சரிபார்ப்பு தோல்வியடைந்தது',
      AppLanguage.kannada: 'ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
      AppLanguage.malayalam: 'പരിശോധന പരാജയപ്പെട്ടു',
      AppLanguage.marathi: 'पडताळणी अयशस्वी झाली',
      AppLanguage.gujarati: 'ચકાસણી નિષ્ફળ ગઈ',
      AppLanguage.bengali: 'যাচাইকরণ ব্যর্থ হয়েছে',
      AppLanguage.punjabi: 'ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
      AppLanguage.odia: 'ଯାଞ୍ଚ ବିଫଳ ହେଲା',
      AppLanguage.assamese: 'সত্যাপন ব্যৰ্থ হ’ল',
      AppLanguage.konkani: 'पडताळणी अपेशी जाली',
      AppLanguage.nepali: 'प्रमाणीकरण असफल भयो',
      AppLanguage.meitei: 'Verification maipak-khide',
      AppLanguage.mizo: 'Fiahna a tlawlh',
      AppLanguage.kashmiri: 'تصدیق گٔیہٕ ناکام',
      AppLanguage.ladakhi: 'ཞིབ་བཤེར་མ་ཐུབ།',
    },
    'Subscription verification failed': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ వెరిఫికేషన్ విఫలమైంది',
      AppLanguage.english: 'Subscription verification failed',
      AppLanguage.hindi: 'सब्सक्रिप्शन सत्यापन विफल हुआ',
      AppLanguage.tamil: 'சந்தா சரிபார்ப்பு தோல்வியடைந்தது',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆ ಪರಿಶೀಲನೆ ವಿಫಲವಾಯಿತು',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ പരിശോധന പരാജയപ്പെട്ടു',
      AppLanguage.marathi: 'सदस्यता पडताळणी अयशस्वी झाली',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન ચકાસણી નિષ્ફળ ગઈ',
      AppLanguage.bengali: 'সাবস্ক্রিপশন যাচাইকরণ ব্যর্থ হয়েছে',
      AppLanguage.punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਤਸਦੀਕ ਅਸਫਲ ਰਹੀ',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ଯାଞ୍ଚ ବିଫଳ ହେଲା',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বন সত্যাপন ব্যৰ্থ হ’ল',
      AppLanguage.konkani: 'वर्गणी पडताळणी अपेशी जाली',
      AppLanguage.nepali: 'सदस्यता प्रमाणीकरण असफल भयो',
      AppLanguage.meitei: 'Subscription verification maipak-khide',
      AppLanguage.mizo: 'Subscription fiahna a tlawlh',
      AppLanguage.kashmiri: 'سبسکرپشن تصدیق گٔیہٕ ناکام',
      AppLanguage.ladakhi: 'མངགས་ཉོ་ཞིབ་བཤེར་མ་ཐུབ།',
    },
    'Restore succeeded, but Pro access is not updated yet. Please try again.': <AppLanguage, String>{
      AppLanguage.telugu: 'రీస్టోర్ అయినా ప్రో యాక్సెస్ ఇంకా అప్డేట్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      AppLanguage.english: 'Restore succeeded, but Pro access is not updated yet. Please try again.',
      AppLanguage.hindi: 'रिस्टोर सफल हुआ, लेकिन प्रो एक्सेस अभी अपडेट नहीं हुआ। कृपया फिर से प्रयास करें।',
      AppLanguage.tamil: 'ரிஸ்டோர் வெற்றியானது, ஆனால் Pro அணுகல் இன்னும் புதுப்பிக்கப்படவில்லை. மீண்டும் முயற்சிக்கவும்.',
      AppLanguage.kannada: 'ರಿಸ್ಟೋರ್ ಯಶಸ್ವಿಯಾಗಿದೆ, ಆದರೆ Pro ಪ್ರವೇಶ ಇನ್ನೂ ಅಪ್‌ಡೇಟ್ ಆಗಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      AppLanguage.malayalam: 'റിസ്റ്റോർ വിജയിച്ചു, പക്ഷേ Pro ആക്സസ് ഇനിയും അപ്ഡേറ്റ് ആയിട്ടില്ല. വീണ്ടും ശ്രമിക്കുക.',
      AppLanguage.marathi: 'रिस्टोअर यशस्वी झाले, पण प्रो अ‍ॅक्सेस अद्याप अपडेट झालेला नाही. कृपया पुन्हा प्रयत्न करा.',
      AppLanguage.gujarati: 'પુનઃસ્થાપિત સફળ થયું, પરંતુ પ્રો ઍક્સેસ હજુ સુધી અપડેટ થઈ નથી. ફરી પ્રયાસ કરો.',
      AppLanguage.bengali: 'পুনরুদ্ধার সফল হয়েছে, তবে প্রো অ্যাক্সেস এখনও আপডেট হয়নি। আবার চেষ্টা করুন।',
      AppLanguage.punjabi: 'ਰੀਸਟੋਰ ਸਫਲ ਰਿਹਾ, ਪਰ ਪ੍ਰੋ ਪਹੁੰਚ ਅਜੇ ਅੱਪਡੇਟ ਨਹੀਂ ਹੋਈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      AppLanguage.odia: 'ରିଷ୍ଟୋର୍ ସଫଳ ହେଲା, କିନ୍ତୁ ପ୍ରୋ ଆକ୍ସେସ୍ ଏପର୍ଯ୍ୟନ୍ତ ଅଦ୍ୟତନ ହୋଇନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      AppLanguage.assamese: 'পুনৰুদ্ধাৰ সফল হ’ল, কিন্তু প্ৰ’ প্ৰৱেশ এতিয়াও আপডেট হোৱা নাই। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      AppLanguage.konkani: 'रिस्टोर जालें, पूण प्रो प्रवेश अजून अपडेट जालो ना. उपकार करून परत प्रयत्न करात.',
      AppLanguage.nepali: 'पुनर्स्थापना सफल भयो, तर प्रो पहुँच अझै अपडेट भएको छैन। कृपया पुन: प्रयास गर्नुहोस्।',
      AppLanguage.meitei: 'Restore touba maipakle, adubu Pro access houjiksu update oide. Amuk hanna hotnabiyu.',
      AppLanguage.mizo: 'La let mah ila Pro access a la thleng lo. Khawngaihin ti nawn leh rawh.',
      AppLanguage.kashmiri: 'ری سٹور گوو کامیاب، مگر پرو ایکسس گوو نہٕ اپ ڈیٹ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
      AppLanguage.ladakhi: 'ཕྱིར་གསོའི་ལེགས་གྲུབ་བྱུང་ཡང་ Pro access གསར་སྒྱུར་མ་སོང། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    },
    'Payment was cancelled': <AppLanguage, String>{
      AppLanguage.telugu: 'చెల్లింపు రద్దు అయింది',
      AppLanguage.english: 'Payment was cancelled',
      AppLanguage.hindi: 'भुगतान रद्द कर दिया गया था',
      AppLanguage.tamil: 'பணம் செலுத்துதல் ரத்து செய்யப்பட்டது',
      AppLanguage.kannada: 'ಪಾವತಿ ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ',
      AppLanguage.malayalam: 'പേയ്‌മെന്റ് റദ്ദാക്കി',
      AppLanguage.marathi: 'पेमेंट रद्द केले गेले',
      AppLanguage.gujarati: 'ચુકવણી રદ કરવામાં આવી',
      AppLanguage.bengali: 'পেমেন্ট বাতিল করা হয়েছে',
      AppLanguage.punjabi: 'ਭੁਗਤਾਨ ਰੱਦ ਕਰ ਦਿੱਤਾ ਗਿਆ ਸੀ',
      AppLanguage.odia: 'ପେମେଣ୍ଟ ବାତିଲ୍ ହେଲା',
      AppLanguage.assamese: 'পৰিশোধ বাতিল কৰা হ’ল',
      AppLanguage.konkani: 'पेमेंट रद्द जालें',
      AppLanguage.nepali: 'भुक्तानी रद्द गरियो',
      AppLanguage.meitei: 'Payment cancel toukhraba',
      AppLanguage.mizo: 'Pawisa chawi sut a ni',
      AppLanguage.kashmiri: 'ادائیگی گٔیہٕ منسوخ',
      AppLanguage.ladakhi: 'དངུལ་སྤྲོད་ཕྱིར་འཐེན་བྱས།',
    },
    'Payment is pending. Pro access will unlock after Google Play confirms it.': <AppLanguage, String>{
      AppLanguage.telugu: 'చెల్లింపు పెండింగ్‌లో ఉంది. Google Play నిర్ధారించిన తర్వాత ప్రో యాక్సెస్ యాక్టివ్ అవుతుంది.',
      AppLanguage.english: 'Payment is pending. Pro access will unlock after Google Play confirms it.',
      AppLanguage.hindi: 'भुगतान लंबित है। Google Play द्वारा पुष्टि किए जाने के बाद प्रो एक्सेस अनलॉक हो जाएगा।',
      AppLanguage.tamil: 'பணம் செலுத்துதல் நிலுவையில் உள்ளது. Google Play உறுதிசெய்த பிறகு Pro அணுகல் திறக்கப்படும்.',
      AppLanguage.kannada: 'ಪಾವತಿ ಬಾಕಿ ಉಳಿದಿದೆ. Google Play ಖಚಿತಪಡಿಸಿದ ನಂತರ Pro ಪ್ರವೇಶವು ಅನ್‌ಲಾಕ್ ಆಗುತ್ತದೆ.',
      AppLanguage.malayalam: 'പേയ്‌മെന്റ് തീർപ്പുകൽപ്പിച്ചിട്ടില്ല. Google Play സ്ഥിരീകരിച്ച ശേഷം Pro ആക്‌സസ് അൺലോക്ക് ചെയ്യും.',
      AppLanguage.marathi: 'पेमेंट प्रलंबित आहे. Google Play ने पुष्टी केल्यानंतर प्रो अ‍ॅक्सेस अनलॉक होईल.',
      AppLanguage.gujarati: 'ચુકવણી બાકી છે. Google Play તેની પુષ્ટિ કર્યા પછી પ્રો ઍક્સેસ અનલૉક થશે.',
      AppLanguage.bengali: 'পেমেন্ট মুলতুবি রয়েছে। Google Play নিশ্চিত করার পরে প্রো অ্যাক্সেস আনলক হবে।',
      AppLanguage.punjabi: 'ਭੁਗਤਾਨ ਬਕਾਇਆ ਹੈ। Google Play ਵੱਲੋਂ ਪੁਸ਼ਟੀ ਕੀਤੇ ਜਾਣ ਤੋਂ ਬਾਅਦ ਪ੍ਰੋ ਪਹੁੰਚ ਅਨਲੌਕ ਹੋ ਜਾਵੇਗੀ।',
      AppLanguage.odia: 'ପେମେଣ୍ଟ ବିଚାରାଧୀନ ଅଛି। Google Play ନିଶ୍ଚିତ କରିବା ପରେ ପ୍ରୋ ଆକ୍ସେସ୍ ଖୋଲିବ।',
      AppLanguage.assamese: 'পৰিশোধ বাকী আছে। Google Play-এ নিশ্চিত কৰাৰ পিছত প্ৰ’ প্ৰৱেশ মুকলি হ’ব।',
      AppLanguage.konkani: 'पेमेंट प्रलंबित आसा. Google Play खात्री करतच प्रो अ‍ॅक्सेस उकतो जातलो.',
      AppLanguage.nepali: 'भुक्तानी बाँकी छ। Google Play ले पुष्टि गरेपछि प्रो पहुँच खुल्नेछ।',
      AppLanguage.meitei: 'Payment pending leiri. Google Play na confirm touraba matungda Pro access honglakkani.',
      AppLanguage.mizo: 'Pawisa chawi a la pending. Google Play-in a pawm hnuah Pro access a inhawng ang.',
      AppLanguage.kashmiri: 'ادائیگی چھِ زیرِ التوا۔ گوگل پلے تصدیق کرنہٕ پتہٕ گژھِ پرو ایکسس چالوٗ۔',
      AppLanguage.ladakhi: 'དངུལ་སྤྲོད་སྒུག་བཞིན་ཡོད། Google Play ཡིས་གཏན་འཁེལ་བྱས་རྗེས་ Pro access ཁ་འབྱེད་རྒྱུ།',
    },
    'Another payment is already in progress.': <AppLanguage, String>{
      AppLanguage.telugu: 'మరొక చెల్లింపు ఇప్పటికే కొనసాగుతోంది.',
      AppLanguage.english: 'Another payment is already in progress.',
      AppLanguage.hindi: 'एक और भुगतान पहले से ही प्रगति पर है।',
      AppLanguage.tamil: 'மற்றொரு பணம் செலுத்துதல் ஏற்கனவே செயலில் உள்ளது.',
      AppLanguage.kannada: 'ಮತ್ತೊಂದು ಪಾವತಿ ಈಗಾಗಲೇ ಪ್ರಗತಿಯಲ್ಲಿದೆ.',
      AppLanguage.malayalam: 'മറ്റൊരു പേയ്‌മെന്റ് ഇതിനകം പുരോഗതിയിലാണ്.',
      AppLanguage.marathi: 'दुसरे पेमेंट आधीच प्रगतीपथावर आहे.',
      AppLanguage.gujarati: 'અન્ય ચુકવણી પહેલેથી જ ચાલુ છે.',
      AppLanguage.bengali: 'অন্য একটি পেমেন্ট ইতিমধ্যে প্রক্রিয়াধীন রয়েছে।',
      AppLanguage.punjabi: 'ਇੱਕ ਹੋਰ ਭੁਗਤਾਨ ਪਹਿਲਾਂ ਹੀ ਚੱਲ ਰਿਹਾ ਹੈ।',
      AppLanguage.odia: 'ଅନ୍ୟ ଏକ ପେମେଣ୍ଟ ପୂର୍ବରୁ ଚାଲୁଅଛି।',
      AppLanguage.assamese: 'অন্য এটা পৰিশোধ ইতিমধ্যে চলি আছে।',
      AppLanguage.konkani: 'दुसरें पेमेंट पयलींच चालू आसा.',
      AppLanguage.nepali: 'अर्को भुक्तानी पहिले नै जारी छ।',
      AppLanguage.meitei: 'Atoppa payment ama mamangdagi chatthari.',
      AppLanguage.mizo: 'Pawisa chawi dang a kal mek.',
      AppLanguage.kashmiri: 'بییہٕ اکھ ادائیگی چھِ گۄڈے جٲری۔',
      AppLanguage.ladakhi: 'དངུལ་སྤྲོད་གཞན་ཞིག་སྔོན་ནས་འགྲོ་བཞིན་ཡོད།',
    },
    'Payment failed': <AppLanguage, String>{
      AppLanguage.telugu: 'చెల్లింపు విఫలమైంది',
      AppLanguage.english: 'Payment failed',
      AppLanguage.hindi: 'भुगतान विफल',
      AppLanguage.tamil: 'பணம் செலுத்துதல் தோல்வியடைந்தது',
      AppLanguage.kannada: 'ಪಾವತಿ ವಿಫಲವಾಗಿದೆ',
      AppLanguage.malayalam: 'പേയ്‌മെന്റ് പരാജയപ്പെട്ടു',
      AppLanguage.marathi: 'पेमेंट अयशस्वी',
      AppLanguage.gujarati: 'ચુકવણી નિષ્ફળ',
      AppLanguage.bengali: 'পেমেন্ট ব্যর্থ হয়েছে',
      AppLanguage.punjabi: 'ਭੁਗਤਾਨ ਅਸਫਲ ਰਿਹਾ',
      AppLanguage.odia: 'ପେମେଣ୍ଟ ବିଫଳ ହେଲା',
      AppLanguage.assamese: 'পৰিশোধ ব্যৰ্থ হ’ল',
      AppLanguage.konkani: 'पेमेंट अपेशी जालें',
      AppLanguage.nepali: 'भुक्तानी असफल भयो',
      AppLanguage.meitei: 'Payment maipak-khide',
      AppLanguage.mizo: 'Pawisa chawi a hlawhchham',
      AppLanguage.kashmiri: 'ادائیگی گٔیہٕ ناکام',
      AppLanguage.ladakhi: 'དངུལ་སྤྲོད་མ་ཐུབ།',
    },
    'Billing service is unavailable': <AppLanguage, String>{
      AppLanguage.telugu: 'బిల్లింగ్ సర్వీస్ అందుబాటులో లేదు',
      AppLanguage.english: 'Billing service is unavailable',
      AppLanguage.hindi: 'बिलिंग सेवा अनुपलब्ध है',
      AppLanguage.tamil: 'பில்லிங் சேவை கிடைக்கவில்லை',
      AppLanguage.kannada: 'ಬಿಲ್ಲಿಂಗ್ ಸೇವೆ ಲಭ್ಯವಿಲ್ಲ',
      AppLanguage.malayalam: 'ബില്ലിംഗ് സേവനം ലഭ്യമല്ല',
      AppLanguage.marathi: 'बिलिंग सेवा अनुपलब्ध आहे',
      AppLanguage.gujarati: 'બિલિંગ સેવા અનુપલબ્ધ છે',
      AppLanguage.bengali: 'বিলিং পরিষেবা অনুপলব্ধ',
      AppLanguage.punjabi: 'ਬਿਲਿੰਗ ਸੇਵਾ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
      AppLanguage.odia: 'ବିଲିଂ ସେବା ଅନୁପଲବ୍ଧ',
      AppLanguage.assamese: 'বিলিং সেৱা উপলব্ধ নহয়',
      AppLanguage.konkani: 'बिलिंग सेवा उपलब्ध ना',
      AppLanguage.nepali: 'बिलिङ सेवा अनुपलब्ध छ',
      AppLanguage.meitei: 'Billing service phangde',
      AppLanguage.mizo: 'Billing service a awm lo',
      AppLanguage.kashmiri: 'بلنگ سٔروِس چھِ نہٕ دستِیاب',
      AppLanguage.ladakhi: 'Billing ཞབས་ཞུ་མི་ཐོབ།',
    },
    'Store product not found. Check product id.': <AppLanguage, String>{
      AppLanguage.telugu: 'స్టోర్ ప్రోడక్ట్ కనిపించలేదు. ప్రోడక్ట్ ఐడీ చూడండి.',
      AppLanguage.english: 'Store product not found. Check product id.',
      AppLanguage.hindi: 'स्टोर उत्पाद नहीं मिला। उत्पाद आईडी जांचें।',
      AppLanguage.tamil: 'ஸ்டோர் தயாரிப்பு கிடைக்கவில்லை. தயாரிப்பு ஐடியைச் சரிபார்க்கவும்.',
      AppLanguage.kannada: 'ಸ್ಟೋರ್ ಉತ್ಪನ್ನ ಕಂಡುಬಂದಿಲ್ಲ. ಉತ್ಪನ್ನ ಐಡಿ ಪರಿಶೀಲಿಸಿ.',
      AppLanguage.malayalam: 'സ്റ്റോർ ഉൽപ്പന്നം കണ്ടെത്തിയില്ല. ഉൽപ്പന്ന ഐഡി പരിശോധിക്കുക.',
      AppLanguage.marathi: 'स्टोअर उत्पादन आढळले नाही. उत्पादन आयडी तपासा.',
      AppLanguage.gujarati: 'સ્ટોર ઉત્પાદન મળ્યું નથી. પ્રોડક્ટ આઈડી તપાસો.',
      AppLanguage.bengali: 'স্টোর পণ্য পাওয়া যায়নি। পণ্য আইডি পরীক্ষা করুন।',
      AppLanguage.punjabi: 'ਸਟੋਰ ਉਤਪਾਦ ਨਹੀਂ ਮਿਲਿਆ। ਉਤਪਾਦ ਆਈਡੀ ਦੀ ਜਾਂਚ ਕਰੋ।',
      AppLanguage.odia: 'ଷ୍ଟୋର୍ ଉତ୍ପାଦ ମିଳିଲା ନାହିଁ। ଉତ୍ପାଦ ଆଇଡି ଯାଞ୍ଚ କରନ୍ତୁ।',
      AppLanguage.assamese: 'ষ্ট’ৰ সামগ্ৰী পোৱা নগ’ল। সামগ্ৰী আইডি পৰীক্ষা কৰক।',
      AppLanguage.konkani: 'स्टोअर उत्पादन मेळ्ळें ना. उत्पादन आयडी तपासात.',
      AppLanguage.nepali: 'स्टोर उत्पादन फेला परेन। उत्पादन आईडी जाँच गर्नुहोस्।',
      AppLanguage.meitei: 'Store product thengnakhide. Product ID check toubiyu.',
      AppLanguage.mizo: 'Store product hmuh a ni lo. Product ID en rawh.',
      AppLanguage.kashmiri: 'سٹور پراڈکٹ میول نہ۔ پراڈکٹ ائی ڈی چیک کٔریو۔',
      AppLanguage.ladakhi: 'Store ཐོན་རྫས་མ་རྙེད། ཐོན་རྫས་ ID ཞིབ་བཤེར་གནང།',
    },
    'Payment response timed out. Please try again.': <AppLanguage, String>{
      AppLanguage.telugu: 'చెల్లింపు ప్రతిస్పందన టైమ్ అవుట్ అయింది. మళ్లీ ప్రయత్నించండి.',
      AppLanguage.english: 'Payment response timed out. Please try again.',
      AppLanguage.hindi: 'भुगतान प्रतिक्रिया का समय समाप्त हो गया। कृपया पुनः प्रयास करें।',
      AppLanguage.tamil: 'பணம் செலுத்துதல் பதில் காலாவதியானது. மீண்டும் முயற்சிக்கவும்.',
      AppLanguage.kannada: 'ಪಾವತಿ ಪ್ರತಿಕ್ರಿಯೆ ಸಮಯ ಮೀರಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      AppLanguage.malayalam: 'പേയ്‌മെന്റ് പ്രതികരണ സമയം കഴിഞ്ഞു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
      AppLanguage.marathi: 'पेमेंट प्रतिसाद कालबाह्य झाला. कृपया पुन्हा प्रयत्न करा.',
      AppLanguage.gujarati: 'ચુકવણી પ્રતિસાદ સમય સમાપ્ત થયો. ફરી પ્રયાસ કરો.',
      AppLanguage.bengali: 'পেমেন্ট প্রতিক্রিয়ার সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
      AppLanguage.punjabi: 'ਭੁਗਤਾਨ ਪ੍ਰਤੀਕਿਰਿਆ ਦਾ ਸਮਾਂ ਸਮਾਪਤ ਹੋ ਗਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      AppLanguage.odia: 'ପେମେଣ୍ଟ ପ୍ରତିକ୍ରିୟା ସମୟ ସମାପ୍ତ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      AppLanguage.assamese: 'পৰিশোধ সঁহাৰিৰ সময় উকলিল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      AppLanguage.konkani: 'पेमेंट प्रतिसाद वेळ सोंपलो. उपकार करून परत प्रयत्न करात.',
      AppLanguage.nepali: 'भुक्तानी प्रतिक्रिया समय समाप्त भयो। कृपया पुन: प्रयास गर्नुहोस्।',
      AppLanguage.meitei: 'Payment response time out oikhre. Amuk hanna hotnabiyu.',
      AppLanguage.mizo: 'Pawisa chawi chhanna a hun a ral. Khawngaihin ti nawn leh rawh.',
      AppLanguage.kashmiri: 'ادائیگی ہُنٛد جواب گوو وقت ختم۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
      AppLanguage.ladakhi: 'དངུལ་སྤྲོད་ལན་གྱི་དུས་ཚོད་རྫོགས། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    },
    'No subscription found to restore': <AppLanguage, String>{
      AppLanguage.telugu: 'రిస్టోర్ చేయడానికి సబ్‌స్క్రిప్షన్ కనిపించలేదు',
      AppLanguage.english: 'No subscription found to restore',
      AppLanguage.hindi: 'पुनर्स्थापित करने के लिए कोई सदस्यता नहीं मिली',
      AppLanguage.tamil: 'மீட்டெடுக்க எந்த சந்தாவும் காணப்படவில்லை',
      AppLanguage.kannada: 'ಮರುಸ್ಥಾಪಿಸಲು ಯಾವುದೇ ಚಂದಾದಾರಿಕೆ ಕಂಡುಬಂದಿಲ್ಲ',
      AppLanguage.malayalam: 'പുനഃസ്ഥാപിക്കാൻ സബ്‌സ്‌ക്രിപ്ഷനൊന്നും കണ്ടെത്തിയില്ല',
      AppLanguage.marathi: 'पुनर्संचयित करण्यासाठी कोणतीही सदस्यता आढळली नाही',
      AppLanguage.gujarati: 'પુનઃસ્થાપિત કરવા માટે કોઈ સબ્સ્ક્રિપ્શન મળ્યું નથી',
      AppLanguage.bengali: 'পুনরুদ্ধার করার মতো কোনো সাবস্ক্রিপশন পাওয়া যায়নি',
      AppLanguage.punjabi: 'ਰੀਸਟੋਰ ਕਰਨ ਲਈ ਕੋਈ ਗਾਹਕੀ ਨਹੀਂ ਮਿਲੀ',
      AppLanguage.odia: 'ପୁନରୁଦ୍ଧାର ପାଇଁ କୌଣସି ସବସ୍କ୍ରିପସନ୍ ମିଳିଲା ନାହିଁ',
      AppLanguage.assamese: 'পুনৰুদ্ধাৰ কৰিবলৈ কোনো চাবস্ক্ৰিপশ্বন পোৱা নগ’ল',
      AppLanguage.konkani: 'परत मेळोवपाक कसलीच वर्गणी मेळ्ळी ना',
      AppLanguage.nepali: 'पुनर्स्थापना गर्न कुनै सदस्यता फेला परेन',
      AppLanguage.meitei: 'Restore tounaba subscription thengnakhide',
      AppLanguage.mizo: 'La let tur subscription a awm lo',
      AppLanguage.kashmiri: 'بحال کرنہٕ باپتھ میول نہ کانہہ سبسکرپشن',
      AppLanguage.ladakhi: 'ཕྱིར་གསོའི་བྱ་རྒྱུའི་མངགས་ཉོ་མ་རྙེད།',
    },
    'Checking plan status...': <AppLanguage, String>{
      AppLanguage.telugu: 'ప్లాన్ స్థితి చెక్ అవుతోంది...',
      AppLanguage.english: 'Checking plan status...',
      AppLanguage.hindi: 'प्लान की स्थिति जांची जा रही है...',
      AppLanguage.tamil: 'திட்டத்தின் நிலை சரிபார்க்கப்படுகிறது...',
      AppLanguage.kannada: 'ಯೋಜನೆ ಸ್ಥಿತಿ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
      AppLanguage.malayalam: 'പ്ലാൻ നില പരിശോധിക്കുന്നു...',
      AppLanguage.marathi: 'प्लॅन स्थिती तपासत आहे...',
      AppLanguage.gujarati: 'પ્લાનની સ્થિતિ તપાસી રહ્યું છે...',
      AppLanguage.bengali: 'প্ল্যানের স্থিতি পরীক্ষা করা হচ্ছে...',
      AppLanguage.punjabi: 'ਪਲਾਨ ਸਥਿਤੀ ਦੀ ਜਾਂਚ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ...',
      AppLanguage.odia: 'ପ୍ଲାନ୍ ସ୍ଥିତି ଯାଞ୍ଚ ହେଉଛି...',
      AppLanguage.assamese: 'প্লেনৰ স্থিতি পৰীক্ষা কৰা হৈছে...',
      AppLanguage.konkani: 'प्लॅन स्थिती तपासतात...',
      AppLanguage.nepali: 'योजना स्थिति जाँच गरिँदैछ...',
      AppLanguage.meitei: 'Plan status check touri...',
      AppLanguage.mizo: 'Plan dinhmun en mek a ni...',
      AppLanguage.kashmiri: 'پلان حالت چھِ چیک گژھان...',
      AppLanguage.ladakhi: 'འཆར་གཞིའི་གནས་སྟངས་ཞིབ་བཤེར་བྱེད་བཞིན་པ...',
    },
    'Status information unavailable': <AppLanguage, String>{
      AppLanguage.telugu: 'స్థితి సమాచారం అందుబాటులో లేదు',
      AppLanguage.english: 'Status information unavailable',
      AppLanguage.hindi: 'स्थिति की जानकारी अनुपलब्ध है',
      AppLanguage.tamil: 'நிலைத் தகவல் கிடைக்கவில்லை',
      AppLanguage.kannada: 'ಸ್ಥಿತಿ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ',
      AppLanguage.malayalam: 'നില വിവരങ്ങൾ ലഭ്യമല്ല',
      AppLanguage.marathi: 'स्थिती माहिती अनुपलब्ध',
      AppLanguage.gujarati: 'સ્થિતિ માહિતી અનુપલબ્ધ',
      AppLanguage.bengali: 'স্থিতি তথ্য অনুপলব্ধ',
      AppLanguage.punjabi: 'ਸਥਿਤੀ ਜਾਣਕਾਰੀ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
      AppLanguage.odia: 'ସ୍ଥିତି ସୂଚନା ଅନୁପଲବ୍ଧ',
      AppLanguage.assamese: 'স্থিতিৰ তথ্য উপলব্ধ নহয়',
      AppLanguage.konkani: 'स्थिती माहिती उपलब्ध ना',
      AppLanguage.nepali: 'स्थिति जानकारी अनुपलब्ध छ',
      AppLanguage.meitei: 'Status information phangde',
      AppLanguage.mizo: 'Dinhmun chanchin a awm lo',
      AppLanguage.kashmiri: 'حالتٕچ معلوٗمات چھِ نہٕ دستِیاب',
      AppLanguage.ladakhi: 'གནས་སྟངས་གནས་ཚུལ་མི་ཐོབ།',
    },
    'Subscription expired': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ గడువు ముగిసింది',
      AppLanguage.english: 'Subscription expired',
      AppLanguage.hindi: 'सदस्यता समाप्त हो गई',
      AppLanguage.tamil: 'சந்தா காலாவதியானது',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆ ಅವಧಿ ಮುಗಿದಿದೆ',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ കാലാവധി കഴിഞ്ഞു',
      AppLanguage.marathi: 'सदस्यता कालबाह्य झाली',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન સમાપ્ત થઈ ગયું',
      AppLanguage.bengali: 'সাবস্ক্রিপশনের মেয়াদ শেষ হয়েছে',
      AppLanguage.punjabi: 'ਗਾਹਕੀ ਦੀ ਮਿਆਦ ਪੁੱਗ ਗਈ',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ଅବଧି ସମାପ୍ତ ହେଲା',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বনৰ ম্যাদ উকলিল',
      AppLanguage.konkani: 'वर्गणीची मुदत सोंपली',
      AppLanguage.nepali: 'सदस्यता समाप्त भयो',
      AppLanguage.meitei: 'Subscription expired oikhre',
      AppLanguage.mizo: 'Subscription hun a ral',
      AppLanguage.kashmiri: 'سبسکرپشن گۆو ختم',
      AppLanguage.ladakhi: 'མངགས་ཉོའི་དུས་ཚོད་རྫོགས།',
    },
    'Subscription is not active': <AppLanguage, String>{
      AppLanguage.telugu: 'సబ్‌స్క్రిప్షన్ యాక్టివ్‌లో లేదు',
      AppLanguage.english: 'Subscription is not active',
      AppLanguage.hindi: 'सदस्यता सक्रिय नहीं है',
      AppLanguage.tamil: 'சந்தா செயலில் இல்லை',
      AppLanguage.kannada: 'ಚಂದಾದಾರಿಕೆ ಸಕ್ರಿಯವಾಗಿಲ್ಲ',
      AppLanguage.malayalam: 'സബ്സ്ക്രിപ്ഷൻ സജീവമല്ല',
      AppLanguage.marathi: 'सदस्यता सक्रिय नाही',
      AppLanguage.gujarati: 'સબ્સ્ક્રિપ્શન સક્રિય નથી',
      AppLanguage.bengali: 'সাবস্ক্রিপশন সক্রিয় নয়',
      AppLanguage.punjabi: 'ਗਾਹਕੀ ਕਿਰਿਆਸ਼ੀਲ ਨਹੀਂ ਹੈ',
      AppLanguage.odia: 'ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ ନାହିଁ',
      AppLanguage.assamese: 'চাবস্ক্ৰিপশ্বন সক্ৰিয় নহয়',
      AppLanguage.konkani: 'वर्गणी चालू ना',
      AppLanguage.nepali: 'सदस्यता सक्रिय छैन',
      AppLanguage.meitei: 'Subscription active oide',
      AppLanguage.mizo: 'Subscription a nung lo',
      AppLanguage.kashmiri: 'سبسکرپشن چھُ نہٕ چالوٗ',
      AppLanguage.ladakhi: 'མངགས་ཉོ་ནུས་ལྡན་མིན།',
    },
    'Plan info mode': <AppLanguage, String>{
      AppLanguage.telugu: 'ప్లాన్ సమాచారం మోడ్',
      AppLanguage.english: 'Plan info mode',
      AppLanguage.hindi: 'प्लान जानकारी मोड',
      AppLanguage.tamil: 'திட்ட தகவல் முறை',
      AppLanguage.kannada: 'ಯೋಜನೆ ಮಾಹಿತಿ ಮೋಡ್',
      AppLanguage.malayalam: 'പ്ലാൻ വിവര മോഡ്',
      AppLanguage.marathi: 'प्लॅन माहिती मोड',
      AppLanguage.gujarati: 'પ્લાન માહિતી મોડ',
      AppLanguage.bengali: 'প্ল্যান তথ্য মোড',
      AppLanguage.punjabi: 'ਪਲਾਨ ਜਾਣਕਾਰੀ ਮੋਡ',
      AppLanguage.odia: 'ପ୍ଲାନ୍ ସୂଚନା ମୋଡ୍',
      AppLanguage.assamese: 'প্লেন তথ্য ম’ড',
      AppLanguage.konkani: 'प्लॅन माहिती मोड',
      AppLanguage.nepali: 'योजना जानकारी मोड',
      AppLanguage.meitei: 'Plan info mode',
      AppLanguage.mizo: 'Plan hriattirna mode',
      AppLanguage.kashmiri: 'پلان معلوٗمات موڈ',
      AppLanguage.ladakhi: 'འཆར་གཞི་གནས་ཚུལ་རྣམ་པ།',
    },
    'Status check failed': <AppLanguage, String>{
      AppLanguage.telugu: 'స్థితి చెక్ విఫలమైంది',
      AppLanguage.english: 'Status check failed',
      AppLanguage.hindi: 'स्थिति जांच विफल',
      AppLanguage.tamil: 'நிலை சரிபார்ப்பு தோல்வியடைந்தது',
      AppLanguage.kannada: 'ಸ್ಥಿತಿ ಪರಿಶೀಲನೆ ವಿಫಲವಾಗಿದೆ',
      AppLanguage.malayalam: 'നില പരിശോധന പരാജയപ്പെട്ടു',
      AppLanguage.marathi: 'स्थिती तपासणी अयशस्वी',
      AppLanguage.gujarati: 'સ્થિતિ તપાસ નિષ્ફળ',
      AppLanguage.bengali: 'স্থিতি পরীক্ষা ব্যর্থ হয়েছে',
      AppLanguage.punjabi: 'ਸਥਿਤੀ ਜਾਂਚ ਅਸਫਲ ਰਹੀ',
      AppLanguage.odia: 'ସ୍ଥିତି ଯାଞ୍ଚ ବିଫଳ ହେଲା',
      AppLanguage.assamese: 'স্থিতি পৰীক্ষা ব্যৰ্থ হ’ল',
      AppLanguage.konkani: 'स्थिती तपासणी अपेशी जाली',
      AppLanguage.nepali: 'स्थिति जाँच असफल भयो',
      AppLanguage.meitei: 'Status check maipak-khide',
      AppLanguage.mizo: 'Dinhmun en a tlawlh',
      AppLanguage.kashmiri: 'حالتٕچ تفتِیش گٔیہٕ ناکام',
      AppLanguage.ladakhi: 'གནས་སྟངས་ཞིབ་བཤེར་མ་ཐུབ།',
    },
    'Active': <AppLanguage, String>{
      AppLanguage.telugu: 'యాక్టివ్',
      AppLanguage.english: 'Active',
      AppLanguage.hindi: 'सक्रिय',
      AppLanguage.tamil: 'செயலில்',
      AppLanguage.kannada: 'ಸಕ್ರಿಯ',
      AppLanguage.malayalam: 'സജീവം',
      AppLanguage.marathi: 'सक्रिय',
      AppLanguage.gujarati: 'સક્રિય',
      AppLanguage.bengali: 'সক্রিয়',
      AppLanguage.punjabi: 'ਕਿਰਿਆਸ਼ੀਲ',
      AppLanguage.odia: 'ସକ୍ରିୟ',
      AppLanguage.assamese: 'সক্ৰিয়',
      AppLanguage.konkani: 'सक्रिय',
      AppLanguage.nepali: 'सक्रिय',
      AppLanguage.meitei: 'Active',
      AppLanguage.mizo: 'Nung',
      AppLanguage.kashmiri: 'چالوٗ',
      AppLanguage.ladakhi: 'ནུས་ལྡན།',
    },
    'Not active': <AppLanguage, String>{
      AppLanguage.telugu: 'యాక్టివ్‌లో లేదు',
      AppLanguage.english: 'Not active',
      AppLanguage.hindi: 'सक्रिय नहीं',
      AppLanguage.tamil: 'செயலில் இல்லை',
      AppLanguage.kannada: 'ಸಕ್ರಿಯವಿಲ್ಲ',
      AppLanguage.malayalam: 'സജീവമല്ല',
      AppLanguage.marathi: 'सक्रिय नाही',
      AppLanguage.gujarati: 'સક્રિય નથી',
      AppLanguage.bengali: 'সক্রিয় নয়',
      AppLanguage.punjabi: 'ਕਿਰਿਆਸ਼ੀਲ ਨਹੀਂ',
      AppLanguage.odia: 'ସକ୍ରିୟ ନାହିଁ',
      AppLanguage.assamese: 'সক্ৰিয় নহয়',
      AppLanguage.konkani: 'सक्रिय ना',
      AppLanguage.nepali: 'सक्रिय छैन',
      AppLanguage.meitei: 'Active oide',
      AppLanguage.mizo: 'Nung lo',
      AppLanguage.kashmiri: 'چالوٗ نہٕ',
      AppLanguage.ladakhi: 'ནུས་མེད།',
    },
    'Already Active': <AppLanguage, String>{
      AppLanguage.telugu: 'ఇప్పటికే యాక్టివ్',
      AppLanguage.english: 'Already Active',
      AppLanguage.hindi: 'पहले से सक्रिय',
      AppLanguage.tamil: 'ஏற்கனவே செயலில் உள்ளது',
      AppLanguage.kannada: 'ಈಗಾಗಲೇ ಸಕ್ರಿಯವಾಗಿದೆ',
      AppLanguage.malayalam: 'ഇതിനകം സജീവം',
      AppLanguage.marathi: 'आधीच सक्रिय',
      AppLanguage.gujarati: 'પહેલેથી જ સક્રિય',
      AppLanguage.bengali: 'ইতিমধ্যে সক্রিয়',
      AppLanguage.punjabi: 'ਪਹਿਲਾਂ ਹੀ ਕਿਰਿਆਸ਼ੀਲ',
      AppLanguage.odia: 'ପୂର୍ବରୁ ସକ୍ରିୟ',
      AppLanguage.assamese: 'ইতিমধ্যে সক্ৰিয়',
      AppLanguage.konkani: 'पयलींच चालू',
      AppLanguage.nepali: 'पहिले नै सक्रिय',
      AppLanguage.meitei: 'Already active',
      AppLanguage.mizo: 'Nung sa',
      AppLanguage.kashmiri: 'گۄڈے چالوٗ',
      AppLanguage.ladakhi: 'སྔོན་ནས་ནུས་ལྡན།',
    },
    'Your plan details': <AppLanguage, String>{
      AppLanguage.telugu: 'మీ ప్లాన్ వివరాలు',
      AppLanguage.english: 'Your plan details',
      AppLanguage.hindi: 'आपके प्लान का विवरण',
      AppLanguage.tamil: 'உங்கள் திட்ட விவரங்கள்',
      AppLanguage.kannada: 'ನಿಮ್ಮ ಯೋಜನೆಯ ವಿವರಗಳು',
      AppLanguage.malayalam: 'നിങ്ങളുടെ പ്ലാൻ വിവരങ്ങൾ',
      AppLanguage.marathi: 'तुमचे प्लॅन तपशील',
      AppLanguage.gujarati: 'તમારી પ્લાનની વિગતો',
      AppLanguage.bengali: 'আপনার প্ল্যানের বিবরণ',
      AppLanguage.punjabi: 'ਤੁਹਾਡੇ ਪਲਾਨ ਦੇ ਵੇਰਵੇ',
      AppLanguage.odia: 'ଆପଣଙ୍କ ପ୍ଲାନ୍ ବିବରଣୀ',
      AppLanguage.assamese: 'আপোনাৰ প্লেনৰ বিৱৰণ',
      AppLanguage.konkani: 'तुमचे प्लॅन तपशील',
      AppLanguage.nepali: 'तपाईंको योजना विवरण',
      AppLanguage.meitei: 'Nangi plan details',
      AppLanguage.mizo: 'I plan chanchin',
      AppLanguage.kashmiri: 'تہنٛد پلان تفصیلات',
      AppLanguage.ladakhi: 'ཁྱེད་ཀྱི་འཆར་གཞིའི་ཞིབ་ཕྲ།',
    },
    'App Pro': <AppLanguage, String>{
      AppLanguage.telugu: 'App Pro',
      AppLanguage.english: 'App Pro',
      AppLanguage.hindi: 'App Pro',
      AppLanguage.tamil: 'App Pro',
      AppLanguage.kannada: 'App Pro',
      AppLanguage.malayalam: 'App Pro',
      AppLanguage.marathi: 'App Pro',
      AppLanguage.gujarati: 'App Pro',
      AppLanguage.bengali: 'App Pro',
      AppLanguage.punjabi: 'App Pro',
      AppLanguage.odia: 'App Pro',
      AppLanguage.assamese: 'App Pro',
      AppLanguage.konkani: 'App Pro',
      AppLanguage.nepali: 'App Pro',
      AppLanguage.meitei: 'App Pro',
      AppLanguage.mizo: 'App Pro',
      AppLanguage.kashmiri: 'App Pro',
      AppLanguage.ladakhi: 'App Pro',
    },
    'Editor Pro': <AppLanguage, String>{
      AppLanguage.telugu: 'Editor Pro',
      AppLanguage.english: 'Editor Pro',
      AppLanguage.hindi: 'Editor Pro',
      AppLanguage.tamil: 'Editor Pro',
      AppLanguage.kannada: 'Editor Pro',
      AppLanguage.malayalam: 'Editor Pro',
      AppLanguage.marathi: 'Editor Pro',
      AppLanguage.gujarati: 'Editor Pro',
      AppLanguage.bengali: 'Editor Pro',
      AppLanguage.punjabi: 'Editor Pro',
      AppLanguage.odia: 'Editor Pro',
      AppLanguage.assamese: 'Editor Pro',
      AppLanguage.konkani: 'Editor Pro',
      AppLanguage.nepali: 'Editor Pro',
      AppLanguage.meitei: 'Editor Pro',
      AppLanguage.mizo: 'Editor Pro',
      AppLanguage.kashmiri: 'Editor Pro',
      AppLanguage.ladakhi: 'Editor Pro',
    },
    'Choose Editor Pro monthly, or All Access yearly for app + editor together.': <AppLanguage, String>{
      AppLanguage.telugu: 'Editor Pro monthly లేదా app + editor కోసం All Access yearly ఎంచుకోండి.',
      AppLanguage.english: 'Choose Editor Pro monthly, or All Access yearly for app + editor together.',
      AppLanguage.hindi: 'Editor Pro मासिक चुनें, या ऐप + एडिटर के लिए All Access वार्षिक चुनें।',
      AppLanguage.tamil: 'Editor Pro மாத சந்தா அல்லது செயலி + எடிட்டருக்கு All Access ஆண்டு சந்தாவைத் தேர்வு செய்யவும்.',
      AppLanguage.kannada: 'Editor Pro ಮಾಸಿಕ ಅಥವಾ ಆಪ್ + ಎಡಿಟರ್‌ಗಾಗಿ All Access ವಾರ್ಷಿಕ ಆಯ್ಕೆಮಾಡಿ.',
      AppLanguage.malayalam: 'Editor Pro monthly അല്ലെങ്കിൽ app + editor നായി All Access yearly തിരഞ്ഞെടുക്കുക.',
      AppLanguage.marathi: 'Editor Pro मासिक किंवा अ‍ॅप + एडिटरसाठी All Access वार्षिक निवडा.',
      AppLanguage.gujarati: 'Editor Pro માસિક અથવા એપ્લિકેશન + એડિટર માટે All Access વાર્ષિક પસંદ કરો.',
      AppLanguage.bengali: 'Editor Pro মাসিক অথবা অ্যাপ + সম্পাদকের জন্য All Access বার্ষিক বেছে নিন।',
      AppLanguage.punjabi: 'Editor Pro ਮਹੀਨਾਵਾਰ ਜਾਂ ਐਪ + ਐਡੀਟਰ ਲਈ All Access ਸਾਲਾਨਾ ਚੁਣੋ।',
      AppLanguage.odia: 'Editor Pro ମାସିକ କିମ୍ବା ଆପ୍ + ଏଡିଟର୍ ପାଇଁ All Access ବାର୍ଷିକ ବାଛନ୍ତୁ।',
      AppLanguage.assamese: 'Editor Pro মাহেকীয়া বা এপ + এডিটৰৰ বাবে All Access বাৰ্ষিক বাছক।',
      AppLanguage.konkani: 'Editor Pro म्हयन्याचें वा अ‍ॅप + एडिटर खातीर All Access वर्सुकी निवडा.',
      AppLanguage.nepali: 'Editor Pro मासिक वा एप + सम्पादकको लागि All Access वार्षिक छनौट गर्नुहोस्।',
      AppLanguage.meitei: 'Editor Pro monthly natraga app + editor gi All Access yearly khanbiyu.',
      AppLanguage.mizo: 'Editor Pro monthly emaw, app + editor atan All Access yearly thlang rawh.',
      AppLanguage.kashmiri: 'Editor Pro ماہور یا ایپ + ایڈیٹر باپتھ کٔریو All Access سالانہ اِنتخاب۔',
      AppLanguage.ladakhi: 'Editor Pro ཟླ་རེ་འམ་ app + editor ཆེད་དུ་ All Access ལོ་རེ་གདམ་ཁ་བྱོས།',
    },
    'Yearly Plan': <AppLanguage, String>{
      AppLanguage.telugu: 'సంవత్సర ప్లాన్',
      AppLanguage.english: 'Yearly Plan',
      AppLanguage.hindi: 'वार्षिक प्लान',
      AppLanguage.tamil: 'வருடாந்திர திட்டம்',
      AppLanguage.kannada: 'ವಾರ್ಷಿಕ ಯೋಜನೆ',
      AppLanguage.malayalam: 'വാർഷിക പ്ലാൻ',
      AppLanguage.marathi: 'वार्षिक प्लॅन',
      AppLanguage.gujarati: 'વાર્ષિક પ્લાન',
      AppLanguage.bengali: 'বার্ষিক প্ল্যান',
      AppLanguage.punjabi: 'ਸਾਲਾਨਾ ਪਲਾਨ',
      AppLanguage.odia: 'ବାର୍ଷିକ ପ୍ଲାନ୍',
      AppLanguage.assamese: 'বাৰ্ষিক প্লেন',
      AppLanguage.konkani: 'वर्सुकी प्लॅन',
      AppLanguage.nepali: 'वार्षिक योजना',
      AppLanguage.meitei: 'Yearly Plan',
      AppLanguage.mizo: 'Kum khat plan',
      AppLanguage.kashmiri: 'سالانہ پلان',
      AppLanguage.ladakhi: 'ལོ་རེའི་འཆར་གཞི།',
    },
    'Pay once and use poster sharing and downloads for the full year.': <AppLanguage, String>{
      AppLanguage.telugu: 'ఒకసారి చెల్లించి సంవత్సరం మొత్తం పోస్టర్ షేర్/డౌన్‌లోడ్ వాడండి.',
      AppLanguage.english: 'Pay once and use poster sharing and downloads for the full year.',
      AppLanguage.hindi: 'एक बार भुगतान करें और पूरे वर्ष पोस्टर शेयर और डाउनलोड का उपयोग करें।',
      AppLanguage.tamil: 'ஒரு முறை பணம் செலுத்தி ஆண்டு முழுவதும் போஸ்டர் பகிர்வு மற்றும் பதிவிறக்கங்களைப் பயன்படுத்துங்கள்.',
      AppLanguage.kannada: 'ಒಮ್ಮೆ ಪಾವತಿಸಿ ಮತ್ತು ಇಡೀ ವರ್ಷ ಪೋಸ್ಟರ್ ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್‌ಗಳನ್ನು ಬಳಸಿ.',
      AppLanguage.malayalam: 'ഒരു തവണ പണമടച്ച് വർഷം മുഴുവൻ പോസ്റ്റർ പങ്കിടലും ഡൗൺലോഡുകളും ഉപയോഗിക്കുക.',
      AppLanguage.marathi: 'एकदा पैसे द्या आणि संपूर्ण वर्षभर पोस्टर शेअर आणि डाउनलोड वापरा.',
      AppLanguage.gujarati: 'એકવાર ચૂકવો અને આખા વર્ષ માટે પોસ્ટર શેરિંગ અને ડાઉનલોડ્સનો ઉપયોગ કરો.',
      AppLanguage.bengali: 'একবার অর্থ প্রদান করুন এবং পুরো বছরের জন্য পোস্টার ভাগ করে নেওয়া এবং ডাউনলোড ব্যবহার করুন।',
      AppLanguage.punjabi: 'ਇੱਕ ਵਾਰ ਭੁਗਤਾਨ ਕਰੋ ਅਤੇ ਪੂਰੇ ਸਾਲ ਲਈ ਪੋਸਟਰ ਸਾਂਝਾਕਰਨ ਅਤੇ ਡਾਊਨਲੋਡ ਵਰਤੋ।',
      AppLanguage.odia: 'ଥରେ ପେମେଣ୍ଟ କରନ୍ତୁ ଏବଂ ପୂରା ବର୍ଷ ପୋଷ୍ଟର ସେୟାର୍ ଓ ଡାଉନଲୋଡ୍ ବ୍ୟବହାର କରନ୍ତୁ।',
      AppLanguage.assamese: 'এবাৰ পৰিশোধ কৰক আৰু সম্পূৰ্ণ বছৰৰ বাবে পোষ্টাৰ শ্বেয়াৰ আৰু ডাউনলোড ব্যৱহাৰ কৰক।',
      AppLanguage.konkani: 'एकदांच फारीक करात आनी वर्सभर पोस्टर शेअर आनी डाऊनलोड वापरात.',
      AppLanguage.nepali: 'एक पटक भुक्तानी गर्नुहोस् र पूरा वर्षको लागि पोस्टर साझेदारी र डाउनलोडहरू प्रयोग गर्नुहोस्।',
      AppLanguage.meitei: 'Amukta payment toubiyu amasung chahi chuppa poster share/download toubiyu.',
      AppLanguage.mizo: 'Vawi khat chawi la kum tluanin poster thawn leh download hmang rawh.',
      AppLanguage.kashmiri: 'اکھ لٹہٕ کٔریو ادا تہٕ پوٗرٕ وریہَس کٔریو پوسٹر شیئر تہٕ ڈاؤنلوڈ اِستعمال۔',
      AppLanguage.ladakhi: 'ཐེངས་གཅིག་དངུལ་སྤྲོད་ནས་ལོ་གཅིག་རིང་ poster share དང་ download བཀོལ་སྤྱོད་བྱོས།',
    },
    'Choose Yearly': <AppLanguage, String>{
      AppLanguage.telugu: 'సంవత్సర ప్లాన్ తీసుకోండి',
      AppLanguage.english: 'Choose Yearly',
      AppLanguage.hindi: 'वार्षिक चुनें',
      AppLanguage.tamil: 'வருடாந்திரத்தைத் தேர்வுசெய்',
      AppLanguage.kannada: 'ವಾರ್ಷಿಕ ಆಯ್ಕೆಮಾಡಿ',
      AppLanguage.malayalam: 'വാർഷികം തിരഞ്ഞെടുക്കുക',
      AppLanguage.marathi: 'वार्षिक निवडा',
      AppLanguage.gujarati: 'વાર્ષિક પસંદ કરો',
      AppLanguage.bengali: 'বার্ষিক বেছে নিন',
      AppLanguage.punjabi: 'ਸਾਲਾਨਾ ਚੁਣੋ',
      AppLanguage.odia: 'ବାର୍ଷିକ ବାଛନ୍ତୁ',
      AppLanguage.assamese: 'বাৰ্ষিক বাছক',
      AppLanguage.konkani: 'वर्सुकी निवडा',
      AppLanguage.nepali: 'वार्षिक छनौट गर्नुहोस्',
      AppLanguage.meitei: 'Yearly khanbiyu',
      AppLanguage.mizo: 'Kum khat thlang rawh',
      AppLanguage.kashmiri: 'سالانہ اِنتخاب کٔریو',
      AppLanguage.ladakhi: 'ལོ་རེ་གདམ་ཁ་བྱོས།',
    },
    'Premium editor tools for every design': <AppLanguage, String>{
      AppLanguage.telugu: 'ప్రతి డిజైన్‌కు ప్రీమియం ఎడిటర్ టూల్స్',
      AppLanguage.english: 'Premium editor tools for every design',
      AppLanguage.hindi: 'हर डिज़ाइन के लिए प्रीमियम संपादक उपकरण',
      AppLanguage.tamil: 'ஒவ்வொரு வடிவமைப்புக்கும் பிரீமியம் எடிட்டர் கருவிகள்',
      AppLanguage.kannada: 'ಪ್ರತಿ ವಿನ್ಯಾಸಕ್ಕೂ ಪ್ರೀಮಿಯಂ ಎಡಿಟರ್ ಪರಿಕರಗಳು',
      AppLanguage.malayalam: 'ഓരോ ഡിസൈനിനും പ്രീമിയം എഡിറ്റർ ടൂളുകൾ',
      AppLanguage.marathi: 'प्रत्येक डिझाइनसाठी प्रीमियम एडिटर टूल्स',
      AppLanguage.gujarati: 'દરેક ડિઝાઇન માટે પ્રીમિયમ એડિટર ટૂલ્સ',
      AppLanguage.bengali: 'প্রতিটি ডিজাইনের জন্য প্রিমিয়াম সম্পাদক সরঞ্জাম',
      AppLanguage.punjabi: 'ਹਰ ਡਿਜ਼ਾਈਨ ਲਈ ਪ੍ਰੀਮੀਅਮ ਐਡੀਟਰ ਟੂਲ',
      AppLanguage.odia: 'ପ୍ରତ୍ୟେକ ଡିଜାଇନ୍ ପାଇଁ ପ୍ରିମିୟମ୍ ଏଡିଟର୍ ଟୁଲ୍ସ',
      AppLanguage.assamese: 'প্ৰতিটো ডিজাইনৰ বাবে প্ৰিমিয়াম এডিটৰ সঁজুলি',
      AppLanguage.konkani: 'दर एका डिझायना खातीर प्रीमियम एडिटर साधनां',
      AppLanguage.nepali: 'प्रत्येक डिजाइनको लागि प्रिमियम सम्पादक उपकरणहरू',
      AppLanguage.meitei: 'Design khudingmakki premium editor tools',
      AppLanguage.mizo: 'Design tin tan premium editor hmanruate',
      AppLanguage.kashmiri: 'پرٛؠتھ ڈیزائنَس باپتھ پریمیم ایڈیٹر اوزار',
      AppLanguage.ladakhi: 'ཇུས་འགོད་རེ་རེར་ premium editor ལག་ཆ།',
    },
    'Restore': <AppLanguage, String>{
      AppLanguage.telugu: 'రిస్టోర్',
      AppLanguage.english: 'Restore',
      AppLanguage.hindi: 'पुनर्स्थापित करें',
      AppLanguage.tamil: 'மீட்டெடு',
      AppLanguage.kannada: 'ಮರುಸ್ಥಾಪಿಸಿ',
      AppLanguage.malayalam: 'പുനഃസ്ഥാപിക്കുക',
      AppLanguage.marathi: 'पुनर्संचयित करा',
      AppLanguage.gujarati: 'પુનઃસ્થાપિત કરો',
      AppLanguage.bengali: 'পুনরুদ্ধার',
      AppLanguage.punjabi: 'ਰੀਸਟੋਰ ਕਰੋ',
      AppLanguage.odia: 'ପୁନରୁଦ୍ଧାର',
      AppLanguage.assamese: 'পুনৰুদ্ধাৰ',
      AppLanguage.konkani: 'परत मेळयात',
      AppLanguage.nepali: 'पुनर्स्थापना',
      AppLanguage.meitei: 'Restore',
      AppLanguage.mizo: 'La let rawh',
      AppLanguage.kashmiri: 'ری سٹور',
      AppLanguage.ladakhi: 'ཕྱིར་གསོའི་བྱོས།',
    },
    'Trial': <AppLanguage, String>{
      AppLanguage.telugu: 'ట్రయల్',
      AppLanguage.english: 'Trial',
      AppLanguage.hindi: 'ट्रायल',
      AppLanguage.tamil: 'சோதனை',
      AppLanguage.kannada: 'ಪ್ರಯೋಗ',
      AppLanguage.malayalam: 'ട്രയൽ',
      AppLanguage.marathi: 'ट्रायल',
      AppLanguage.gujarati: 'ટ્રાયલ',
      AppLanguage.bengali: 'ট্রায়াল',
      AppLanguage.punjabi: 'ਟਰਾਇਲ',
      AppLanguage.odia: 'ଟ୍ରାଏଲ୍',
      AppLanguage.assamese: 'ট্ৰায়েল',
      AppLanguage.konkani: 'ट्रायल',
      AppLanguage.nepali: 'परीक्षण',
      AppLanguage.meitei: 'Trial',
      AppLanguage.mizo: 'Chhinna',
      AppLanguage.kashmiri: 'ٹرائل',
      AppLanguage.ladakhi: 'ཚོད་ལྟ།',
    },
  };

  String _t({
    required String telugu,
    required String english,
    String? hindi,
    String? tamil,
    String? kannada,
    String? malayalam,
    String? assamese,
    String? konkani,
    String? gujarati,
    String? marathi,
    String? meitei,
    String? mizo,
    String? odia,
    String? punjabi,
    String? nepali,
    String? bengali,
    String? kashmiri,
    String? ladakhi,
  }) {
    if (_isEditorPlan) {
      return english;
    }
    final dict = _subDictionary[english];
    return _strings.localized(
      telugu: telugu,
      english: english,
      hindi: hindi ?? dict?[AppLanguage.hindi],
      tamil: tamil ?? dict?[AppLanguage.tamil],
      kannada: kannada ?? dict?[AppLanguage.kannada],
      malayalam: malayalam ?? dict?[AppLanguage.malayalam],
      assamese: assamese ?? dict?[AppLanguage.assamese],
      konkani: konkani ?? dict?[AppLanguage.konkani],
      gujarati: gujarati ?? dict?[AppLanguage.gujarati],
      marathi: marathi ?? dict?[AppLanguage.marathi],
      meitei: meitei ?? dict?[AppLanguage.meitei],
      mizo: mizo ?? dict?[AppLanguage.mizo],
      odia: odia ?? dict?[AppLanguage.odia],
      punjabi: punjabi ?? dict?[AppLanguage.punjabi],
      nepali: nepali ?? dict?[AppLanguage.nepali],
      bengali: bengali ?? dict?[AppLanguage.bengali],
      kashmiri: kashmiri ?? dict?[AppLanguage.kashmiri],
      ladakhi: ladakhi ?? dict?[AppLanguage.ladakhi],
    );
  }

  String get _monthlyPriceLabel {
    final price = _selectedProduct?.price.trim() ?? '';
    return price.isNotEmpty ? price : _monthlyFallbackPrice;
  }

  String get _trialPriceLabel => SubscriptionPlanConfig.trialPriceDisplay;

  int get _trialDays => SubscriptionPlanConfig.trialDays;

  String get _yearlyPriceLabel => '$_yearlyFallbackPrice / year';

  String get _alreadyActiveLabel => _t(
    telugu: 'ఇప్పటికే యాక్టివ్',
    english: 'Already Active',
    hindi: 'पहले से सक्रिय',
    tamil: 'ஏற்கனவே செயலில் உள்ளது',
    kannada: 'ಈಗಾಗಲೇ ಸಕ್ರಿಯವಾಗಿದೆ',
    malayalam: 'ഇതിനകം ആക്റ്റീവാണ്',
  );

  // ignore: unused_element
  String get _appPlanDetailsTitle => _t(
    telugu: 'మీ ప్లాన్ వివరాలు',
    english: 'Your plan details',
    hindi: 'आपके प्लान विवरण',
    tamil: 'உங்கள் திட்ட விவரங்கள்',
    kannada: 'ನಿಮ್ಮ ಯೋಜನೆಯ ವಿವರಗಳು',
    malayalam: 'നിങ്ങളുടെ പ്ലാൻ വിവരങ്ങൾ',
  );

  String get _appProTitle => _t(
    telugu: 'App Pro',
    english: 'App Pro',
    hindi: 'App Pro',
    tamil: 'App Pro',
    kannada: 'App Pro',
    malayalam: 'App Pro',
  );

  String get _appPlanTitleClean => _t(
    telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్',
    english: 'Subscription Plan',
    hindi: 'सब्सक्रिप्शन प्लान',
    tamil: 'சந்தா திட்டம்',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ',
    malayalam: 'സബ്സ്ക്രിപ്ഷൻ പ്ലാൻ',
    assamese: 'চাবস্ক্ৰিপচন প্লেন',
    konkani: 'सदस्यता प्लॅन',
    gujarati: 'સબ્સ્ક્રિપ્શન પ્લાન',
    marathi: 'सबस्क्रिप्शन प्लॅन',
    meitei: 'Subscription plan',
    mizo: 'Subscription plan',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ପ୍ଲାନ୍',
    punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਪਲਾਨ',
    nepali: 'सब्स्क्रिप्सन प्लान',
    bengali: 'সাবস্ক্রিপশন প্ল্যান',
    kashmiri: 'سبسکرپشن پلان',
    ladakhi: 'Subscription plan',
  );

  String get _appPlanSubtitleClean => _t(
    telugu:
        '$_trialPriceLabel ట్రయల్‌తో ప్రారంభించి పోస్టర్ షేర్/డౌన్‌లోడ్ అన్‌లాక్ చేయండి.',
    english:
        'Start with a $_trialPriceLabel trial and unlock poster sharing and downloads.',
    hindi:
        '$_trialPriceLabel ट्रायल से शुरू करें और पोस्टर शेयर/डाउनलोड अनलॉक करें।',
    tamil:
        '$_trialPriceLabel சோதனையுடன் தொடங்கி போஸ்டர் பகிர்வு/பதிவிறக்கத்தை திறக்கவும்.',
    kannada:
        '$_trialPriceLabel ಟ್ರಯಲ್‌ನಿಂದ ಪ್ರಾರಂಭಿಸಿ ಪೋಸ್ಟರ್ ಹಂಚಿಕೆ/ಡೌನ್‌ಲೋಡ್ ಅನ್‌ಲಾಕ್ ಮಾಡಿ.',
    malayalam:
        '$_trialPriceLabel ട്രയലോടെ തുടങ്ങി പോസ്റ്റർ ഷെയർ/ഡൗൺലോഡ് അൺലോക്ക് ചെയ്യുക.',
    assamese:
        '$_trialPriceLabel ট্রায়েলৰে আৰম্ভ কৰি পোষ্টাৰ শ্বেয়াৰ/ডাউনলোড আনলক কৰক।',
    konkani:
        '$_trialPriceLabel ट्रायलान सुरू करून पोस्टर शेयर/डाउनलोड अनलॉक करात.',
    gujarati:
        '$_trialPriceLabel ટ્રાયલથી શરૂ કરો અને પોસ્ટર શેર/ડાઉનલોડ અનલૉક કરો.',
    marathi:
        '$_trialPriceLabel ट्रायलने सुरू करा आणि पोस्टर शेअर/डाउनलोड अनलॉक करा.',
    meitei:
        '$_trialPriceLabel trial dagi houro, poster share/download unlock tou.',
    mizo:
        '$_trialPriceLabel trial-in tan la, poster share/download unlock rawh.',
    odia:
        '$_trialPriceLabel ଟ୍ରାୟାଲ୍ ସହିତ ଆରମ୍ଭ କରି ପୋଷ୍ଟର ଶେୟାର/ଡାଉନଲୋଡ୍ ଅନଲକ୍ କରନ୍ତୁ।',
    punjabi:
        '$_trialPriceLabel ਟ੍ਰਾਇਲ ਨਾਲ ਸ਼ੁਰੂ ਕਰੋ ਅਤੇ ਪੋਸਟਰ ਸ਼ੇਅਰ/ਡਾਊਨਲੋਡ ਅਨਲੌਕ ਕਰੋ।',
    nepali:
        '$_trialPriceLabel ट्रायलबाट सुरु गर्नुहोस् र पोस्टर शेयर/डाउनलोड अनलक गर्नुहोस्।',
    bengali:
        '$_trialPriceLabel ট্রায়াল দিয়ে শুরু করুন এবং পোস্টার শেয়ার/ডাউনলোড আনলক করুন।',
    kashmiri:
        '$_trialPriceLabel ٹرائل سٲتھ شروع کٔریو تہ پوسٹر شیئر/ڈاؤنلوڈ ان لاک کٔریو۔',
    ladakhi:
        '$_trialPriceLabel trial nas gojug in, poster share/download unlock chog.',
  );

  String get _trialOfferBodyClean => _t(
    telugu:
        'ఈ ప్లాన్ $_trialPriceLabel తో $_trialDays రోజుల ట్రయల్‌గా ప్రారంభమవుతుంది. ఈ సమయంలో మీరు రద్దు చేయవచ్చు.',
    english:
        'The plan starts with a $_trialPriceLabel trial for $_trialDays days. You can cancel within this period.',
    hindi:
        'यह प्लान $_trialPriceLabel में $_trialDays दिन के ट्रायल से शुरू होता है। इस अवधि में आप रद्द कर सकते हैं।',
    tamil:
        'இந்த திட்டம் $_trialPriceLabel க்கு $_trialDays நாள் சோதனையாக தொடங்கும். இந்த காலத்தில் நீங்கள் ரத்து செய்யலாம்.',
    kannada:
        'ಈ ಯೋಜನೆ $_trialPriceLabel ಗೆ $_trialDays ದಿನಗಳ ಟ್ರಯಲ್ ಆಗಿ ಆರಂಭವಾಗುತ್ತದೆ. ಈ ಅವಧಿಯಲ್ಲಿ ನೀವು ರದ್ದು ಮಾಡಬಹುದು.',
    malayalam:
        'ഈ പ്ലാൻ $_trialPriceLabel ന് $_trialDays ദിവസത്തെ ട്രയലായി തുടങ്ങും. ഈ സമയത്ത് നിങ്ങൾക്ക് റദ്ദാക്കാം.',
    assamese:
        'এই প্লেনটো $_trialPriceLabel ত $_trialDays দিনৰ ট্রায়েল হিচাপে আৰম্ভ হয়। এই সময়ত আপুনি বাতিল কৰিব পাৰে।',
    konkani:
        'हो प्लॅन $_trialPriceLabel न $_trialDays दिसांच्या ट्रायलान सुरू जाता. ह्या काळांत तुमी रद्द करूंक शकतात.',
    gujarati:
        'આ પ્લાન $_trialPriceLabel માં $_trialDays દિવસની ટ્રાયલ તરીકે શરૂ થાય છે. આ સમયગાળા દરમિયાન તમે રદ કરી શકો છો.',
    marathi:
        'हा प्लॅन $_trialPriceLabel मध्ये $_trialDays दिवसांच्या ट्रायलने सुरू होतो. या काळात तुम्ही रद्द करू शकता.',
    meitei:
        'Plan asi $_trialPriceLabel da $_trialDays numit trial oina houri. Masigi matamda cancel touba yai.',
    mizo:
        'He plan hi $_trialPriceLabel-a $_trialDays ni trial-in a tan. He hun chhung hian cancel theih a ni.',
    odia:
        'ଏହି ପ୍ଲାନ୍ $_trialPriceLabel ରେ $_trialDays ଦିନର ଟ୍ରାୟାଲ୍ ଭାବେ ଆରମ୍ଭ ହୁଏ। ଏହି ସମୟରେ ଆପଣ ରଦ୍ଦ କରିପାରିବେ।',
    punjabi:
        'ਇਹ ਪਲਾਨ $_trialPriceLabel ਨਾਲ $_trialDays ਦਿਨਾਂ ਦੀ ਟ੍ਰਾਇਲ ਵਜੋਂ ਸ਼ੁਰੂ ਹੁੰਦਾ ਹੈ। ਇਸ ਸਮੇਂ ਵਿੱਚ ਤੁਸੀਂ ਰੱਦ ਕਰ ਸਕਦੇ ਹੋ।',
    nepali:
        'यो प्लान $_trialPriceLabel मा $_trialDays दिनको ट्रायलबाट सुरु हुन्छ। यो अवधिमा तपाईं रद्द गर्न सक्नुहुन्छ।',
    bengali:
        'এই প্ল্যানটি $_trialPriceLabel দিয়ে $_trialDays দিনের ট্রায়াল হিসেবে শুরু হয়। এই সময়ে আপনি বাতিল করতে পারেন।',
    kashmiri:
        'یہ پلان $_trialPriceLabel منز $_trialDays دوہہ ٹرائل سٲتھ شروع گژھان چھ۔ امی مدت منز توہیہ منسوخ کٔرتھ ہیکیو۔',
    ladakhi:
        'Plan di $_trialPriceLabel la $_trialDays nyin trial nang gojug in. Di dus la cancel chog.',
  );

  String get _appProSimpleBenefitClean => _t(
    telugu: 'ఫోటో మరియు పేరుతో పోస్టర్లు షేర్, డౌన్‌లోడ్ చేసుకోవచ్చు',
    english: 'Share and download posters with photo and name',
    hindi: 'फोटो और नाम के साथ पोस्टर शेयर और डाउनलोड करें',
    tamil: 'புகைப்படம் மற்றும் பெயருடன் போஸ்டர்களை பகிர்ந்து பதிவிறக்கலாம்',
    kannada: 'ಫೋಟೋ ಮತ್ತು ಹೆಸರಿನೊಂದಿಗೆ ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಿ, ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ',
    malayalam: 'ഫോട്ടോയും പേരും ചേർത്ത് പോസ്റ്ററുകൾ ഷെയർ/ഡൗൺലോഡ് ചെയ്യാം',
    assamese: 'ফটো আৰু নামৰ সৈতে পোষ্টাৰ শ্বেয়াৰ আৰু ডাউনলোড কৰক',
    konkani: 'फोटो आनी नांवासयत पोस्टर शेयर आनी डाउनलोड करात',
    gujarati: 'ફોટો અને નામ સાથે પોસ્ટર શેર અને ડાઉનલોડ કરો',
    marathi: 'फोटो आणि नावासह पोस्टर शेअर आणि डाउनलोड करा',
    meitei: 'Photo amasung mingga poster share/download tou',
    mizo: 'Photo leh hming nen poster share/download rawh',
    odia: 'ଫଟୋ ଏବଂ ନାମ ସହିତ ପୋଷ୍ଟର ଶେୟାର ଓ ଡାଉନଲୋଡ୍ କରନ୍ତୁ',
    punjabi: 'ਫੋਟੋ ਅਤੇ ਨਾਮ ਨਾਲ ਪੋਸਟਰ ਸ਼ੇਅਰ ਅਤੇ ਡਾਊਨਲੋਡ ਕਰੋ',
    nepali: 'फोटो र नामसहित पोस्टर शेयर र डाउनलोड गर्नुहोस्',
    bengali: 'ছবি ও নামসহ পোস্টার শেয়ার এবং ডাউনলোড করুন',
    kashmiri: 'فوٹو تہ ناو سٲتھ پوسٹر شیئر تہ ڈاؤنلوڈ کٔریو',
    ladakhi: 'Photo dang ming che poster share/download chog',
  );

  String get _appProTrialPriceLabelClean => _t(
    telugu: '₹4 / 3 రోజులు, తర్వాత $_monthlyPriceLabel / నెల',
    english: '₹4 / 3 days, then $_monthlyPriceLabel / month',
    hindi: '₹4 / 3 दिन, फिर $_monthlyPriceLabel / माह',
    tamil: '₹4 / 3 நாட்கள், பிறகு $_monthlyPriceLabel / மாதம்',
    kannada: '₹4 / 3 ದಿನಗಳು, ನಂತರ $_monthlyPriceLabel / ತಿಂಗಳು',
    malayalam: '₹4 / 3 ദിവസം, ശേഷം $_monthlyPriceLabel / മാസം',
    assamese: '₹4 / 3 দিন, তাৰ পিছত $_monthlyPriceLabel / মাহ',
    konkani: '₹4 / 3 दिस, मागीर $_monthlyPriceLabel / म्हयनो',
    gujarati: '₹4 / 3 દિવસ, પછી $_monthlyPriceLabel / મહિનો',
    marathi: '₹4 / 3 दिवस, नंतर $_monthlyPriceLabel / महिना',
    meitei: '₹4 / 3 numit, adugi matungda $_monthlyPriceLabel / tha',
    mizo: '₹4 / 3 ni, chutah $_monthlyPriceLabel / thla',
    odia: '₹4 / 3 ଦିନ, ପରେ $_monthlyPriceLabel / ମାସ',
    punjabi: '₹4 / 3 ਦਿਨ, ਫਿਰ $_monthlyPriceLabel / ਮਹੀਨਾ',
    nepali: '₹4 / 3 दिन, त्यसपछि $_monthlyPriceLabel / महिना',
    bengali: '₹4 / 3 দিন, তারপর $_monthlyPriceLabel / মাস',
    kashmiri: '₹4 / 3 دوہہ، پتہ $_monthlyPriceLabel / مہینہ',
    ladakhi: '₹4 / 3 nyin, dena $_monthlyPriceLabel / month',
  );

  String get _plansAutoRenewNoticeClean => _t(
    telugu:
        'ప్లాన్ ఆటో-రిన్యూ అవుతుంది. Play Store లో ఎప్పుడైనా రద్దు చేయవచ్చు.',
    english: 'Plans auto-renew. Cancel anytime in Play Store.',
    hindi: 'प्लान ऑटो-रिन्यू होता है। Play Store में कभी भी रद्द कर सकते हैं।',
    tamil:
        'திட்டம் தானாக புதுப்பிக்கும். Play Store-ல் எப்போது வேண்டுமானாலும் ரத்து செய்யலாம்.',
    kannada:
        'ಯೋಜನೆ ಸ್ವಯಂ ನವೀಕರಿಸುತ್ತದೆ. Play Store ನಲ್ಲಿ ಯಾವಾಗ ಬೇಕಾದರೂ ರದ್ದು ಮಾಡಬಹುದು.',
    malayalam:
        'പ്ലാൻ ഓട്ടോ-റിന്യൂ ചെയ്യും. Play Store-ൽ എപ്പോൾ വേണമെങ്കിലും റദ്ദാക്കാം.',
    assamese: 'প্লেন অটো-ৰিনিউ হয়। Play Store ত যিকোনো সময়ত বাতিল কৰিব পাৰে।',
    konkani: 'प्लॅन ऑटो-रिन्यू जाता. Play Storeांत केन्नाय रद्द करूंक शकतात.',
    gujarati:
        'પ્લાન ઓટો-રિન્યુ થાય છે. Play Store માં ક્યારે પણ રદ કરી શકો છો.',
    marathi: 'प्लॅन ऑटो-रिन्यू होतो. Play Store मध्ये कधीही रद्द करू शकता.',
    meitei:
        'Plan auto-renew tougani. Play Store da matam pumnamakta cancel touba yai.',
    mizo:
        'Plan chu auto-renew a ni. Play Store-ah engtik lai pawhin cancel theih.',
    odia: 'ପ୍ଲାନ୍ ଅଟୋ-ରିନ୍ୟୁ ହୁଏ। Play Store ରେ କେବେବି ରଦ୍ଦ କରିପାରିବେ।',
    punjabi: 'ਪਲਾਨ ਆਟੋ-ਰੀਨਿਊ ਹੁੰਦਾ ਹੈ। Play Store ਵਿੱਚ ਕਦੇ ਵੀ ਰੱਦ ਕਰ ਸਕਦੇ ਹੋ।',
    nepali:
        'प्लान अटो-रिन्यू हुन्छ। Play Store मा जुनसुकै बेला रद्द गर्न सकिन्छ।',
    bengali:
        'প্ল্যান অটো-রিনিউ হয়। Play Store-এ যেকোনো সময় বাতিল করতে পারবেন।',
    kashmiri:
        'پلان آٹو رینیو گژھان چھ۔ Play Store منز کنہِ وقت منسوخ کٔرتھ ہیکیو۔',
    ladakhi: 'Plan auto-renew in. Play Store la nam yang cancel chog.',
  );

  String get _subscribeAppProLabelClean => _t(
    telugu: 'App Pro సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe App Pro',
    hindi: 'App Pro सब्सक्राइब करें',
    tamil: 'App Pro சந்தா எடுக்கவும்',
    kannada: 'App Pro ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'App Pro സബ്സ്ക്രൈബ് ചെയ്യുക',
    assamese: 'App Pro চাবস্ক্ৰাইব কৰক',
    konkani: 'App Pro सदस्यता घेवप',
    gujarati: 'App Pro સબ્સ્ક્રાઇબ કરો',
    marathi: 'App Pro सबस्क्राइब करा',
    meitei: 'App Pro subscribe tou',
    mizo: 'App Pro subscribe rawh',
    odia: 'App Pro ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
    punjabi: 'App Pro ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ',
    nepali: 'App Pro सब्स्क्राइब गर्नुहोस्',
    bengali: 'App Pro সাবস্ক্রাইব করুন',
    kashmiri: 'App Pro سبسکرائب کٔریو',
    ladakhi: 'App Pro subscribe chog',
  );

  String get _unlockPosterFeaturesClean => _t(
    telugu: 'పోస్టర్ షేర్ మరియు డౌన్‌లోడ్ ఫీచర్లు అన్‌లాక్ అవుతాయి.',
    english: 'Unlock poster share and download features.',
    hindi: 'पोस्टर शेयर और डाउनलोड फीचर अनलॉक होंगे।',
    tamil: 'போஸ்டர் பகிர்வு மற்றும் பதிவிறக்க அம்சங்கள் திறக்கும்.',
    kannada: 'ಪೋಸ್ಟರ್ ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್ ವೈಶಿಷ್ಟ್ಯಗಳು ಅನ್‌ಲಾಕ್ ಆಗುತ್ತವೆ.',
    malayalam: 'പോസ്റ്റർ ഷെയർ, ഡൗൺലോഡ് ഫീച്ചറുകൾ അൺലോക്ക് ചെയ്യും.',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ আৰু ডাউনলোড ফিচাৰ আনলক হ’ব।',
    konkani: 'पोस्टर शेयर आनी डाउनलोड सुविधा अनलॉक जातली.',
    gujarati: 'પોસ્ટર શેર અને ડાઉનલોડ ફીચર અનલૉક થશે.',
    marathi: 'पोस्टर शेअर आणि डाउनलोड फीचर्स अनलॉक होतील.',
    meitei: 'Poster share amasung download feature unlock tougani.',
    mizo: 'Poster share leh download feature unlock a ni ang.',
    odia: 'ପୋଷ୍ଟର ଶେୟାର ଏବଂ ଡାଉନଲୋଡ୍ ଫିଚର୍ ଅନଲକ୍ ହେବ।',
    punjabi: 'ਪੋਸਟਰ ਸ਼ੇਅਰ ਅਤੇ ਡਾਊਨਲੋਡ ਫੀਚਰ ਅਨਲੌਕ ਹੋਣਗੇ।',
    nepali: 'पोस्टर शेयर र डाउनलोड फिचर अनलक हुन्छन्।',
    bengali: 'পোস্টার শেয়ার ও ডাউনলোড ফিচার আনলক হবে।',
    kashmiri: 'پوسٹر شیئر تہ ڈاؤنلوڈ فیچر ان لاک گژھن۔',
    ladakhi: 'Poster share dang download feature unlock jung.',
  );

  String get _afterTrialRenewalClean => _t(
    telugu:
        '$_trialDays రోజుల తర్వాత ప్లాన్ $_monthlyPriceLabel / నెలగా ఆటో-రిన్యూ అవుతుంది.',
    english:
        'After $_trialDays days, the plan auto-renews at $_monthlyPriceLabel per month.',
    hindi:
        '$_trialDays दिन के बाद प्लान $_monthlyPriceLabel प्रति माह पर ऑटो-रिन्यू होगा।',
    tamil:
        '$_trialDays நாட்களுக்கு பிறகு திட்டம் மாதத்திற்கு $_monthlyPriceLabel ஆக தானாக புதுப்பிக்கும்.',
    kannada:
        '$_trialDays ದಿನಗಳ ನಂತರ ಯೋಜನೆ ತಿಂಗಳಿಗೆ $_monthlyPriceLabel ಆಗಿ ಸ್ವಯಂ ನವೀಕರಿಸುತ್ತದೆ.',
    malayalam:
        '$_trialDays ദിവസത്തിന് ശേഷം പ്ലാൻ മാസം $_monthlyPriceLabel ആയി ഓട്ടോ-റിന്യൂ ചെയ്യും.',
    assamese:
        '$_trialDays দিনৰ পিছত প্লেনটো মাহে $_monthlyPriceLabel ত অটো-ৰিনিউ হ’ব।',
    konkani:
        '$_trialDays दिसां उपरांत प्लॅन म्हयन्याक $_monthlyPriceLabel न ऑटो-रिन्यू जातलो.',
    gujarati:
        '$_trialDays દિવસ પછી પ્લાન દર મહિને $_monthlyPriceLabel પર ઓટો-રિન્યુ થશે.',
    marathi:
        '$_trialDays दिवसांनंतर प्लॅन $_monthlyPriceLabel प्रति महिना ऑटो-रिन्यू होईल.',
    meitei:
        '$_trialDays numit matungda plan asi $_monthlyPriceLabel / tha auto-renew tougani.',
    mizo:
        '$_trialDays ni hnuah plan chu thla tin $_monthlyPriceLabel-a auto-renew a ni ang.',
    odia:
        '$_trialDays ଦିନ ପରେ ପ୍ଲାନ୍ ପ୍ରତି ମାସ $_monthlyPriceLabel ରେ ଅଟୋ-ରିନ୍ୟୁ ହେବ।',
    punjabi:
        '$_trialDays ਦਿਨਾਂ ਬਾਅਦ ਪਲਾਨ $_monthlyPriceLabel ਪ੍ਰਤੀ ਮਹੀਨਾ ਆਟੋ-ਰੀਨਿਊ ਹੋਵੇਗਾ।',
    nepali:
        '$_trialDays दिनपछि प्लान $_monthlyPriceLabel प्रति महिना अटो-रिन्यू हुन्छ।',
    bengali:
        '$_trialDays দিন পরে প্ল্যানটি প্রতি মাসে $_monthlyPriceLabel হিসেবে অটো-রিনিউ হবে।',
    kashmiri:
        '$_trialDays دوہہ پتہ پلان $_monthlyPriceLabel فی مہینہ آٹو رینیو گژھ۔',
    ladakhi:
        '$_trialDays nyin nas plan $_monthlyPriceLabel / month auto-renew jung.',
  );

  String get _cancelTrialClean => _t(
    telugu: 'నెలసరి ఛార్జ్ రాకుండా $_trialDays రోజుల్లో రద్దు చేయవచ్చు.',
    english: 'Cancel within $_trialDays days to avoid the monthly charge.',
    hindi: 'मासिक शुल्क से बचने के लिए $_trialDays दिन में रद्द कर सकते हैं।',
    tamil: 'மாத கட்டணத்தை தவிர்க்க $_trialDays நாட்களில் ரத்து செய்யலாம்.',
    kannada: 'ಮಾಸಿಕ ಶುಲ್ಕ ತಪ್ಪಿಸಲು $_trialDays ದಿನಗಳಲ್ಲಿ ರದ್ದು ಮಾಡಬಹುದು.',
    malayalam: 'മാസ ചാർജ് ഒഴിവാക്കാൻ $_trialDays ദിവസത്തിനുള്ളിൽ റദ്ദാക്കാം.',
    assamese: 'মাহেকীয়া চার্জ এৰাবলৈ $_trialDays দিনৰ ভিতৰত বাতিল কৰিব পাৰে।',
    konkani: 'म्हयन्याच्या शुल्का पासून वाचपाक $_trialDays दिसांत रद्द करात.',
    gujarati: 'માસિક ચાર્જથી બચવા માટે $_trialDays દિવસમાં રદ કરી શકો છો.',
    marathi: 'मासिक शुल्क टाळण्यासाठी $_trialDays दिवसांत रद्द करू शकता.',
    meitei:
        'Tha khudinggi charge leitaba $_trialDays numit manungda cancel touba yai.',
    mizo: 'Thla tin charge pumpelh nan $_trialDays ni chhungin cancel rawh.',
    odia: 'ମାସିକ ଚାର୍ଜ ଏଡାଇବାକୁ $_trialDays ଦିନ ମଧ୍ୟରେ ରଦ୍ଦ କରିପାରିବେ।',
    punjabi: 'ਮਾਸਿਕ ਚਾਰਜ ਤੋਂ ਬਚਣ ਲਈ $_trialDays ਦਿਨਾਂ ਵਿੱਚ ਰੱਦ ਕਰ ਸਕਦੇ ਹੋ।',
    nepali: 'मासिक शुल्कबाट बच्न $_trialDays दिनभित्र रद्द गर्न सक्नुहुन्छ।',
    bengali: 'মাসিক চার্জ এড়াতে $_trialDays দিনের মধ্যে বাতিল করতে পারবেন।',
    kashmiri:
        'ماہانہ چارج بچاونہ خٲطرہ $_trialDays دوہن اندر منسوخ کٔرتھ ہیکیو۔',
    ladakhi: 'Monthly charge skyabse $_trialDays nyin nang cancel chog.',
  );

  String get _noEditorAssetsClean => _t(
    telugu: 'ఈ ప్లాన్‌లో ప్రీమియం ఎడిటర్ ఆస్తులు లేదా తెలుగు ఫాంట్లు ఉండవు.',
    english:
        'This plan does not include premium editor assets or Telugu fonts.',
    hindi: 'इस प्लान में प्रीमियम एडिटर एसेट्स या तेलुगु फॉन्ट शामिल नहीं हैं।',
    tamil:
        'இந்த திட்டத்தில் பிரீமியம் எடிட்டர் ஆஸெட்டுகள் அல்லது தெலுங்கு எழுத்துருக்கள் இல்லை.',
    kannada:
        'ಈ ಯೋಜನೆಯಲ್ಲಿ ಪ್ರೀಮಿಯಂ ಎಡಿಟರ್ ಆಸ್ತಿಗಳು ಅಥವಾ ತೆಲುಗು ಫಾಂಟ್‌ಗಳು ಇಲ್ಲ.',
    malayalam: 'ഈ പ്ലാനിൽ പ്രീമിയം എഡിറ്റർ ആസെറ്റുകളോ തെലുങ്ക് ഫോണ്ടുകളോ ഇല്ല.',
    assamese:
        'এই প্লেনত প্ৰিমিয়াম এডিটৰ এচেট বা তেলুগু ফণ্ট অন্তৰ্ভুক্ত নহয়।',
    konkani: 'ह्या प्लॅनांत premium editor assets वा Telugu fonts आसपाव नात.',
    gujarati: 'આ પ્લાનમાં પ્રીમિયમ એડિટર એસેટ્સ અથવા તેલુગુ ફૉન્ટ્સ સામેલ નથી.',
    marathi:
        'या प्लॅनमध्ये प्रीमियम एडिटर अ‍ॅसेट्स किंवा तेलुगू फॉन्ट्स नाहीत.',
    meitei: 'Plan asida premium editor assets nattraga Telugu fonts yaode.',
    mizo: 'He plan-ah premium editor assets emaw Telugu fonts a tel lo.',
    odia: 'ଏହି ପ୍ଲାନ୍‌ରେ ପ୍ରିମିୟମ୍ ଏଡିଟର୍ ଆସେଟ୍ କିମ୍ବା ତେଲୁଗୁ ଫଣ୍ଟ୍ ନାହିଁ।',
    punjabi: 'ਇਸ ਪਲਾਨ ਵਿੱਚ ਪ੍ਰੀਮੀਅਮ ਐਡੀਟਰ ਐਸੈਟ ਜਾਂ ਤੇਲਗੂ ਫੌਂਟ ਸ਼ਾਮਲ ਨਹੀਂ ਹਨ।',
    nepali: 'यो प्लानमा प्रिमियम एडिटर एसेट वा तेलुगु फन्ट समावेश छैन।',
    bengali: 'এই প্ল্যানে প্রিমিয়াম এডিটর অ্যাসেট বা তেলুগু ফন্ট নেই।',
    kashmiri: 'امس پلان منز پریمیم ایڈیٹر اثاثہ یا تیلگو فونٹ شامل چھنہ۔',
    ladakhi: 'Di plan nang premium editor assets yangna Telugu fonts med.',
  );

  String get _restorePurchasedPlanClean => _t(
    telugu: 'కొనుగోలు చేసిన ప్లాన్ కనిపించకపోతే రీస్టోర్ చేయండి.',
    english: 'Restore if a purchased plan is not showing.',
    hindi: 'खरीदा हुआ प्लान नहीं दिखे तो रिस्टोर करें।',
    tamil: 'வாங்கிய திட்டம் தெரியவில்லை என்றால் மீட்டெடுக்கவும்.',
    kannada: 'ಖರೀದಿಸಿದ ಯೋಜನೆ ಕಾಣಿಸದಿದ್ದರೆ ರಿಸ್ಟೋರ್ ಮಾಡಿ.',
    malayalam: 'വാങ്ങിയ പ്ലാൻ കാണുന്നില്ലെങ്കിൽ റിസ്റ്റോർ ചെയ്യുക.',
    assamese: 'ক্ৰয় কৰা প্লেন দেখা নাযায় যদি ৰিষ্ট’ৰ কৰক।',
    konkani: 'घेतिल्लो प्लॅन दिसना जाल्यार restore करात.',
    gujarati: 'ખરીદેલો પ્લાન ન દેખાય તો રિસ્ટોર કરો.',
    marathi: 'खरेदी केलेला प्लॅन दिसत नसेल तर रिस्टोर करा.',
    meitei: 'Leiraba plan udrabadi restore tou.',
    mizo: 'Plan lei tawh a lang loh chuan restore rawh.',
    odia: 'କିଣାଯାଇଥିବା ପ୍ଲାନ୍ ଦେଖାନଥିଲେ ରିଷ୍ଟୋର୍ କରନ୍ତୁ।',
    punjabi: 'ਖਰੀਦਿਆ ਪਲਾਨ ਨਾ ਦਿਖੇ ਤਾਂ ਰੀਸਟੋਰ ਕਰੋ।',
    nepali: 'किनेको प्लान नदेखिए रिस्टोर गर्नुहोस्।',
    bengali: 'কেনা প্ল্যান না দেখালে রিস্টোর করুন।',
    kashmiri: 'خرید کرنہ آمت پلان نہ ہاونہ صورتس منز ریسٹور کٔریو۔',
    ladakhi: 'Nyospa plan mathong na restore chog.',
  );

  String get _editorProTitle => _t(
    telugu: 'Editor Pro',
    english: 'Editor Pro',
    hindi: 'Editor Pro',
    tamil: 'Editor Pro',
    kannada: 'Editor Pro',
    malayalam: 'Editor Pro',
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
        marathi:
            'Editor Pro दरमहा ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} आहे. All Access प्रति वर्ष ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} असून त्यात App Pro + Editor Pro दोन्ही समाविष्ट आहेत. Subscription auto-renew होते व Play Store मध्ये कधीही रद्द केले जाऊ शकते.',
        gujarati:
            'Editor Pro દર મહિને ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} છે. All Access વાર્ષિક ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} છે જેમાં App Pro + Editor Pro બંને શામેલ છે. Subscription auto-renew થાય છે અને Play Store માં ગમે ત્યારે રદ કરી શકાય છે.',
        bengali:
            'Editor Pro প্রতি মাসে ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}। All Access প্রতি বছর ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} এবং এতে App Pro + Editor Pro উভয়ই অন্তর্ভুক্ত। Subscription auto-renew হয় এবং Play Store-এ যেকোনো সময় বাতিল করা যেতে পারে।',
        punjabi:
            'Editor Pro ਪ੍ਰਤੀ ਮਹੀਨਾ ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} ਹੈ। All Access ਸਾਲਾਨਾ ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} ਹੈ ਜਿਸ ਵਿੱਚ App Pro + Editor Pro ਦੋਵੇਂ ਸ਼ਾਮਲ ਹਨ। Subscription auto-renew ਹੁੰਦੀ ਹੈ ਅਤੇ Play Store ਵਿੱਚ ਕਦੇ ਵੀ ਰੱਦ ਕੀਤੀ ਜਾ ਸਕਦੀ ਹੈ।',
        odia:
            'Editor Pro ମାସିକ ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}। All Access ବାର୍ଷିକ ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} ଏବଂ ଏଥିରେ App Pro + Editor Pro ଉଭୟ ଅନ୍ତର୍ଭୁକ୍ତ। Subscription auto-renew ହୁଏ ଏବଂ Play Store ରେ ଯେକୌଣସି ସମୟରେ ରଦ୍ଦ କରାଯାଇପାରେ।',
        assamese:
            'Editor Pro প্ৰতিমাহে ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}। All Access প্ৰতি বছৰে ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} য’ত App Pro + Editor Pro দুয়োটা অন্তৰ্ভুক্ত। Subscription auto-renew হয় আৰু Play Store-ত যিকোনো সময়তে বাতিল কৰিব পাৰি।',
        konkani:
            'Editor Pro दर म्हयन्याक ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}. All Access वर्साक ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} आनी तातूंत App Pro + Editor Pro दोनूय आसात. Subscription auto-renew जाता आनी Play Store चेर केन्नाय रद्द करूं येता.',
        nepali:
            'Editor Pro प्रति महिना ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} हो। All Access प्रति वर्ष ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} हो जसमा App Pro + Editor Pro दुवै समावेश छन्। Subscription auto-renew हुन्छ र Play Store मा जुनसुकै बेला रद्द गर्न सकिन्छ।',
        meitei:
            'Editor Pro thada ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} ni. All Access chahida ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} ni aduga App Pro + Editor Pro animak yaori. Subscription auto-renew tou-i amasung Play Store da cancel touba yai.',
        mizo:
            'Editor Pro thla khatah ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} a ni. All Access kum khatah ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} a ni a, App Pro + Editor Pro a tel ve ve. Subscription auto-renew a ni a, Play Store-ah cancel theih reng a ni.',
        kashmiri:
            'Editor Pro چھُ ماہانہ ${EditorSubscriptionPlanConfig.monthlyPriceDisplay}۔ All Access چھُ سالانہ ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} یَتھ منز App Pro + Editor Pro دۄشوے شٲمِل چھِ۔ Subscription چھِ auto-renew گژھان تہٕ Play Store منز ہیکیو کُنہِ تہِ وقتہٕ cancel کٔرِتھ۔',
        ladakhi:
            'Editor Pro ཟླ་རེར་ ${EditorSubscriptionPlanConfig.monthlyPriceDisplay} ཡིན། All Access ལོ་རེར་ ${EditorSubscriptionPlanConfig.yearlyPriceDisplay} ཡིན་ཞིང་ App Pro + Editor Pro གཉིས་ཀ་ཚུད་ཡོད། Subscription auto-renew འགྱུར་ཞིང་ Play Store ནང་ནམ་ཡང་ cancel བྱེད་ཆོག',
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
    return <Widget>[
      _PlanChoiceCard(
        title: _appProTitle,
        subtitle: _appProSimpleBenefitClean,
        price: _appProTrialPriceLabelClean,
        details: const <String>[],
        buttonLabel: _isSubscriptionActive
            ? _alreadyActiveLabel
            : _subscribeAppProLabelClean,
        busy: _busyFree,
        enabled: _canSubscribe,
        accent: const Color(0xFF1D4ED8),
        onTap: () => unawaited(_subscribeFreePlan()),
      ),
      const SizedBox(height: 10),
      _PlanChoiceCard(
        title: _t(
          telugu: 'సంవత్సర ప్లాన్',
          english: 'Yearly Plan',
          hindi: 'Yearly Plan',
          tamil: 'Yearly Plan',
          kannada: 'Yearly Plan',
          malayalam: 'Yearly Plan',
        ),
        subtitle: _t(
          telugu:
              'ఒకసారి చెల్లించి సంవత్సరం మొత్తం పోస్టర్ షేర్/డౌన్‌లోడ్ వాడండి.',
          english:
              'Pay once and use poster sharing and downloads for the full year.',
          hindi:
              'Pay once and use poster sharing and downloads for the full year.',
          tamil:
              'Pay once and use poster sharing and downloads for the full year.',
          kannada:
              'Pay once and use poster sharing and downloads for the full year.',
          malayalam:
              'Pay once and use poster sharing and downloads for the full year.',
        ),
        price: _yearlyPriceLabel,
        details: const <String>[],
        buttonLabel: _isSubscriptionActive
            ? _alreadyActiveLabel
            : _t(
                telugu: 'సంవత్సర ప్లాన్ తీసుకోండి',
                english: 'Choose Yearly',
                hindi: 'Choose Yearly',
                tamil: 'Choose Yearly',
                kannada: 'Choose Yearly',
                malayalam: 'Choose Yearly',
              ),
        busy: _busyYearly,
        enabled: _canSubscribe,
        accent: const Color(0xFF047857),
        onTap: () => unawaited(_subscribeYearlyPlan()),
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
      _trialOfferBodyClean,
      _unlockPosterFeaturesClean,
      _afterTrialRenewalClean,
      _cancelTrialClean,
      _noEditorAssetsClean,
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
            physics: isEditorPlan
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isEditorPlan ? 20 : 16,
              isEditorPlan ? 8 : 0,
              isEditorPlan ? 20 : 16,
              isEditorPlan ? 26 : 12,
            ),
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
                          color: const Color(
                            0xFFFACC15,
                          ).withValues(alpha: 0.14),
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
                          _t(
                            telugu: 'ప్రతి డిజైన్‌కు ప్రీమియం ఎడిటర్ టూల్స్',
                            english: 'Premium editor tools for every design',
                            hindi: 'हर डिजाइन के लिए प्रीमियम एडिटर टूल्स',
                            tamil:
                                'ஒவ்வொரு டிசைனுக்கும் பிரீமியம் எடிட்டர் கருவிகள்',
                            kannada:
                                'ಪ್ರತಿ ವಿನ್ಯಾಸಕ್ಕೂ ಪ್ರೀಮಿಯಂ ಎಡಿಟರ್ ಟೂಲ್‌ಗಳು',
                            malayalam: 'ഓരോ ഡിസൈനിനും പ്രീമിയം എഡിറ്റർ ടൂളുകൾ',
                          ),
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
                isEditorPlan ? _editorProTitle : _appPlanTitleClean,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ).copyWith(color: titleColor, fontSize: isEditorPlan ? 27 : 23),
              ),
              SizedBox(height: isEditorPlan ? 8 : 5),
              Text(
                isEditorPlan ? _editorPlanHeroSubtitle : _appPlanSubtitleClean,
                style:
                    const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ).copyWith(
                      color: subtitleColor,
                      fontSize: isEditorPlan ? 14.5 : 13,
                    ),
              ),
              SizedBox(height: isEditorPlan ? 16 : 10),
              _SubscriptionStatusCard(
                label: _subscriptionStatusLabel(),
                helper: _statusLine(),
                startLine: _subscriptionStartLine(),
                expiryLine: _subscriptionExpiryLine(),
                statusColor: _statusColor,
                backgroundColor: _statusBackgroundColor,
                borderColor: _statusBorderColor,
              ),
              SizedBox(height: isEditorPlan ? 14 : 10),
              ..._buildPlanCards(planDetails),
              SizedBox(height: isEditorPlan ? 14 : 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
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
                        _restorePurchasedPlanClean,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12.5,
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
              SizedBox(height: isEditorPlan ? 12 : 8),
              Container(
                padding: EdgeInsets.all(isEditorPlan ? 14 : 10),
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
                        isEditorPlan
                            ? _billingNoticeText
                            : _plansAutoRenewNoticeClean,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.28,
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

// ignore: unused_element
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
              marathi: 'ट्रायल',
              gujarati: 'ટ્રાયલ',
              bengali: 'ট্রায়াল',
              punjabi: 'ਟਰਾਇਲ',
              odia: 'ଟ୍ରାଏଲ୍',
              assamese: 'ট্ৰায়েল',
              konkani: 'ट्रायल',
              nepali: 'परीक्षण',
              meitei: 'Trial',
              mizo: 'Chhinna',
              kashmiri: 'ٹرائل',
              ladakhi: 'ཚོད་ལྟ།',
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
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF2563EB),
            Color(0xFF9333EA),
            Color(0xFFEC4899),
            Color(0xFFF59E0B),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    price,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 12.8,
                height: 1.22,
              ),
            ),
            if (details.isNotEmpty) const SizedBox(height: 12),
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
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
