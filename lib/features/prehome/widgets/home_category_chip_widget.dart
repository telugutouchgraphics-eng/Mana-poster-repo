// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!_isPressed) {
      setState(() => _isPressed = true);
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (!_isPressed) {
      HapticFeedback.selectionClick();
    } else {
      setState(() => _isPressed = false);
    }
    try {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    } catch (_) {}
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isSelected = widget.isSelected;
    final isAll = data.slug == _HomeScreenState._allCategorySlug;
    final displaySlug = data.selectionSlug ?? data.slug;
    final iconAssetPath =
        data.iconAssetPath ??
        CategoryDisplayHelper.assetPathFor(displaySlug, data.label);
    final cleanLabel = CategoryDisplayHelper.stripIcon(data.label);
    final dateLabel = data.dateLabel?.trim();
    final showDate =
        data.isDynamic && dateLabel != null && dateLabel.isNotEmpty;
    const selectedChipColor = Color(0xFF6D28D9);
    const selectedChipBorder = Color(0xFF5B21B6);
    const allChipColor = Color(0xFF25D366);
    const allChipBorder = Color(0xFF1FAE54);
    final chipTint = isAll && isSelected
        ? allChipColor
        : isSelected
        ? selectedChipColor
        : data.isDynamic
        ? const Color(0xFFFFF4DB)
        : Colors.white;
    final borderColor = isAll && isSelected
        ? allChipBorder
        : isSelected
        ? selectedChipBorder
        : data.isDynamic
        ? const Color(0xFFF2C66D)
        : const Color(0xFFDCE6F3);
    final textColor = isSelected
        ? Colors.white
        : data.isDynamic
        ? const Color(0xFF8A5A00)
        : const Color(0xFF334155);
    final secondaryTextColor = isSelected
        ? Colors.white.withValues(alpha: 0.82)
        : textColor.withValues(alpha: 0.78);

    return AnimatedScale(
      scale: _isPressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: Material(
        color: chipTint,
        borderRadius: BorderRadius.circular(999),
        elevation: isSelected || isAll ? 1.0 : 0.0,
        shadowColor: const Color(0x1F0F172A),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: isSelected
              ? Colors.white.withValues(alpha: 0.32)
              : const Color(0xFF6D28D9).withValues(alpha: 0.18),
          highlightColor: isSelected
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFF6D28D9).withValues(alpha: 0.10),
          child: Container(
            constraints: BoxConstraints(minHeight: showDate ? 29 : 27),
            padding: EdgeInsets.symmetric(
              horizontal: showDate ? 7 : 8,
              vertical: showDate ? 2.5 : 3.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (iconAssetPath != null) ...<Widget>[
                  _CategoryChipAssetIcon(assetPath: iconAssetPath),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: showDate
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              cleanLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 9.8,
                                height: 1.02,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Text(
                              dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 8.5,
                                height: 1.0,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          cleanLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 10.4,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChipAssetIcon extends StatelessWidget {
  const _CategoryChipAssetIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final normalized = assetPath.trim();
    final lower = normalized.toLowerCase();
    final isNetwork = lower.startsWith('https://');
    final isSvg = lower.endsWith('.svg') || lower.contains('.svg?');
    return Container(
      width: 15,
      height: 15,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: isNetwork
          ? (isSvg
                ? SvgPicture.network(
                    normalized,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const _CategoryChipFallbackIcon(),
                  )
                : Image.network(
                    normalized,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CategoryChipFallbackIcon(),
                  ))
          : (isSvg
                ? SvgPicture.asset(
                    normalized,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const _CategoryChipFallbackIcon(),
                  )
                : Image.asset(
                    normalized,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CategoryChipFallbackIcon(),
                  )),
    );
  }
}

class _CategoryChipFallbackIcon extends StatelessWidget {
  const _CategoryChipFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.category_rounded,
      size: 11,
      color: Color(0xFF64748B),
    );
  }
}

// ignore: unused_element
String _subscriptionPromptCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'పోస్టర్లను షేర్ చేయడానికి లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్‌ను యాక్టివేట్ చేయండి.',
    english: 'Activate subscription to share or download posters.',
    hindi: 'पोस्टर शेयर या डाउनलोड करने के लिए सदस्यता सक्रिय करें।',
    tamil: 'போஸ்டர்களைப் பகிர அல்லது பதிவிறக்க சந்தாவைச் செயல்படுத்தவும்.',
    kannada:
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಲು ಅಥವಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಚಂದಾದಾರಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    malayalam:
        'പോസ്റ്ററുകൾ പങ്കിടാനോ ഡൗൺലോഡ് ചെയ്യാനോ സബ്‌സ്‌ക്രിപ്ഷൻ സജീവമാക്കുക.',
    marathi: 'पोस्टर्स शेअर किंवा डाउनलोड करण्यासाठी सदस्यता सक्रिय करा.',
    gujarati: 'પોસ્ટર્સ શેર અથવા ડાઉનલોડ કરવા માટે સબ્સ્ક્રિપ્શન સક્રિય કરો.',
    bengali: 'পোস্টার শেয়ার বা ডাউনলোড করতে সাবস্ক্রিপশন সক্রিয় করুন।',
    punjabi: 'ਪੋਸਟਰ ਸਾਂਝੇ ਕਰਨ ਜਾਂ ਡਾਊਨਲੋਡ ਕਰਨ ਲਈ ਗਾਹਕੀ ਨੂੰ ਸਰਗਰਮ ਕਰੋ।',
    odia: 'ପୋଷ୍ଟର ସେୟାର କିମ୍ବା ଡାଉନଲୋଡ୍ କରିବାକୁ ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ କରନ୍ତୁ।',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ বা ডাউনলোড কৰিবলৈ চাবস্ক্ৰিপচন সক্ৰিয় কৰক।',
    konkani: 'पोस्टरां वांटूंक वा डाऊनलोड करूंक वर्गणी सक्रीय करात.',
    nepali: 'पोस्टरहरू सेयर वा डाउनलोड गर्न सदस्यता सक्रिय गर्नुहोस्।',
    meitei: 'পোস্তরশিং শিয়র নত্রগা দাউনলোদ তৌনবগীদমক সবস্ক্রিপসন সনা তৌবীয়ু।',
    mizo: 'Poster share emaw download turin subscription ti nung rawh.',
    kashmiri: 'پوسٹر شیئر یا ڈاؤنلوڈ کرن خٲطرٕ کٔرِو سبسکرپشن چالوٗ۔',
    ladakhi: 'པོ་སི་ཊར་བགོ་འགྲེམས་སམ་ཕབ་ལེན་ཆེད་དུ་མངགས་ཉོ་ནུས་ལྡན་བཟོས།',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
    hindi: 'सदस्यता आवश्यक है',
    tamil: 'சந்தா தேவை',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅಗತ್ಯವಿದೆ',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ ആവശ്യമാണ്',
    marathi: 'सदस्यता आवश्यक आहे',
    gujarati: 'સબ્સ્ક્રિપ્શન જરૂરી છે',
    bengali: 'সাবস্ক্রিপশন প্রয়োজন',
    punjabi: 'ਗਾਹਕੀ ਲੋੜੀਂਦੀ ਹੈ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
    assamese: 'চাবস্ক্ৰিপচন প্ৰয়োজন',
    konkani: 'वर्गणी जाय',
    nepali: 'सदस्यता आवश्यक छ',
    meitei: 'সবস্ক্রিপসন মথৌ তাই',
    mizo: 'Subscription a ngai',
    kashmiri: 'سبسکرپشن ضۆروٗری',
    ladakhi: 'མངགས་ཉོ་དགོས།',
  );
}

