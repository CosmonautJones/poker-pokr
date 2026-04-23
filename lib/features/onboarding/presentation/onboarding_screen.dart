import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).setSeen(true);
    if (!mounted) return;
    context.go('/home');
  }

  void _skip() {
    unawaited(_finish());
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: const [
                _WelcomePage(),
                _LearnPage(),
                _BookkeeperPage(),
                _ProgressionPage(),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLast ? 0 : 1,
                child: TextButton(
                  onPressed: isLast ? null : _skip,
                  child: Text(
                    'Skip',
                    style: textTheme.labelLarge?.copyWith(
                      color: pt.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? pt.goldPrimary
                              : pt.textMuted.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Deal me in' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: illustration
                  .animate()
                  .fadeIn(duration: 380.ms)
                  .scale(begin: const Offset(0.92, 0.92), duration: 380.ms),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 380.ms, delay: 80.ms)
                    .slideY(begin: 0.06, duration: 380.ms, delay: 80.ms),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: pt.textMuted,
                    height: 1.4,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 380.ms, delay: 140.ms)
                    .slideY(begin: 0.06, duration: 380.ms, delay: 140.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return _OnboardingPage(
      illustration: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pt.goldPrimary, pt.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Table',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: 'Sense',
                  style: textTheme.headlineMedium?.copyWith(
                    color: pt.goldPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      title: 'Welcome to TableSense',
      body: 'Master poker strategy, one hand at a time.',
    );
  }
}

class _LearnPage extends StatelessWidget {
  const _LearnPage();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return _OnboardingPage(
      illustration: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  pt.goldPrimary.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(icon: Icons.school_rounded, color: pt.goldPrimary),
              const SizedBox(width: 14),
              _IconBadge(icon: Icons.lightbulb_rounded, color: pt.accent),
              const SizedBox(width: 14),
              _IconBadge(
                icon: Icons.play_circle_fill_rounded,
                color: pt.profit,
              ),
            ],
          ),
        ],
      ),
      title: 'Learn by playing',
      body: 'Interactive lessons and coaching tips walk you through real '
          'spots so strategy sticks.',
    );
  }
}

class _BookkeeperPage extends StatelessWidget {
  const _BookkeeperPage();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return _OnboardingPage(
      illustration: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: pt.goldPrimary.withValues(alpha: 0.4),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: [
              pt.feltCenter.withValues(alpha: 0.30),
              pt.surfaceDim,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: CustomPaint(
          painter: _SparklinePainter(color: pt.goldPrimary),
          child: const SizedBox.expand(),
        ),
      ),
      title: 'Track your game',
      body: 'Log every session and watch your bankroll trend. Honest data '
          'beats memory every time.',
    );
  }
}

class _ProgressionPage extends StatelessWidget {
  const _ProgressionPage();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return _OnboardingPage(
      illustration: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(
              icon: Icons.local_fire_department_rounded, color: pt.allInGlow),
          const SizedBox(width: 14),
          _IconBadge(icon: Icons.star_rounded, color: pt.goldPrimary),
          const SizedBox(width: 14),
          _IconBadge(icon: Icons.emoji_events_rounded, color: pt.accent),
        ],
      ),
      title: 'Earn and level up',
      body: 'Daily streaks, XP, and achievements keep your edge sharp. '
          'Tap the button below to get started.',
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[
      Offset(size.width * 0.00, size.height * 0.80),
      Offset(size.width * 0.18, size.height * 0.65),
      Offset(size.width * 0.33, size.height * 0.72),
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.66, size.height * 0.55),
      Offset(size.width * 0.82, size.height * 0.28),
      Offset(size.width * 1.00, size.height * 0.18),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);

    final fill = Paint()..color = color.withValues(alpha: 0.16);
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fill);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color;
}
