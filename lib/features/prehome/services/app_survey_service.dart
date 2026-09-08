import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/features/prehome/models/app_survey.dart';
import 'package:mana_poster/features/prehome/services/app_region_service.dart';
import 'package:mana_poster/features/prehome/services/app_religion_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_survey_bottom_sheet.dart';

class AppSurveyService {
  AppSurveyService._();
  static final AppSurveyService instance = AppSurveyService._();

  bool _checkedThisSession = false;
  bool _dismissedThisSession = false;

  /// Fetch active survey if available and user has not already submitted it.
  Future<AppSurvey?> getActiveSurvey({String? regionId}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appSurveys')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return null;
      }

      final survey = AppSurvey.fromFirestore(snap.docs.first);
      if (survey.options.length < 2 || survey.question.isEmpty) {
        return null;
      }

      // Check religion targeting if specified
      final targetReligion = survey.targetReligion.toLowerCase().trim();
      if (targetReligion.isNotEmpty && targetReligion != 'all') {
        final userReligion = await AppReligionService.loadSelection();
        if (userReligion != null &&
            userReligion != AppReligionPreference.all &&
            userReligion.name.toLowerCase().trim() != targetReligion) {
          return null;
        }
      }

      // Check region targeting if specified (supports comma-separated multiple states)
      final targetRegion = survey.targetRegion.toLowerCase().trim();
      if (targetRegion.isNotEmpty && targetRegion != 'all') {
        final effectiveRegion =
            regionId ?? (await AppRegionService.loadSelection())?.id;
        if (effectiveRegion != null && effectiveRegion.isNotEmpty) {
          final allowedRegions = targetRegion
              .split(',')
              .map((r) => r.trim())
              .where((r) => r.isNotEmpty)
              .toSet();
          if (allowedRegions.isNotEmpty &&
              !allowedRegions.contains(effectiveRegion.toLowerCase())) {
            return null;
          }
        }
      }

      // Check if user already submitted this survey locally
      final prefs = await SharedPreferences.getInstance();
      final answered = prefs.getBool('answered_survey_${survey.id}') ?? false;
      if (answered) {
        return null;
      }

      // Check if user already submitted in Firestore (if logged in)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final responseDoc = await FirebaseFirestore.instance
            .collection('appSurveys')
            .doc(survey.id)
            .collection('responses')
            .doc(user.uid)
            .get();

        if (responseDoc.exists) {
          await prefs.setBool('answered_survey_${survey.id}', true);
          return null;
        }
      }

      return survey;
    } catch (e) {
      debugPrint('AppSurveyService getActiveSurvey error: $e');
      return null;
    }
  }

  /// Submit the user's vote for the survey (supports single or multiple questions and optional feedback comment).
  Future<bool> submitResponse({
    required AppSurvey survey,
    int? selectedOptionIndex,
    Map<int, int>? selectedAnswers,
    String? userComment,
  }) async {
    try {
      final answers = <int, int>{};
      if (selectedAnswers != null && selectedAnswers.isNotEmpty) {
        answers.addAll(selectedAnswers);
      } else if (selectedOptionIndex != null) {
        answers[0] = selectedOptionIndex;
      }

      if (answers.isEmpty) {
        return false;
      }

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().millisecondsSinceEpoch;
      final cleanComment = userComment?.trim() ?? '';

      final surveyRef = FirebaseFirestore.instance
          .collection('appSurveys')
          .doc(survey.id);

      // 1. Build individual response records
      final answerRecords = <String, dynamic>{};
      answers.forEach((qIdx, optIdx) {
        final q = (qIdx >= 0 && qIdx < survey.questions.length)
            ? survey.questions[qIdx]
            : null;
        final optLabel = (q != null && optIdx >= 0 && optIdx < q.options.length)
            ? q.options[optIdx]
            : (optIdx >= 0 && optIdx < survey.options.length
                  ? survey.options[optIdx]
                  : 'Option $optIdx');
        answerRecords['$qIdx'] = {
          'question': q?.question ?? survey.question,
          'selectedIndex': optIdx,
          'selectedOption': optLabel,
        };
      });

      if (user != null) {
        await surveyRef.collection('responses').doc(uid).set({
          'userId': uid,
          'answers': answerRecords,
          'selectedIndex': answers[0] ?? 0,
          'selectedOption': answerRecords['0']?['selectedOption'] ?? '',
          'comment': cleanComment,
          'answeredAt': now,
        });
      }

      final updateData = <String, dynamic>{
        'totalVotes': FieldValue.increment(1),
        'updatedAt': now,
      };

      final q0Opt = answers[0];
      if (q0Opt != null) {
        updateData['voteCounts.$q0Opt'] = FieldValue.increment(1);
      }

      if (survey.questions.isNotEmpty) {
        final updatedQuestions = <Map<String, dynamic>>[];
        for (var i = 0; i < survey.questions.length; i++) {
          final question = survey.questions[i];
          final counts = Map<String, dynamic>.from(question.voteCounts);
          final chosenOpt = answers[i];
          if (chosenOpt != null) {
            counts['$chosenOpt'] =
                ((counts['$chosenOpt'] as num?)?.toInt() ?? 0) + 1;
          }
          updatedQuestions.add({
            'id': question.id,
            'question': question.question,
            'options': question.options,
            'voteCounts': counts,
          });
        }
        updateData['questions'] = updatedQuestions;
      }

      if (cleanComment.isNotEmpty) {
        updateData['recentComments'] = FieldValue.arrayUnion([
          {'userId': uid, 'comment': cleanComment, 'createdAt': now},
        ]);
      }

      await surveyRef.update(updateData);

      // 3. Mark as answered locally so it never asks again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('answered_survey_${survey.id}', true);

      return true;
    } catch (e) {
      debugPrint('AppSurveyService submitResponse error: $e');
      return false;
    }
  }

  /// Checks and automatically presents the survey bottom sheet on the Home screen.
  Future<void> checkAndShowSurvey(
    BuildContext context, {
    String? regionId,
  }) async {
    if (_checkedThisSession || _dismissedThisSession) {
      return;
    }
    _checkedThisSession = true;

    // Small delay so home screen UI finishes rendering smoothly
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) {
      return;
    }

    final survey = await getActiveSurvey(regionId: regionId);
    if (survey == null || !context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSurveyBottomSheet(
        survey: survey,
        onDismiss: () {
          _dismissedThisSession = true;
        },
      ),
    );
  }
}
