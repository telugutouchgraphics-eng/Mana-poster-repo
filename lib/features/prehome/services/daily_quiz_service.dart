import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/features/prehome/models/app_region.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class DailyQuizOption {
  const DailyQuizOption({required this.id, required this.text});

  final String id;
  final String text;

  factory DailyQuizOption.fromJson(Map<String, dynamic> json) {
    return DailyQuizOption(
      id: (json['optionId'] ?? json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class DailyQuizQuestion {
  const DailyQuizQuestion({
    required this.id,
    required this.question,
    required this.correctOptionId,
    required this.options,
  });

  final String id;
  final String question;
  final String correctOptionId;
  final List<DailyQuizOption> options;

  factory DailyQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return DailyQuizQuestion(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      correctOptionId: (json['correctOptionId'] ?? '').toString(),
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map(
                  (item) =>
                      DailyQuizOption.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <DailyQuizOption>[],
    );
  }
}

class DailyQuiz {
  const DailyQuiz({
    required this.id,
    required this.dateKey,
    required this.title,
    required this.questions,
  });

  final String id;
  final String dateKey;
  final String title;
  final List<DailyQuizQuestion> questions;

  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return DailyQuiz(
      id: (json['id'] ?? '').toString(),
      dateKey: (json['dateKey'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      questions: rawQuestions is List
          ? rawQuestions
                .whereType<Map>()
                .map(
                  (item) => DailyQuizQuestion.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <DailyQuizQuestion>[],
    );
  }
}

class DailyQuizAnswerState {
  const DailyQuizAnswerState({
    required this.questionId,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
  });

  final String questionId;
  final String selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;

  factory DailyQuizAnswerState.fromJson(Map<String, dynamic> json) {
    return DailyQuizAnswerState(
      questionId: (json['questionId'] ?? '').toString(),
      selectedOptionId: (json['selectedOptionId'] ?? '').toString(),
      correctOptionId: (json['correctOptionId'] ?? '').toString(),
      isCorrect: json['isCorrect'] == true,
    );
  }
}

class DailyQuizAttempt {
  const DailyQuizAttempt({
    required this.answers,
    required this.correctCount,
    required this.totalAnswered,
    required this.completed,
  });

  final Map<String, DailyQuizAnswerState> answers;
  final int correctCount;
  final int totalAnswered;
  final bool completed;

  factory DailyQuizAttempt.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DailyQuizAttempt(
        answers: <String, DailyQuizAnswerState>{},
        correctCount: 0,
        totalAnswered: 0,
        completed: false,
      );
    }
    final rawAnswers = json['answered'] ?? json['answers'];
    final answers = <String, DailyQuizAnswerState>{};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.isEmpty || value is! Map) {
          continue;
        }
        answers[key] = DailyQuizAnswerState.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    }
    return DailyQuizAttempt(
      answers: answers,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalAnswered: (json['totalAnswered'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
    );
  }
}

class DailyQuizFeed {
  const DailyQuizFeed({required this.quiz, required this.attempt});

  final DailyQuiz? quiz;
  final DailyQuizAttempt attempt;

  factory DailyQuizFeed.fromJson(Map<String, dynamic> json) {
    final rawQuiz = json['quiz'];
    return DailyQuizFeed(
      quiz: rawQuiz is Map
          ? DailyQuiz.fromJson(Map<String, dynamic>.from(rawQuiz))
          : null,
      attempt: DailyQuizAttempt.fromJson(
        json['attempt'] is Map
            ? Map<String, dynamic>.from(json['attempt'] as Map)
            : null,
      ),
    );
  }
}

class DailyQuizSubmitResult {
  const DailyQuizSubmitResult({required this.answer});

  final DailyQuizAnswerState answer;

  factory DailyQuizSubmitResult.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    if (rawResult is! Map) {
      throw const FormatException('Invalid quiz answer response.');
    }
    return DailyQuizSubmitResult(
      answer: DailyQuizAnswerState.fromJson(
        Map<String, dynamic>.from(rawResult),
      ),
    );
  }
}

class DailyQuizService {
  DailyQuizService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _feedUrl = String.fromEnvironment(
    'MANA_POSTER_DAILY_QUIZ_FEED_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/dailyQuizFeed',
  );
  static const String _submitUrl = String.fromEnvironment(
    'MANA_POSTER_DAILY_QUIZ_SUBMIT_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/submitDailyQuizAnswer',
  );

  final FirebaseAuth _firebaseAuth;

  Future<DailyQuizFeed> loadTodayQuiz(AppLanguage language) async {
    final region = await AppRegionService.loadSelection();
    final regionId = region?.id ?? AppRegionService.fallbackRegionId;
    await AppRegionService.ensureRemoteSelectionSynced(
      region ?? appRegionById(regionId),
    );
    final userDetails = await _buildUserDetails(language);
    final response = await _postJson(_feedUrl, <String, dynamic>{
      'language': language.name,
      'regionId': regionId,
      'userDetails': userDetails,
    });
    return DailyQuizFeed.fromJson(response);
  }

  Future<DailyQuizSubmitResult> submitAnswer({
    required String quizId,
    required String questionId,
    required String optionId,
    required AppLanguage language,
    required int durationSeconds,
  }) async {
    final userDetails = await _buildUserDetails(language);
    final response = await _postJson(_submitUrl, <String, dynamic>{
      'quizId': quizId,
      'questionId': questionId,
      'optionId': optionId,
      'durationSeconds': durationSeconds,
      'userDetails': userDetails,
    });
    return DailyQuizSubmitResult.fromJson(response);
  }

  Future<Map<String, dynamic>> _buildUserDetails(AppLanguage language) async {
    final user = _firebaseAuth.currentUser;
    final region = await AppRegionService.loadSelection();
    final profile = await PosterProfileService.load();
    final name = profile.activeName.trim();
    final photoUrl = profile.photoUrl.trim().isNotEmpty
        ? profile.photoUrl.trim()
        : profile.originalPhotoUrl.trim();
    return <String, dynamic>{
      'uid': user?.uid ?? '',
      'name': name.isNotEmpty ? name : user?.displayName ?? '',
      'email': user?.email ?? '',
      'phoneNumber': user?.phoneNumber ?? profile.activeWhatsappNumber,
      'photoUrl': photoUrl.isNotEmpty ? photoUrl : user?.photoURL ?? '',
      'regionId': region?.id ?? AppRegionService.fallbackRegionId,
      'regionName': region?.name ?? '',
      'language': language.name,
      'submittedFrom': 'android',
    };
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const DailyQuizException('Login required.');
    }
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      final idToken = await user.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(responseBody);
      final json = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DailyQuizException(
          (json['error'] ?? 'Quiz request failed.').toString(),
        );
      }
      if (json['ok'] == false) {
        throw DailyQuizException((json['error'] ?? 'Quiz failed.').toString());
      }
      return json;
    } on DailyQuizException {
      rethrow;
    } catch (error) {
      throw DailyQuizException(error.toString());
    } finally {
      client?.close(force: true);
    }
  }
}

class DailyQuizException implements Exception {
  const DailyQuizException(this.message);

  final String message;

  @override
  String toString() => message;
}
