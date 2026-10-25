// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _EmptyPosterGameState extends StatefulWidget {
  const _EmptyPosterGameState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.categorySlug,
    required this.categoryLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String categorySlug;
  final String categoryLabel;

  @override
  State<_EmptyPosterGameState> createState() => _EmptyPosterGameStateState();
}

class _EmptyPosterGameStateState extends State<_EmptyPosterGameState> {
  bool _gameStarted = false;
  static int _globalHighScore = 0;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (_gameStarted) {
      return _SnakePosterGameCard(
        key: ValueKey<String>(
          'snake-${widget.categorySlug}-${widget.categoryLabel}',
        ),
        initialHighScore: _globalHighScore,
        onHighScoreUpdated: (score) {
          if (score > _globalHighScore) {
            _globalHighScore = score;
          }
        },
        onExit: () => setState(() => _gameStarted = false),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HomeFeedState(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
        ),
        const SizedBox(height: 12),
        _SnakeCountdownCard(
          key: const ValueKey<String>('snake-countdown'),
          label: strings.localized(
            telugu: 'పోస్టర్లు లోడ్ అయ్యే వరకు స్నేక్ గేమ్ ఆడండి',
            english: 'Play Snake while posters load',
            hindi: 'पोस्टर लोड होने तक स्नेक गेम खेलें',
            tamil: 'போஸ்டர்கள் ஏற்றப்படும் வரை ஸ்னேக் கேம் விளையாடுங்கள்',
            kannada: 'ಪೋಸ್ಟರ್‌ಗಳು ಲೋಡ್ ಆಗುವವರೆಗೆ ಸ್ನೇಕ್ ಗೇಮ್ ಆಡಿ',
            malayalam: 'പോസ്റ്ററുകൾ ലോഡാകുന്നതുവരെ സ്നേക്ക് ഗെയിം കളിക്കുക',
            marathi: 'पोस्टर्स लोड होईपर्यंत स्नेक गेम खेळा',
            gujarati: 'પોસ્ટરો લોડ થાય ત્યાં સુધી સ્નેક ગેમ રમો',
            bengali: 'পোস্টার লোড হওয়ার সময় স্নেক গেম খেলুন',
            punjabi: 'ਪੋਸਟਰ ਲੋਡ ਹੋਣ ਤੱਕ ਸੱਪ ਵਾਲੀ ਗੇਮ ਖੇਡੋ',
            odia: 'ପୋଷ୍ଟର ଲୋଡ୍ ହେବା ପର୍ଯ୍ୟନ୍ତ ସ୍ନେକ୍ ଗେମ୍ ଖେଳନ୍ତୁ',
            assamese: 'পোষ্টাৰ লোড হোৱালৈকে স্নেক গেম খেলক',
            konkani: 'पोस्टरां लोड जावंचे मेरेन स्नेक खेळ खेळात',
            nepali: 'पोस्टर लोड हुँदा सम्म स्नेक गेम खेल्नुहोस्',
            meitei: 'পোস্তরশিং লোদ ওইরিঙৈ মনুংদা স্নেক শান্নবীয়ু',
            mizo: 'Poster load chhungin Snake game khel rawh',
            kashmiri: 'پوسٹر لوڈ گژھنس تام گِندِو سنیک گیم',
            ladakhi: 'པོ་སི་ཊར་མ་བསླེབ་བར་དུ་སྦྲུལ་གྱི་རྩེད་མོ་རྩེས།',
          ),
          onPlay: () => setState(() => _gameStarted = true),
        ),
      ],
    );
  }
}

class _SnakeCountdownCard extends StatelessWidget {
  const _SnakeCountdownCard({
    super.key,
    required this.label,
    required this.onPlay,
  });