// ignore: unused_element
String _subscriptionTrialTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3-दिवसीय परीक्षण योजना',
    tamil: '3 நாள் சோதனைத் திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '3 दिवसांचा ट्रायल प्लॅन',
    gujarati: '3-દિવસનો ટ્રાયલ પ્લાન',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনীয়া ট্ৰায়েল প্লেন',
    konkani: '3 दिसांचो ट्रायल प्लॅन',
    nepali: '३ दिने परीक्षण योजना',
    meitei: 'নুমিৎ 3 নিগী ত্রায়ল প্লান',
    mizo: 'Ni 3 chhung trial plan',
    kashmiri: '3 دوہُن ٹرائل پلان',
    ladakhi: 'ཉིན་ ༣ ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionTrialValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
    hindi:
        '${SubscriptionPlanConfig.trialDays} दिनों के लिए ${SubscriptionPlanConfig.trialPriceDisplay}',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாட்களுக்கு ${SubscriptionPlanConfig.trialPriceDisplay}',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳಿಗೆ ${SubscriptionPlanConfig.trialPriceDisplay}',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തേക്ക് ${SubscriptionPlanConfig.trialPriceDisplay}',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांसाठी ${SubscriptionPlanConfig.trialPriceDisplay}',
    gujarati:
        '${SubscriptionPlanConfig.trialDays} દિવસ માટે ${SubscriptionPlanConfig.trialPriceDisplay}',
    bengali:
        '${SubscriptionPlanConfig.trialDays} দিনের জন্য ${SubscriptionPlanConfig.trialPriceDisplay}',
    punjabi:
        '${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਲਈ ${SubscriptionPlanConfig.trialPriceDisplay}',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନ ପାଇଁ ${SubscriptionPlanConfig.trialPriceDisplay}',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনৰ বাবে ${SubscriptionPlanConfig.trialPriceDisplay}',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसां खातीर ${SubscriptionPlanConfig.trialPriceDisplay}',
    nepali:
        '${SubscriptionPlanConfig.trialDays} दिनको लागि ${SubscriptionPlanConfig.trialPriceDisplay}',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগীদমক ${SubscriptionPlanConfig.trialPriceDisplay}',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} atan ${SubscriptionPlanConfig.trialPriceDisplay}',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن خٲطرٕ ${SubscriptionPlanConfig.trialPriceDisplay}',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཆེད་དུ ${SubscriptionPlanConfig.trialPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionMonthlyTitleLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक योजना',
    tamil: 'மாதாந்திர திட்டம்',
    kannada: 'ಮಾಸಿಕ ಯೋಜನೆ',
    malayalam: 'പ്രതിമാസ പ്ലാൻ',
    marathi: 'मासिक प्लॅन',
    gujarati: 'માસિક પ્લાન',
    bengali: 'মাসিক প্ল্যান',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    assamese: 'মাহেকীয়া প্লেন',
    konkani: 'म्हयन्याचो प्लॅन',
    nepali: 'मासिक योजना',
    meitei: 'থাগী প্লান',
    mizo: 'Thla tina plan',
    kashmiri: 'ماہانہ پلان',
    ladakhi: 'ཟླ་རེའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionMonthlyValueLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
    hindi: '${SubscriptionPlanConfig.monthlyPriceDisplay} प्रति माह',
    tamil: 'மாதத்திற்கு ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kannada: 'ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    malayalam: 'പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    marathi: 'दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    gujarati: 'દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    bengali: 'প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    punjabi: 'ਪ੍ਰਤੀ ਮਹੀਨਾ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    odia: 'ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    assamese: 'প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    konkani: 'दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    nepali: 'प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    meitei: 'থা খুদিংগী ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    mizo: 'Thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kashmiri: 'پر ماہ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    ladakhi: 'ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionRenewalCopyLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో-రీన్యూ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజులలోపు రద్దు చేస్తే, నెలవారీ ఛార్జీ వర్తించదు. ప్రస్తుత ప్లాన్ ముగిసే వరకు ప్రయోజనాలు కొనసాగుతాయి.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
    hindi:
        '${SubscriptionPlanConfig.trialDays}-दिनों के परीक्षण के बाद, रद्द न करने पर यह ${SubscriptionPlanConfig.monthlyPriceDisplay}/माह पर स्वतः नवीनीकृत होगा। यदि ${SubscriptionPlanConfig.trialDays} दिनों में रद्द किया जाता है, तो मासिक शुल्क लागू नहीं होगा। लाभ मौजूदा योजना समाप्त होने तक जारी रहेंगे।',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் ${SubscriptionPlanConfig.monthlyPriceDisplay}-க்கு தானாகப் புதுப்பிக்கப்படும். ${SubscriptionPlanConfig.trialDays} நாட்களுக்குள் ரத்து செய்தால் மாதாந்திரக் கட்டணம் பொருந்தாது. நடப்புத் திட்டம் முடியும் வரை நன்மைகள் தொடரும்.',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay} ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ. ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಲ್ಲಿ ರದ್ದುಗೊಳಿಸಿದರೆ ಮಾಸಿಕ ಶುಲ್ಕ ಅನ್ವಯಿಸುವುದಿಲ್ಲ. ಪ್ರಸ್ತುತ ಪ್ಲಾನ್ ಮುಗಿಯುವವರೆಗೆ ಪ್ರಯೋಜನಗಳು ಮುಂದುವರಿಯುತ್ತವೆ.',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay} നിരക്കിൽ സ്വയമേവ പുതുക്കും. ${SubscriptionPlanConfig.trialDays} ദിവസത്തിനുള്ളിൽ റദ്ദാക്കിയാൽ പ്രതിമാസ നിരക്ക് ബാധകമല്ല. നിലവിലെ പ്ലാൻ തീരുന്നതുവരെ ആനുകൂല്യങ്ങൾ തുടരും.',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay} वर ऑटो-रिन्यू होईल. ${SubscriptionPlanConfig.trialDays} दिवसांच्या आत रद्द केल्यास, मासिक शुल्क आकारले जाणार नाही. चालू प्लॅन संपेपर्यंत फायदे सुरू राहतील.',
    gujarati:
        '${SubscriptionPlanConfig.trialDays}-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay} પર ઑટો-રિન્યૂ થાય છે. જો ${SubscriptionPlanConfig.trialDays} દિવસમાં રદ કરવામાં આવે, તો માસિક શુલ્ક લાગુ પડતું નથી. વર્તમાન પ્લાન સમાપ્ત થાય ત્યાં સુધી લાભો ચાલુ રહે છે.',
    bengali:
        '${SubscriptionPlanConfig.trialDays}-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay} হারে স্বতঃ-নবায়ন হবে। ${SubscriptionPlanConfig.trialDays} দিনের মধ্যে বাতিল করলে মাসিক চার্জ প্রযোজ্য হবে না। বর্তমান প্ল্যানের মেয়াদ শেষ না হওয়া পর্যন্ত সুবিধাগুলি অব্যাহত থাকবে।',
    punjabi:
        '${SubscriptionPlanConfig.trialDays}-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ ${SubscriptionPlanConfig.monthlyPriceDisplay}/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ। ਜੇਕਰ ${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਦੇ ਅੰਦਰ ਰੱਦ ਕੀਤਾ ਜਾਂਦਾ ਹੈ, ਤਾਂ ਮਹੀਨਾਵਾਰ ਖਰਚਾ ਲਾਗੂ ਨਹੀਂ ਹੋਵੇਗਾ। ਲਾਭ ਮੌਜੂਦਾ ਪਲਾਨ ਖਤਮ ਹੋਣ ਤੱਕ ਜਾਰੀ ਰਹਿਣਗੇ।',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay} ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ। ${SubscriptionPlanConfig.trialDays} ଦିନ ମଧ୍ୟରେ ବାତିଲ୍ କଲେ ମାସିକ ଶୁଳ୍କ ଲାଗୁ ହେବ ନାହିଁ। ବର୍ତ୍ତମାନର ପ୍ଲାନ୍ ସରିବା ପର୍ଯ୍ୟନ୍ତ ସୁବିଧା ଜାରି ରହିବ।',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay} ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব। ${SubscriptionPlanConfig.trialDays} দিনৰ ভিতৰত বাতিল কৰিলে মাহেকীয়া মাচুল প্ৰযোজ্য নহয়। বৰ্তমানৰ প্লেন শেষ নোহোৱালৈকে সুবিধাসমূহ অব্যাহত থাকিব।',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay} प्रमाण स्वयंचलित नूतनीकरण जातलें. ${SubscriptionPlanConfig.trialDays} दिसां भितर रद्द केल्यार म्हयन्याचो आकार लागू जायना. चालू प्लॅन सोंपमेरेन फायदे चालू उरतले.',
    nepali:
        '${SubscriptionPlanConfig.trialDays}-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay} मा स्वतः नवीकरण हुन्छ। यदि ${SubscriptionPlanConfig.trialDays} दिन भित्र रद्द गरियो भने, मासिक शुल्क लाग्दैन। हालको योजना समाप्त नभएसम्म फाइदाहरू जारी रहनेछन्।',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা ${SubscriptionPlanConfig.monthlyPriceDisplay} দা ওতো-রিনিউ তৌগনি। নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী মনুংদা কেন্সেল তৌরবদি থাগী চান্দা লৌরোই। হৌজিক্কী প্লান লোইদ্রিফাওবা কান্নবশিং চত্থগনি।',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} trial hnuah, cancel loh chuan thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}-in auto-renew ang. Ni ${SubscriptionPlanConfig.trialDays} chhunga cancel chuan thla tin charge a kal lo ang. Tun thlenga plan a tawp hma chuan a hlawkna a chhunzawm zel ang.',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود ${SubscriptionPlanConfig.monthlyPriceDisplay}/ماہس پؠٹھ نویں سرٕ। اگر ${SubscriptionPlanConfig.trialDays} دوہَن منٛز کینسل کٔرِو، تیٚلہِ لاگوٗ گژھِ نہٕ ماہانہ فیس। فایدٕ روزَن موٗجوٗدٕ پلان ختم گژھنَس تام جٲری۔',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay} རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད། ཉིན་ ${SubscriptionPlanConfig.trialDays} ནང་ཕྱིར་འཐེན་བྱས་ན་ཟླ་རེའི་རིན་པ་མི་ལེན། ད་ལྟའི་འཆར་གཞི་མ་རྫོགས་བར་དུ་ཁེ་ཕན་རྣམས་འཐོབ་རྒྱུ།',
  );
}

