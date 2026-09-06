import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/app_survey.dart';
import 'package:mana_poster/features/prehome/services/app_survey_service.dart';

class AppSurveyBottomSheet extends StatefulWidget {
  const AppSurveyBottomSheet({
    super.key,
    required this.survey,
    this.onDismiss,
  });

  final AppSurvey survey;
  final VoidCallback? onDismiss;

  @override
  State<AppSurveyBottomSheet> createState() => _AppSurveyBottomSheetState();
}

class _AppSurveyBottomSheetState extends State<AppSurveyBottomSheet> {
  late final PageController _pageController;
  late final TextEditingController _commentController;
  int _currentPage = 0;
  final Map<int, int> _selectedAnswers = <int, int>{};
  bool _submitting = false;
  bool _submitted = false;

  List<SurveyQuestion> get _questions {
    if (widget.survey.questions.isNotEmpty) {
      return widget.survey.questions;
    }
    return [
      SurveyQuestion(
        id: 'q_0',
        question: widget.survey.question,
        options: widget.survey.options,
        voteCounts: widget.survey.voteCounts,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleOptionSelected(int qIndex, int optionIndex) async {
    if (_submitting || _submitted) {
      return;
    }

    setState(() {
      _selectedAnswers[qIndex] = optionIndex;
    });

    final total = _questions.length;
    if (qIndex < total - 1) {
      // Brief delay for visual touch confirmation
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;

      // Smoothly advance to next question in carousel
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentPage = qIndex + 1;
      });
    }
    // On the final question, we keep the option selected so user can optionally write a comment and press submit.
  }

  void _previousQuestion() {
    if (_currentPage > 0 && !_submitting) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _submitAll() async {
    if (_submitting || _submitted) {
      return;
    }

    setState(() => _submitting = true);

    final success = await AppSurveyService.instance.submitResponse(
      survey: widget.survey,
      selectedAnswers: _selectedAnswers,
      selectedOptionIndex: _selectedAnswers[0],
      userComment: _commentController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_submitFailedLabel(context)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final totalQuestions = questions.length;
    final selectedOpt = _selectedAnswers[_currentPage];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _submitted
            ? _buildSuccessView()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Row
                  Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _previousQuestion,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.poll_rounded,
                            size: 18,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.survey.title.isNotEmpty
                              ? widget.survey.title
                              : _surveyTitleLabel(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalQuestions > 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1} / $totalQuestions',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.black45,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          widget.onDismiss?.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),

                  // Progress bar if multiple questions
                  if (totalQuestions > 1) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / totalQuestions,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Carousel Container
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.58,
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalQuestions,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentPage = idx;
                        });
                      },
                      itemBuilder: (context, qIndex) {
                        final question = questions[qIndex];
                        final currentSelected = _selectedAnswers[qIndex];
                        final isLastQuestion = qIndex == totalQuestions - 1;

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                question.question,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...List.generate(question.options.length, (optIdx) {
                                final isSelected = currentSelected == optIdx;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: InkWell(
                                    onTap: _submitting
                                        ? null
                                        : () => _handleOptionSelected(
                                              qIndex,
                                              optIdx,
                                            ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEEF2FF)
                                            : const Color(0xFFF8FAFC),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked_rounded
                                                : Icons.radio_button_off_rounded,
                                            size: 20,
                                            color: isSelected
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              question.options[optIdx],
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? const Color(0xFF1E1B4B)
                                                    : const Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Optional comment input box on the final question
                              if (isLastQuestion) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _optionalFeedbackLabel(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _commentController,
                                  maxLines: 2,
                                  maxLength: 200,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _feedbackHintLabel(context),
                                    hintStyle: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    counterText: '',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF6366F1),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Actions
                  Row(
                    children: [
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                widget.onDismiss?.call();
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          _laterLabel(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: (selectedOpt == null || _submitting)
                              ? null
                              : () {
                                  if (_currentPage < totalQuestions - 1) {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                    );
                                    setState(() => _currentPage++);
                                  } else {
                                    _submitAll();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentPage < totalQuestions - 1
                                      ? _nextQuestionLabel(context)
                                      : _submitLabel(context),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 56,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(height: 16),
          Text(
            _thankYouLabel(context),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _feedbackSubmittedLabel(context),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _surveyTitleLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'యూజర్ సర్వే',
        english: 'User Survey',
        hindi: 'यूज़र सर्वे',
        tamil: 'பயனர் கணக்கெடுப்பு',
        kannada: 'ಬಳಕೆದಾರರ ಸಮೀಕ್ಷೆ',
        malayalam: 'ഉപയോക്തൃ സർവേ',
        marathi: 'वापरकर्ता सर्वेक्षण',
        gujarati: 'વપરાશકર્તા સર્વે',
        bengali: 'ব্যবহারকারী জরিপ',
        punjabi: 'ਯੂਜ਼ਰ ਸਰਵੇਖਣ',
        odia: 'ବ୍ୟବହାରକାରୀ ସର୍ଭେ',
        assamese: 'ব্যৱহাৰকাৰী জৰীপ',
        konkani: 'वापरपी सर्व्हे',
        nepali: 'प्रयोगकर्ता सर्वेक्षण',
        meitei: 'User Survey',
        mizo: 'Hmanrua Survey',
        kashmiri: 'صارف سروے',
        ladakhi: 'User Survey',
      );

  static String _submitFailedLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'సమర్పించడం విఫలమైంది. దయచేసి మళ్ళీ ప్రయత్నించండి.',
        english: 'Submission failed. Please try again.',
        hindi: 'सबमिट करना विफल रहा। कृपया पुनः प्रयास करें।',
        tamil: 'சமர்ப்பித்தல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
        kannada: 'ಸಲ್ಲಿಸುವುದು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
        malayalam: 'സമർപ്പിക്കൽ പരാജയപ്പെട്ടു. ദയവായി വീണ്ടും ശ്രമിക്കുക.',
        marathi: 'सबमिट करणे अयशस्वी झाले. कृपया पुन्हा प्रयत्न करा.',
        gujarati: 'સબમિટ કરવાનું નિષ્ફળ ગયું. કૃપા કરીને ફરી પ્રયાસ કરો.',
        bengali: 'জমা দেওয়া ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
        punjabi: 'ਸਬਮਿਟ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
        odia: 'ଦାଖଲ ବିଫଳ ହେଲା। ଦୟାକରି ପୁନର୍ବାର ଚେଷ୍ଟା କରନ୍ତୁ।',
        assamese: 'দাখিল কৰা ব্যৰ্থ হ’ল। অনুগ্ৰহ কৰি পুনৰ চেষ্টা কৰক।',
        konkani: 'सबमिट करप अपेस जाಲೆಂ. उपकार करून परत यत्न करात.',
        nepali: 'सबमिट गर्न असफल भयो। कृपया पुन: प्रयास गर्नुहोस्।',
        meitei: 'Submitting failed. Please try again.',
        mizo: 'Submit a hlawhchham. Khawngaihin han ti leh rawh.',
        kashmiri: 'جمع کرنس مَنٛز آو نقْصان۔ مہرَبٲنی کٔرِتھ پؠٹھ کوشش کٔرِو۔',
        ladakhi: 'Submission failed. Please try again.',
      );

  static String _optionalFeedbackLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'అదనపు అభిప్రాయం / సూచనలు (ఐచ్ఛికం)',
        english: 'Additional feedback / suggestions (optional)',
        hindi: 'अतिरिक्त प्रतिक्रिया / सुझाव (वैकल्पिक)',
        tamil: 'கூடுதல் கருத்து / பரிந்துரைகள் (விருப்பத்தேர்வு)',
        kannada: 'ಹೆಚ್ಚುವರಿ ಪ್ರತಿಕ್ರಿಯೆ / ಸಲಹೆಗಳು (ಐಚ್ಛಿಕ)',
        malayalam: 'കൂടുതൽ അഭിപ്രായം / നിർദ്ദേശങ്ങൾ (ഓപ്ഷണൽ)',
        marathi: 'अतिरिक्त अभिप्राय / सूचना (पर्यायी)',
        gujarati: 'વધારાનો પ્રતિસાદ / સૂચનો (વૈકલ્પિક)',
        bengali: 'অতিরিক্ত প্রতিক্রিয়া / পরামর্শ (ঐচ্ছিক)',
        punjabi: 'ਵਾਧੂ ਫੀਡਬੈਕ / ਸੁਝਾਅ (ਵਿਕਲਪਿਕ)',
        odia: 'ଅତିରିକ୍ତ ମତାମତ / ପରାମର୍ଶ (ଐଚ୍ଛିକ)',
        assamese: 'অতিৰিক্ত মতামত / পৰামৰ্শ (ঐচ্ছিক)',
        konkani: 'चડतीक प्रतिक्रिया / सुचोवणी (ऐच्छिक)',
        nepali: 'थप प्रतिक्रिया / सुझावहरू (वैकल्पिक)',
        meitei: 'Additional feedback / suggestions (optional)',
        mizo: 'Ngaihdan dang / rawtna (optional)',
        kashmiri: 'اضافی رائے / تجاویز (اختیاری)',
        ladakhi: 'Additional feedback / suggestions (optional)',
      );

  static String _feedbackHintLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'మీ సలహాలు లేదా సూచనలు ఇక్కడ రాయండి...',
        english: 'Write your suggestions or comments here...',
        hindi: 'अपने सुझाव या टिप्पणी यहाँ लिखें...',
        tamil: 'உங்கள் பரிந்துரைகள் அல்லது கருத்துகளை இங்கே எழுதுங்கள்...',
        kannada: 'ನಿಮ್ಮ ಸಲಹೆಗಳು ಅಥವಾ ಅಭಿಪ್ರಾಯಗಳನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...',
        malayalam: 'നിങ്ങളുടെ നിർദ്ദേശങ്ങളോ അഭിപ്രായങ്ങളോ ഇവിടെ എഴുതുക...',
        marathi: 'आपल्या सूचना किंवा अभिप्राय येथे लिहा...',
        gujarati: 'તમારા સૂચનો અથવા ટિપ્પણીઓ અહીં લખો...',
        bengali: 'আপনার পরামর্শ বা মন্তব্য এখানে লিখুন...',
        punjabi: 'ਆਪਣੇ ਸੁਝਾਅ ਜਾਂ ਟਿੱਪਣੀਆਂ ਇੱਥੇ ਲਿਖੋ...',
        odia: 'ଆପଣଙ୍କ ପରାମର୍ଶ କିମ୍ବା ମନ୍ତବ୍ୟ ଏଠାରେ ଲେଖନ୍ତୁ...',
        assamese: 'আপোনাৰ পৰামৰ্শ বা মন্তব্য ইয়াত লিখক...',
        konkani: 'तुमच्यो सुचोवण्यो वा मंतव्यां हांगा बरयात...',
        nepali: 'आफ्ना सुझाव वा टिप्पणीहरू यहाँ लेख्नुहोस्...',
        meitei: 'Write your suggestions or comments here...',
        mizo: 'I rawtna emaw ngaihdan hetah hian ziak rawh...',
        kashmiri: 'پنٕنؠ تجاویز یا رائے ییٚتہِ لؠکھِو...',
        ladakhi: 'Write your suggestions or comments here...',
      );

  static String _laterLabel(BuildContext context) => context.strings.localized(
        telugu: 'తర్వాత',
        english: 'Later',
        hindi: 'बाद में',
        tamil: 'பிறகு',
        kannada: 'ನಂತರ',
        malayalam: 'പിന്നീട്',
        marathi: 'नंतर',
        gujarati: 'પછી',
        bengali: 'পরে',
        punjabi: 'ਬਾਅਦ ਵਿੱਚ',
        odia: 'ପରେ',
        assamese: 'পাছত',
        konkani: 'मागीर',
        nepali: 'पछि',
        meitei: 'Later',
        mizo: 'Nakinah',
        kashmiri: 'پتہٕ',
        ladakhi: 'Later',
      );

  static String _nextQuestionLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'తదుపరి ప్రశ్న →',
        english: 'Next Question →',
        hindi: 'अगला प्रश्न →',
        tamil: 'அடுத்த கேள்வி →',
        kannada: 'ಮುಂದಿನ ಪ್ರಶ್ನೆ →',
        malayalam: 'അടുത്ത ചോദ്യം →',
        marathi: 'पुढील प्रश्न →',
        gujarati: 'આગળનો પ્રશ્ન →',
        bengali: 'পরবর্তী প্রশ্ন →',
        punjabi: 'ਅਗਲਾ ਸਵਾਲ →',
        odia: 'ପରବର୍ତ୍ତୀ ପ୍ରଶ୍ନ →',
        assamese: 'পৰৱৰ্তী প্ৰশ্ন →',
        konkani: 'फुडलो प्रश्न →',
        nepali: 'अर्को प्रश्न →',
        meitei: 'Next Question →',
        mizo: 'Zawhna dawt leh →',
        kashmiri: 'اگلا سوال →',
        ladakhi: 'Next Question →',
      );

  static String _submitLabel(BuildContext context) => context.strings.localized(
        telugu: 'సమర్పించు',
        english: 'Submit',
        hindi: 'सबमिट करें',
        tamil: 'சமர்ப்பி',
        kannada: 'ಸಲ್ಲಿಸಿ',
        malayalam: 'സമർപ്പിക്കുക',
        marathi: 'सबमिट करा',
        gujarati: 'સબમિટ કરો',
        bengali: 'জমা দিন',
        punjabi: 'ਸਬਮਿਟ ਕਰੋ',
        odia: 'ଦାଖଲ କରନ୍ତୁ',
        assamese: 'দাখিল কৰক',
        konkani: 'सबमिट करात',
        nepali: 'सबमिट गर्नुहोस्',
        meitei: 'Submit',
        mizo: 'Submit rawh',
        kashmiri: 'جمع کٔرِو',
        ladakhi: 'Submit',
      );

  static String _thankYouLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'ధన్యవాదాలు!',
        english: 'Thank You!',
        hindi: 'धन्यवाद!',
        tamil: 'நன்றி!',
        kannada: 'ಧನ್ಯವಾದಗಳು!',
        malayalam: 'നന്ദി!',
        marathi: 'धन्यवाद!',
        gujarati: 'આભાર!',
        bengali: 'ধন্যবাদ!',
        punjabi: 'ਧੰਨਵਾਦ!',
        odia: 'ଧନ୍ୟବାଦ!',
        assamese: 'ধন্যবাদ!',
        konkani: 'देव बरें करूं!',
        nepali: 'धन्यवाद!',
        meitei: 'Thank You!',
        mizo: 'Ka lawm e!',
        kashmiri: 'شُکریہ!',
        ladakhi: 'Thank You!',
      );

  static String _feedbackSubmittedLabel(BuildContext context) =>
      context.strings.localized(
        telugu: 'మీ విలువైన అభిప్రాయం విజయవంతంగా అందింది.',
        english: 'Your valuable feedback has been submitted successfully.',
        hindi: 'आपकी बहुमूल्य प्रतिक्रिया सफलतापूर्वक प्राप्त हो गई है।',
        tamil: 'உங்கள் மதிப்புமிக்க கருத்து வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது.',
        kannada: 'ನಿಮ್ಮ ಅಮೂಲ್ಯವಾದ ಪ್ರತಿಕ್ರಿಯೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಸಲ್ಲಿಸಲಾಗಿದೆ.',
        malayalam: 'നിങ്ങളുടെ വിലയേറിയ അഭിപ്രായം വിജയകരമായി സമർപ്പിച്ചു.',
        marathi: 'तुमचा मौल्यवान अभिप्राय यशस्वीरीत्या सबमिट झाला आहे.',
        gujarati: 'તમારો મૂલ્યવાન પ્રતિસાદ સફળતાપૂર્વક સબમિટ થઈ ગયો છે.',
        bengali: 'আপনার মূল্যবান মতামত সফলভাবে জমা হয়েছে।',
        punjabi: 'ਤੁਹਾਡਾ ਕੀਮਤੀ ਫੀਡਬੈਕ ਸਫਲਤਾਪੂਰਵਕ ਸਬਮਿਟ ਹੋ ਗਿਆ ਹੈ।',
        odia: 'ଆପଣଙ୍କ ମୂଲ୍ୟବାନ ମତାମତ ସଫଳତାର ସହ ଦାଖଲ ହୋଇଛି।',
        assamese: 'আপোনাৰ মূল্যৱান মতামত সফলতাৰে দাখিল কৰা হৈছে।',
        konkani: 'तुमची मोलाची प्रतिक्रिया येಶಸ್ವಿपणान पावल्या.',
        nepali: 'तपाईंको बहुमूल्य प्रतिक्रिया सफलतापूर्वक पेश गरिएको छ।',
        meitei: 'Your valuable feedback has been submitted successfully.',
        mizo: 'I ngaihdan hlu tak chu hlawhtling takin thehluh a ni e.',
        kashmiri: 'تہُند قۭمتی رائے چھُ کٲمیابی سان جمع گومُت۔',
        ladakhi: 'Your valuable feedback has been submitted successfully.',
      );
}
