import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:mana_poster/app/localization/app_language.dart';

enum OnboardingAudioCue {
  languageSelection('language_selection_guide.mp3'),
  login('login_screen_guide.mp3'),
  religionSelection('religion_selection_guide.mp3'),
  profileSetup('profile_setup_guide.mp3');

  const OnboardingAudioCue(this.fileName);

  final String fileName;

  String get assetPath => 'audio/onboarding/$fileName';
}

class OnboardingAudioService {
  OnboardingAudioService() : _player = AudioPlayer() {
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentCue = null;
    });
  }

  final AudioPlayer _player;
  late final StreamSubscription<void> _completeSubscription;
  OnboardingAudioCue? _currentCue;
  bool _isPlaying = false;

  bool supportsLanguage(AppLanguage language) => language == AppLanguage.telugu;

  Future<void> autoplayIfSupported({
    required AppLanguage language,
    required OnboardingAudioCue cue,
  }) async {
    if (!supportsLanguage(language)) {
      await stop();
      return;
    }
    await play(cue);
  }

  Future<void> toggleIfSupported({
    required AppLanguage language,
    required OnboardingAudioCue cue,
  }) async {
    if (!supportsLanguage(language)) {
      await stop();
      return;
    }
    if (_isPlaying && _currentCue == cue) {
      await stop();
      return;
    }
    await play(cue);
  }

  Future<void> replayIfSupported({
    required AppLanguage language,
    required OnboardingAudioCue cue,
  }) {
    return toggleIfSupported(language: language, cue: cue);
  }

  Future<void> play(OnboardingAudioCue cue) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(cue.assetPath));
      _currentCue = cue;
      _isPlaying = true;
    } catch (_) {
      _currentCue = null;
      _isPlaying = false;
      // Missing or invalid audio files should not block onboarding.
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _currentCue = null;
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _completeSubscription.cancel();
      await _player.dispose();
    } catch (_) {}
  }
}
