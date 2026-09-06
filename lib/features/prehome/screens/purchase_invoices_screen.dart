import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/services/purchase_invoice_service.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() => _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState extends State<PurchaseInvoicesScreen>
    with AppLanguageStateMixin {
  final PurchaseInvoiceService _service = PurchaseInvoiceService();
  Future<List<PurchaseInvoice>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchInvoices();
  }

  Future<void> _refresh() async {
    final future = _service.fetchInvoices();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder owns the visible error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PurchaseInvoicesCopy(context.strings);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          copy.title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: copy.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<PurchaseInvoice>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _InvoiceStateMessage(
                icon: Icons.receipt_long_outlined,
                title: copy.loadFailedTitle,
                message: copy.loadFailedMessage,
                actionLabel: copy.tryAgain,
                onAction: _refresh,
              );
            }
            final invoices = snapshot.data ?? const <PurchaseInvoice>[];
            if (invoices.isEmpty) {
              return _InvoiceStateMessage(
                icon: Icons.receipt_long_outlined,
                title: copy.emptyTitle,
                message: copy.emptyMessage,
                actionLabel: copy.refresh,
                onAction: _refresh,
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: invoices.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _InvoiceNotice(copy: copy);
                  }
                  return _InvoiceCard(invoice: invoices[index - 1], copy: copy);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceNotice extends StatelessWidget {
  const _InvoiceNotice({required this.copy});

  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copy.notice,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.copy});

  final PurchaseInvoice invoice;
  final _PurchaseInvoicesCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDate = invoice.displayDate;
    final expiryAt = invoice.expiryAt;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      invoice.planName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.priceLabel,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: copy.statusText(invoice.statusLabel)),
            ],
          ),
          const SizedBox(height: 16),
          _InvoiceRow(
            label: copy.purchaseDate,
            value: displayDate == null
                ? copy.notAvailable
                : _formatDate(context, displayDate),
          ),
          if (expiryAt != null)
            _InvoiceRow(
              label: copy.validUntil,
              value: _formatDate(context, expiryAt),
            ),
          _InvoiceRow(
            label: copy.orderId,
            value: invoice.orderId ?? copy.notAvailable,
          ),
          _InvoiceRow(
            label: copy.platform,
            value: invoice.platform?.isNotEmpty == true
                ? invoice.platform!
                : copy.googlePlay,
          ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceStateMessage extends StatelessWidget {
  const _InvoiceStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 46, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => onAction(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseInvoicesCopy {
  const _PurchaseInvoicesCopy(this.strings);

  final AppStrings strings;

  String get title => strings.localized(
    telugu: 'కొనుగోలు ఇన్వాయిసులు',
    english: 'Purchase invoices',
    hindi: 'खरीद इनवॉइस',
    tamil: 'வாங்கிய ரசீதுகள்',
    kannada: 'ಖರೀದಿ ಇನ್ವಾಯ್ಸ್',
    malayalam: 'വാങ്ങൽ ഇൻവോയിസുകൾ',
    marathi: 'खरेदी पावत्या',
    gujarati: 'ખરીદી ઇનવૉઇસ',
    bengali: 'ক্রয় চালান',
    punjabi: 'ਖਰੀਦ ਇਨਵੌਇਸ',
    odia: 'କ୍ରୟ ଇନଭଏସ୍',
    assamese: 'ক্ৰয় চালান',
    konkani: 'खरेदी इनव्हॉइस',
    nepali: 'खरिद इनभ्वाइसहरू',
    meitei: 'Leiraba invoice sing',
    mizo: 'Leina invoice-te',
    kashmiri: 'خٔریٖد اِنوائِس',
    ladakhi: 'ཉོ་སྒྲུབ་ རྩིས་ཁྲ།',
  );

  String get refresh => strings.localized(
    telugu: 'రిఫ్రెష్',
    english: 'Refresh',
    hindi: 'रीफ्रेश',
    tamil: 'புதுப்பிக்கவும்',
    kannada: 'ರಿಫ್ರೆಶ್',
    malayalam: 'പുതുക്കുക',
    marathi: 'रीफ्रेश करा',
    gujarati: 'રીફ્રેશ કરો',
    bengali: 'রিফ্রেশ করুন',
    punjabi: 'ਰੀਫ੍ਰੈਸ਼ ਕਰੋ',
    odia: 'ରିଫ୍ରେଶ୍ କରନ୍ତୁ',
    assamese: 'ৰিফ্ৰেছ কৰক',
    konkani: 'रिफ्रेश करात',
    nepali: 'रिफ्रेस गर्नुहोस्',
    meitei: 'Amuk hanna thagatlu',
    mizo: 'Tharlam rawh',
    kashmiri: 'ریفریش کٔریو',
    ladakhi: 'ཡང་བསྐྱར་གསར་བཟོ་བྱོས།',
  );

  String get tryAgain => strings.localized(
    telugu: 'మళ్లీ ప్రయత్నించండి',
    english: 'Try again',
    hindi: 'फिर कोशिश करें',
    tamil: 'மீண்டும் முயற்சிக்கவும்',
    kannada: 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    malayalam: 'വീണ്ടും ശ്രമിക്കുക',
    marathi: 'पुन्हा प्रयत्न करा',
    gujarati: 'ફરી પ્રયાસ કરો',
    bengali: 'আবার চেষ্টা করুন',
    punjabi: 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    odia: 'ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ',
    assamese: 'পুনৰ চেষ্টা কৰক',
    konkani: 'परत यत्न करात',
    nepali: 'पुन: प्रयास गर्नुहोस्',
    meitei: 'Amuk hanna hotnabiyu',
    mizo: 'Ti nawn leh rawh',
    kashmiri: 'دۆبارٕ کٔریو کوشِش',
    ladakhi: 'ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );

  String get notice => strings.localized(
    telugu:
        'ఇక్కడ మీ Mana Poster కొనుగోలు వివరాలు మాత్రమే కనిపిస్తాయి. అధికారిక చెల్లింపు రసీదు Google Play లో ఉంటుంది.',
    english:
        'This shows your Mana Poster purchase details only. The official payment receipt is managed by Google Play.',
    hindi:
        'यहां केवल आपके Mana Poster खरीद विवरण दिखते हैं. आधिकारिक भुगतान रसीद Google Play में रहती है.',
    tamil:
        'இங்கு உங்கள் Mana Poster வாங்கிய விவரங்கள் மட்டும் காட்டப்படும். அதிகாரப்பூர்வ கட்டண ரசீது Google Play-ல் இருக்கும்.',
    kannada:
        'ಇಲ್ಲಿ ನಿಮ್ಮ Mana Poster ಖರೀದಿ ವಿವರಗಳು ಮಾತ್ರ ಕಾಣುತ್ತವೆ. ಅಧಿಕೃತ ಪಾವತಿ ರಸೀದಿ Google Play ನಲ್ಲಿ ಇರುತ್ತದೆ.',
    malayalam:
        'ഇവിടെ നിങ്ങളുടെ Mana Poster വാങ്ങൽ വിവരങ്ങൾ മാത്രം കാണിക്കും. ഔദ്യോഗിക പേയ്മെന്റ് രസീത് Google Play-ലാണ്.',
    marathi:
        'येथे फक्त तुमचे Mana Poster खरेदी तपशील दिसतात. अधिकृत पेमेंट पावती Google Play द्वारे व्यवस्थापित केली जाते.',
    gujarati:
        'અહીં ફક્ત તમારી Mana Poster ખરીદી વિગતો દેખાય છે. સત્તાવાર ચુકવણી રસીદ Google Play દ્વારા સંચાલિત થાય છે.',
    bengali:
        'এখানে কেবল আপনার Mana Poster ক্রয়ের বিবরণ প্রদর্শিত হয়। অফিসিয়াল পেমেন্ট রসিদ Google Play দ্বারা পরিচালিত হয়।',
    punjabi:
        'ਇੱਥੇ ਸਿਰਫ਼ ਤੁਹਾਡੇ Mana Poster ਖਰੀਦ ਵੇਰਵੇ ਦਿਖਾਈ ਦਿੰਦੇ ਹਨ। ਅਧਿਕਾਰਤ ਭੁਗਤਾਨ ਰਸੀਦ Google Play ਦੁਆਰਾ ਪ੍ਰਬੰਧਿਤ ਕੀਤੀ ਜਾਂਦੀ ਹੈ।',
    odia:
        'ଏଠାରେ କେବଳ ଆପଣଙ୍କର Mana Poster କ୍ରୟ ବିବରଣୀ ଦେଖାଯାଏ। ସରକାରୀ ଦେୟ ରସିଦ Google Play ଦ୍ୱାରା ପରିଚାଳିତ ହୁଏ।',
    assamese:
        'ইয়াত কেৱল আপোনাৰ Mana Poster ক্ৰয়ৰ বিৱৰণ দেখুওৱা হয়। অফিচিয়েল পেমেণ্ট ৰচিদ Google Play দ্বাৰা পৰিচালিত হয়।',
    konkani:
        'हांगा फक्त तुमचे Mana Poster खरेदी तपशील दिसतात. अधिकृत पेमेंट पावती Google Play कडेन आसा.',
    nepali:
        'यहाँ तपाईंका Mana Poster खरिद विवरणहरू मात्र देखिन्छन्। आधिकारिक भुक्तानी रसिद Google Play द्वारा व्यवस्थित गरिएको छ।',
    meitei:
        'Masi phamda nangi Mana Poster leiraba details khaktani. Official payment receipt ti Google Play na manage tou-i.',
    mizo:
        'He hmunah hian i Mana Poster leina chauh a lang. Pawisa pekna receipt dik tak chu Google Play-ah a awm.',
    kashmiri:
        'ییٚتھ چھِ صِرَف تہٕنٛزِ Mana Poster خٔریٖداری ہٕنٛزِ تفصیلات ہاونہٕ یِوان۔ سرکٲرۍ ادائیگی رسیٖد چھِ Google Play منز آسان۔',
    ladakhi:
        'འདིར་ཁྱེད་ཀྱི་ Mana Poster ཉོ་སྒྲུབ་ཀྱི་གནས་ཚུལ་ཙམ་སྟོན། གཞུང་འབྲེལ་གྱི་དངུལ་སྤྲོད་རྩིས་ཁྲ་ Google Play ནང་ཡོད།',
  );

  String get emptyTitle => strings.localized(
    telugu: 'ఇన్వాయిసులు లేవు',
    english: 'No invoices found',
    hindi: 'कोई इनवॉइस नहीं मिला',
    tamil: 'ரசீதுகள் இல்லை',
    kannada: 'ಇನ್ವಾಯ್ಸ್ ಸಿಗಲಿಲ್ಲ',
    malayalam: 'ഇൻവോയിസുകൾ ഇല്ല',
    marathi: 'पावत्या आढळल्या नाहीत',
    gujarati: 'કોઈ ઇનવૉઇસ મળ્યું નથી',
    bengali: 'কোনো চালান পাওয়া যায়নি',
    punjabi: 'ਕੋਈ ਇਨਵੌਇਸ ਨਹੀਂ ਮਿਲਿਆ',
    odia: 'କୌଣସି ଇନଭଏସ୍ ମିଳିଲା ନାହିଁ',
    assamese: 'কোনো চালান পোৱা নগ’ল',
    konkani: 'खंयचीच इनव्हॉइस मेळ्ळी ना',
    nepali: 'कुनै इनभ्वाइस फेला परेन',
    meitei: 'Invoices thengnakhide',
    mizo: 'Invoice hmuh a ni lo',
    kashmiri: 'کانٛہہ اِنوائِس مِلیو نہٕ',
    ladakhi: 'རྩིས་ཁྲ་མ་རྙེད།',
  );

  String get emptyMessage => strings.localized(
    telugu: 'ఈ అకౌంట్‌లో కొనుగోలు వివరాలు ఇంకా కనిపించడం లేదు.',
    english: 'No purchase details are available for this account yet.',
    hindi: 'इस खाते के लिए अभी कोई खरीद विवरण उपलब्ध नहीं है.',
    tamil: 'இந்த கணக்கிற்கு வாங்கிய விவரங்கள் இன்னும் இல்லை.',
    kannada: 'ಈ ಖಾತೆಗೆ ಖರೀದಿ ವಿವರಗಳು ಇನ್ನೂ ಲಭ್ಯವಿಲ್ಲ.',
    malayalam: 'ഈ അക്കൗണ്ടിന് വാങ്ങൽ വിവരങ്ങൾ ഇതുവരെ ലഭ്യമല്ല.',
    marathi: 'या खात्यासाठी अद्याप कोणतेही खरेदी तपशील उपलब्ध नाहीत.',
    gujarati: 'આ એકાઉન્ટ માટે હજી સુધી કોઈ ખરીદી વિગતો ઉપલબ્ધ નથી.',
    bengali: 'এই অ্যাকাউন্টের জন্য এখনো কোনো ক্রয়ের বিবরণ পাওয়া যায়নি।',
    punjabi: 'ਇਸ ਖਾਤੇ ਲਈ ਅਜੇ ਕੋਈ ਖਰੀਦ ਵੇਰਵੇ ਉਪਲਬਧ ਨਹੀਂ ਹਨ।',
    odia: 'ଏହି ଖାତା ପାଇଁ ଏପର୍ଯ୍ୟନ୍ତ କୌଣସି କ୍ରୟ ବିବରଣୀ ଉପଲବ୍ଧ ନାହିଁ।',
    assamese: 'এই একাউন্টৰ বাবে এতিয়ালৈকে কোনো ক্ৰয়ৰ বিৱৰণ উপলব্ধ নহয়।',
    konkani: 'ह्या खात्या खातीर आझून खंयचेच खरेदी तपशील उपलब्ध नात.',
    nepali: 'यस खाताका लागि हालसम्म कुनै खरिद विवरण उपलब्ध छैन।',
    meitei: 'Account asigi damak leiraba details amatta leitari.',
    mizo: 'He account tan hian leina chanchin a la awm lo.',
    kashmiri: 'یَتھ کھاتَس خٲطرٕ چھنہٕ وؠن کانٛہہ خٔریٖداری ہٕنٛز تفصیلات دستِیاب۔',
    ladakhi: 'འདི་འདྲའི་ account ལ་ད་དུང་ཉོ་སྒྲུབ་ཀྱི་གནས་ཚུལ་མེད།',
  );

  String get loadFailedTitle => strings.localized(
    telugu: 'లోడ్ కాలేదు',
    english: 'Could not load',
    hindi: 'लोड नहीं हुआ',
    tamil: 'லோடு ஆகவில்லை',
    kannada: 'ಲೋಡ್ ಆಗಲಿಲ್ಲ',
    malayalam: 'ലോഡ് ചെയ്യാനായില്ല',
    marathi: 'लोड झाले नाही',
    gujarati: 'લોડ થઈ શક્યું નથી',
    bengali: 'লোড করা যায়নি',
    punjabi: 'ਲੋਡ ਨਹੀਂ ਹੋ ਸਕਿਆ',
    odia: 'ଲୋଡ୍ ହୋଇପାରିଲା ନାହିଁ',
    assamese: 'লোড কৰিব পৰা নগ’ল',
    konkani: 'लोड जावंक ना',
    nepali: 'लोड हुन सकेन',
    meitei: 'Load touba ngamkhide',
    mizo: 'Load theih a ni lo',
    kashmiri: 'لوڈ سپُد نہٕ',
    ladakhi: 'Load མ་ཐུབ།',
  );

  String get loadFailedMessage => strings.localized(
    telugu: 'కొనుగోలు వివరాలు తెచ్చుకోలేకపోయాం. మళ్లీ ప్రయత్నించండి.',
    english: 'Purchase details could not be loaded. Please try again.',
    hindi: 'खरीद विवरण लोड नहीं हो सके. फिर कोशिश करें.',
    tamil: 'வாங்கிய விவரங்களை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    kannada: 'ಖರೀದಿ ವಿವರಗಳನ್ನು ಲೋಡ್ ಮಾಡಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    malayalam: 'വാങ്ങൽ വിവരങ്ങൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
    marathi: 'खरेदी तपशील लोड करता आले नाहीत. कृपया पुन्हा प्रयत्न करा.',
    gujarati: 'ખરીદી વિગતો લોડ થઈ શકી નથી. ફરી પ્રયાસ કરો.',
    bengali: 'ক্রয়ের বিবরণ লোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
    punjabi: 'ਖਰੀਦ ਵੇਰਵੇ ਲੋਡ ਨਹੀਂ ਕੀਤੇ ਜਾ ਸਕੇ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
    odia: 'କ୍ରୟ ବିବରଣୀ ଲୋଡ୍ ହୋଇପାରିଲା ନାହିଁ। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।',
    assamese: 'ক্ৰয়ৰ বিৱৰণ লোড কৰিব পৰা নগ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
    konkani: 'खरेदी तपशील लोड करूंक जमले नात. उपकार करून परत यत्न करात.',
    nepali: 'खरिद विवरणहरू लोड गर्न सकिएन। कृपया पुन: प्रयास गर्नुहोस्।',
    meitei: 'Leiraba details load touba ngamkhide. Amuk hanna hotnabiyu.',
    mizo: 'Leina chanchin load theih a ni lo. Khawngaihin ti nawn leh rawh.',
    kashmiri: 'خٔریٖداری ہٕنٛز تفصیلات ہیکہِ نہٕ لوڈ گژھِتھ۔ مہربٲنی کٔرتھ دۆبارٕ کٔریو کوشِش۔',
    ladakhi: 'ཉོ་སྒྲུབ་ཀྱི་གནས་ཚུལ་ load མ་ཐུབ། ཡང་བསྐྱར་འབད་བརྩོན་གནང།',
  );

  String get purchaseDate => strings.localized(
    telugu: 'కొనుగోలు తేదీ',
    english: 'Purchase date',
    hindi: 'खरीद की तारीख',
    tamil: 'வாங்கிய தேதி',
    kannada: 'ಖರೀದಿಸಿದ ದಿನಾಂಕ',
    malayalam: 'വാങ്ങിയ തീയതി',
    marathi: 'खरेदी तारीख',
    gujarati: 'ખરીદી તારીખ',
    bengali: 'ক্রয়ের তারিখ',
    punjabi: 'ਖਰੀਦ ਦੀ ਮਿਤੀ',
    odia: 'କ୍ରୟ ତାରିଖ',
    assamese: 'ক্ৰয়ৰ তাৰিখ',
    konkani: 'खरेदी तारीख',
    nepali: 'खरिद मिति',
    meitei: 'Leiraba Numit',
    mizo: 'Leini',
    kashmiri: 'خٔریٖداری ہٕنٛز تٲریٖخ',
    ladakhi: 'ཉོ་བའི་ཚེས་གྲངས།',
  );

  String get validUntil => strings.localized(
    telugu: 'చెల్లుబాటు',
    english: 'Valid until',
    hindi: 'वैधता',
    tamil: 'செல்லுபடியாகும் வரை',
    kannada: 'ಮಾನ್ಯತೆ',
    malayalam: 'സാധുത',
    marathi: 'या तारखेपर्यंत वैध',
    gujarati: 'સુધી માન્ય',
    bengali: 'পর্যন্ত বৈধ',
    punjabi: 'ਤੱਕ ਵੈਧ',
    odia: 'ପର୍ଯ୍ୟନ୍ତ ବୈଧ',
    assamese: 'লৈকে বৈধ',
    konkani: 'ह्या तारखे मेरेन लागू',
    nepali: 'सम्म मान्य',
    meitei: 'Chatnaba numit',
    mizo: 'A hman theih hun chhung',
    kashmiri: 'تَمام گژھنُک وؠکھ',
    ladakhi: 'ནུས་པ་ཡོད་པའི་དུས་ཚོད།',
  );

  String get orderId => strings.localized(
    telugu: 'ఆర్డర్ ID',
    english: 'Order ID',
    hindi: 'ऑर्डर आईडी',
    tamil: 'ஆர்டர் ஐடி',
    kannada: 'ಆರ್ಡರ್ ಐಡಿ',
    malayalam: 'ഓർഡർ ഐഡി',
    marathi: 'ऑर्डर आयडी',
    gujarati: 'ઓર્ડર આઈડી',
    bengali: 'অর্ডার আইডি',
    punjabi: 'ਆਰਡਰ ਆਈਡੀ',
    odia: 'ଅର୍ଡର ଆଇଡି',
    assamese: 'অৰ্ডাৰ আইডি',
    konkani: 'ऑर्डर आयडी',
    nepali: 'अर्डर आईडी',
    meitei: 'Order ID',
    mizo: 'Order ID',
    kashmiri: 'آرڈر آئی ڈی',
    ladakhi: 'Order ID',
  );

  String get platform => strings.localized(
    telugu: 'ప్లాట్‌ఫారమ్',
    english: 'Platform',
    hindi: 'प्लेटफ़ॉर्म',
    tamil: 'தளம்',
    kannada: 'ಪ್ಲಾಟ್‌ಫಾರ್ಮ್',
    malayalam: 'പ്ലാറ്റ്ഫോം',
    marathi: 'प्लॅटफॉर्म',
    gujarati: 'પ્લેટફોર્મ',
    bengali: 'প্ল্যাটফর্ম',
    punjabi: 'ਪਲੇਟਫਾਰਮ',
    odia: 'ପ୍ଲାଟଫର୍ମ',
    assamese: 'প্লেটফৰ্ম',
    konkani: 'प्लॅटफॉर्म',
    nepali: 'प्लेटफर्म',
    meitei: 'Platform',
    mizo: 'Platform',
    kashmiri: 'پلیٹ فارم',
    ladakhi: 'Platform',
  );

  String get googlePlay => 'Google Play';

  String get notAvailable => strings.localized(
    telugu: 'లభ్యం లేదు',
    english: 'Not available',
    hindi: 'उपलब्ध नहीं',
    tamil: 'கிடைக்கவில்லை',
    kannada: 'ಲಭ್ಯವಿಲ್ಲ',
    malayalam: 'ലഭ്യമല്ല',
    marathi: 'उपलब्ध नाही',
    gujarati: 'ઉપલબ્ધ નથી',
    bengali: 'উপলব্ধ নয়',
    punjabi: 'ਉਪਲਬਧ ਨਹੀਂ',
    odia: 'ଉପଲବ୍ଧ ନାହିଁ',
    assamese: 'উপলব্ধ নহয়',
    konkani: 'उपलब्ध ना',
    nepali: 'उपलब्ध छैन',
    meitei: 'Phangde',
    mizo: 'A awm lo',
    kashmiri: 'دستِیاب چھُنہٕ',
    ladakhi: 'མི་འདུག',
  );

  String statusText(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('active') ||
        normalized.contains('purchased') ||
        normalized.contains('verified')) {
      return strings.localized(
        telugu: 'యాక్టివ్',
        english: 'Active',
        hindi: 'सक्रिय',
        tamil: 'செயலில்',
        kannada: 'ಸಕ್ರಿಯ',
        malayalam: 'സജീവം',
        marathi: 'सक्रिय',
        gujarati: 'સક્રિય',
        bengali: 'সক্রিয়',
        punjabi: 'ਸਰਗਰਮ',
        odia: 'ସକ୍ରିୟ',
        assamese: 'সক্ৰিয়',
        konkani: 'सक्रिय',
        nepali: 'सक्रिय',
        meitei: 'Active',
        mizo: 'Hman theih',
        kashmiri: 'متحرک',
        ladakhi: 'བྱེད་ནུས་ཅན།',
      );
    }
    if (normalized.contains('expired') || normalized.contains('cancel')) {
      return strings.localized(
        telugu: 'ముగిసింది',
        english: 'Expired',
        hindi: 'समाप्त',
        tamil: 'காலாவதியானது',
        kannada: 'ಅವಧಿ ಮುಗಿದಿದೆ',
        malayalam: 'കാലഹരണപ്പെട്ടു',
        marathi: 'कालबाह्य झाले',
        gujarati: 'મુદત પૂરી થઈ',
        bengali: 'মেয়াদ শেষ',
        punjabi: 'ਮਿਆਦ ਪੁੱਗ ਗਈ',
        odia: 'ଅବଧି ସମାପ୍ତ',
        assamese: 'ম্যাদ উকলিল',
        konkani: 'मुदत सोंपली',
        nepali: 'म्याद सकियो',
        meitei: 'Matam loire',
        mizo: 'A hun a liam tawh',
        kashmiri: 'مُکِیمُت',
        ladakhi: 'དུས་ཚོད་ཟིན་པ།',
      );
    }
    return raw.trim().isEmpty
        ? strings.localized(
            telugu: 'సరే',
            english: 'OK',
            hindi: 'ठीक है',
            tamil: 'சரி',
            kannada: 'ಸರಿ',
            malayalam: 'ശരി',
            marathi: 'ठीक आहे',
            gujarati: 'બરાબર',
            bengali: 'ঠিক আছে',
            punjabi: 'ਠੀਕ ਹੈ',
            odia: 'ଠିକ୍ ଅଛି',
            assamese: 'ঠিক আছে',
            konkani: 'बरे',
            nepali: 'हुन्छ',
            meitei: 'Yare',
            mizo: 'Aw le',
            kashmiri: 'ٹھیک چھُ',
            ladakhi: 'འགྲིགས།',
          )
        : raw;
  }
}
