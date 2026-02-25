import 'package:flutter/material.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';
import 'package:poker_trainer/poker/models/action.dart';

/// Callback for when the user selects an action.
typedef OnAction = void Function(PokerAction action);

/// Bottom bar showing legal actions with premium 3D-embossed buttons
/// and a polished bet slider interface.
class ActionBar extends StatefulWidget {
  final int currentPlayerIndex;
  final LegalActionSet legalActions;
  final double currentPot;
  final OnAction onAction;

  const ActionBar({
    super.key,
    required this.currentPlayerIndex,
    required this.legalActions,
    required this.currentPot,
    required this.onAction,
  });

  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar>
    with SingleTickerProviderStateMixin {
  bool _showBetSlider = false;
  double _betAmount = 0;
  double _minBet = 0;
  double _maxBet = 0;
  bool _isRaise = false;

  late AnimationController _sliderAnimController;
  late Animation<double> _sliderAnimation;

  @override
  void initState() {
    super.initState();
    _sliderAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sliderAnimation = CurvedAnimation(
      parent: _sliderAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sliderAnimController.dispose();
    super.dispose();
  }

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  void _openBetSlider({required bool isRaise}) {
    final range =
        isRaise ? widget.legalActions.raiseRange : widget.legalActions.betRange;
    if (range == null) return;

    setState(() {
      _showBetSlider = true;
      _isRaise = isRaise;
      _minBet = range.min;
      _maxBet = range.max;
      _betAmount = range.min;
    });
    _sliderAnimController.forward(from: 0);
  }

  void _closeBetSlider() {
    _sliderAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBetSlider = false;
        });
      }
    });
  }

  void _confirmBet() {
    final type = _isRaise ? ActionType.raise : ActionType.bet;
    widget.onAction(PokerAction(
      playerIndex: widget.currentPlayerIndex,
      type: type,
      amount: _betAmount,
    ));
    setState(() {
      _showBetSlider = false;
    });
    _sliderAnimController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final legal = widget.legalActions;
    final playerIdx = widget.currentPlayerIndex;

    if (_showBetSlider) {
      return _buildBetSlider(context);
    }

    // Count visible buttons to adjust sizing.
    int buttonCount = 0;
    if (legal.canFold) buttonCount++;
    if (legal.canCheck) buttonCount++;
    if (legal.callAmount != null) buttonCount++;
    if (legal.betRange != null) buttonCount++;
    if (legal.raiseRange != null) buttonCount++;
    if (legal.canAllIn) buttonCount++;
    final compact = buttonCount > 3;
    final gap = compact ? 6.0 : 8.0;
    final fontSize = compact ? 13.0 : 14.0;
    const btnHeight = 48.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        10,
        compact ? 8 : 12,
        8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: pt.borderSubtle.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (legal.canFold)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: 'Fold',
                    color: pt.actionFold,
                    height: btnHeight,
                    fontSize: fontSize,
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.fold,
                      ));
                    },
                  ),
                ),
              ),
            if (legal.canCheck)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: 'Check',
                    color: pt.actionCheck,
                    height: btnHeight,
                    fontSize: fontSize,
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.check,
                      ));
                    },
                  ),
                ),
              ),
            if (legal.callAmount != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: 'Call ${_formatChips(legal.callAmount!)}',
                    color: pt.actionCall,
                    height: btnHeight,
                    fontSize: fontSize,
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.call,
                        amount: legal.callAmount!,
                      ));
                    },
                  ),
                ),
              ),
            if (legal.betRange != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: 'Bet',
                    color: pt.actionBet,
                    height: btnHeight,
                    fontSize: fontSize,
                    onPressed: () => _openBetSlider(isRaise: false),
                  ),
                ),
              ),
            if (legal.raiseRange != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: 'Raise',
                    color: pt.actionBet,
                    height: btnHeight,
                    fontSize: fontSize,
                    onPressed: () => _openBetSlider(isRaise: true),
                  ),
                ),
              ),
            if (legal.canAllIn)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: _ActionButton(
                    label: compact
                        ? 'All-In'
                        : 'All-In ${_formatChips(legal.allInAmount ?? 0)}',
                    color: pt.actionAllIn,
                    height: btnHeight,
                    fontSize: fontSize,
                    isAllIn: true,
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.allIn,
                        amount: legal.allInAmount ?? 0,
                      ));
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetSlider(BuildContext context) {
    final pt = context.poker;
    final pot = widget.currentPot;
    final presets = <(String, double)>[
      ('1/3', pot / 3),
      ('1/2', pot / 2),
      ('3/4', pot * 3 / 4),
      ('Pot', pot),
    ];

    return FadeTransition(
      opacity: _sliderAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: pt.borderSubtle.withValues(alpha: 0.5)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount display with gold shimmer
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [pt.goldPrimary, pt.goldLight, pt.goldPrimary],
                    ).createShader(bounds);
                  },
                  child: Text(
                    '${_isRaise ? "Raise to" : "Bet"}: ${_formatChips(_betAmount)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              // Slider with enhanced theme
              Row(
                children: [
                  Text(
                    _formatChips(_minBet),
                    style: TextStyle(color: pt.textMuted, fontSize: 10),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: pt.goldPrimary,
                        inactiveTrackColor:
                            pt.borderSubtle.withValues(alpha: 0.3),
                        thumbColor: pt.goldPrimary,
                        overlayColor: pt.goldPrimary.withValues(alpha: 0.12),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 4,
                        ),
                      ),
                      child: Slider(
                        value: _betAmount.clamp(_minBet, _maxBet),
                        min: _minBet,
                        max: _maxBet,
                        divisions: _maxBet > _minBet
                            ? ((_maxBet - _minBet) /
                                    (_minBet > 0 ? _minBet : 1))
                                .round()
                                .clamp(1, 100)
                            : 1,
                        onChanged: (v) {
                          setState(() {
                            _betAmount = _roundBet(v);
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatChips(_maxBet),
                    style: TextStyle(color: pt.textMuted, fontSize: 10),
                  ),
                ],
              ),
              // Preset buttons
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    for (final (label, amount) in presets)
                      if (amount >= _minBet && amount <= _maxBet)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: _PresetButton(
                              label: label,
                              isActive:
                                  (_betAmount - _roundBet(amount)).abs() <
                                      0.01,
                              onPressed: () {
                                setState(() {
                                  _betAmount = _roundBet(amount);
                                });
                              },
                            ),
                          ),
                        ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _PresetButton(
                          label: 'Max',
                          isActive: (_betAmount - _maxBet).abs() < 0.01,
                          accentColor: pt.actionAllIn,
                          onPressed: () {
                            setState(() {
                              _betAmount = _maxBet;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Confirm / Cancel
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        onPressed: _closeBetSlider,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _ActionButton(
                        label:
                            '${_isRaise ? "Raise to" : "Bet"} ${_formatChips(_betAmount)}',
                        color: pt.actionBet,
                        height: 44,
                        fontSize: 14,
                        onPressed: _confirmBet,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _roundBet(double value) {
    if (value <= 10) return (value * 2).roundToDouble() / 2;
    if (value <= 100) return value.roundToDouble();
    return (value / 5).roundToDouble() * 5;
  }
}

/// Premium 3D-embossed action button with tactile press animation.
class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final double height;
  final double fontSize;
  final bool isAllIn;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.height,
    required this.fontSize,
    this.isAllIn = false,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _yOffset;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: PokerAnimations.kButtonPress,
      reverseDuration: PokerAnimations.kButtonRelease,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: PokerAnimations.buttonPressCurve,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
    _yOffset = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: PokerAnimations.buttonPressCurve,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _isPressed = true;
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      _isPressed = false;
      _pressController.reverse();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    _isPressed = false;
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final lightened = Color.lerp(color, Colors.white, 0.15)!;
    final darkened = Color.lerp(color, Colors.black, 0.25)!;

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final isDown = _pressController.value > 0;
        return Transform.translate(
          offset: Offset(0, _yOffset.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                // 3-stop gradient: light top → base → dark bottom
                gradient: LinearGradient(
                  colors: isDown
                      ? [
                          Color.lerp(color, Colors.black, 0.1)!,
                          darkened,
                        ]
                      : [lightened, color, darkened],
                  stops: isDown ? null : const [0.0, 0.4, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  top: BorderSide(
                    color: isDown
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.black.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: isDown
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: isDown
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact preset button for bet sizing.
class _PresetButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? accentColor;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final borderColor = accentColor ?? pt.goldPrimary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        minimumSize: const Size(0, 34),
        textStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color:
              isActive ? borderColor : borderColor.withValues(alpha: 0.4),
          width: isActive ? 1.5 : 1,
        ),
        backgroundColor: isActive
            ? borderColor.withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      child: Text(label),
    );
  }
}
