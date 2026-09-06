import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';

class RegionSelectionScreen extends StatefulWidget {
  const RegionSelectionScreen({super.key, this.returnToPreviousOnSave = false});

  final bool returnToPreviousOnSave;

  @override
  State<RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen>
    with AppLanguageStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _savingRegionId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectRegion(AppRegion region) async {
    if (_savingRegionId != null) {
      return;
    }
    setState(() => _savingRegionId = region.id);
    final saved = await AppRegionService.persistSelection(region);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _savingRegionId = null);
      ScaffoldMessenger.of(context).showTopSnackBar(
        AppSnackBar.build(
          content: Text(
            context.strings.localized(
              telugu: 'రాష్ట్రం సేవ్ కాలేదు. దయచేసి మళ్లీ ప్రయత్నించండి.',
              english: 'Could not save region. Please try again.',
              hindi: 'क्षेत्र सहेजा नहीं जा सका। कृपया पुन: प्रयास करें।',
              tamil: 'பிராந்தியத்தைச் சேமிக்க முடியவில்லை. மீண்டும் முயல்க.',
              kannada: 'ಪ್ರದೇಶವನ್ನು ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam: 'പ്രദേശം സംരക്ഷിക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കുക.',
              marathi: 'प्रदेश जतन करता आला नाही. कृपया पुन्हा प्रयत्न करा.',
              gujarati: 'પ્રદેશ સાચવી શકાયો નથી. કૃપા કરીને ફરી પ્રયાસ કરો.',
              bengali: 'অঞ্চল সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
              punjabi: 'ਖੇਤਰ ਸੁਰੱਖਿਅਤ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
              odia: 'ଅଞ୍ଚଳ ସଂରକ୍ଷଣ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
              assamese: 'অঞ্চল সংৰক্ষণ কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
              konkani: 'प्रदेश सांबाळपाक जमलो ना. उपकार करून परत प्रयत्न करात.',
              nepali: 'क्षेत्र सुरक्षित गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
              meitei: 'Region save touba ngamkhide. Amuk hanna hotnabiyu.',
              mizo: 'Bial save thei lo. Khawngaihin ti nawn leh rawh.',
              kashmiri: 'علاقہ ہیکہِ نہٕ محفوٗظ کٔرِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
              ladakhi: 'ས་ཁུལ་ཉར་ཚགས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
            ),
          ),
        ),
      );
      return;
    }
    unawaited(NotificationService.instance.syncCurrentPreferences());
    if (widget.returnToPreviousOnSave) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.appLanguage,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final regions = appRegions
        .where((region) => region.matches(_query))
        .toList(growable: false);
    final stateCount = appRegions
        .where((item) => item.type == AppRegionType.state)
        .length;
    final unionTerritoryCount = appRegions.length - stateCount;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;
                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 72, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: _RegionHeader(
                            stateCount: stateCount,
                            unionTerritoryCount: unionTerritoryCount,
                            controller: _searchController,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          math.max(20, viewportHeight * 0.04),
                        ),
                        sliver: regions.isEmpty
                            ? const SliverToBoxAdapter(child: _EmptyRegions())
                            : SliverList.separated(
                                itemCount: regions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final region = regions[index];
                                  return _RegionTile(
                                    region: region,
                                    loading: _savingRegionId == region.id,
                                    disabled: _savingRegionId != null,
                                    onTap: () =>
                                        unawaited(_selectRegion(region)),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 0,
            child: SafeArea(child: AppScreenBackButton()),
          ),
        ],
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({
    required this.stateCount,
    required this.unionTerritoryCount,
    required this.controller,
  });

  final int stateCount;
  final int unionTerritoryCount;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = context.strings;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.localized(
                          telugu: 'రాష్ట్రం / యూనియన్ టెరిటరీ ఎంచుకోండి',
                          english: 'Select State / Union Territory',
                          hindi: 'राज्य / केंद्र शासित प्रदेश चुनें',
                          tamil: 'மாநிலம் / யூனியன் பிரதேசத்தைத் தேர்ந்தெடுக்கவும்',
                          kannada: 'ರಾಜ್ಯ / ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
                          malayalam: 'സംസ്ഥാനം / കേന്ദ്രഭരണ പ്രദേശം തിരഞ്ഞെടുക്കുക',
                          marathi: 'राज्य / केंद्रशासित प्रदेश निवडा',
                          gujarati: 'રાજ્ય / કેન્દ્રશાસિત પ્રદેશ પસંદ કરો',
                          bengali: 'রাজ্য / কেন্দ্রশাসিত অঞ্চল নির্বাচন করুন',
                          punjabi: 'ਰਾਜ / ਕੇਂਦਰ ਸ਼ਾਸਤ ਪ੍ਰਦੇਸ਼ ਚੁਣੋ',
                          odia: 'ରାଜ୍ୟ / କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ ବାଛନ୍ତୁ',
                          assamese: 'ৰাজ্য / কেন্দ্ৰীয় শাসিত অঞ্চল বাছক',
                          konkani: 'राज्य / केंद्रशासित प्रदेश वेंचून काडात',
                          nepali: 'राज्य / केन्द्र शासित प्रदेश छान्नुहोस्',
                          meitei: 'State / Union Territory khallu',
                          mizo: 'State / Union Territory thlang rawh',
                          kashmiri: 'ریاست / یونین ٹیریٹری ژٲریو',
                          ladakhi: 'མངའ་སྡེའམ་དབུས་གཞུང་ཁུལ་འདེམས།',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.localized(
                          telugu:
                              '$stateCount రాష్ట్రాలు • $unionTerritoryCount యూనియన్ టెరిటరీలు',
                          english:
                              '$stateCount States • $unionTerritoryCount Union Territories',
                          hindi:
                              '$stateCount राज्य • $unionTerritoryCount केंद्र शासित प्रदेश',
                          tamil:
                              '$stateCount மாநிலங்கள் • $unionTerritoryCount யூனியன் பிரதேசங்கள்',
                          kannada:
                              '$stateCount ರಾಜ್ಯಗಳು • $unionTerritoryCount ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶಗಳು',
                          malayalam:
                              '$stateCount സംസ്ഥാനങ്ങൾ • $unionTerritoryCount കേന്ദ്രഭരണ പ്രദേശങ്ങൾ',
                          marathi:
                              '$stateCount राज्ये • $unionTerritoryCount केंद्रशासित प्रदेश',
                          gujarati:
                              '$stateCount રાજ્યો • $unionTerritoryCount કેન્દ્રશાસિત પ્રદેશો',
                          bengali:
                              '$stateCount রাজ্য • $unionTerritoryCount কেন্দ্রশাসিত অঞ্চল',
                          punjabi:
                              '$stateCount ਰਾਜ • $unionTerritoryCount ਕੇਂਦਰ ਸ਼ਾਸਤ ਪ੍ਰਦੇਸ਼',
                          odia:
                              '$stateCount ରାଜ୍ୟ • $unionTerritoryCount କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ',
                          assamese:
                              '$stateCount ৰাজ্য • $unionTerritoryCount কেন্দ্ৰীয় শাসিত অঞ্চল',
                          konkani:
                              '$stateCount राज्यां • $unionTerritoryCount केंद्रशासित प्रदेश',
                          nepali:
                              '$stateCount राज्यहरू • $unionTerritoryCount केन्द्र शासित प्रदेशहरू',
                          meitei:
                              '$stateCount States • $unionTerritoryCount Union Territories',
                          mizo:
                              '$stateCount State-te • $unionTerritoryCount Union Territory-te',
                          kashmiri:
                              '$stateCount ریاستہٕ • $unionTerritoryCount یونین ٹیریٹری',
                          ladakhi:
                              '$stateCount མངའ་སྡེ། • $unionTerritoryCount དབུས་གཞུང་ཁུལ།',
                        ),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.localized(
                  telugu: 'రాష్ట్రం, యూటీ లేదా భాష వెతకండి',
                  english: 'Search State, UT or language',
                  hindi: 'राज्य, केंद्र शासित प्रदेश या भाषा खोजें',
                  tamil: 'மாநிலம், யூனியன் பிரதேசம் அல்லது மொழியைத் தேடவும்',
                  kannada: 'ರಾಜ್ಯ, ಕೇಂದ್ರಾಡಳಿತ ಪ್ರದೇಶ ಅಥವಾ ಭಾಷೆ ಹುಡುಕಿ',
                  malayalam: 'സംസ്ഥാനം, കേന്ദ്രഭരണ ప్రദേശം അല്ലെങ്കിൽ ഭാഷ തിരയുക',
                  marathi: 'राज्य, केंद्रशासित प्रदेश किंवा भाषा शोधा',
                  gujarati: 'રાજ્ય, કેન્દ્રશાસિત પ્રદેશ અથવા ભાષા શોધો',
                  bengali: 'রাজ্য, কেন্দ্রশাসিত অঞ্চল বা ভাষা অনুসন্ধান করুন',
                  punjabi: 'ਰਾਜ, ਕੇਂਦਰ ਸ਼ਾਸਤ ਪ੍ਰਦੇਸ਼ ਜਾਂ ਭਾਸ਼ਾ ਖੋਜੋ',
                  odia: 'ରାଜ୍ୟ, କେନ୍ଦ୍ରଶାସିତ ଅଞ୍ଚଳ କିମ୍ବା ଭାଷା ଖୋଜନ୍ତୁ',
                  assamese: 'ৰাজ্য, কেন্দ্ৰীয় শাসিত অঞ্চল বা ভাষা সন্ধান কৰক',
                  konkani: 'राज्य, केंद्रशासित प्रदेश वा भास सोदात',
                  nepali: 'राज्य, केन्द्र शासित प्रदेश वा भाषा खोज्नुहोस्',
                  meitei: 'State, UT nattraga Lon thiba',
                  mizo: 'State, UT emaw ṭawng zawng rawh',
                  kashmiri: 'ریاست، یونین ٹیریٹری یا زبٲن ژھانٛڈیو',
                  ladakhi: 'མངའ་སྡེ་དང་སྐད་རིགས་འཚོལ།',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final AppRegion region;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _regionColor(region);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    region.logoAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        region.nativeName.characters.first,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      region.nativeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      region.nativePrimaryLanguage,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRegions extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        strings.localized(
          telugu: 'సరిపోయే ప్రాంతం లేదు.',
          english: 'No matching region found.',
          hindi: 'कोई मिलता-जुलता क्षेत्र नहीं मिला।',
          tamil: 'பொருந்தும் பிராந்தியம் எதுவும் காணப்படவில்லை.',
          kannada: 'ಯಾವುದೇ ಹೊಂದಾಣಿಕೆಯ ಪ್ರದೇಶ ಕಂಡುಬಂದಿಲ್ಲ.',
          malayalam: 'പൊരുത്തപ്പെടുന്ന പ്രദേശമൊന്നും കണ്ടെത്തിയില്ല.',
          marathi: 'जुळणारा प्रदेश आढळला नाही.',
          gujarati: 'કોઈ મેળ ખાતો પ્રદેશ મળ્યો નથી.',
          bengali: 'কোনো মিল থাকা অঞ্চল পাওয়া যায়নি।',
          punjabi: 'ਕੋਈ ਮੇਲ ਖਾਂਦਾ ਖੇਤਰ ਨਹੀਂ ਮਿਲਿਆ।',
          odia: 'କୌଣସି ମେଳ ଖାଉଥିବା ଅଞ୍ଚଳ ମିଳିଲା ନାହିଁ।',
          assamese: 'কোনো মিল থকা অঞ্চল পোৱা নগ’ল।',
          konkani: 'लागसारचो खंयचोच प्रदेश मेळ्ळो ना.',
          nepali: 'कुनै मिल्दो क्षेत्र फेला परेन।',
          meitei: 'Channaba region thengnakhide.',
          mizo: 'Bial mil hmuh a ni lo.',
          kashmiri: 'کانٛہہ رلنہٕ وول علاقہ میول نہٕ۔',
          ladakhi: 'མཐུན་པའི་ས་ཁུལ་མ་རྙེད།',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color _regionColor(AppRegion region) {
  return switch (region.appLanguage.supportedUiLanguage) {
    SupportedUiLanguage.telugu => const Color(0xFF0F766E),
    SupportedUiLanguage.hindi => const Color(0xFFB45309),
    SupportedUiLanguage.english => const Color(0xFF2563EB),
    SupportedUiLanguage.tamil => const Color(0xFFBE123C),
    SupportedUiLanguage.kannada => const Color(0xFF7C3AED),
    SupportedUiLanguage.malayalam => const Color(0xFF15803D),
    SupportedUiLanguage.assamese ||
    SupportedUiLanguage.konkani ||
    SupportedUiLanguage.gujarati ||
    SupportedUiLanguage.marathi ||
    SupportedUiLanguage.meitei ||
    SupportedUiLanguage.mizo ||
    SupportedUiLanguage.odia ||
    SupportedUiLanguage.punjabi ||
    SupportedUiLanguage.nepali ||
    SupportedUiLanguage.bengali ||
    SupportedUiLanguage.kashmiri ||
    SupportedUiLanguage.ladakhi => const Color(0xFF2563EB),
  };
}
