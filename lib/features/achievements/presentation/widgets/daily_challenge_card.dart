import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements/daily_challenge.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Compact card that surfaces today's challenge: progress bar, target, claim
/// button when complete. Hidden once claimed (so it doesn't take real estate
/// once the user already collected today's reward).
class DailyChallengeCard extends ConsumerWidget {
  /// When true, hide the entire widget while the daily challenge is claimed.
  /// Useful on Home where we don't want a stale "Claimed" tile after victory.
  final bool hideWhenClaimed;

  const DailyChallengeCard({super.key, this.hideWhenClaimed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(dailyChallengeProvider);
    final tpl = challenge.template;
    if (tpl == null) return const SizedBox.shrink();
    if (hideWhenClaimed && challenge.claimed) return const SizedBox.shrink();

    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final fraction = challenge.progressFraction;
    final claimable = challenge.isComplete && !challenge.claimed;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: claimable
              ? pt.profit.withValues(alpha: 0.6)
              : pt.goldPrimary.withValues(alpha: 0.25),
          width: claimable ? 1.5 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (claimable ? pt.profit : pt.goldPrimary)
                  .withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      pt.goldPrimary.withValues(alpha: 0.45),
                      pt.goldPrimary.withValues(alpha: 0.05),
                    ]),
                    border: Border.all(
                      color: pt.goldPrimary.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Icon(tpl.icon,
                      size: 16, color: pt.goldPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daily Challenge',
                        style: textTheme.labelSmall?.copyWith(
                          color: pt.goldPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tpl.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _RewardBadge(xp: tpl.xpReward),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tpl.description,
              style: textTheme.bodySmall?.copyWith(
                color: pt.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        claimable ? pt.profit : pt.goldPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${challenge.progress}/${tpl.target}',
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: claimable
                    ? () => _claim(context, ref, tpl)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: claimable
                      ? pt.profit
                      : Colors.white.withValues(alpha: 0.06),
                  foregroundColor: claimable
                      ? Colors.white
                      : pt.textMuted,
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: Icon(
                  challenge.claimed
                      ? Icons.check_rounded
                      : claimable
                          ? Icons.redeem_rounded
                          : Icons.hourglass_top_rounded,
                  size: 18,
                ),
                label: Text(
                  challenge.claimed
                      ? 'Reward claimed'
                      : claimable
                          ? 'Claim +${tpl.xpReward} XP'
                          : 'Keep playing',
                ),
              )
                  .animate(target: claimable ? 1 : 0)
                  .scaleXY(
                    begin: 1.0,
                    end: 1.03,
                    duration: 220.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(
    BuildContext context,
    WidgetRef ref,
    DailyChallengeTemplate tpl,
  ) async {
    ref.read(hapticServiceProvider).success();
    final xp = await ref
        .read(dailyChallengeProvider.notifier)
        .claim();
    if (!context.mounted) return;
    if (xp > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily challenge complete! +$xp XP'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _RewardBadge extends StatelessWidget {
  final int xp;

  const _RewardBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [pt.goldDark, pt.goldPrimary]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            '+$xp XP',
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
