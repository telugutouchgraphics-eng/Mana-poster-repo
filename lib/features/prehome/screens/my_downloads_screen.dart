import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mana_poster/app/widgets/app_snack_bar.dart';

import 'package:mana_poster/app/config/app_public_info.dart';
import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/services/media_export_service.dart';
import 'package:mana_poster/app/services/screen_security_service.dart';
import 'package:mana_poster/features/prehome/services/poster_downloads_service.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/onboarding_surface_card.dart';

class MyDownloadsScreen extends StatefulWidget {
  const MyDownloadsScreen({super.key});

  @override
  State<MyDownloadsScreen> createState() => _MyDownloadsScreenState();
}

class _MyDownloadsScreenState extends State<MyDownloadsScreen> {
  Future<List<PosterDownloadListed>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    unawaited(ScreenSecurityService.protectScreen());
    _itemsFuture = PosterDownloadsService.listForDisplay();
  }

  @override
  void dispose() {
    unawaited(ScreenSecurityService.unprotectScreen());
    super.dispose();
  }

  Future<void> _reload() async {
    final next = PosterDownloadsService.listForDisplay();
    setState(() => _itemsFuture = next);
    await next;
  }

  Future<void> _shareListed(PosterDownloadListed item) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = context.strings;
    final failed = strings.localized(
      telugu: 'షేర్ కాలేదు. మళ్లీ ప్రయత్నించండి.',
      english: 'Share failed. Please try again.',
      hindi: 'शेयर नहीं हुआ। फिर से कोशिश करें।',
      tamil: 'பகிர முடியவில்லை. மீண்டும் முயலவும்.',
      kannada: 'ಹಂಚಿಕೊಳ್ಳಲು ಸಾಧ್ಯವಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      malayalam: 'ഷെയർ ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
      marathi: 'शेअर करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      gujarati: 'શેર કરવામાં નિષ્ફળ. ફરી પ્રયાસ કરો.',
      bengali: 'শেয়ার করা ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
      punjabi: 'ਸਾਂਝਾ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      odia: 'ସେୟାର ବିଫଳ ହେଲା। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
      assamese: 'শ্বেয়াৰ ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
      konkani: 'शेअर जावंक ना. उपकार करून परत यत्न करात.',
      nepali: 'साझेदारी असफल भयो। कृपया पुन: प्रयास गर्नुहोस्.',
      meitei: 'Share touba maipak-khide. Amuk hanna hotnabiyu.',
      mizo: 'Share a hlawhchham. Khawngaihin ti nawn leh rawh.',
      kashmiri: 'شیئر گۆو ناکام۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
      ladakhi: 'བགོ་འགྲེམས་མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
    );
    try {
      final path = item.absolutePath;
      if (path.trim().isEmpty) {
        messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
        return;
      }
      if (!await File(path).exists()) {
        messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
        return;
      }
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      final shareText =
          '✨ Shared using ${AppPublicInfo.appName}\n'
          'Download the app: ${AppPublicInfo.playStoreUrl}';
      await MediaExportService.shareImageFile(
        path,
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } on MediaShareException {
      messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
    } catch (_) {
      messenger?.showTopSnackBar(AppSnackBar.build(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = strings.localized(
      telugu: 'నా డౌన్‌లోడ్లు',
      english: 'My Downloads',
      hindi: 'मेरे डाउनलोड',
      tamil: 'எனது பதிவிறக்கங்கள்',
      kannada: 'ನನ್ನ ಡೌನ್‌ಲೋಡ್‌ಗಳು',
      malayalam: 'എന്റെ ഡൗൺലോഡുകൾ',
      marathi: 'माझे डाउनलोड्स',
      gujarati: 'મારા ડાઉનલોડ્સ',
      bengali: 'আমার ডাউনলোড',
      punjabi: 'ਮੇਰੇ ਡਾਊਨਲੋਡ',
      odia: 'ମୋର ଡାଉନଲୋଡ୍',
      assamese: 'মোৰ ডাউনলোডসমূহ',
      konkani: 'म्हजे डाऊनलोड्स',
      nepali: 'मेरो डाउनलोडहरू',
      meitei: 'Eigi downloads',
      mizo: 'Ka download-te',
      kashmiri: 'میٚأنۍ ڈاؤنلوڈ',
      ladakhi: 'ངའི་ཕབ་ལེན།',
    );

    if (kIsWeb) {
      final msg = strings.localized(
        telugu: 'వెబ్‌లో అందుబాటులో లేదు.',
        english: 'Not available on web.',
        hindi: 'वेब पर उपलब्ध नहीं।',
        tamil: 'வலையில் இல்லை.',
        kannada: 'ವೆಬ್‌ನಲ್ಲಿ ಲಭ್ಯವಿಲ್ಲ.',
        malayalam: 'വെബിൽ ലഭ്യമല്ല.',
        marathi: 'वेबवर उपलब्ध नाही.',
        gujarati: 'વેબ પર ઉપલબ્ધ નથી.',
        bengali: 'ওয়েবে উপলব্ধ নয়।',
        punjabi: 'ਵੈੱਬ ਤੇ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
        odia: 'ୱେବ୍‌ରେ ଉପଲବ୍ଧ ନାହିଁ।',
        assamese: 'ৱেবত উপলব্ধ নহয়।',
        konkani: 'वेबार उपलब्ध ना.',
        nepali: 'वेबमा उपलब्ध छैन।',
        meitei: 'Web-ta phangde.',
        mizo: 'Web-ah a awm lo.',
        kashmiri: 'ویبس پیٹھہٕ چھُنہٕ دستِیاب۔',
        ladakhi: 'Web ཐོག་ཏུ་མི་འདུག',
      );
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(title),
        ),
        body: GradientShell(
          child: OnboardingSurfaceCard(
            child: Text(msg, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: GradientShell(
        child: FutureBuilder<List<PosterDownloadListed>>(
          future: _itemsFuture,
          builder: (BuildContext context, AsyncSnapshot<List<PosterDownloadListed>> snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                (!snap.hasData || snap.data == null)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return OnboardingSurfaceCard(
                child: Text(
                  strings.localized(
                    telugu: 'లోడ్ కాలేదు.',
                    english: 'Could not load downloads.',
                    hindi: 'लोड नहीं हो सका।',
                    tamil: 'ஏற்ற முடியவில்லை.',
                    kannada: 'ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಿಲ್ಲ.',
                    malayalam: 'ലോഡ് ചെയ്യാനായില്ല.',
                    marathi: 'डाउनलोड लोड करता आले नाही.',
                    gujarati: 'ડાઉનલોડ્સ લોડ થઈ શક્યા નથી.',
                    bengali: 'ডাউনলোড লোড করা যায়নি।',
                    punjabi: 'ਡਾਊਨਲੋਡ ਲੋਡ ਨਹੀਂ ਹੋ ਸਕੇ।',
                    odia: 'ଡାଉନଲୋଡ୍ ଲୋଡ୍ ହୋଇପାରିଲା ନାହିଁ।',
                    assamese: 'ডাউনলোডসমূহ লোড কৰিব পৰা নগ’ল।',
                    konkani: 'डाऊनलोड्स लोड करूंक जमले ना.',
                    nepali: 'डाउनलोडहरू लोड गर्न सकिएन।',
                    meitei: 'Downloads load touba ngamde.',
                    mizo: 'Download-te load theih a ni lo.',
                    kashmiri: 'ڈاؤنلوڈ ہیکہِ نہٕ لوڈ گژھِتھ۔',
                    ladakhi: 'ཕབ་ལེན་རྣམས་ load མ་ཐུབ།',
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final list = snap.data ?? <PosterDownloadListed>[];
            if (list.isEmpty) {
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    OnboardingSurfaceCard(
                      child: Text(
                        strings.localized(
                          telugu:
                              'డౌన్‌లోడ్ చేసిన పోస్టర్లు ఇక్కడ కనిపిస్తాయి.'
                              '\nగ్యాలరీకి సేవ్ చేసిన ప్రతీ పోస్టరు ఇక్కడా దాఖలవుతుంది.',
                          english:
                              'Downloaded posters will appear here.'
                              '\nEvery poster saved to gallery is tracked here.',
                          hindi:
                              'डाउनलोड किए गए पोस्टर यहाँ दिखाई देंगे।'
                              '\nगैलरी में सहेजा गया हर पोस्टर यहाँ दिखेगा।',
                          tamil:
                              'பதிவிறக்கம் செய்யப்பட்ட போஸ்டர்கள் இங்கே தோன்றும்.'
                              '\nகேலரியில் சேமிக்கப்பட்ட ஒவ்வொரு போஸ்டரும் இங்கே கண்காணிக்கப்படும்.',
                          kannada:
                              'ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ಪೋಸ್ಟರ್‌ಗಳು ಇಲ್ಲಿ ಗೋಚರಿಸುತ್ತವೆ.'
                              '\nಗ್ಯಾಲರಿಗೆ ಉಳಿಸಿದ ಪ್ರತಿಯೊಂದು ಪೋಸ್ಟರ್ ಇಲ್ಲೂ ದಾಖಲಾಗುತ್ತದೆ.',
                          malayalam:
                              'ഡൗൺലോഡ് ചെയ്‌ത പോസ്റ്ററുകൾ ഇവിടെ കാണാം.'
                              '\nഗ്യാലറിയിൽ സംരക്ഷിച്ച എല്ലാ പോസ്റ്ററുകളും ഇവിടെ ട്രാക്ക് ചെയ്യും.',
                          marathi:
                              'डाउनलोड केलेले पोस्टर्स येथे दिसतील.'
                              '\nगॅलरीत सेव्ह केलेला प्रत्येक पोस्टर येथे नोंदवला जाईल.',
                          gujarati:
                              'ડાઉનલોડ કરેલા પોસ્ટર્સ અહીં દેખાશે.'
                              '\nગેલેરીમાં સાચવેલ દરેક પોસ્ટર અહીં ટ્રૅક થાય છે.',
                          bengali:
                              'ডাউনলোড করা পোস্টারগুলি এখানে উপস্থিত হবে।'
                              '\nগ্যালারিতে সংরক্ষিত প্রতিটি পোস্টার এখানে ট্র্যাক করা হয়।',
                          punjabi:
                              'ਡਾਊਨਲੋਡ ਕੀਤੇ ਪੋਸਟਰ ਇੱਥੇ ਦਿਖਾਈ ਦੇਣਗੇ।'
                              '\nਗੈਲਰੀ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਹਰ ਪੋਸਟਰ ਇੱਥੇ ਟਰੈਕ ਕੀਤਾ ਜਾਂਦਾ է।',
                          odia:
                              'ଡାଉନଲୋଡ୍ ହୋଇଥିବା ପୋଷ୍ଟରଗୁଡ଼ିକ ଏଠାରେ ଦେଖାଯିବ।'
                              '\nଗ୍ୟାଲେରୀରେ ସଂରକ୍ଷିତ ପ୍ରତ୍ୟେକ ପୋଷ୍ଟର ଏଠାରେ ଟ୍ରାକ୍ କରାଯାଏ।',
                          assamese:
                              'ডাউনলোড কৰা পোষ্টাৰসমূহ ইয়াত দেখা যাব।'
                              '\nগেলেৰীত সংৰক্ষণ কৰা প্ৰতিখন পোষ্টাৰ ইয়াত ট্ৰেক কৰা হয়।',
                          konkani:
                              'डाऊनलोड केल्लीं पोस्टरां हांगा दिसतील.'
                              '\nगॅलरींत सांबाळिल्लें दर एक पोस्टर हांगा नोंद जातलें.',
                          nepali:
                              'डाउनलोड गरिएका पोस्टरहरू यहाँ देखा पर्नेछन्।'
                              '\nग्यालरीमा सुरक्षित गरिएको प्रत्येक पोस्टर यहाँ ट्र्याक गरिन्छ।',
                          meitei:
                              'Download touba postering masi phamda thengnagani.'
                              '\nGallery da save touba postering tracks tou-i.',
                          mizo:
                              'Download tawh poster-te heta tang hian a hmuh theih ang.'
                              '\nGallery-a i dah luh zawng zawng heta tang hian chhui theih a ni.',
                          kashmiri:
                              'ڈاؤنلوڈ کٔرمٕژ پوسٹر یِن ییٚتھ ہاونہٕ۔'
                              '\nگیلری منز محفوٗظ کٔرمُت پرؠتھ پوسٹر گژھہِ ییٚتھ ٹریک۔',
                          ladakhi:
                              'ཕབ་ལེན་བྱས་པའི་པོ་སཊར་རྣམས་འདི་ནས་མཐོང་ཐུབ།'
                              '\nGallery ལ་ཉར་བའི་པོ་སཊར་རེ་རེ་འདིར་འགོད་ཀྱི་ཡོད།',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  OnboardingSurfaceCard(
                    maxWidth: 520,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: list.length,
                      itemBuilder: (BuildContext _, int index) {
                        final PosterDownloadListed item = list[index];
                        final String path = item.absolutePath;
                        return ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(14),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(
                                color: const Color(0xFFE2E8F0),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, Object error, StackTrace? st) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => _shareListed(item),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.share_rounded,
                                          size: 20,
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
