import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:mana_poster/app/config/subscription_plan_config.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/navigation/app_navigator.dart';
import 'package:mana_poster/features/image_editor/services/pro_purchase_gateway.dart';
import 'package:mana_poster/features/image_editor/services/subscription_backend_service.dart';

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
    with AppLanguageStateMixin {
  final SubscriptionBackendService _backendService =
      SubscriptionBackendService();
  final ProPurchaseGateway _freePlanGateway = InAppPurchaseGateway(
    productId: SubscriptionPlanConfig.primaryMonthlyProductId,
    fallbackProductIds: const <String>[
      SubscriptionPlanConfig.primaryMonthlyProductId,
    ],
  );
  final ProPurchaseGateway _restoreGateway = InAppPurchaseGateway(
    productId: SubscriptionPlanConfig.primaryMonthlyProductId,
    fallbackProductIds: <String>[
      SubscriptionPlanConfig.primaryMonthlyProductId,
    ],
  );

  SubscriptionBackendResult? _backendResult;
  ProductDetails? _selectedProduct;
  bool _loading = true;
  bool _busyFree = false;
  bool _busyRestore = false;
  bool _didAutoStartPurchase = false;
  bool _didAutoTriggerRestore = false;
  bool _didAttemptSilentStoreSync = false;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  bool get _isBusy => _loading || _busyFree || _busyRestore;
  bool get _isSubscriptionActive => _backendResult?.isActive == true;
  bool get _isSubscriptionExpired => _backendResult?.isExpired == true;
  bool get _canSubscribe => !_isSubscriptionActive;

  @override
  void initState() {
    super.initState();
    unawaited(_freePlanGateway.initialize());
    unawaited(_restoreGateway.initialize());
    SubscriptionBackendService.entitlementNotifier.addListener(
      _handleEntitlementChanged,
    );
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    SubscriptionBackendService.entitlementNotifier.removeListener(
      _handleEntitlementChanged,
    );
    super.dispose();
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
    final product = await _loadStoreProduct();
    final result = await _backendService.fetchFreshEntitlement();
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
    if (!_isSubscriptionActive && !_didAttemptSilentStoreSync) {
      _didAttemptSilentStoreSync = true;
      unawaited(_syncExistingSubscriptionSilently());
    }
    if (widget.triggerRestoreOnOpen && !_didAutoTriggerRestore) {
      _didAutoTriggerRestore = true;
      unawaited(_restoreSubscriptions());
      return;
    }
    if (widget.startPurchaseOnOpen && !_didAutoStartPurchase && _canSubscribe) {
      _didAutoStartPurchase = true;
      unawaited(_subscribeFreePlan());
    }
  }

  Future<void> _syncExistingSubscriptionSilently() async {
    final outcome = await _restoreGateway.restorePurchases();
    if (!mounted) {
      return;
    }
    final evidence = outcome.evidence;
    if (outcome.result == PurchaseFlowResult.success && evidence != null) {
      final verifyResult = await _verifyPurchaseWithRetry(evidence);
      if (!mounted) {
        return;
      }
      if (verifyResult.isSuccess) {
        await evidence.completeStorePurchase();
        await _refreshEntitlementAfterRestore();
      }
      return;
    }
    if (outcome.result == PurchaseFlowResult.nothingToRestore) {
      final fallback = await _backendService.fetchFreshEntitlement();
      if (!mounted) {
        return;
      }
      if (fallback.isSuccess) {
        setState(() => _backendResult = fallback);
      }
    }
  }

  Future<ProductDetails?> _loadStoreProduct() async {
    try {
      final store = InAppPurchase.instance;
      final available = await store.isAvailable();
      if (!available) {
        return null;
      }
      const envProductId = String.fromEnvironment(
        'MANA_POSTER_PRO_PRODUCT_ID',
        defaultValue: '',
      );
      final ids = <String>{
        SubscriptionPlanConfig.primaryMonthlyProductId,
        if (envProductId.isNotEmpty) envProductId,
      };
      final response = await store.queryProductDetails(ids);
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

  Future<void> _subscribeFreePlan() async {
    if (_isBusy || !_canSubscribe) {
      return;
    }
    setState(() => _busyFree = true);
    try {
      final outcome = await _freePlanGateway.purchaseMonthlyPro();
      if (outcome.result != PurchaseFlowResult.success) {
        await _syncExistingSubscriptionSilently();
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

  Future<void> _restoreSubscriptions() async {
    if (_isBusy) {
      return;
    }
    setState(() => _busyRestore = true);
    try {
      final outcome = await _restoreGateway.restorePurchases();
      if (outcome.result == PurchaseFlowResult.nothingToRestore) {
        final fallback = await _backendService.fetchFreshEntitlementWithRetry();
        if (!mounted) {
          return;
        }
        if (fallback.isActive) {
          await _refreshEntitlementAfterRestore();
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
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
      await outcome.evidence?.completeStorePurchase();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      await _refreshEntitlementAfterRestore();
      return true;
    }

    final evidence = outcome.evidence;
    if (evidence == null) {
      messenger.showSnackBar(
        SnackBar(
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

    if (!verifyResult.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
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
      messenger.showSnackBar(
        SnackBar(
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
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
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
      if (lastResult.isSuccess) {
        return lastResult;
      }
    }
    return lastResult ??
        const SubscriptionBackendResult(
          state: SubscriptionBackendState.failed,
          message: 'Subscription verification failed',
        );
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
    final formatted = _formatDate(expiryDate);
    return _t(
      telugu: 'గడువు ముగిసే తేదీ: $formatted',
      english: 'Expires on: $formatted',
      hindi: 'समाप्ति तिथि: $formatted',
      tamil: 'காலாவதி தேதி: $formatted',
      kannada: 'ಅವಧಿ ಮುಗಿಯುವ ದಿನಾಂಕ: $formatted',
      malayalam: 'കാലാവധി തീരുന്ന തീയതി: $formatted',
    );
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
    return context.strings.localized(
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
    return price.isNotEmpty
        ? price
        : SubscriptionPlanConfig.monthlyPriceDisplay;
  }

  String get _trialPriceLabel => SubscriptionPlanConfig.trialPriceDisplay;

  int get _trialDays => SubscriptionPlanConfig.trialDays;

  String get _trialOfferTitle => _t(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '$_trialDays-day trial plan',
    hindi: '3-दिन ट्रायल प्लान',
    tamil: '3 நாள் சோதனை திட்டம்',
    kannada: '3 ದಿನಗಳ ಟ್ರಯಲ್ ಪ್ಲಾನ್',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
  );

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

  @override
  Widget build(BuildContext context) {
    final List<String> planDetails = <String>[
      _trialOfferBody,
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
      if (_subscriptionStartLine() != null) _subscriptionStartLine()!,
      if (_subscriptionExpiryLine() != null) _subscriptionExpiryLine()!,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF4F46E5), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x224F46E5),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _t(
                        telugu: 'షేర్ & డౌన్‌లోడ్ అన్‌లాక్',
                        english: 'Unlock share & download',
                        hindi: 'शेयर और डाउनलोड अनलॉक करें',
                        tamil: 'பகிர்வு மற்றும் பதிவிறக்கம் திறக்கவும்',
                        kannada: 'ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್ ಅನ್ಲಾಕ್ ಮಾಡಿ',
                        malayalam: 'ഷെയറും ഡൗൺലോഡും അൺലോക്ക് ചെയ്യുക',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t(
                      telugu: 'సబ్‌స్క్రిప్షన్ ప్లాన్',
                      english: 'Subscription Plan',
                      hindi: 'सब्सक्रिप्शन प्लान',
                      tamil: 'சந்தா திட்டம்',
                      kannada: 'ಚಂದಾದಾರಿಕೆ ಯೋಜನೆ',
                      malayalam: 'സബ്സ്ക്രിപ്ഷൻ പ്ലാൻ',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t(
                      telugu:
                          'రూ.4 తో 3 రోజుల ట్రయల్ ప్రారంభించి పోస్టర్ షేరింగ్ మరియు డౌన్‌లోడ్‌ను వెంటనే అన్‌లాక్ చేయండి.',
                      english:
                          'Start with a $_trialPriceLabel trial for $_trialDays days and instantly unlock poster sharing and downloads.',
                      hindi:
                          'Rs.4 के 3-दिन ट्रायल से शुरू करें और तुरंत पोस्टर शेयर और डाउनलोड अनलॉक करें।',
                      tamil:
                          'Rs.4 க்கு 3 நாள் சோதனையுடன் தொடங்கி போஸ்டர் பகிர்வு மற்றும் பதிவிறக்கத்தை உடனே திறக்கவும்.',
                      kannada:
                          'Rs.4 ಗೆ 3 ದಿನಗಳ ಟ್ರಯಲ್‌ನೊಂದಿಗೆ ಆರಂಭಿಸಿ ಪೋಸ್ಟರ್ ಹಂಚಿಕೆ ಮತ್ತು ಡೌನ್‌ಲೋಡ್ ಅನ್ನು ತಕ್ಷಣ ಅನ್ಲಾಕ್ ಮಾಡಿ.',
                      malayalam:
                          'Rs.4 ന് 3 ദിവസത്തെ ട്രയലോടെ ആരംഭിച്ച് പോസ്റ്റർ ഷെയറും ഡൗൺലോഡും ഉടൻ അൺലോക്ക് ചെയ്യൂ.',
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _PlanHighlightChip(
                        icon: Icons.bolt_rounded,
                        label: _trialOfferTitle,
                      ),
                      _PlanHighlightChip(
                        icon: Icons.calendar_month_rounded,
                        label: _t(
                          telugu: 'నెలకు $_monthlyPriceLabel',
                          english: '$_monthlyPriceLabel per month',
                          hindi: '$_monthlyPriceLabel प्रति माह',
                          tamil: 'மாதத்திற்கு $_monthlyPriceLabel',
                          kannada: 'ತಿಂಗಳಿಗೆ $_monthlyPriceLabel',
                          malayalam: 'മാസം $_monthlyPriceLabel',
                        ),
                      ),
                      _PlanHighlightChip(
                        icon: Icons.autorenew_rounded,
                        label: _t(
                          telugu: 'ఆటో రిన్యువల్',
                          english: 'Auto-renewal',
                          hindi: 'ऑटो-रिन्यूअल',
                          tamil: 'தானியங்கி புதுப்பிப்பு',
                          kannada: 'ಸ್ವಯಂ ನವೀಕರಣ',
                          malayalam: 'ഓട്ടോ റിന്യൂവൽ',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SubscriptionStatusCard(
              label: _subscriptionStatusLabel(),
              helper: _statusLine(),
              startLine: _subscriptionStartLine(),
              expiryLine: _subscriptionExpiryLine(),
              statusColor: _statusColor,
              backgroundColor: _statusBackgroundColor,
              borderColor: _statusBorderColor,
            ),
            const SizedBox(height: 18),
            _PlanSection(
              title: _t(
                telugu: 'మీ ప్లాన్ వివరాలు',
                english: 'Your plan details',
                hindi: 'आपके प्लान की जानकारी',
                tamil: 'உங்கள் திட்ட விவரங்கள்',
                kannada: 'ನಿಮ್ಮ ಯೋಜನೆ ವಿವರಗಳು',
                malayalam: 'നിങ്ങളുടെ പ്ലാൻ വിവരങ്ങൾ',
              ),
              details: planDetails,
              buttonLabel: _t(
                telugu: _isSubscriptionActive
                    ? 'ఇప్పటికే యాక్టివ్'
                    : 'ఇప్పుడే సబ్‌స్క్రైబ్ చేయండి',
                english: _isSubscriptionActive
                    ? 'Already Active'
                    : 'Subscribe now',
                hindi: _isSubscriptionActive
                    ? 'पहले से सक्रिय'
                    : 'अभी सब्सक्राइब करें',
                tamil: _isSubscriptionActive
                    ? 'ஏற்கனவே செயலிலுள்ளது'
                    : 'இப்போது சந்தா செய்யவும்',
                kannada: _isSubscriptionActive
                    ? 'ಈಗಾಗಲೇ ಸಕ್ರಿಯ'
                    : 'ಈಗಲೇ ಚಂದಾದಾರರಾಗಿ',
                malayalam: _isSubscriptionActive
                    ? 'ഇതിനകം സജീവം'
                    : 'ഇപ്പോൾ സബ്സ്ക്രൈബ് ചെയ്യൂ',
              ),
              onTap: _subscribeFreePlan,
              busy: _busyFree,
              accent: const Color(0xFF1D4ED8),
              enabled: _canSubscribe,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restore_rounded,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _t(
                            telugu:
                                'వెరిఫై అయిన సబ్‌స్క్రిప్షన్ స్థితిని రిఫ్రెష్ చేయడానికి రిస్టోర్ చేయండి',
                            english:
                                'Restore to refresh your verified subscription status',
                            hindi:
                                'सत्यापित सब्सक्रिप्शन स्थिति रीफ्रेश करने के लिए रिस्टोर करें',
                            tamil:
                                'உறுதிப்படுத்தப்பட்ட சந்தா நிலையை புதுப்பிக்க மீட்டெடுக்கவும்',
                            kannada:
                                'ಪರಿಶೀಲಿತ ಚಂದಾದಾರಿಕೆ ಸ್ಥಿತಿಯನ್ನು ರಿಫ್ರೆಶ್ ಮಾಡಲು ಮರುಸ್ಥಾಪಿಸಿ',
                            malayalam:
                                'സ്ഥിരീകരിച്ച സബ്സ്ക്രിപ്ഷൻ നില പുതുക്കാൻ റിസ്റ്റോർ ചെയ്യുക',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busyRestore ? null : _restoreSubscriptions,
                      icon: _busyRestore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.history_rounded),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFD6DCE8)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      label: Text(
                        _t(
                          telugu: 'సబ్‌స్క్రిప్షన్లు రిస్టోర్ చేయండి',
                          english: 'Restore subscriptions',
                          hindi: 'सब्सक्रिप्शन बहाल करें',
                          tamil: 'சந்தாக்களை மீட்டெடுக்கவும்',
                          kannada: 'ಚಂದಾದಾರಿಕೆಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಿ',
                          malayalam: 'സബ്സ്ക്രിപ്ഷനുകൾ പുനഃസ്ഥാപിക്കുക',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(22),
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
                      _t(
                        telugu:
                            '3 రోజుల ట్రయల్ తర్వాత మీరు unsubscribe లేదా cancel చేయకపోతే ప్లాన్ నెలకు $_monthlyPriceLabel తో ఆటో రిన్యువల్ అవుతుంది. 3 రోజుల్లో రద్దు చేస్తే నెలసరి ఛార్జ్ వర్తించదు. ప్రస్తుతం ఉన్న ప్లాన్ గడువు ముగిసే వరకు ప్రయోజనాలు కొనసాగుతాయి.',
                        english:
                            'After the 3-day trial, the plan auto-renews at $_monthlyPriceLabel per month unless you unsubscribe or cancel. If you cancel within 3 days, the monthly charge does not apply. Benefits continue until the current plan expires.',
                        hindi:
                            '3-दिन ट्रायल के बाद, यदि आप अनसब्सक्राइब या रद्द नहीं करते हैं तो प्लान $_monthlyPriceLabel प्रति माह पर ऑटो-रिन्यू होगा। 3 दिनों के भीतर रद्द करने पर मासिक शुल्क लागू नहीं होगा। वर्तमान प्लान समाप्त होने तक लाभ जारी रहेंगे।',
                        tamil:
                            '3 நாள் சோதனைக்குப் பிறகு, நீங்கள் ரத்து செய்யாவிட்டால் திட்டம் $_monthlyPriceLabel மாதத்திற்கு தானாக புதுப்பிக்கும். 3 நாட்களுக்குள் ரத்து செய்தால் மாதாந்திர கட்டணம் வசூலிக்கப்படாது. தற்போதைய திட்டம் முடியும் வரை நன்மைகள் தொடரும்.',
                        kannada:
                            '3 ದಿನಗಳ ಟ್ರಯಲ್ ನಂತರ ನೀವು unsubscribe ಅಥವಾ cancel ಮಾಡದಿದ್ದರೆ ಯೋಜನೆ $_monthlyPriceLabel ಪ್ರತಿ ತಿಂಗಳು ಸ್ವಯಂ ನವೀಕರಿಸುತ್ತದೆ. 3 ದಿನಗಳ ಒಳಗೆ ರದ್ದುಗೊಳಿಸಿದರೆ ಮಾಸಿಕ ಶುಲ್ಕ ಅನ್ವಯಿಸುವುದಿಲ್ಲ. ಪ್ರಸ್ತುತ ಯೋಜನೆ ಮುಗಿಯುವವರೆಗೆ ಪ್ರಯೋಜನಗಳು ಮುಂದುವರೆಯುತ್ತವೆ.',
                        malayalam:
                            '3 ദിവസത്തെ ട്രയലിന് ശേഷം നിങ്ങൾ unsubscribe ചെയ്യുകയോ cancel ചെയ്യുകയോ ഇല്ലെങ്കിൽ പ്ലാൻ $_monthlyPriceLabel മാസത്തിൽ ഓട്ടോ റിന്യൂവാകും. 3 ദിവസത്തിനുള്ളിൽ റദ്ദാക്കിയാൽ മാസചെലവ് ബാധകമല്ല. നിലവിലെ പ്ലാൻ അവസാനിക്കുന്നതുവരെ ആനുകൂല്യങ്ങൾ തുടരും.',
                      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
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
          if (startLine != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              startLine!,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (expiryLine != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              expiryLine!,
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
    required this.buttonLabel,
    required this.onTap,
    required this.busy,
    required this.accent,
    required this.enabled,
  });

  final String title;
  final List<String> details;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool busy;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color bulletAccent = enabled ? accent : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
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
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          ...details.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _PriceBadge(
                    title: context.strings.localized(
                      telugu: 'ట్రయల్',
                      english: 'Trial',
                      hindi: 'ट्रायल',
                      tamil: 'சோதனை',
                      kannada: 'ಟ್ರಯಲ್',
                      malayalam: 'ട്രയൽ',
                    ),
                    value: SubscriptionPlanConfig.trialValueDisplay,
                    accent: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PriceBadge(
                    title: context.strings.localized(
                      telugu: 'నెలసరి',
                      english: 'Monthly',
                      hindi: 'मासिक',
                      tamil: 'மாதாந்திரம்',
                      kannada: 'ಮಾಸಿಕ',
                      malayalam: 'മാസാന്ത്യം',
                    ),
                    value: SubscriptionPlanConfig.monthlyPriceDisplay,
                    accent: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy || !enabled ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor: enabled ? accent : const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                disabledForegroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
        ],
      ),
    );
  }
}

class _PlanHighlightChip extends StatelessWidget {
  const _PlanHighlightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
