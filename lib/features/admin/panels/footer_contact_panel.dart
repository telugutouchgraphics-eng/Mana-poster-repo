import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class FooterContactPanel extends StatelessWidget {
  const FooterContactPanel({
    super.key,
    required this.footer,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onDescriptionChanged,
    required this.onSupportEmailChanged,
    required this.onSupportPhoneChanged,
    required this.onPrivacyLinkChanged,
    required this.onTermsLinkChanged,
    required this.onDownloadLinkChanged,
    required this.onQuickLinkChanged,
    required this.onAddQuickLink,
    required this.onRemoveQuickLink,
    required this.onMoveQuickLinkUp,
    required this.onMoveQuickLinkDown,
  });

  final FooterContentDraft footer;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String> onSupportEmailChanged;
  final ValueChanged<String> onSupportPhoneChanged;
  final ValueChanged<String> onPrivacyLinkChanged;
  final ValueChanged<String> onTermsLinkChanged;
  final ValueChanged<String> onDownloadLinkChanged;
  final void Function(int index, String value) onQuickLinkChanged;
  final VoidCallback onAddQuickLink;
  final ValueChanged<int> onRemoveQuickLink;
  final ValueChanged<int> onMoveQuickLinkUp;
  final ValueChanged<int> onMoveQuickLinkDown;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Footer & Contact Management',
          subtitle:
              'Edit support, legal and app-download blocks shown in footer.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Visible',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5E6884)),
              ),
              Switch(value: visible, onChanged: onVisibilityChanged),
            ],
          ),
          child: Column(
            children: <Widget>[
              _field(
                label: 'App Description',
                value: footer.description,
                maxLines: 3,
                onChanged: onDescriptionChanged,
              ),
              _field(
                label: 'Support Email',
                value: footer.supportEmail,
                onChanged: onSupportEmailChanged,
              ),
              _field(
                label: 'Support Phone',
                value: footer.supportPhone,
                onChanged: onSupportPhoneChanged,
              ),
              _field(
                label: 'Privacy Policy Link',
                value: footer.privacyLink,
                onChanged: onPrivacyLinkChanged,
              ),
              _field(
                label: 'Terms Link',
                value: footer.termsLink,
                onChanged: onTermsLinkChanged,
              ),
              _field(
                label: 'Download Link',
                value: footer.downloadLink,
                onChanged: onDownloadLinkChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Footer Quick Links',
          subtitle: 'Manage footer link labels.',
          child: Column(
            children: <Widget>[
              ...footer.quickLinks.asMap().entries.map((
                MapEntry<int, String> entry,
              ) {
                final int index = entry.key;
                final String link = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == footer.quickLinks.length - 1 ? 0 : 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFF),
                      border: Border.all(color: const Color(0xFFE3E9F7)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            key: ValueKey<String>('footer-link-$link'),
                            initialValue: link,
                            onChanged: (String value) =>
                                onQuickLinkChanged(index, value),
                            decoration: _fieldDecoration('Quick link label'),
                          ),
                        ),
                        IconButton(
                          onPressed: index > 0
                              ? () => onMoveQuickLinkUp(index)
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                        IconButton(
                          onPressed: index < footer.quickLinks.length - 1
                              ? () => onMoveQuickLinkDown(index)
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        IconButton(
                          onPressed: () => onRemoveQuickLink(index),
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: const Color(0xFF9D3A4A),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddQuickLink,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Quick Link'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Footer Preview',
          subtitle: 'Compact preview from local draft footer values.',
          child: _FooterPreview(footer: footer, visible: visible),
        ),
      ],
    );
  }
}

Widget _field({
  required String label,
  required String value,
  required ValueChanged<String> onChanged,
  int maxLines = 1,
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
          key: ValueKey<String>('footer-$label-$value'),
          initialValue: value,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: _fieldDecoration(label),
        ),
      ],
    ),
  );
}

class _FooterPreview extends StatelessWidget {
  const _FooterPreview({required this.footer, required this.visible});

  final FooterContentDraft footer;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Mana Poster',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2646),
                  ),
                ),
              ),
              Text(
                visible ? 'Visible' : 'Hidden',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: visible
                      ? const Color(0xFF1B8445)
                      : const Color(0xFFB02D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footer.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5E6986),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: footer.quickLinks
                .map(
                  (String link) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDEE5F4)),
                    ),
                    child: Text(
                      link,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF304065),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Support: ${footer.supportEmail} | ${footer.supportPhone}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF566282)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
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
