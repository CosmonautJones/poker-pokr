import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/learn/domain/pot_odds.dart';

/// Pot-odds reference + a small live calculator.
///
/// The reference is a fixed table of common bet sizings. The calculator
/// lets the player type any pot/bet pair and instantly see the break-even
/// equity and ratio.
class PotOddsScreen extends StatefulWidget {
  const PotOddsScreen({super.key});

  @override
  State<PotOddsScreen> createState() => _PotOddsScreenState();
}

class _PotOddsScreenState extends State<PotOddsScreen> {
  // Pot defaults to 150 / call 50 → 25% (a half-pot bet, the canonical
  // "pot is 100, villain bets 50" example).
  final _potCtrl = TextEditingController(text: '150');
  final _callCtrl = TextEditingController(text: '50');

  double get _pot => double.tryParse(_potCtrl.text.trim()) ?? 0;
  double get _call => double.tryParse(_callCtrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _potCtrl.dispose();
    _callCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    // The user enters the pot they see on the table (already includes any
    // villain bet they have to call) and the chips required to call. This
    // matches how poker UIs display the pot mid-action.
    final result = computePotOdds(potBeforeCall: _pot, toCall: _call);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pot Odds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/learn'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: Responsive.hPadding(context).add(
            const EdgeInsets.only(top: 8, bottom: 24),
          ),
          children: [
            _CalculatorCard(
              potCtrl: _potCtrl,
              callCtrl: _callCtrl,
              onChanged: () => setState(() {}),
              result: result,
            )
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.05, duration: 280.ms),
            const SizedBox(height: 18),
            Text(
              'Bet-size cheat sheet',
              style: textTheme.labelLarge?.copyWith(
                color: pt.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const _ReferenceTable()
                .animate()
                .fadeIn(duration: 320.ms, delay: 80.ms),
            const SizedBox(height: 18),
            const _RuleOfTwoFourCard()
                .animate()
                .fadeIn(duration: 320.ms, delay: 160.ms),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final TextEditingController potCtrl;
  final TextEditingController callCtrl;
  final VoidCallback onChanged;
  final PotOdds result;

  const _CalculatorCard({
    required this.potCtrl,
    required this.callCtrl,
    required this.onChanged,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final hasResult =
        result.toCall > 0 && result.potBeforeCall >= result.toCall;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.goldPrimary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded,
                    size: 18, color: pt.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  'Live calculator',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumField(
                    label: 'Pot',
                    helper: 'Total chips you\'re calling into',
                    controller: potCtrl,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumField(
                    label: 'To call',
                    helper: 'Chips you need to add',
                    controller: callCtrl,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasResult)
              _ResultBlock(result: result)
            else
              Text(
                result.toCall <= 0
                    ? 'Enter a non-zero call to see your break-even equity.'
                    : 'Pot must be at least the call amount '
                        '(it already includes the bet you\'re calling).',
                style: textTheme.bodySmall?.copyWith(color: pt.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String helper;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NumField({
    required this.label,
    required this.helper,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: pt.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Allow only digits and a single decimal point.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text;
              if (text.isEmpty) return newValue;
              if ('.'.allMatches(text).length > 1) return oldValue;
              return newValue;
            }),
          ],
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: pt.surfaceDim,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: pt.borderSubtle.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: pt.goldPrimary),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          helper,
          style: textTheme.labelSmall?.copyWith(
            color: pt.textMuted.withValues(alpha: 0.7),
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final PotOdds result;

  const _ResultBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: _ResultStat(
            label: 'Need to win',
            value: result.equityPercentLabel,
            color: pt.profit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResultStat(
            label: 'Pot odds',
            value: result.ratioLabel,
            color: pt.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResultStat(
            label: 'Pot after call',
            value: (result.potBeforeCall + result.toCall).toStringAsFixed(0),
            color: pt.goldPrimary,
            valueStyle: textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextStyle? valueStyle;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: pt.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: pt.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: (valueStyle ?? textTheme.titleMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceTable extends StatelessWidget {
  const _ReferenceTable();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            color: pt.surfaceDim,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Bet sizing',
                      style: textTheme.labelSmall?.copyWith(
                          color: pt.textMuted, letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Need',
                      textAlign: TextAlign.end,
                      style: textTheme.labelSmall?.copyWith(
                          color: pt.textMuted, letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Ratio',
                      textAlign: TextAlign.end,
                      style: textTheme.labelSmall?.copyWith(
                          color: pt.textMuted, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          for (var i = 0; i < PotOddsReference.rows.length; i++) ...[
            if (i != 0) Divider(height: 1, color: pt.borderSubtle.withValues(alpha: 0.3)),
            _ReferenceRow(row: PotOddsReference.rows[i]),
          ],
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final PotOddsRow row;

  const _ReferenceRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  row.betLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.equityPercentLabel,
                  textAlign: TextAlign.end,
                  style: textTheme.titleSmall?.copyWith(
                    color: pt.profit,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.ratioLabel,
                  textAlign: TextAlign.end,
                  style: textTheme.titleSmall?.copyWith(
                    color: pt.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            row.scenarioHint,
            style: textTheme.bodySmall?.copyWith(
              color: pt.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleOfTwoFourCard extends StatelessWidget {
  const _RuleOfTwoFourCard();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: pt.seatActiveBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 18, color: pt.seatActiveBorder),
                const SizedBox(width: 8),
                Text(
                  'Rule of 2 and 4',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quick estimate: multiply your outs by 4 on the flop (two cards '
              'to come) or by 2 on the turn (one card to come). The result '
              'is your equity %.',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Example: 9 outs to a flush × 4 ≈ 36% equity on the flop.',
              style: textTheme.bodySmall?.copyWith(
                color: pt.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