// ignore: unused_element
String _subscriptionTermsLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

// ignore: unused_element
String _subscriptionSkipLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

// ignore: unused_element
String _subscriptionButtonLabelLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

// ignore: unused_element
String _subscriptionPromptCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'పోస్టర్లను షేర్ చేయడానికి లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్‌ను యాక్టివేట్ చేయండి.',
    english: 'Activate subscription to share or download posters.',
    hindi: 'पोस्टर शेयर या डाउनलोड करने के लिए सदस्यता सक्रिय करें।',
    tamil: 'போஸ்டர்களைப் பகிர அல்லது பதிவிறக்க சந்தாவைச் செயல்படுத்தவும்.',
    kannada:
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಿಕೊಳ್ಳಲು ಅಥವಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಚಂದಾದಾರಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    malayalam:
        'പോസ്റ്ററുകൾ പങ്കിടാനോ ഡൗൺലോഡ് ചെയ്യാനോ സബ്‌സ്‌ക്രിപ്ഷൻ സജീവമാക്കുക.',
    marathi: 'पोस्टर्स शेअर किंवा डाउनलोड करण्यासाठी सदस्यता सक्रिय करा.',
    gujarati: 'પોસ્ટર્સ શેર અથવા ડાઉનલોડ કરવા માટે સબ્સ્ક્રિપ્શન સક્રિય કરો.',
    bengali: 'পোস্টার শেয়ার বা ডাউনলোড করতে সাবস্ক্রিপশন সক্রিয় করুন।',
    punjabi: 'ਪੋਸਟਰ ਸਾਂਝੇ ਕਰਨ ਜਾਂ ਡਾਊਨਲੋਡ ਕਰਨ ਲਈ ਗਾਹਕੀ ਨੂੰ ਸਰਗਰਮ ਕਰੋ।',
    odia: 'ପୋଷ୍ଟର ସେୟାର କିମ୍ବା ଡାଉନଲୋଡ୍ କରିବାକୁ ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ କରନ୍ତୁ।',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ বা ডাউনলোড কৰিবলৈ চাবস্ক্ৰিপচন সক্ৰিয় কৰক।',
    konkani: 'पोस्टरां वांटूंक वा डाऊनलोड करूंक वर्गणी सक्रीय करात.',
    nepali: 'पोस्टरहरू सेयर वा डाउनलोड गर्न सदस्यता सक्रिय गर्नुहोस्।',
    meitei: 'পোস্তরশিং শিয়র নত্রগা দাউনলোদ তৌনবগীদমক সবস্ক্রিপসন সনা তৌবীয়ু।',
    mizo: 'Poster share emaw download turin subscription ti nung rawh.',
    kashmiri: 'پوسٹر شیئر یا ڈاؤنلوڈ کرن خٲطرٕ کٔرِو سبسکرپشن چالوٗ।',
    ladakhi: 'པོ་སི་ཊར་བགོ་འགྲེམས་སམ་ཕབ་ལེན་ཆེད་དུ་མངགས་ཉོ་ནུས་ལྡན་བཟོས།',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
    hindi: 'सदस्यता आवश्यक है',
    tamil: 'சந்தா தேவை',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅಗತ್ಯವಿದೆ',
    malayalam: 'സബ്‌സ്‌ക്രിപ്ഷൻ ആവശ്യമാണ്',
    marathi: 'सदस्यता आवश्यक आहे',
    gujarati: 'સબ્સ્ક્રિપ્શન જરૂરી છે',
    bengali: 'সাবস্ক্রিপশন প্রয়োজন',
    punjabi: 'ਗਾਹਕੀ ਲੋੜੀਂਦੀ ਹੈ',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
    assamese: 'চাবস্ক্ৰিপচন প্ৰয়োজন',
    konkani: 'वर्गणी जाय',
    nepali: 'सदस्यता आवश्यक छ',
    meitei: 'সবস্ক্রিপসন মথৌ তাই',
    mizo: 'Subscription a ngai',
    kashmiri: 'سبسکرپشن ضۆروٗری',
    ladakhi: 'མངགས་ཉོ་དགོས།',
  );
}