  final String label;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videogame_asset_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              strings.localized(
                telugu: 'ఆడండి',
                english: 'Play',
                hindi: 'खेलें',
                tamil: 'விளையாடு',
                kannada: 'ಆಟವಾಡಿ',
                malayalam: 'കളിക്കുക',
                marathi: 'खेळा',
                gujarati: 'રમો',
                bengali: 'খেলুন',
                punjabi: 'ਖੇਡੋ',
                odia: 'ଖେଳନ୍ତୁ',
                assamese: 'খেলক',
                konkani: 'खेळात',
                nepali: 'खेल्नुहोस्',
                meitei: 'শান্নবীয়ু',
                mizo: 'Khel rawh',
                kashmiri: 'گِندِو',
                ladakhi: 'རྩེས།',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SnakeDirection { up, right, down, left }

class _SnakePosterGameCard extends StatefulWidget {
  const _SnakePosterGameCard({
    super.key,
    required this.initialHighScore,
    required this.onHighScoreUpdated,
    required this.onExit,
  });

  final int initialHighScore;
  final ValueChanged<int> onHighScoreUpdated;
  final VoidCallback onExit;

  @override
  State<_SnakePosterGameCard> createState() => _SnakePosterGameCardState();
}

class _SnakePosterGameCardState extends State<_SnakePosterGameCard> {
  static const int _gridSize = 14;
  static const Duration _tickDuration = Duration(milliseconds: 220);
  final math.Random _random = math.Random();
  Timer? _timer;

  List<math.Point<int>> _snake = const <math.Point<int>>[
    math.Point<int>(6, 7),
    math.Point<int>(5, 7),
    math.Point<int>(4, 7),
  ];
  math.Point<int> _food = const math.Point<int>(10, 7);
  _SnakeDirection _direction = _SnakeDirection.right;
  _SnakeDirection _nextDirection = _SnakeDirection.right;
  int _score = 0;
  late int _highScore;
  bool _gameOver = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _highScore = widget.initialHighScore;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (_) => _tick());
  }

  void _tick() {
    if (!mounted || _gameOver || _isPaused) {
      return;
    }
    final head = _snake.first;
    final direction = _nextDirection;
    final nextHead = switch (direction) {
      _SnakeDirection.up => math.Point<int>(head.x, head.y - 1),
      _SnakeDirection.right => math.Point<int>(head.x + 1, head.y),
      _SnakeDirection.down => math.Point<int>(head.x, head.y + 1),
      _SnakeDirection.left => math.Point<int>(head.x - 1, head.y),
    };
    final wrappedHead = math.Point<int>(
      (nextHead.x + _gridSize) % _gridSize,
      (nextHead.y + _gridSize) % _gridSize,
    );
    final ateFood = wrappedHead == _food;
    final nextSnake = <math.Point<int>>[wrappedHead, ..._snake];
    if (!ateFood) {
      nextSnake.removeLast();
    }
    final hitSelf = nextSnake.skip(1).contains(wrappedHead);
    if (hitSelf) {
      setState(() => _gameOver = true);
      _timer?.cancel();
      return;
    }
    setState(() {
      _direction = direction;
      _snake = nextSnake;
      if (ateFood) {
        _score++;
        if (_score > _highScore) {
          _highScore = _score;
          widget.onHighScoreUpdated(_score);
        }
        _food = _newFood(nextSnake);
      }
    });
  }

  math.Point<int> _newFood(List<math.Point<int>> occupied) {
    if (occupied.length >= _gridSize * _gridSize) {
      return const math.Point<int>(0, 0);
    }
    while (true) {
      final point = math.Point<int>(
        _random.nextInt(_gridSize),
        _random.nextInt(_gridSize),
      );
      if (!occupied.contains(point)) {
        return point;
      }
    }
  }

  void _setDirection(_SnakeDirection direction) {
    final opposite = switch (_direction) {
      _SnakeDirection.up => _SnakeDirection.down,
      _SnakeDirection.right => _SnakeDirection.left,
      _SnakeDirection.down => _SnakeDirection.up,
      _SnakeDirection.left => _SnakeDirection.right,
    };
    if (direction == opposite) {
      return;
    }
    setState(() => _nextDirection = direction);
  }

