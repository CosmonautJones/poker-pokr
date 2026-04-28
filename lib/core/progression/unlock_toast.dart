import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/poker_theme.dart';
import 'achievements.dart';
import 'daily_challenges.dart';

const _toastDuration = Duration(milliseconds: 3000);
const _fadeDuration = Duration(milliseconds: 280);

/// Tracks the most recent in-flight toast so a duplicate request can tear the
/// previous one down early instead of stacking forever.
_ToastHandle? _activeToast;

class _ToastHandle {
  final OverlayEntry entry;
  Timer? timer;
  _ToastHandle(this.entry);

  void dismiss() {
    timer?.cancel();
    timer = null;
    if (entry.mounted) entry.remove();
  }
}

/// Shows a transient achievement-unlocked banner near the top of the screen.
///
/// No-ops when the [context] doesn't have an [Overlay] (e.g. in unit tests).
void showAchievementUnlocked(
  BuildContext context,
  AchievementDefinition def,
) {
  _showOverlay(
    context,
    child: _UnlockToast(
      icon: def.icon,
      headline: 'Achievement Unlocked!',
      title: def.title,
      description: def.description,
    ),
  );
  HapticFeedback.mediumImpact();
}

/// Shows a transient daily-challenge-completed banner with the +XP badge.
void showChallengeCompleted(
  BuildContext context,
  DailyChallengeDefinition def,
  int xp,
) {
  _showOverlay(
    context,
    child: _UnlockToast(
      icon: def.icon,
      headline: 'Challenge Complete!',
      title: def.title,
      description: def.description,
      xpBadge: '+$xp XP',
    ),
  );
  HapticFeedback.mediumImpact();
}

void _showOverlay(BuildContext context, {required Widget child}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // If another toast is in flight, tear it down so they don't stack visually.
  _activeToast?.dismiss();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Positioned(
        top: media.padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      );
    },
  );

  final handle = _ToastHandle(entry);
  _activeToast = handle;

  overlay.insert(entry);

  handle.timer = Timer(
    _toastDuration + _fadeDuration + const Duration(milliseconds: 50),
    () {
      // Guard against the route being popped before the timer fires —
      // calling remove() on a detached entry throws.
      handle.timer = null;
      if (identical(_activeToast, handle)) _activeToast = null;
      if (entry.mounted) entry.remove();
    },
  );
}

class _UnlockToast extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String title;
  final String description;
  final String? xpBadge;

  const _UnlockToast({
    required this.icon,
    required this.headline,
    required this.title,
    required this.description,
    this.xpBadge,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            pt.surfaceDim.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: pt.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [pt.goldPrimary, pt.goldDark],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(color: pt.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (xpBadge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pt.goldDark, pt.goldPrimary],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                xpBadge!,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: _fadeDuration)
        .slideY(begin: -0.25, end: 0, duration: _fadeDuration)
        .then(delay: _toastDuration)
        .fadeOut(duration: _fadeDuration);
  }
}