// ignore: unused_element
String _subscriptionTrialTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3-दिवसीय परीक्षण योजना',
    tamil: '3 நாள் சோதனைத் திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '3 दिवसांचा ट्रायल प्लॅन',
    gujarati: '3-દિવસનો ટ્રાયલ પ્લાન',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনীয়া ট্ৰায়েল প্লেন',
    konkani: '3 दिसांचो ट्रायल प्लॅन',
    nepali: '३ दिने परीक्षण योजना',
    meitei: 'নুমিৎ 3 নিগী ত্রায়ল প্লান',
    mizo: 'Ni 3 chhung trial plan',
    kashmiri: '3 دوہُن ٹرائل پلان',
    ladakhi: 'ཉིན་ ༣ ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionTrialValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజులకు ${SubscriptionPlanConfig.trialPriceDisplay}',
    english:
        '${SubscriptionPlanConfig.trialPriceDisplay} for ${SubscriptionPlanConfig.trialDays} days',
    hindi:
        '${SubscriptionPlanConfig.trialDays} दिनों के लिए ${SubscriptionPlanConfig.trialPriceDisplay}',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாட்களுக்கு ${SubscriptionPlanConfig.trialPriceDisplay}',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳಿಗೆ ${SubscriptionPlanConfig.trialPriceDisplay}',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തേക്ക് ${SubscriptionPlanConfig.trialPriceDisplay}',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांसाठी ${SubscriptionPlanConfig.trialPriceDisplay}',
    gujarati:
        '${SubscriptionPlanConfig.trialDays} દિવસ માટે ${SubscriptionPlanConfig.trialPriceDisplay}',
    bengali:
        '${SubscriptionPlanConfig.trialDays} দিনের জন্য ${SubscriptionPlanConfig.trialPriceDisplay}',
    punjabi:
        '${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਲਈ ${SubscriptionPlanConfig.trialPriceDisplay}',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନ ପାଇଁ ${SubscriptionPlanConfig.trialPriceDisplay}',
    assamese:
        '${SubscriptionPlanConfig.trialDays} দিনৰ বাবে ${SubscriptionPlanConfig.trialPriceDisplay}',
    konkani:
        '${SubscriptionPlanConfig.trialDays} दिसां खातीर ${SubscriptionPlanConfig.trialPriceDisplay}',
    nepali:
        '${SubscriptionPlanConfig.trialDays} दिनको लागि ${SubscriptionPlanConfig.trialPriceDisplay}',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগীদমক ${SubscriptionPlanConfig.trialPriceDisplay}',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} atan ${SubscriptionPlanConfig.trialPriceDisplay}',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن خٲطرٕ ${SubscriptionPlanConfig.trialPriceDisplay}',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཆེད་དུ ${SubscriptionPlanConfig.trialPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionMonthlyTitleCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक योजना',
    tamil: 'மாதாந்திர திட்டம்',
    kannada: 'ಮಾಸಿಕ ಯೋಜನೆ',
    malayalam: 'പ്രതിമാസ പ്ലാൻ',
    marathi: 'मासिक प्लॅन',
    gujarati: 'માસિક પ્લાન',
    bengali: 'মাসিক প্ল্যান',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    assamese: 'মাহেকীয়া প্লেন',
    konkani: 'म्हयन्याचो प्लॅन',
    nepali: 'मासिक योजना',
    meitei: 'থাগী প্লান',
    mizo: 'Thla tina plan',
    kashmiri: 'ماہانہ پلان',
    ladakhi: 'ཟླ་རེའི་འཆར་གཞི།',
  );
}

