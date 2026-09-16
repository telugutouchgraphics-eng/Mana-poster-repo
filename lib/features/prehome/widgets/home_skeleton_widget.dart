// ignore_for_file: unused_element_parameter, unused_element
part of '../screens/home_screen.dart';

class _PosterFeedSkeletonSliver extends StatelessWidget {
  const _PosterFeedSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _PosterSkeletonCard(),
      ),
    );
  }
}

class _PosterFeedSkeletonViewport extends StatelessWidget {
  const _PosterFeedSkeletonViewport();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => const _PosterSkeletonCard(),
    );
  }
}

class _PosterSkeletonCard extends StatelessWidget {
  const _PosterSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            _SkeletonBox(height: 220, radius: 18),
            SizedBox(height: 12),
            _SkeletonBox(width: 120, height: 12),
            SizedBox(height: 10),
            _SkeletonBox(height: 54, radius: 14),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _SkeletonBox(height: 44, radius: 14)),
                SizedBox(width: 10),
                Expanded(child: _SkeletonBox(height: 44, radius: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (progress * 4.0), -0.3),
              end: Alignment(0.0 + (progress * 4.0), 0.3),
              colors: const <Color>[
                Color(0xFFE2E8F0),
                Color(0xFFFFFFFF),
                Color(0xFFE2E8F0),
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _ImageLoadingState extends StatelessWidget {
  const _ImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3F8),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  const _ImageErrorState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 20,
        vertical: compact ? 10 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.image_not_supported_outlined,
            color: const Color(0xFF94A3B8),
            size: compact ? 22 : 28,
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              height: 1.35,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
