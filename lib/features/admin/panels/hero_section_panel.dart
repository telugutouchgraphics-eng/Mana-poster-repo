import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_content_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_panel_card.dart';

class HeroSectionPanel extends StatelessWidget {
  const HeroSectionPanel({
    super.key,
    required this.hero,
    required this.visible,
    required this.onVisibilityChanged,
    required this.onBadgeChanged,
    required this.onHeadingChanged,
    required this.onSubheadingChanged,
    required this.onPrimaryCtaChanged,
    required this.onSecondaryCtaChanged,
    required this.onAddTrustBullet,
    required this.onTrustBulletChanged,
    required this.onRemoveTrustBullet,
    required this.onMoveTrustBulletUp,
    required this.onMoveTrustBulletDown,
    required this.onAddScreenshot,
    required this.onScreenshotTitleChanged,
    required this.onScreenshotPathChanged,
    required this.onRemoveScreenshot,
    required this.onMoveScreenshotUp,
    required this.onMoveScreenshotDown,
    required this.onSelectScreenshotFromMedia,
  });

  final HeroContentDraft hero;
  final bool visible;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onBadgeChanged;
  final ValueChanged<String> onHeadingChanged;
  final ValueChanged<String> onSubheadingChanged;
  final ValueChanged<String> onPrimaryCtaChanged;
  final ValueChanged<String> onSecondaryCtaChanged;
  final VoidCallback onAddTrustBullet;
  final void Function(int index, String value) onTrustBulletChanged;
  final ValueChanged<int> onRemoveTrustBullet;
  final ValueChanged<int> onMoveTrustBulletUp;
  final ValueChanged<int> onMoveTrustBulletDown;
  final VoidCallback onAddScreenshot;
  final void Function(int index, String value) onScreenshotTitleChanged;
  final void Function(int index, String value) onScreenshotPathChanged;
  final ValueChanged<int> onRemoveScreenshot;
  final ValueChanged<int> onMoveScreenshotUp;
  final ValueChanged<int> onMoveScreenshotDown;
  final ValueChanged<int> onSelectScreenshotFromMedia;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        AdminPanelCard(
          title: 'Hero Content Settings',
          subtitle:
              'Update headline messaging, CTA labels and trust points for first screen.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Visible',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5E6884)),
              ),
              Switch(
                value: visible,
                activeThumbColor: const Color(0xFF5A31E1),
                onChanged: onVisibilityChanged,
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              _LabeledField(
                label: 'Badge Text',
                value: hero.badgeText,
                onChanged: onBadgeChanged,
              ),
              _LabeledField(
                label: 'Main Heading',
                value: hero.heading,
                onChanged: onHeadingChanged,
              ),
              _LabeledField(
                label: 'Subheading',
                value: hero.subheading,
                maxLines: 3,
                onChanged: onSubheadingChanged,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _LabeledField(
                      label: 'Primary CTA',
                      value: hero.primaryCtaText,
                      onChanged: onPrimaryCtaChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LabeledField(
                      label: 'Secondary CTA',
                      value: hero.secondaryCtaText,
                      onChanged: onSecondaryCtaChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Trust Bullet Points',
          subtitle: 'Short value bullets displayed near CTA buttons.',
          child: Column(
            children: <Widget>[
              ...hero.trustBullets.asMap().entries.map((
                MapEntry<int, String> entry,
              ) {
                final int index = entry.key;
                final String text = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == hero.trustBullets.length - 1 ? 0 : 10,
                  ),
                  child: _BulletRow(
                    value: text,
                    onChanged: (String value) =>
                        onTrustBulletChanged(index, value),
                    onRemove: () => onRemoveTrustBullet(index),
                    onMoveUp: index > 0
                        ? () => onMoveTrustBulletUp(index)
                        : null,
                    onMoveDown: index < hero.trustBullets.length - 1
                        ? () => onMoveTrustBulletDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddTrustBullet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Bullet'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Hero Screenshots',
          subtitle: 'Manage screenshot titles and local asset path values.',
          child: Column(
            children: <Widget>[
              ...hero.screenshots.asMap().entries.map((
                MapEntry<int, HeroScreenshotDraft> entry,
              ) {
                final int index = entry.key;
                final HeroScreenshotDraft screenshot = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == hero.screenshots.length - 1 ? 0 : 10,
                  ),
                  child: _ScreenshotRow(
                    screenshot: screenshot,
                    onTitleChanged: (String value) =>
                        onScreenshotTitleChanged(index, value),
                    onPathChanged: (String value) =>
                        onScreenshotPathChanged(index, value),
                    onSelectFromMedia: () => onSelectScreenshotFromMedia(index),
                    onRemove: () => onRemoveScreenshot(index),
                    onMoveUp: index > 0
                        ? () => onMoveScreenshotUp(index)
                        : null,
                    onMoveDown: index < hero.screenshots.length - 1
                        ? () => onMoveScreenshotDown(index)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddScreenshot,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Screenshot'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminPanelCard(
          title: 'Hero Live Preview',
          subtitle: 'Preview only. Uses local draft values from this panel.',
          child: _HeroPreview(hero: hero, visible: visible),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

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
          TextFormField(
            key: ValueKey<String>('hero-$label-$value'),
            initialValue: value,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: _fieldDecoration(),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.value,
    required this.onChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE3E9F7)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              key: ValueKey<String>('hero-bullet-$value'),
              initialValue: value,
              onChanged: onChanged,
              decoration: _fieldDecoration(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMoveUp,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            onPressed: onMoveDown,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF9F3C4D),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotRow extends StatelessWidget {
  const _ScreenshotRow({
    required this.screenshot,
    required this.onTitleChanged,
    required this.onPathChanged,
    required this.onSelectFromMedia,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final HeroScreenshotDraft screenshot;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onPathChanged;
  final VoidCallback onSelectFromMedia;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7F8FD),
        border: Border.all(color: const Color(0xFFE3E7F4)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>(
                    'hero-screenshot-title-${screenshot.title}',
                  ),
                  initialValue: screenshot.title,
                  onChanged: onTitleChanged,
                  decoration: _fieldDecoration(hint: 'Screenshot title'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFF9F3C4D),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey<String>(
              'hero-screenshot-path-${screenshot.assetPath}',
            ),
            initialValue: screenshot.assetPath,
            onChanged: onPathChanged,
            decoration: _fieldDecoration(hint: 'assets/...'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onSelectFromMedia,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Select from Media Library'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview({required this.hero, required this.visible});

  final HeroContentDraft hero;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFFFF5F6),
            Color(0xFFF3F2FF),
            Color(0xFFEFF7FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE3E7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFFECE7FF),
                ),
                child: Text(
                  hero.badgeText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4730B5),
                  ),
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 12),
          Text(
            hero.heading,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17223F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hero.subheading,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4E5875),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hero.trustBullets
                .map(
                  (String bullet) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDDE4F4)),
                    ),
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF304165),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A31E1),
                  foregroundColor: Colors.white,
                ),
                child: Text(hero.primaryCtaText),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: Text(hero.secondaryCtaText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hero.screenshots.length,
              separatorBuilder: (_, int index) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final HeroScreenshotDraft screenshot = hero.screenshots[index];
                return Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE1E6F5)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        screenshot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E294B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        screenshot.assetPath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF63708E),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE3F3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6A46F5)),
    ),
  );
}
