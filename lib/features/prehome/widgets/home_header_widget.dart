// ignore_for_file: unused_element_parameter
part of '../screens/home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onHeaderTap,
    required this.onProfileTap,
    required this.viewerPosterProfile,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.compact,
  });

  final VoidCallback onHeaderTap;
  final VoidCallback onProfileTap;
  final PosterProfileData viewerPosterProfile;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onSearchSubmitted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final topInset = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onHeaderTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          10,
          topInset + (compact ? 4 : 8),
          10,
          compact ? 5 : 9,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFD81B60),
              Color(0xFFFF6F3C),
              Color(0xFFFFB703),
            ],
            stops: <double>[0.0, 0.58, 1.0],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.05,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  cursorColor: Colors.white,
                  onChanged: onSearchChanged,
                  onTapOutside: (_) => searchFocusNode.unfocus(),
                  onEditingComplete: () => unawaited(onSearchSubmitted()),
                  onSubmitted: (_) => unawaited(onSearchSubmitted()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.searchTemplates,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                    prefixIcon: IconButton(
                      onPressed: () => unawaited(onSearchSubmitted()),
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.16),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 36,
                child: _HeaderProfileAvatar(
                  viewerPosterProfile: viewerPosterProfile,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