// ignore: unused_element
String _subscriptionMonthlyValueCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    english: '${SubscriptionPlanConfig.monthlyPriceDisplay} per month',
    hindi: '${SubscriptionPlanConfig.monthlyPriceDisplay} प्रति माह',
    tamil: 'மாதத்திற்கு ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kannada: 'ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    malayalam: 'പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    marathi: 'दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    gujarati: 'દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    bengali: 'প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    punjabi: 'ਪ੍ਰਤੀ ਮਹੀਨਾ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    odia: 'ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    assamese: 'প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    konkani: 'दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    nepali: 'प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    meitei: 'থা খুদিংগী ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    mizo: 'Thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    kashmiri: 'پر ماہ ${SubscriptionPlanConfig.monthlyPriceDisplay}',
    ladakhi: 'ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay}',
  );
}

// ignore: unused_element
String _subscriptionRenewalCopyCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        '${SubscriptionPlanConfig.trialDays} రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు ${SubscriptionPlanConfig.monthlyPriceDisplay} ఆటో-రీన్యూ అవుతుంది. ${SubscriptionPlanConfig.trialDays} రోజులలోపు రద్దు చేస్తే, నెలవారీ ఛార్జీ వర్తించదు. ప్రస్తుత ప్లాన్ ముగిసే వరకు ప్రయోజనాలు కొనసాగుతాయి.',
    english:
        'After the ${SubscriptionPlanConfig.trialDays}-day trial, it auto-renews at ${SubscriptionPlanConfig.monthlyPriceDisplay}/month unless cancelled. If cancelled within ${SubscriptionPlanConfig.trialDays} days, the monthly charge does not apply. Benefits continue until the current plan expires.',
    hindi:
        '${SubscriptionPlanConfig.trialDays}-दिनों के परीक्षण के बाद, रद्द न करने पर यह ${SubscriptionPlanConfig.monthlyPriceDisplay}/माह पर स्वतः नवीनीकृत होगा। यदि ${SubscriptionPlanConfig.trialDays} दिनों में रद्द किया जाता है, तो मासिक शुल्क लागू नहीं होगा। लाभ मौजूदा योजना समाप्त होने तक जारी रहेंगे।',
    tamil:
        '${SubscriptionPlanConfig.trialDays} நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் ${SubscriptionPlanConfig.monthlyPriceDisplay}-க்கு தானாகப் புதுப்பிக்கப்படும். ${SubscriptionPlanConfig.trialDays} நாட்களுக்குள் ரத்து செய்தால் மாதாந்திரக் கட்டணம் பொருந்தாது. நடப்புத் திட்டம் முடியும் வரை நன்மைகள் தொடரும்.',
    kannada:
        '${SubscriptionPlanConfig.trialDays} ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ ${SubscriptionPlanConfig.monthlyPriceDisplay} ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ. ${SubscriptionPlanConfig.trialDays} ದಿನಗಳಲ್ಲಿ ರದ್ದುಗೊಳಿಸಿದರೆ ಮಾಸಿಕ ಶುಲ್ಕ ಅನ್ವಯಿಸುವುದಿಲ್ಲ. ಪ್ರಸ್ತುತ ಪ್ಲಾನ್ ಮುಗಿಯುವವರೆಗೆ ಪ್ರಯೋಜನಗಳು ಮುಂದುವರಿಯುತ್ತವೆ.',
    malayalam:
        '${SubscriptionPlanConfig.trialDays} ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം ${SubscriptionPlanConfig.monthlyPriceDisplay} നിരക്കിൽ സ്വയമേവ പുതുക്കും. ${SubscriptionPlanConfig.trialDays} ദിവസത്തിനുള്ളിൽ റദ്ദാക്കിയാൽ പ്രതിമാസ നിരക്ക് ബാധകമല്ല. നിലവിലെ പ്ലാൻ തീരുന്നതുവരെ ആനുകൂല്യങ്ങൾ തുടരും.',
    marathi:
        '${SubscriptionPlanConfig.trialDays} दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा ${SubscriptionPlanConfig.monthlyPriceDisplay} वर ऑटो-रिन्यू होईल. ${SubscriptionPlanConfig.trialDays} दिवसांच्या आत रद्द केल्यास, मासिक शुल्क आकारले जाणार नाही. चालू प्लॅन संपेपर्यंत फायदे सुरू राहतील.',
    gujarati:
        '${SubscriptionPlanConfig.trialDays}-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને ${SubscriptionPlanConfig.monthlyPriceDisplay} પર ઑટો-રિન્યૂ થાય છે. જો ${SubscriptionPlanConfig.trialDays} દિવસમાં રદ કરવામાં આવે, તો માસિક શુલ્ક લાગુ પડતું નથી. વર્તમાન પ્લાન સમાપ્ત થાય ત્યાં સુધી લાભો ચાલુ રહે છે.',
    bengali:
        '${SubscriptionPlanConfig.trialDays}-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে ${SubscriptionPlanConfig.monthlyPriceDisplay} হারে স্বতঃ-নবায়ন হবে। ${SubscriptionPlanConfig.trialDays} দিনের মধ্যে বাতিল করলে মাসিক চার্জ প্রযোজ্য হবে না। বর্তমান প্ল্যানের মেয়াদ শেষ না হওয়া পর্যন্ত সুবিধাগুলি অব্যাহত থাকবে।',
    punjabi:
        '${SubscriptionPlanConfig.trialDays}-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ ${SubscriptionPlanConfig.monthlyPriceDisplay}/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ। ਜੇਕਰ ${SubscriptionPlanConfig.trialDays} ਦਿਨਾਂ ਦੇ ਅੰਦਰ ਰੱਦ ਕੀਤਾ ਜਾਂਦਾ ਹੈ, ਤਾਂ ਮਹੀਨਾਵਾਰ ਖਰਚਾ ਲਾਗੂ ਨਹੀਂ ਹੋਵੇਗਾ। ਲਾਭ ਮੌਜੂਦਾ ਪਲਾਨ ਖਤਮ ਹੋਣ ਤੱਕ ਜਾਰੀ ਰਹਿਣਗੇ।',
    odia:
        '${SubscriptionPlanConfig.trialDays} ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ ${SubscriptionPlanConfig.monthlyPriceDisplay} ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ। ${SubscriptionPlanConfig.trialDays} ଦିନ ମଧ୍ୟରେ ବାତିଲ୍ କଲେ ମାସିକ ଶୁଳ୍କ ଲାଗୁ ହେବ ନାହିଁ। ବର୍ତ୍ତମାନର ପ୍ଲାନ୍ ସରିବା ପର୍ଯ୍ୟନ୍ତ ସୁବିଧା ଜାରି ରହିବ।',
    assamese:
        'আপোনাৰ প্লেন শেষ নোহোৱালৈকে সুবিধাসমূহ অব্যাহত থাকিব। ${SubscriptionPlanConfig.trialDays} দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে ${SubscriptionPlanConfig.monthlyPriceDisplay} ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব। ${SubscriptionPlanConfig.trialDays} দিনৰ ভিতৰত বাতিল কৰিলে মাহেকীয়া মাচুল প্ৰযোজ্য নহয়।',
    konkani:
        'चालू प्लॅन सोंपमेरेन फायदे चालू उरतले. ${SubscriptionPlanConfig.trialDays} दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक ${SubscriptionPlanConfig.monthlyPriceDisplay} प्रमाण स्वयंचलित नूतनीकरण जातलें. ${SubscriptionPlanConfig.trialDays} दिसां भितर रद्द केल्यार म्हयन्याचो आकार लागू जायना.',
    nepali:
        '${SubscriptionPlanConfig.trialDays}-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना ${SubscriptionPlanConfig.monthlyPriceDisplay} मा स्वतः नवीकरण हुन्छ। यदि ${SubscriptionPlanConfig.trialDays} दिन भित्र रद्द गरियो भने, मासिक शुल्क लाग्दैन। हालको योजना समाप्त नभएसम्म फाइदाहरू जारी रहनेछन्।',
    meitei:
        'নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা ${SubscriptionPlanConfig.monthlyPriceDisplay} দা ওতো-রিনিউ তৌগনি। নুমিৎ ${SubscriptionPlanConfig.trialDays} নিগী মনুংদা কেন্সেল তৌরবদি থাগী চান্দা লৌরোই। হৌজিক্কী প্লান লোইদ্রিফাওবা কান্নবশিং চত্থগনি।',
    mizo:
        'Ni ${SubscriptionPlanConfig.trialDays} trial hnuah, cancel loh chuan thla tin ${SubscriptionPlanConfig.monthlyPriceDisplay}-in auto-renew ang. Ni ${SubscriptionPlanConfig.trialDays} chhunga cancel chuan thla tin charge a kal lo ang. Tun thlenga plan a tawp hma chuan a hlawkna a chhunzawm zel ang.',
    kashmiri:
        '${SubscriptionPlanConfig.trialDays} دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود ${SubscriptionPlanConfig.monthlyPriceDisplay}/ماہس پؠٹھ نویں سرٕ۔ اگر ${SubscriptionPlanConfig.trialDays} دوہَن منٛز کینسل کٔرِو، تیٚلہِ لاگوٗ گژھِ نہٕ ماہانہ فیس۔ فایدٕ روزَن موٗجوٗدٕ پلان ختم گژھنَس تام جٲری۔',
    ladakhi:
        'ཉིན་ ${SubscriptionPlanConfig.trialDays} ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར ${SubscriptionPlanConfig.monthlyPriceDisplay} རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད། ཉིན་ ${SubscriptionPlanConfig.trialDays} ནང་ཕྱིར་འཐེན་བྱས་ན་ཟླ་རེའི་རིན་པ་མི་ལེན། ད་ལྟའི་འཆར་གཞི་མ་རྫོགས་བར་དུ་ཁེ་ཕན་རྣམས་འཐོབ་རྒྱུ།',
  );
}

