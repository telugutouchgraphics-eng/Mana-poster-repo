import 'package:flutter/material.dart';

import 'package:mana_poster/features/prehome/models/approved_creator_template.dart';
import 'package:mana_poster/features/prehome/services/poster_profile_service.dart';

import '../models/editor_page_config.dart';
import '../models/editor_stage_background.dart';

class ImageEditorScreen extends StatelessWidget {
  const ImageEditorScreen({
    super.key,
    this.pageConfig,
    this.initialStageBackground,
    this.templateDocumentSource,
    this.initialPosterProfile,
    this.initialPersonalizationConfig,
    this.initialDesignImportPath,
    this.initialDraft,
  });

  final EditorPageConfig? pageConfig;
  final EditorStageBackground? initialStageBackground;
  final String? templateDocumentSource;
  final PosterProfileData? initialPosterProfile;
  final CreatorPosterPersonalization? initialPersonalizationConfig;
  final String? initialDesignImportPath;
  final Map<String, dynamic>? initialDraft;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Image editor is available in the mobile app only.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
