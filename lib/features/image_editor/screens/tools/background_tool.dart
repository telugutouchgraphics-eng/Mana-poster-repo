part of '../image_editor_screen.dart';

enum _BackgroundEditorTab { white, transparent, color, gradient, image }

class BackgroundEditorFullscreenOverlay extends StatefulWidget {
  const BackgroundEditorFullscreenOverlay({
    super.key,
    required this.colors,
    required this.gradients,
    required this.selectedColor,
    required this.selectedGradientIndex,
    required this.hasSelectedImage,
    required this.onColorSelected,
    required this.onGradientSelected,
    required this.onImageSelected,
  });

  final List<Color> colors;
  final List<List<Color>> gradients;
  final Color selectedColor;
  final int selectedGradientIndex;
  final bool hasSelectedImage;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<int> onGradientSelected;
  final Future<bool> Function() onImageSelected;

  @override
  State<BackgroundEditorFullscreenOverlay> createState() =>
      _BackgroundEditorFullscreenOverlayState();
}

class _BackgroundEditorFullscreenOverlayState
    extends State<BackgroundEditorFullscreenOverlay> {
  late Color _selectedColor = widget.selectedColor;
  late int _selectedGradientIndex = widget.selectedGradientIndex;
  late bool _hasSelectedImage = widget.hasSelectedImage;
  late _BackgroundEditorTab _activeTab = _resolveInitialTab();

  _BackgroundEditorTab _resolveInitialTab() {
    if (_hasSelectedImage) {
      return _BackgroundEditorTab.image;
    }
    if (_selectedGradientIndex >= 0) {
      return _BackgroundEditorTab.gradient;
    }
    if (_selectedColor.a <= 0.001) {
      return _BackgroundEditorTab.transparent;
    }
    if (_selectedColor.toARGB32() == Colors.white.toARGB32()) {
      return _BackgroundEditorTab.white;
    }
    return _BackgroundEditorTab.color;
  }

  Widget _buildTabButton(_BackgroundEditorTab tab, String label) {
    final selected = _activeTab == tab;
    return SizedBox(
      width: 106,
      child: _PressableSurface(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.58)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 0.97 : 0.78),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteTab() {
    return Center(
      child: _PressableSurface(
        onTap: () {
          widget.onColorSelected(Colors.white);
          setState(() {
            _selectedColor = Colors.white;
            _selectedGradientIndex = -1;
            _hasSelectedImage = false;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 180,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A0F172A)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Pure White',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransparentTab() {
    return Center(
      child: _PressableSurface(
        onTap: () {
          widget.onColorSelected(Colors.transparent);
          setState(() {
            _selectedColor = Colors.transparent;
            _selectedGradientIndex = -1;
            _hasSelectedImage = false;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF334155), Color(0xFF0F172A)],
            ),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Transparent Stage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorTab() {
    return GridView.builder(
      itemCount: widget.colors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final color = widget.colors[index];
        final selected =
            _selectedGradientIndex == -1 &&
            _selectedColor.toARGB32() == color.toARGB32();
        return _BackgroundColorTile(
          color: color,
          selected: selected,
          onTap: () {
            widget.onColorSelected(color);
            setState(() {
              _selectedColor = color;
              _selectedGradientIndex = -1;
              _hasSelectedImage = false;
            });
          },
        );
      },
    );
  }

  Widget _buildGradientTab() {
    return GridView.builder(
      itemCount: widget.gradients.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _BackgroundGradientTile(
          colors: widget.gradients[index],
          selected: _selectedGradientIndex == index,
          onTap: () {
            widget.onGradientSelected(index);
            setState(() {
              _selectedGradientIndex = index;
              _hasSelectedImage = false;
            });
          },
        );
      },
    );
  }

  Widget _buildImageTab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _PressableSurface(
          onTap: () async {
            final didSelect = await widget.onImageSelected();
            if (!mounted || !didSelect) {
              return;
            }
            setState(() {
              _hasSelectedImage = true;
              _selectedGradientIndex = -1;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 240,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Text(
              _hasSelectedImage ? 'Change from Gallery' : 'Import from Gallery',
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PressableSurface(
          onTap: _hasSelectedImage
              ? () {
                  widget.onColorSelected(Colors.white);
                  setState(() {
                    _hasSelectedImage = false;
                    _selectedColor = Colors.white;
                    _selectedGradientIndex = -1;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 240,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: _hasSelectedImage ? 0.06 : 0.03,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: _hasSelectedImage ? 0.12 : 0.07,
                ),
              ),
            ),
            child: Text(
              'Remove Image',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: _hasSelectedImage ? 0.86 : 0.42,
                ),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_activeTab) {
      case _BackgroundEditorTab.white:
        return _buildWhiteTab();
      case _BackgroundEditorTab.transparent:
        return _buildTransparentTab();
      case _BackgroundEditorTab.color:
        return _buildColorTab();
      case _BackgroundEditorTab.gradient:
        return _buildGradientTab();
      case _BackgroundEditorTab.image:
        return _buildImageTab(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Material(
      color: Colors.transparent,
      child: EditorFullscreenOverlay(
        title: strings.localized(
          telugu: 'బ్యాక్‌గ్రౌండ్',
          english: 'Background',
        ),
        onBack: () => Navigator.of(context).pop(),
        onDone: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    _buildTabButton(
                      _BackgroundEditorTab.white,
                      strings.localized(telugu: 'తెలుపు', english: 'White'),
                    ),
                    const SizedBox(width: 6),
                    _buildTabButton(
                      _BackgroundEditorTab.transparent,
                      strings.localized(
                        telugu: 'పారదర్శకం',
                        english: 'Transparent',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTabButton(
                      _BackgroundEditorTab.color,
                      strings.localized(telugu: 'రంగు', english: 'Color'),
                    ),
                    const SizedBox(width: 6),
                    _buildTabButton(
                      _BackgroundEditorTab.gradient,
                      strings.localized(
                        telugu: 'గ్రేడియెంట్',
                        english: 'Gradient',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTabButton(
                      _BackgroundEditorTab.image,
                      strings.localized(telugu: 'ఇమేజ్', english: 'Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey<String>(_activeTab.name),
                    child: _buildBody(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundColorTile extends StatelessWidget {
  const _BackgroundColorTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGradientTile extends StatelessWidget {
  const _BackgroundGradientTile({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: selected
            ? const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientDot extends StatelessWidget {
  const _GradientDot({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: const Color(0x1A2563EB),
        highlightColor: const Color(0x0F2563EB),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