// ignore: unused_element
String _subscriptionTermsLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

// ignore: unused_element
String _subscriptionSkipLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

// ignore: unused_element
String _subscriptionButtonLabelCleanLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ୍ରାଇବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

// ignore: unused_element
String _subscriptionPromptCopyAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu:
        'పోస్టర్లను షేర్ లేదా డౌన్‌లోడ్ చేయడానికి సబ్‌స్క్రిప్షన్ యాక్టివ్ చేయండి.',
    english: 'Activate subscription to share or download posters.',
    hindi: 'पोस्टर शेयर या डाउनलोड करने के लिए सदस्यता सक्रिय करें।',
    tamil: 'போஸ்டர்களை பகிர அல்லது பதிவிறக்க சந்தாவை இயக்கவும்.',
    kannada:
        'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಹಂಚಲು ಅಥವಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ಚಂದಾದಾರಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    malayalam:
        'പോസ്റ്ററുകൾ പങ്കിടാനോ ഡൗൺലോഡ് ചെയ്യാനോ സബ്സ്ക്രിപ്ഷൻ സജീവമാക്കുക.',
    assamese: 'পোষ্টাৰ শ্বেয়াৰ বা ডাউনলোড কৰিবলৈ সদস্যতা সক্ৰিয় কৰক।',
    konkani: 'पोस्टर शेअर वा डाउनलोड करपाक सदस्यता सुरू करात.',
    gujarati: 'પોસ્ટર શેર અથવા ડાઉનલોડ કરવા માટે સબ્સ્ક્રિપ્શન સક્રિય કરો.',
    marathi: 'पोस्टर शेअर किंवा डाउनलोड करण्यासाठी सदस्यता सक्रिय करा.',
    meitei:
        'Poster share touba nattraga download tounaba subscription active tou.',
    mizo: 'Poster share emaw download turin subscription activate rawh.',
    odia: 'ପୋଷ୍ଟର ସେୟାର କିମ୍ବା ଡାଉନଲୋଡ୍ ପାଇଁ ସବସ୍କ୍ରିପସନ୍ ସକ୍ରିୟ କରନ୍ତୁ।',
    punjabi: 'ਪੋਸਟਰ ਸਾਂਝੇ ਜਾਂ ਡਾਊਨਲੋਡ ਕਰਨ ਲਈ ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਚਾਲੂ ਕਰੋ।',
    nepali: 'पोस्टर सेयर वा डाउनलोड गर्न सदस्यता सक्रिय गर्नुहोस्।',
    bengali: 'পোস্টার শেয়ার বা ডাউনলোড করতে সাবস্ক্রিপশন চালু করুন।',
    kashmiri: 'پوسٹر شیئر یا ڈاؤنلوڈ کرنہٕ خٲطرٕ سبسکرپشن چالو کٔریو۔',
    ladakhi: 'Poster share ཡང་ན download བྱེད་པར subscription འགོ་འཛུགས་བྱེད།',
  );
}

