import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_visuals.dart';

/// Mounts an `OverlayEntry` toast whenever a new achievement is queued.
/// Drains the queue one at a time so multi-unlocks display sequentially.
class AchievementUnlockHost extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementUnlockHost({super.key, required this.child});

  @override
  ConsumerState<AchievementUnlockHost> createState() =>
      _AchievementUnlockHostState();
}

class _AchievementUnlockHostState extends ConsumerState<AchievementUnlockHost> {
  OverlayEntry? _entry;
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingUnlockProvider, (prev, next) {
      if (next != null && !_showing) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
      }
    });
    return widget.child;
  }

  /// Remove [_entry] at most once. The toast's onDismissed and our own dispose
  /// can both fire, so an idempotent removal is required.
  void _removeEntry() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    if (entry.mounted) entry.remove();
  }

  void _drain() {
    if (!mounted || _showing) return;
    final id = ref.read(achievementsProvider.notifier).consumeNextPending();
    if (id == null) return;
    final def = AchievementCatalog.byId(id);
    _showing = true;
    ref.read(hapticServiceProvider).success();
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _UnlockToast(
        def: def,
        onDismissed: () {
          if (identical(_entry, entry)) {
            _removeEntry();
          }
          _showing = false;
          if (!mounted) return;
          if (ref.read(pendingUnlockProvider) != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }
}

class _UnlockToast extends StatefulWidget {
  final AchievementDef def;
  final VoidCallback onDismissed;

  const _UnlockToast({required this.def, required this.onDismissed});

  @override
  State<_UnlockToast> createState() => _UnlockToastState();
}

class _UnlockToastState extends State<_UnlockToast>
    with SingleTickerProviderStateMixin {
  static const _enter = Duration(milliseconds: 320);
  static const _hold = Duration(milliseconds: 2200);
  static const _exit = Duration(milliseconds: 260);

  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: _enter + _hold + _exit,
      vsync: this,
    );
    final enterEnd = _enter.inMilliseconds / _ctrl.duration!.inMilliseconds;
    final exitStart = (_enter + _hold).inMilliseconds /
        _ctrl.duration!.inMilliseconds;

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1.2), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: enterEnd,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: exitStart - enterEnd,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.2))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 1.0 - exitStart,
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: enterEnd,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: exitStart - enterEnd,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 1.0 - exitStart,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  void _dismissEarly() {
    if (_exiting) return;
    _exiting = true;
    final exitFraction = _exit.inMilliseconds /
        (_enter.inMilliseconds + _hold.inMilliseconds + _exit.inMilliseconds);
    final from = (1.0 - exitFraction).clamp(0.0, 1.0);
    if (_ctrl.value < from) _ctrl.value = from;
    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PokerTheme>() ?? PokerTheme.dark;
    final style = TierStyle.of(context, widget.def.tier);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _opacity,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismissEarly,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: style.accent.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: style.accent.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AchievementMedallion(
                        def: widget.def,
                        unlocked: true,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ACHIEVEMENT UNLOCKED',
                                  style: TextStyle(
                                    color: style.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: style.accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    style.label.toUpperCase(),
                                    style: TextStyle(
                                      color: style.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.def.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.def.description,
                              style: TextStyle(
                                color: pt.textMuted,
                                fontSize: 12,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
