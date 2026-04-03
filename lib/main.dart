import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:mana_poster/app/app.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = DefaultFirebaseOptions.currentPlatformOrNull;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  }

  final snapshot = await AppFlowService.loadSnapshot();

  runApp(ManaPosterApp(initialLanguage: snapshot.language));
}