// ignore: unused_element
String _subscriptionDialogTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రిప్షన్ అవసరం',
    english: 'Subscription Required',
    hindi: 'सदस्यता आवश्यक',
    tamil: 'சந்தா தேவை',
    kannada: 'ಚಂದಾದಾರಿಕೆ ಅಗತ್ಯ',
    malayalam: 'സബ്സ്ക്രിപ്ഷൻ ആവശ്യമാണ്',
    assamese: 'সদস্যতা প্ৰয়োজন',
    konkani: 'सदस्यता गरजेची',
    gujarati: 'સબ્સ્ક્રિપ્શન જરૂરી',
    marathi: 'सदस्यता आवश्यक',
    meitei: 'Subscription mathou tai',
    mizo: 'Subscription a ngai',
    odia: 'ସବସ୍କ୍ରିପସନ୍ ଆବଶ୍ୟକ',
    punjabi: 'ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਲੋੜੀਂਦੀ ਹੈ',
    nepali: 'सदस्यता आवश्यक',
    bengali: 'সাবস্ক্রিপশন প্রয়োজন',
    kashmiri: 'سبسکرپشن ضرٲرت',
    ladakhi: 'སབསི་ཀྲིབ་ཤན་དགོས།',
  );
}

String _subscriptionTrialTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: '3 రోజుల ట్రయల్ ప్లాన్',
    english: '3-day trial plan',
    hindi: '3 दिन का ट्रायल प्लान',
    tamil: '3 நாள் சோதனை திட்டம்',
    kannada: '3 ದಿನಗಳ ಪ್ರಾಯೋಗಿಕ ಯೋಜನೆ',
    malayalam: '3 ദിവസത്തെ ട്രയൽ പ്ലാൻ',
    marathi: '३ दिवसांची चाचणी योजना',
    gujarati: '3 દિવસની ટ્રાયલ યોજના',
    bengali: '৩ দিনের ট্রায়াল প্ল্যান',
    punjabi: '3 ਦਿਨਾਂ ਦਾ ਟ੍ਰਾਇਲ ਪਲਾਨ',
    odia: '୩ ଦିନର ଟ୍ରାଏଲ୍ ପ୍ଲାନ୍',
    assamese: '৩ দিনৰ ট্রায়েল প্লেন',
    konkani: '३ दिसांची ट्रायल येवजण',
    nepali: '३ दिने परीक्षण योजना',
    meitei: '3-day trial plan',
    mizo: '3-day trial plan',
    kashmiri: '۳ دۄہَن ہُنٛد آزمٲیِشی منصوٗبہٕ',
    ladakhi: 'ཉིན་ ༣ གྱི་ཚོད་ལྟའི་འཆར་གཞི།',
  );
}

String _subscriptionTrialValueAppLocalized(BuildContext context) {
  final days = SubscriptionPlanConfig.trialDays;
  final price = SubscriptionPlanConfig.trialPriceDisplay;
  return context.strings.localized(
    telugu: '$days రోజులకు $price',
    english: '$price for $days days',
    hindi: '$days दिनों के लिए $price',
    tamil: '$days நாட்களுக்கு $price',
    kannada: '$days ದಿನಗಳಿಗೆ $price',
    malayalam: '$days ദിവസത്തേക്ക് $price',
    marathi: '$days दिवसांसाठी $price',
    gujarati: '$days દિવસો માટે $price',
    bengali: '$days দিনের জন্য $price',
    punjabi: '$days ਦਿਨਾਂ ਲਈ $price',
    odia: '$days ଦିନ ପାଇଁ $price',
    assamese: '$days দিনৰ বাবে $price',
    konkani: '$days दिसां खातीर $price',
    nepali: '$days दिनका लागि $price',
    meitei: '$days numitki $price',
    mizo: '$days ni atan $price',
    kashmiri: '$days دۄہَن خٲطرٕ $price',
    ladakhi: '$days ཉིན་གྱི་དོན་དུ་ $price',
  );
}

String _subscriptionMonthlyTitleAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నెలవారీ ప్లాన్',
    english: 'Monthly plan',
    hindi: 'मासिक प्लान',
    tamil: 'மாதாந்திர திட்டம்',
    kannada: 'ಮಾಸಿಕ ಪ್ಲಾನ್',
    malayalam: 'മാസിക പ്ലാൻ',
    assamese: 'মাহেকীয়া প্লেন',
    konkani: 'म्हयन्याचो प्लॅन',
    gujarati: 'માસિક પ્લાન',
    marathi: 'मासिक प्लॅन',
    meitei: 'Monthly plan',
    mizo: 'Monthly plan',
    odia: 'ମାସିକ ପ୍ଲାନ୍',
    punjabi: 'ਮਹੀਨਾਵਾਰ ਪਲਾਨ',
    nepali: 'मासिक प्लान',
    bengali: 'মাসিক প্ল্যান',
    kashmiri: 'ماہانہ پلان',
    ladakhi: 'Monthly plan',
  );
}

String _subscriptionMonthlyValueAppLocalized(BuildContext context) {
  final price = SubscriptionPlanConfig.monthlyPriceDisplay;
  return context.strings.localized(
    telugu: 'నెలకు $price',
    english: '$price per month',
    hindi: '$price प्रति माह',
    tamil: 'மாதத்திற்கு $price',
    kannada: 'ತಿಂಗಳಿಗೆ $price',
    malayalam: 'മാസം $price',
    assamese: 'প্ৰতি মাহে $price',
    konkani: 'म्हयन्याक $price',
    gujarati: 'દર મહિને $price',
    marathi: 'दर महिन्याला $price',
    meitei: 'tha khuding $price',
    mizo: 'thla tin $price',
    odia: 'ମାସକୁ $price',
    punjabi: 'ਪ੍ਰਤੀ ਮਹੀਨਾ $price',
    nepali: 'प्रति महिना $price',
    bengali: 'প্রতি মাসে $price',
    kashmiri: 'مہینس $price',
    ladakhi: 'ཟླ་རེར $price',
  );
}

