import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const String _deleteUrl = String.fromEnvironment(
    'MANA_POSTER_ACCOUNT_DELETE_URL',
    defaultValue:
        'https://asia-south1-mana-poster-ap.cloudfunctions.net/requestAccountDeletion',
  );

  final FirebaseAuth _firebaseAuth;

  Future<AccountDeletionResult> deleteCurrentAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const AccountDeletionResult(
        success: false,
        message: 'No logged-in user found.',
      );
    }

    if (_deleteUrl.isEmpty) {
      return _deleteLocally(user);
    }

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(_deleteUrl));
      request.headers.contentType = ContentType.json;

      final idToken = await user.getIdToken();
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.add(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'uid': user.uid,
            'email': user.email,
          }),
        ),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AccountDeletionResult(
          success: false,
          message: body.isEmpty ? 'Account deletion failed.' : body,
        );
      }

      await _clearLocalState();
      return const AccountDeletionResult(
        success: true,
        message: 'Account deleted successfully.',
      );
    } catch (_) {
      return _deleteLocally(user);
    } finally {
      client?.close(force: true);
    }
  }

  Future<AccountDeletionResult> _deleteLocally(User user) async {
    try {
      final profile = await PosterProfileService.loadLocal();
      await PosterProfileService.deleteProfilePhoto(photoUrl: profile.photoUrl);
      await PosterProfileService.deleteProfilePhoto(
        photoUrl: profile.originalPhotoUrl,
      );
      await PosterProfileService.deleteProfilePhoto(
        photoUrl: profile.businessLogoUrl,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posterProfile')
          .doc('main')
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activeSession')
          .doc('current')
          .delete();

      await user.delete();
      await _clearLocalState();
      return const AccountDeletionResult(
        success: true,
        message: 'Account deleted successfully.',
      );
    } on FirebaseAuthException catch (error) {
      return AccountDeletionResult(
        success: false,
        message: error.code == 'requires-recent-login'
            ? 'Please log in again and retry account deletion.'
            : (error.message ?? 'Account deletion failed.'),
      );
    } catch (_) {
      return const AccountDeletionResult(
        success: false,
        message: 'Account deletion failed.',
      );
    }
  }

  Future<void> _clearLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
