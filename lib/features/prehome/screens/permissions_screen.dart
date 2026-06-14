import 'package:flutter/material.dart';

import 'package:mana_poster/app/localization/app_language.dart';
import 'package:mana_poster/app/routes/app_routes.dart';
import 'package:mana_poster/features/prehome/services/app_flow_service.dart';
import 'package:mana_poster/features/prehome/services/notification_service.dart';
import 'package:mana_poster/features/prehome/services/permission_service.dart';
import 'package:mana_poster/features/prehome/widgets/app_screen_back_button.dart';
import 'package:mana_poster/features/prehome/widgets/gradient_shell.dart';
import 'package:mana_poster/features/prehome/widgets/primary_button.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with AppLanguageStateMixin {
  final PermissionService _service = PermissionService();
  bool _loading = false;
  PermissionSnapshot _snapshot = const PermissionSnapshot(
    photos: AppPermissionState(
      type: AppPermissionType.photos,
      status: PermissionStatus.denied,
    ),
    camera: AppPermissionState(
      type: AppPermissionType.camera,
      status: PermissionStatus.denied,
    ),
    notifications: AppPermissionState(
      type: AppPermissionType.notifications,
      status: PermissionStatus.denied,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await _service.getSnapshot();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
  }

  Future<void> _completeFlowAndGoHome() async {
    await AppFlowService.markPermissionsStepHandled();
    await AppFlowService.syncInitialSetupCompletion(isAuthenticated: true);
    final String nextRoute =
        await AppFlowService.resolveAuthenticatedEntryRoute();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _grant() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final snapshot = await _service.requestEssentialPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
      await NotificationService.instance.syncCurrentPreferences();
      await _completeFlowAndGoHome();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.localized(
              telugu: 'Permissions request పూర్తి కాలేదు. మళ్లీ ప్రయత్నించండి.',
              english:
                  'Permissions request could not be completed. Please try again.',
              hindi: 'Permissions request पूरी नहीं हो सकी। फिर से कोशिश करें.',
              tamil:
                  'Permissions request முடிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
              kannada: 'Permissions request ಪೂರ್ಣಗೊಳ್ಳಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
              malayalam:
                  'Permissions request പൂർത്തിയാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _continueLater() async {
    await _completeFlowAndGoHome();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final cs = Theme.of(context).colorScheme;
    final copy = _PermissionIntroCopy(context.currentLanguage);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GradientShell(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 96,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x120F172A),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFFF59E0B),
                                        Color(0xFFEF4444),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  copy.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  copy.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _PermissionRow(
                                  icon: Icons.photo_library_outlined,
                                  iconColor: const Color(0xFF0EA5E9),
                                  badgeColor: const Color(0xFFE0F2FE),
                                  title: strings.photosGallery,
                                  subtitle: copy.photosSubtitle,
                                  granted: _snapshot.photos.isGranted,
                                ),
                                const SizedBox(height: 12),
                                _PermissionRow(
                                  icon: Icons.photo_camera_outlined,
                                  iconColor: const Color(0xFF8B5CF6),
                                  badgeColor: const Color(0xFFEDE9FE),
                                  title: strings.localized(
                                    telugu: 'కెమెరా',
                                    english: 'Camera',
                                  ),
                                  subtitle: copy.cameraSubtitle,
                                  granted: _snapshot.camera.isGranted,
                                ),
                                const SizedBox(height: 12),
                                _PermissionRow(
                                  icon: Icons.notifications_none_rounded,
                                  iconColor: const Color(0xFF14B8A6),
                                  badgeColor: const Color(0xFFCCFBF1),
                                  title: strings.notifications,
                                  subtitle: copy.notificationsSubtitle,
                                  granted: _snapshot.notifications.isGranted,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  copy.footerHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                PrimaryButton(
                                  label: strings.allowLabel,
                                  loading: _loading,
                                  onPressed: _grant,
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _loading ? null : _continueLater,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(strings.laterLabel),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 0,
            child: SafeArea(
              child: AppScreenBackButton(fallbackRoute: AppRoutes.religion),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: granted
                ? const Color(0xFFDCFCE7)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            granted
                ? context.strings.localized(
                    telugu: 'అనుమతి ఉంది',
                    english: 'Allowed',
                  )
                : context.strings.localized(
                    telugu: 'తరువాత కూడా చేయొచ్చు',
                    english: 'Optional now',
                  ),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: granted ? const Color(0xFF166534) : cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionIntroCopy {
  const _PermissionIntroCopy(this.language);

  final AppLanguage language;

  String get title => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'అనుమతులు',
    SupportedUiLanguage.english => 'Permissions',
    SupportedUiLanguage.hindi => 'अनुमतियाँ',
    SupportedUiLanguage.tamil => 'அனுமதிகள்',
    SupportedUiLanguage.kannada => 'ಅನುಮತಿಗಳು',
    SupportedUiLanguage.malayalam => 'അനുമതികൾ',
  };

  String get subtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'త్వరగా పూర్తిచేయండి',
    SupportedUiLanguage.english => 'Quick setup',
    SupportedUiLanguage.hindi => 'Quick setup',
    SupportedUiLanguage.tamil => 'Quick setup',
    SupportedUiLanguage.kannada => 'Quick setup',
    SupportedUiLanguage.malayalam => 'Quick setup',
  };

  String get photosSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'పోస్టర్లు సేవ్ చేయడానికి.',
    SupportedUiLanguage.english => 'To save posters.',
    SupportedUiLanguage.hindi => 'पोस्टर सेव करने के लिए।',
    SupportedUiLanguage.tamil => 'போஸ்டர்களை சேமிக்க.',
    SupportedUiLanguage.kannada => 'ಪೋಸ್ಟರ್‌ಗಳನ್ನು ಸೇವ್ ಮಾಡಲು.',
    SupportedUiLanguage.malayalam => 'പോസ്റ്ററുകൾ സേവ് ചെയ്യാൻ.',
  };

  String get cameraSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'ఫోటో తీసుకోవడానికి.',
    SupportedUiLanguage.english => 'To capture your photo.',
    SupportedUiLanguage.hindi => 'फोटो लेने के लिए।',
    SupportedUiLanguage.tamil => 'புகைப்படம் எடுக்க.',
    SupportedUiLanguage.kannada => 'ಫೋಟೋ ತೆಗೆದುಕೊಳ್ಳಲು.',
    SupportedUiLanguage.malayalam => 'ഫോട്ടോ എടുക്കാൻ.',
  };

  String get notificationsSubtitle => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'అప్డేట్స్ కోసం.',
    SupportedUiLanguage.english => 'For updates.',
    SupportedUiLanguage.hindi => 'अपडेट्स के लिए।',
    SupportedUiLanguage.tamil => 'புதிய தகவல்களுக்கு.',
    SupportedUiLanguage.kannada => 'ಅಪ್ಡೇಟ್‌ಗಳಿಗಾಗಿ.',
    SupportedUiLanguage.malayalam => 'അപ്ഡേറ്റുകൾക്കായി.',
  };

  String get footerHint => switch (language.supportedUiLanguage) {
    SupportedUiLanguage.telugu => 'తర్వాత settings లో కూడా ఇవ్వొచ్చు.',
    SupportedUiLanguage.english => 'You can allow them later in settings.',
    SupportedUiLanguage.hindi => 'बाद में सेटिंग्स में भी अनुमति दे सकते हैं।',
    SupportedUiLanguage.tamil => 'பிறகு settings-ல் அனுமதி தரலாம்.',
    SupportedUiLanguage.kannada => 'ನಂತರ settings ನಲ್ಲಿ ಅನುಮತಿ ನೀಡಬಹುದು.',
    SupportedUiLanguage.malayalam => 'പിന്നീട് settings-ൽ അനുവദിക്കാം.',
  };
}
