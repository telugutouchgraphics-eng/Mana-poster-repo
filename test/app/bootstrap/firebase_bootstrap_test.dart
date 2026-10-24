// Platform interface is used only to simulate Firebase startup races.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/app/bootstrap/firebase_bootstrap.dart';

class DelayedFirebase extends FirebasePlatform {
  final ready = Completer<void>();
  final initializedApps = <FirebaseAppPlatform>[];
  int attempts = 0;

  @override
  List<FirebaseAppPlatform> get apps => initializedApps;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    attempts++;
    if (attempts == 1) {
      throw FirebaseException(plugin: 'firebase_core', code: 'unavailable');
    }
    await ready.future;
    final app = FirebaseAppPlatform('[DEFAULT]', options!);
    initializedApps.add(app);
    return app;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup retries initialization failure and concurrent callers await readiness',
    () async {
      final original = FirebasePlatform.instance;
      final firebase = DelayedFirebase();
      FirebasePlatform.instance = firebase;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        FirebasePlatform.instance = original;
        debugDefaultTargetPlatformOverride = null;
      });

      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
      expect(firebase.attempts, 1);
      expect(Firebase.apps, isEmpty);

      var completed = 0;
      final loads = List.generate(6, (_) async {
        await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
        completed++;
        expect(Firebase.apps, isNotEmpty);
      });
      await Future<void>.delayed(Duration.zero);
      expect(firebase.attempts, 2);
      expect(completed, 0);

      firebase.ready.complete();
      await Future.wait(loads);
      expect(completed, 6);
      await FirebaseBootstrap.ensureInitialized(activateAppCheck: false);
      expect(firebase.attempts, 2);
    },
  );
}