String _subscriptionRenewalCopyAppLocalized(BuildContext context) {
  final days = SubscriptionPlanConfig.trialDays;
  final price = SubscriptionPlanConfig.monthlyPriceDisplay;
  final copy =
      'After the $days-day trial, it auto-renews at $price/month unless cancelled.';
  return context.strings.localized(
    telugu:
        '$days రోజుల ట్రయల్ తర్వాత, రద్దు చేయకపోతే నెలకు $price ఆటో-రీన్యూ అవుతుంది.',
    english: copy,
    hindi:
        '$days-दिनों के परीक्षण के बाद, रद्द न करने पर यह $price/माह पर स्वतः नवीनीकृत होगा।',
    tamil:
        '$days நாள் சோதனைக்குப் பிறகு, ரத்து செய்யாவிட்டால் மாதம் $price-க்கு தானாகப் புதுப்பிக்கப்படும்.',
    kannada:
        '$days ದಿನಗಳ ಪ್ರಯೋಗದ ನಂತರ, ರದ್ದುಗೊಳಿಸದಿದ್ದರೆ ತಿಂಗಳಿಗೆ $price ಸ್ವಯಂ-ನವೀಕರಣಗೊಳ್ಳುತ್ತದೆ.',
    malayalam:
        '$days ദിവസത്തെ ട്രയലിന് ശേഷം, റദ്ദാക്കിയില്ലെങ്കിൽ പ്രതിമാസം $price നിരക്കിൽ സ്വയമേവ പുതുക്കും.',
    marathi:
        '$days दिवसांच्या चाचणीनंतर, रद्द न केल्यास दरमहा $price वर ऑटो-रिन्यू होईल.',
    gujarati:
        '$days-દિવસની અજમાયશ પછી, રદ ન કરવામાં આવે તો તે દર મહિને $price પર ઑટો-રિન્યૂ થાય છે.',
    bengali:
        '$days-দিনের ট্রায়ালের পরে, বাতিল না করা হলে প্রতি মাসে $price হারে স্বতঃ-নবায়ন হবে।',
    punjabi:
        '$days-ਦਿਨਾਂ ਦੇ ਟਰਾਇਲ ਤੋਂ ਬਾਅਦ, ਰੱਦ ਨਾ ਕਰਨ \'ਤੇ ਇਹ $price/ਮਹੀਨਾ \'ਤੇ ਸਵੈ-ਨਵਿਆਇਆ ਜਾਵੇਗਾ।',
    odia:
        '$days ଦିନର ଟ୍ରାଏଲ୍ ପରେ, ବାତିଲ୍ ନକଲେ ଏହା ମାସକୁ $price ରେ ସ୍ୱୟଂ-ନବୀକରଣ ହେବ।',
    assamese:
        '$days দিনীয়া ট্ৰায়েলৰ পিছত, বাতিল নকৰিলে প্ৰতি মাহে $price ত স্বয়ংক্ৰিয়ভাৱে নবীকৰণ হ’ব।',
    konkani:
        '$days दिसांच्या चाचणी उपरांत, रद्द करीना जाल्यार दर म्हयन्याक $price प्रमाण स्वयंचलित नूतनीकरण जातलें.',
    nepali:
        '$days-दिने परीक्षण पछि, रद्द नगरेमा यो प्रति महिना $price मा स्वतः नवीकरण हुन्छ।',
    meitei:
        'নুমিৎ $days নিগী ত্রায়ল মতুংদা, কেন্সেল তৌদ্রবদি থাদা $price দা ওতো-রিনিউ তৌগনি।',
    mizo:
        'Ni $days trial hnuah, cancel loh chuan thla tin $price-in auto-renew ang.',
    kashmiri:
        '$days دوہَن ہُنٛد ٹرائل پتہٕ، کینسل نہٕ کرنہٕ کِس صورتس منٛز گژھِ یہِ خود بخود $price/ماہس پؠٹھ نویں سرٕ۔',
    ladakhi:
        'ཉིན་ $days ཚོད་ལྟའི་རྗེས་སུ། ཕྱིར་འཐེན་མ་བྱས་ན་ཟླ་རེར $price རང་བཞིན་གྱིས་གསར་བཟོ་བྱེད།',
  );
}

String _subscriptionTermsLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'నిబంధనలు',
    english: 'Terms',
    hindi: 'नियम',
    tamil: 'விதிமுறைகள்',
    kannada: 'ನಿಯಮಗಳು',
    malayalam: 'നിബന്ധനകൾ',
    marathi: 'अटी',
    gujarati: 'શરતો',
    bengali: 'শর্তাবলী',
    punjabi: 'ਸ਼ਰਤਾਂ',
    odia: 'ନିୟମାବଳୀ',
    assamese: 'চৰ্তাৱলী',
    konkani: 'अटी',
    nepali: 'सर्तहरू',
    meitei: 'চৎন-পথাপশিং',
    mizo: 'Hman dan tur',
    kashmiri: 'شرائط',
    ladakhi: 'ཆ་རྐྱེན།',
  );
}

String _subscriptionSkipLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'దాటవేయి',
    english: 'Skip',
    hindi: 'छोड़ें',
    tamil: 'தவிர்',
    kannada: 'ಬಿಟ್ಟುಬಿಡಿ',
    malayalam: 'ഒഴിവാക്കുക',
    marathi: 'वगळा',
    gujarati: 'છોડો',
    bengali: 'এড়িয়ে যান',
    punjabi: 'ਛੱਡੋ',
    odia: 'ଛାଡ଼ନ୍ତୁ',
    assamese: 'এৰক',
    konkani: 'सोडून दियात',
    nepali: 'छोड्नुहोस्',
    meitei: 'থাংদোইথোকউ',
    mizo: 'Kalsan rawh',
    kashmiri: 'ترک کٔرِو',
    ladakhi: 'མཆོང་།',
  );
}

String _subscriptionButtonLabelAppLocalized(BuildContext context) {
  return context.strings.localized(
    telugu: 'సబ్‌స్క్రైబ్ చేయండి',
    english: 'Subscribe',
    hindi: 'सदस्यता लें',
    tamil: 'குழுசேர்',
    kannada: 'ಚಂದಾದಾರರಾಗಿ',
    malayalam: 'സബ്സ്ക്രൈബ് ചെയ്യുക',
    marathi: 'सदस्यता घ्या',
    gujarati: 'સબ્સ્ક્રાઇબ કરો',
    bengali: 'সাবস্ক্রাইব করুন',
    punjabi: 'ਗਾਹਕ ਬਣੋ',
    odia: 'ସବସ୍କ੍ਰਾਈବ୍ କରନ୍ତୁ',
    assamese: 'চাবস্ক্ৰাইব কৰক',
    konkani: 'वर्गणीदार जायात',
    nepali: 'सदस्यता लिनुहोस्',
    meitei: 'সবস্ক্রাইব তৌবীয়ু',
    mizo: 'Subscribe rawh',
    kashmiri: 'سبسکرائب کٔرِو',
    ladakhi: 'མངགས་ཉོ་བྱོས།',
  );
}

String _posterShareLabel(BuildContext context) => 'Share';
String _posterDownloadLabel(BuildContext context) => 'Download';
