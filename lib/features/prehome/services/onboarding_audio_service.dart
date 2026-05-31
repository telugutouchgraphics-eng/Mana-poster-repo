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
  OnboardingAudioService() : _player = AudioPlayer();

  final AudioPlayer _player;

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

  Future<void> replayIfSupported({
    required AppLanguage language,
    required OnboardingAudioCue cue,
  }) async {
    if (!supportsLanguage(language)) {
      return;
    }
    await play(cue);
  }

  Future<void> play(OnboardingAudioCue cue) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(cue.assetPath));
    } catch (_) {
      // Missing or invalid audio files should not block onboarding.
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