  void _handleDrag(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < 70) {
      return;
    }
    if (velocity.dx.abs() > velocity.dy.abs()) {
      _setDirection(
        velocity.dx > 0 ? _SnakeDirection.right : _SnakeDirection.left,
      );
    } else {
      _setDirection(
        velocity.dy > 0 ? _SnakeDirection.down : _SnakeDirection.up,
      );
    }
  }

  void _restart() {
    setState(() {
      _snake = const <math.Point<int>>[
        math.Point<int>(6, 7),
        math.Point<int>(5, 7),
        math.Point<int>(4, 7),
      ];
      _food = const math.Point<int>(10, 7);
      _direction = _SnakeDirection.right;
      _nextDirection = _SnakeDirection.right;
      _score = 0;
      _gameOver = false;
      _isPaused = false;
    });
    _startTimer();
  }

  void _togglePause() {
    if (_gameOver) {
      _restart();
      return;
    }
    setState(() => _isPaused = !_isPaused);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    final gameTitle = strings.localized(
      telugu: 'స్నేక్ గేమ్',
      english: 'Snake Game',
      hindi: 'स्नेक गेम',
      tamil: 'ஸ்னேக் கேம்',
      kannada: 'ಸ್ನೇಕ್ ಗೇಮ್',
      malayalam: 'സ്നേക്ക് ഗെയിം',
      marathi: 'स्नेक गेम',
      gujarati: 'સ્નેક ગેમ',
      bengali: 'স্নেক গেম',
      punjabi: 'ਸੱਪ ਵਾਲੀ ਗੇਮ',
      odia: 'ସ୍ନେକ୍ ଗେମ୍',
      assamese: 'স্নেক গেম',
      konkani: 'स्नेक खेळ',
      nepali: 'स्नेक गेम',
      meitei: 'স্নেক শান্নপোৎ',
      mizo: 'Snake Game',
      kashmiri: 'سنیک گیم',
      ladakhi: 'སྦྲུལ་གྱི་རྩེད་མོ།',
    );

    final gameOverLabel = strings.localized(
      telugu: 'గేమ్ ముగిసింది',
      english: 'Game Over',
      hindi: 'खेल समाप्त',
      tamil: 'ஆட்டம் முடிந்தது',
      kannada: 'ಆಟ ಮುಕ್ತಾಯ',
      malayalam: 'ഗെയിം അവസാനിച്ചു',
      marathi: 'खेळ संपला',
      gujarati: 'રમત સમાપ્ત',
      bengali: 'খেলা সমাপ্ত',
      punjabi: 'ਗੇਮ ਖਤਮ',
      odia: 'ଖେଳ ସମାପ୍ତ',
      assamese: 'খেল সমাপ্ত',
      konkani: 'खेळ सोंपलो',
      nepali: 'खेल समाप्त',
      meitei: 'শান্নবা লোইরে',
      mizo: 'Game tawp',
      kashmiri: 'گیم گوو ختم',
      ladakhi: 'རྩེད་མོ་རྫོགས།',
    );

    final playAgainLabel = strings.localized(
      telugu: 'మళ్లీ ఆడండి',
      english: 'Play again',
      hindi: 'फिर से खेलें',
      tamil: 'மீண்டும் விளையாடு',
      kannada: 'ಮತ್ತೆ ಆಟವಾಡಿ',
      malayalam: 'വീണ്ടും കളിക്കുക',
      marathi: 'पुन्हा खेळा',
      gujarati: 'ફરીથી રમો',
      bengali: 'আবার খেলুন',
      punjabi: 'ਦੁਬਾਰਾ ਖੇਡੋ',
      odia: 'ପୁନର୍ବାର ଖେଳନ୍ତୁ',
      assamese: 'পুনৰ খেলক',
      konkani: 'परत खेळात',
      nepali: 'फेरि खेल्नुहोस्',
      meitei: 'অমুক হন্না শান্নবীয়ু',
      mizo: 'Khel nawn leh rawh',
      kashmiri: 'دُوبارٕ گِندِو',
      ladakhi: 'ཡང་བསྐྱར་རྩེས།',
    );

    final pausedLabel = strings.localized(
      telugu: 'పాజ్ చేయబడింది',
      english: 'Paused',
      hindi: 'रोका गया',
      tamil: 'இடைநிறுத்தப்பட்டது',
      kannada: 'ವಿರಾಮಗೊಳಿಸಲಾಗಿದೆ',
      malayalam: 'താൽക്കാലികമായി നിർത്തി',
      marathi: 'थांबवले',
      gujarati: 'થોભાવેલ',
      bengali: 'বিরতি দেওয়া হয়েছে',
      punjabi: 'ਰੋਕਿਆ ਗਿਆ',
      odia: 'ସ୍ଥଗିତ',
      assamese: 'স্থগিত কৰা হ’ল',
      konkani: 'थांबयलां',
      nepali: 'रोकिएको',
      meitei: 'লেপলেপ তৌরে',
      mizo: 'Chawl rih',
      kashmiri: 'روٗکِتھ',
      ladakhi: 'བར་མཚམས་བཞག',
    );

    final resumeLabel = strings.localized(
      telugu: 'కొనసాగించు',
      english: 'Resume',
      hindi: 'जारी रखें',
      tamil: 'தொடரவும்',
      kannada: 'ಮುಂದುವರಿಸಿ',
      malayalam: 'തുടരുക',
      marathi: 'सुरू ठेवा',
      gujarati: 'ચાલુ રાખો',
      bengali: 'চালিয়ে যান',
      punjabi: 'ਜਾਰੀ ਰੱਖੋ',
      odia: 'ଜାରି ରଖନ୍ତୁ',
      assamese: 'অব্যাহত ৰাখক',
      konkani: 'चालू दवरात',
      nepali: 'जारी राख्नुहोस्',
      meitei: 'মখা চত্থবীয়ু',
      mizo: 'Chhunzawm rawh',
      kashmiri: 'جاری تھاوِو',
      ladakhi: 'མུ་མཐུད་དུ་རྩེས།',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;
        final availableWidth = constraints.maxWidth;

        // Space reserved for single top bar (~44px) + clean bottom pad (~104px) + gaps
        final maxBoardHeight = (availableHeight - 170).clamp(180.0, 310.0);
        final maxBoardWidth = (availableWidth - 28).clamp(180.0, 310.0);
        final boardSize = math.min(maxBoardHeight, maxBoardWidth);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Single Sleek Top Bar
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gameTitle,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Score Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('🍎', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Best Score Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('🏆', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '$_highScore',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Restart Icon
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _restart,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Close Icon
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: widget.onExit,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Clean Game Board
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: _handleDrag,
                onVerticalDragEnd: _handleDrag,
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: <Widget>[
                        CustomPaint(
                          painter: _SnakeBoardPainter(
                            gridSize: _gridSize,
                            snake: _snake,
                            food: _food,
                            direction: _direction,
                          ),
                          child: const SizedBox.expand(),
                        ),
                        if (_gameOver)
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    gameOverLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.icon(
                                    onPressed: _restart,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: Text(playAgainLabel),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF22C55E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_isPaused && !_gameOver)
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    pausedLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: _togglePause,
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 16,
                                    ),
                                    label: Text(resumeLabel),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      elevation: 0,
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
              ),
              const SizedBox(height: 10),

              // Clean Inverted-T Arrow Pad
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _CleanArrowButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: () => _setDirection(_SnakeDirection.up),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _CleanArrowButton(
                        icon: Icons.keyboard_arrow_left_rounded,
                        onTap: () => _setDirection(_SnakeDirection.left),
                      ),
                      const SizedBox(width: 8),
                      _CleanArrowButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => _setDirection(_SnakeDirection.down),
                      ),
                      const SizedBox(width: 8),
                      _CleanArrowButton(
                        icon: Icons.keyboard_arrow_right_rounded,
                        onTap: () => _setDirection(_SnakeDirection.right),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CleanArrowButton extends StatelessWidget {
  const _CleanArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 54,
          height: 44,
          child: Icon(
            icon,
            color: const Color(0xFF1E293B),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _SnakeBoardPainter extends CustomPainter {
  const _SnakeBoardPainter({
    required this.gridSize,
    required this.snake,
    required this.food,
    required this.direction,
  });

  final int gridSize;
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final _SnakeDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / gridSize;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var index = 1; index < gridSize; index++) {
      final offset = index * cell;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        gridPaint,
      );
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), gridPaint);
    }

    // Draw Food (Apple)
    final foodCenter = Offset(
      food.x * cell + cell / 2,
      food.y * cell + cell / 2,
    );
    canvas
      ..drawCircle(
        foodCenter,
        cell * 0.36,
        Paint()..color = const Color(0xFFEF4444),
      )
      ..drawCircle(
        foodCenter.translate(-cell * 0.1, -cell * 0.11),
        cell * 0.11,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      )
      ..drawOval(
        Rect.fromCenter(
          center: foodCenter.translate(cell * 0.12, -cell * 0.36),
          width: cell * 0.28,
          height: cell * 0.16,
        ),
        Paint()..color = const Color(0xFF22C55E),
      );

    // Draw Snake Segments
    for (var index = snake.length - 1; index >= 0; index--) {
      final part = snake[index];
      final isHead = index == 0;
      final center = Offset(part.x * cell + cell / 2, part.y * cell + cell / 2);
      final radius = isHead ? cell * 0.44 : cell * (0.35 + index * 0.001);

      // Segment drop shadow
      canvas.drawCircle(
        center.translate(0, cell * 0.05),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.22),
      );

      // Segment body gradient
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center.translate(-cell * 0.12, -cell * 0.16),
            radius * 1.35,
            isHead
                ? const <Color>[Color(0xFF86EFAC), Color(0xFF16A34A)]
                : const <Color>[Color(0xFF6EE7B7), Color(0xFF0D9488)],
          ),
      );

      // Body shine highlight on alternating segments
      if (!isHead && index.isOdd) {
        canvas.drawCircle(
          center.translate(-cell * 0.06, -cell * 0.06),
          cell * 0.07,
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
      }

      if (isHead) {
        _paintSnakeFace(canvas, center, cell);
      }
    }
  }

  void _paintSnakeFace(Canvas canvas, Offset center, double cell) {
    final eyePaint = Paint()..color = const Color(0xFF052E16);
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final tonguePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final offsets = switch (direction) {
      _SnakeDirection.up => (
        Offset(-cell * 0.15, -cell * 0.14),
        Offset(cell * 0.15, -cell * 0.14),
        Offset(0, -cell * 0.44),
      ),
      _SnakeDirection.right => (
        Offset(cell * 0.14, -cell * 0.15),
        Offset(cell * 0.14, cell * 0.15),
        Offset(cell * 0.44, 0),
      ),
      _SnakeDirection.down => (
        Offset(-cell * 0.15, cell * 0.14),
        Offset(cell * 0.15, cell * 0.14),
        Offset(0, cell * 0.44),
      ),
      _SnakeDirection.left => (
        Offset(-cell * 0.14, -cell * 0.15),
        Offset(-cell * 0.14, cell * 0.15),
        Offset(-cell * 0.44, 0),
      ),
    };

    final firstEye = center + offsets.$1;
    final secondEye = center + offsets.$2;

    canvas
      ..drawCircle(firstEye, cell * 0.065, eyePaint)
      ..drawCircle(secondEye, cell * 0.065, eyePaint)
      ..drawCircle(
        firstEye.translate(cell * 0.015, -cell * 0.018),
        cell * 0.02,
        shinePaint,
      )
      ..drawCircle(
        secondEye.translate(cell * 0.015, -cell * 0.018),
        cell * 0.02,
        shinePaint,
      );

    final tongueStart = center + offsets.$3 * 0.72;
    final tongueEnd = center + offsets.$3;
    canvas.drawLine(tongueStart, tongueEnd, tonguePaint);

    final forkA = switch (direction) {
      _SnakeDirection.up || _SnakeDirection.down => Offset(-cell * 0.07, 0),
      _SnakeDirection.left || _SnakeDirection.right => Offset(0, -cell * 0.07),
    };
    canvas
      ..drawLine(tongueEnd, tongueEnd + forkA, tonguePaint)
      ..drawLine(tongueEnd, tongueEnd - forkA, tonguePaint);
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) =>
      oldDelegate.snake != snake ||
      oldDelegate.food != food ||
      oldDelegate.direction != direction;
}
