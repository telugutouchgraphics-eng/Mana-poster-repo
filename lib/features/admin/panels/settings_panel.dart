import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

const List<String> _accentThemes = <String>[
  'saffron-pink',
  'pink-purple',
  'purple-blue',
  'saffron-blue',
];

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.settings,
    required this.sections,
    required this.onBrandNameChanged,
    required this.onTaglineChanged,
    required this.onAccentChanged,
    required this.onShowSupportEmailChanged,
    required this.onShowSupportPhoneChanged,
    required this.onShowSectionsSummaryChanged,
    required this.onCompactCardsChanged,
    required this.onPreviewAnimationsChanged,
  });

  final AdminSettingsDraft settings;
  final List<LandingSectionDraft> sections;
  final ValueChanged<String> onBrandNameChanged;
  final ValueChanged<String> onTaglineChanged;
  final ValueChanged<String> onAccentChanged;
  final ValueChanged<bool> onShowSupportEmailChanged;
  final ValueChanged<bool> onShowSupportPhoneChanged;
  final ValueChanged<bool> onShowSectionsSummaryChanged;
  final ValueChanged<bool> onCompactCardsChanged;
  final ValueChanged<bool> onPreviewAnimationsChanged;

  @override
  Widget build(BuildContext context) {
    final int visibleSections = sections
        .where((LandingSectionDraft section) => section.visible)
        .length;

    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Dashboard Settings',
          subtitle: 'Update brand-level preferences used across the admin UI.',
          child: Column(
            children: <Widget>[
              _field(
                label: 'Brand / App Name',
                value: settings.brandName,
                onChanged: onBrandNameChanged,
              ),
              _field(
                label: 'Short Tagline',
                value: settings.tagline,
                onChanged: onTaglineChanged,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Accent Theme',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF5E6884),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _accentThemes
                    .map(
                      (String theme) => ChoiceChip(
                        label: Text(theme),
                        selected: settings.accentTheme == theme,
                        onSelected: (_) => onAccentChanged(theme),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Visibility Preferences',
          subtitle: 'Enable or disable support details and summary blocks.',
          child: Column(
            children: <Widget>[
              _toggleRow(
                'Show Support Email',
                settings.showSupportEmail,
                onShowSupportEmailChanged,
              ),
              _toggleRow(
                'Show Support Phone',
                settings.showSupportPhone,
                onShowSupportPhoneChanged,
              ),
              _toggleRow(
                'Show Section Summary',
                settings.showSectionsSummary,
                onShowSectionsSummaryChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Admin Preferences',
          subtitle: 'Control how the admin workspace is displayed.',
          child: Column(
            children: <Widget>[
              _toggleRow(
                'Compact Cards Layout',
                settings.compactCards,
                onCompactCardsChanged,
              ),
              _toggleRow(
                'Enable Preview Animations',
                settings.enablePreviewAnimations,
                onPreviewAnimationsChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'System Info',
          subtitle: 'Lightweight local system summary.',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FAFF),
              border: Border.all(color: const Color(0xFFE2E8F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _info(
                  'Visible Landing Sections',
                  '$visibleSections / ${sections.length}',
                ),
                _info('Current Accent', settings.accentTheme),
                _info('Mode', 'Draft editing'),
                _info('Persistence', 'Saved through the admin content flow'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _field({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF5E6884)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey<String>('settings-$label-$value'),
          initialValue: value,
          onChanged: onChanged,
          decoration: _fieldDecoration(),
        ),
      ],
    ),
  );
}

Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3557),
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

Widget _info(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF4D5A79)),
    ),
  );
}

InputDecoration _fieldDecoration() {
  return InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFF6A46F5)),
    ),
  );
}
