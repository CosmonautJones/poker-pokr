/// Metadata for a single branch/line in a hand replay.
class BranchInfo {
  final String label; // "Line A", "Line B", etc.
  final int? dbHandId; // null if unsaved
  final int forkAtActionIndex; // 0 for the original line

  const BranchInfo({
    required this.label,
    this.dbHandId,
    this.forkAtActionIndex = 0,
  });

  BranchInfo copyWith({
    String? label,
    int? Function()? dbHandId,
    int? forkAtActionIndex,
  }) {
    return BranchInfo(
      label: label ?? this.label,
      dbHandId: dbHandId != null ? dbHandId() : this.dbHandId,
      forkAtActionIndex: forkAtActionIndex ?? this.forkAtActionIndex,
    );
  }
}
