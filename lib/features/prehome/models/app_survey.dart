import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.voteCounts,
  });

  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> voteCounts;

  factory SurveyQuestion.fromMap(
    Map<String, dynamic> data, {
    String defaultId = 'q_0',
  }) {
    final rawOptions = data['options'];
    final options = rawOptions is List
        ? rawOptions
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawCounts = data['voteCounts'];
    final voteCounts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        voteCounts[k.toString()] =
            v is int ? v : int.tryParse(v.toString()) ?? 0;
      });
    }

    return SurveyQuestion(
      id: (data['id'] ?? defaultId).toString().trim(),
      question: (data['question'] ?? '').toString().trim(),
      options: options,
      voteCounts: voteCounts,
    );
  }
}

class AppSurvey {
  const AppSurvey({
    required this.id,
    required this.title,
    required this.question,
    required this.options,
    required this.questions,
    required this.targetRegion,
    this.targetReligion = 'all',
    required this.status,
    required this.totalVotes,
    required this.voteCounts,
  });

  final String id;
  final String title;
  final String question;
  final List<String> options;
  final List<SurveyQuestion> questions;
  final String targetRegion;
  final String targetReligion;
  final String status;
  final int totalVotes;
  final Map<String, int> voteCounts;

  factory AppSurvey.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final rawQuestions = data['questions'];
    final questions = <SurveyQuestion>[];
    if (rawQuestions is List && rawQuestions.isNotEmpty) {
      for (var i = 0; i < rawQuestions.length; i++) {
        final item = rawQuestions[i];
        if (item is Map) {
          questions.add(
            SurveyQuestion.fromMap(
              Map<String, dynamic>.from(item),
              defaultId: 'q_$i',
            ),
          );
        }
      }
    }

    final rawOptions = data['options'];
    final options = rawOptions is List
        ? rawOptions
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawCounts = data['voteCounts'];
    final voteCounts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) {
        voteCounts[k.toString()] =
            v is int ? v : int.tryParse(v.toString()) ?? 0;
      });
    }

    final legacyQuestion = (data['question'] ?? '').toString().trim();

    // If questions array is not present, synthesize from top-level fields
    if (questions.isEmpty && legacyQuestion.isNotEmpty) {
      questions.add(
        SurveyQuestion(
          id: 'q_0',
          question: legacyQuestion,
          options: options,
          voteCounts: voteCounts,
        ),
      );
    }

    final primaryQuestion =
        questions.isNotEmpty ? questions.first.question : legacyQuestion;
    final primaryOptions =
        questions.isNotEmpty ? questions.first.options : options;
    final primaryVoteCounts =
        questions.isNotEmpty ? questions.first.voteCounts : voteCounts;

    return AppSurvey(
      id: doc.id,
      title: (data['title'] ?? '').toString().trim(),
      question: primaryQuestion,
      options: primaryOptions,
      questions: questions,
      targetRegion: (data['targetRegion'] ?? 'all').toString().trim(),
      targetReligion: (data['targetReligion'] ?? 'all').toString().trim().toLowerCase(),
      status: (data['status'] ?? 'active').toString().trim(),
      totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
      voteCounts: primaryVoteCounts,
    );
  }
}
