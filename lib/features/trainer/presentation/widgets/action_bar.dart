import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';
import 'package:poker_trainer/poker/models/action.dart';

/// Callback for when the user selects an action.
typedef OnAction = void Function(PokerAction action);

/// Bottom bar showing legal actions for the current player.
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

class _ActionBarState extends State<ActionBar> {
  bool _showBetSlider = false;
  double _betAmount = 0;
  double _minBet = 0;
  double _maxBet = 0;
  bool _isRaise = false;

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
  }

  void _closeBetSlider() {
    setState(() {
      _showBetSlider = false;
    });
  }

  void _confirmBet() {
    final type = _isRaise ? ActionType.raise : ActionType.bet;
    widget.onAction(PokerAction(
      playerIndex: widget.currentPlayerIndex,
      type: type,
      amount: _betAmount,
    ));
    _closeBetSlider();
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
    final hPad = compact ? 2.0 : 4.0;
    final fontSize = compact ? 12.0 : 14.0;
    const btnHeight = 48.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: pt.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Fold button
            if (legal.canFold)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.fold,
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionFold,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: const Text('Fold'),
                  ),
                ),
              ),
            // Check button
            if (legal.canCheck)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.check,
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionCheck,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: const Text('Check'),
                  ),
                ),
              ),
            // Call button
            if (legal.callAmount != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.call,
                        amount: legal.callAmount!,
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionCall,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Call ${_formatChips(legal.callAmount!)}'),
                    ),
                  ),
                ),
              ),
            // Bet button
            if (legal.betRange != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () => _openBetSlider(isRaise: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionBet,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: const Text('Bet'),
                  ),
                ),
              ),
            // Raise button
            if (legal.raiseRange != null)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () => _openBetSlider(isRaise: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionBet,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: const Text('Raise'),
                  ),
                ),
              ),
            // All-in button
            if (legal.canAllIn)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: FilledButton(
                    onPressed: () {
                      widget.onAction(PokerAction(
                        playerIndex: playerIdx,
                        type: ActionType.allIn,
                        amount: legal.allInAmount ?? 0,
                      ));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.actionAllIn,
                      minimumSize: Size(0, btnHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: TextStyle(fontSize: fontSize),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(compact
                          ? 'All-In'
                          : 'All-In ${_formatChips(legal.allInAmount ?? 0)}'),
                    ),
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
    // Preset amounts.
    final presets = <(String, double)>[
      ('1/3', pot / 3),
      ('1/2', pot / 2),
      ('3/4', pot * 3 / 4),
      ('Pot', pot),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: pt.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount display
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${_isRaise ? "Raise to" : "Bet"}: ${_formatChips(_betAmount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pt.accent,
                ),
              ),
            ),
            // Slider
            Row(
              children: [
                Text(
                  _formatChips(_minBet),
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: 10,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _betAmount.clamp(_minBet, _maxBet),
                    min: _minBet,
                    max: _maxBet,
                    divisions: _maxBet > _minBet
                        ? ((_maxBet - _minBet) / (_minBet > 0 ? _minBet : 1))
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
                Text(
                  _formatChips(_maxBet),
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            // Preset buttons
            Row(
              children: [
                for (final (label, amount) in presets)
                  if (amount >= _minBet && amount <= _maxBet)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _betAmount = _roundBet(amount);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                            minimumSize: const Size(0, 36),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                // All-in preset
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _betAmount = _maxBet;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0),
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 11),
                        side: BorderSide(color: pt.actionAllIn),
                      ),
                      child: const Text('Max'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Confirm / Cancel
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: _closeBetSlider,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton(
                      onPressed: _confirmBet,
                      style: FilledButton.styleFrom(
                        backgroundColor: pt.actionBet,
                        minimumSize: const Size(0, 44),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${_isRaise ? "Raise to" : "Bet"} ${_formatChips(_betAmount)}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Round bet to nearest whole number or half (for cleaner amounts).
  double _roundBet(double value) {
    if (value <= 10) return (value * 2).roundToDouble() / 2;
    if (value <= 100) return value.roundToDouble();
    return (value / 5).roundToDouble() * 5;
  }
}
