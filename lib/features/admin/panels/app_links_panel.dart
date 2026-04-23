import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class AppLinksPanel extends StatelessWidget {
  const AppLinksPanel({
    super.key,
    required this.links,
    required this.onPlayStoreChanged,
    required this.onWatchDemoChanged,
    required this.onPrivacyChanged,
    required this.onTermsChanged,
    required this.onSupportEmailChanged,
    required this.onSupportPhoneChanged,
    required this.onWhatsappChanged,
    required this.onCanonicalChanged,
    required this.onCopyValue,
  });

  final AppLinksDraft links;
  final ValueChanged<String> onPlayStoreChanged;
  final ValueChanged<String> onWatchDemoChanged;
  final ValueChanged<String> onPrivacyChanged;
  final ValueChanged<String> onTermsChanged;
  final ValueChanged<String> onSupportEmailChanged;
  final ValueChanged<String> onSupportPhoneChanged;
  final ValueChanged<String> onWhatsappChanged;
  final ValueChanged<String> onCanonicalChanged;
  final ValueChanged<String> onCopyValue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'App Links Management',
          subtitle:
              'Maintain app URLs and contact links used across landing and footer.',
          child: Column(
            children: <Widget>[
              _LinkField(
                label: 'Play Store URL',
                value: links.playStoreUrl,
                hint: 'https://play.google.com/...',
                helperText: _urlHint(links.playStoreUrl),
                onChanged: onPlayStoreChanged,
                onCopy: () => onCopyValue(links.playStoreUrl),
              ),
              _LinkField(
                label: 'Watch Demo URL',
                value: links.watchDemoUrl,
                hint: 'https://manaposter.in/demo',
                helperText: _urlHint(links.watchDemoUrl),
                onChanged: onWatchDemoChanged,
                onCopy: () => onCopyValue(links.watchDemoUrl),
              ),
              _LinkField(
                label: 'Privacy Policy URL',
                value: links.privacyPolicyUrl,
                hint: 'https://manaposter.in/privacy',
                helperText: _urlHint(links.privacyPolicyUrl),
                onChanged: onPrivacyChanged,
                onCopy: () => onCopyValue(links.privacyPolicyUrl),
              ),
              _LinkField(
                label: 'Terms & Conditions URL',
                value: links.termsUrl,
                hint: 'https://manaposter.in/terms',
                helperText: _urlHint(links.termsUrl),
                onChanged: onTermsChanged,
                onCopy: () => onCopyValue(links.termsUrl),
              ),
              _LinkField(
                label: 'Support Email',
                value: links.supportEmail,
                hint: 'support@manaposter.in',
                helperText: _emailHint(links.supportEmail),
                onChanged: onSupportEmailChanged,
                onCopy: () => onCopyValue(links.supportEmail),
              ),
              _LinkField(
                label: 'Support Phone',
                value: links.supportPhone,
                hint: '+91-90000-00000',
                helperText: _phoneHint(links.supportPhone),
                onChanged: onSupportPhoneChanged,
                onCopy: () => onCopyValue(links.supportPhone),
              ),
              _LinkField(
                label: 'WhatsApp Link',
                value: links.whatsappUrl,
                hint: 'https://wa.me/...',
                helperText: _urlHint(links.whatsappUrl),
                onChanged: onWhatsappChanged,
                onCopy: () => onCopyValue(links.whatsappUrl),
              ),
              _LinkField(
                label: 'Canonical Website URL',
                value: links.canonicalUrl,
                hint: 'https://manaposter.in',
                helperText: _urlHint(links.canonicalUrl),
                onChanged: onCanonicalChanged,
                onCopy: () => onCopyValue(links.canonicalUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Links Preview',
          subtitle:
              'Quick local reference of currently configured link values.',
          child: _LinksPreview(links: links),
        ),
      ],
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.label,
    required this.value,
    required this.hint,
    required this.helperText,
    required this.onChanged,
    required this.onCopy,
  });

  final String label;
  final String value;
  final String hint;
  final String helperText;
  final ValueChanged<String> onChanged;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('app-link-$label-$value'),
                  initialValue: value,
                  onChanged: onChanged,
                  decoration: _fieldDecoration(hint),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 11.5,
              color: helperText.contains('valid')
                  ? const Color(0xFF1E7C43)
                  : const Color(0xFF985136),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinksPreview extends StatelessWidget {
  const _LinksPreview({required this.links});

  final AppLinksDraft links;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _previewRow('Play Store', links.playStoreUrl),
          _previewRow('Watch Demo', links.watchDemoUrl),
          _previewRow('Privacy', links.privacyPolicyUrl),
          _previewRow('Terms', links.termsUrl),
          _previewRow(
            'Support',
            '${links.supportEmail} | ${links.supportPhone}',
          ),
          _previewRow('WhatsApp', links.whatsappUrl),
          _previewRow('Canonical', links.canonicalUrl),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF4D5A79)),
      ),
    );
  }
}

String _urlHint(String value) {
  final Uri? parsed = Uri.tryParse(value.trim());
  final bool valid =
      parsed != null && parsed.hasScheme && parsed.host.isNotEmpty;
  return valid ? 'Looks valid' : 'Use a complete URL including https://';
}

String _emailHint(String value) {
  final bool valid = value.contains('@') && value.contains('.');
  return valid ? 'Looks valid' : 'Email format looks incomplete';
}

String _phoneHint(String value) {
  final String compact = value.replaceAll(RegExp(r'[^0-9+]'), '');
  final bool valid = compact.length >= 10;
  return valid ? 'Looks valid' : 'Phone number may be incomplete';
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
