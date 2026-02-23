/// Side-pot representation for split-pot / all-in scenarios.
///
/// Pure Dart - no Flutter imports.
library;

class SidePot {
  final double amount;
  final List<int> eligiblePlayerIndices;

  const SidePot({
    required this.amount,
    required this.eligiblePlayerIndices,
  });

  SidePot copyWith({
    double? amount,
    List<int>? eligiblePlayerIndices,
  }) {
    return SidePot(
      amount: amount ?? this.amount,
      eligiblePlayerIndices:
          eligiblePlayerIndices ?? this.eligiblePlayerIndices,
    );
  }

  @override
  String toString() =>
      'SidePot(amount: $amount, eligible: $eligiblePlayerIndices)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SidePot &&
          other.amount == amount &&
          _listEquals(other.eligiblePlayerIndices, eligiblePlayerIndices));

  @override
  int get hashCode => Object.hash(amount, Object.hashAll(eligiblePlayerIndices));

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
