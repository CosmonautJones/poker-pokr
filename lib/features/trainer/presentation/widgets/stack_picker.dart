import 'package:flutter/material.dart';

/// A bottom sheet that lets the user pick a chip stack amount by scrolling.
class StackPickerBottomSheet extends StatefulWidget {
  final double currentStack;
  final double bigBlind;

  const StackPickerBottomSheet({
    super.key,
    required this.currentStack,
    required this.bigBlind,
  });

  static Future<double?> show(
    BuildContext context, {
    required double currentStack,
    required double bigBlind,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StackPickerBottomSheet(
        currentStack: currentStack,
        bigBlind: bigBlind,
      ),
    );
  }

  @override
  State<StackPickerBottomSheet> createState() => _StackPickerBottomSheetState();
}

class _StackPickerBottomSheetState extends State<StackPickerBottomSheet> {
  late final List<double> _amounts;
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _amounts = _buildAmounts(widget.bigBlind);
    // Find the closest index to the current stack.
    _selectedIndex = _findClosestIndex(widget.currentStack);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  List<double> _buildAmounts(double bb) {
    // Common BB multiples: 20, 30, 40, 50, 60, 80, 100, 150, 200, 250, 300, 500
    final multipliers = [
      10, 15, 20, 25, 30, 40, 50, 60, 75, 80, 100,
      125, 150, 175, 200, 250, 300, 400, 500, 750, 1000,
    ];
    return multipliers.map((m) => bb * m).toList();
  }

  int _findClosestIndex(double target) {
    int closest = 0;
    double minDiff = (target - _amounts[0]).abs();
    for (int i = 1; i < _amounts.length; i++) {
      final diff = (target - _amounts[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  String _formatAmount(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  String _formatBBs(double v) {
    final bbs = v / widget.bigBlind;
    if (bbs == bbs.roundToDouble()) return '${bbs.toStringAsFixed(0)} BB';
    return '${bbs.toStringAsFixed(1)} BB';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set Stack',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Current selection display
            Text(
              _formatBBs(_amounts[_selectedIndex]),
              style: TextStyle(
                color: Colors.amber.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            // Scroll wheel
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal:
                              BorderSide(color: Colors.grey.shade700, width: 1),
                        ),
                      ),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: 44,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _amounts.length,
                      builder: (context, index) {
                        final isSelected = index == _selectedIndex;
                        return Center(
                          child: Text(
                            _formatAmount(_amounts[index]),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Preset chips row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [50, 100, 200, 300, 500]
                    .map((mult) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text('${mult}BB'),
                            labelStyle:
                                const TextStyle(fontSize: 12),
                            onPressed: () {
                              final target = widget.bigBlind * mult;
                              final idx = _findClosestIndex(target);
                              _controller.animateToItem(
                                idx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Confirm / Cancel
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                      side: BorderSide(color: Colors.grey.shade700),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _amounts[_selectedIndex]),
                    child: const Text('Set'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
