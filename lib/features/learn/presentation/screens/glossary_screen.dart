import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/trainer/domain/poker_glossary.dart';

/// Full-screen, searchable, filterable glossary.
///
/// Replaces the bottom-sheet-only experience for browsing — the sheet is
/// still used for in-context glossary lookups during a hand replay.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _activeCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GlossaryEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    return PokerGlossary.entries.where((e) {
      if (_activeCategory != null && e.category != _activeCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return e.term.toLowerCase().contains(q) ||
          e.abbreviation.toLowerCase().contains(q) ||
          e.definition.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glossary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/learn'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: Responsive.hPadding(context).add(
                const EdgeInsets.symmetric(vertical: 8),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search ${PokerGlossary.entries.length} terms…',
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: pt.textMuted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: pt.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: pt.surfaceDim,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: pt.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: pt.borderSubtle.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: pt.goldPrimary),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: Responsive.hPadding(context),
                children: [
                  _CategoryChip(
                    label: 'All',
                    color: pt.goldPrimary,
                    selected: _activeCategory == null,
                    onTap: () => setState(() => _activeCategory = null),
                  ),
                  for (final c in PokerGlossary.categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _CategoryChip(
                        label: c,
                        color: _categoryColor(pt, c),
                        selected: _activeCategory == c,
                        onTap: () => setState(() => _activeCategory =
                            _activeCategory == c ? null : c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? _EmptyResult(query: _query)
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: Responsive.hPadding(context).add(
                        const EdgeInsets.symmetric(vertical: 8),
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _EntryTile(entry: results[i], query: _query),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(PokerTheme pt, String category) {
  return switch (category) {
    PokerGlossary.categoryPositions => pt.positionBlinds,
    PokerGlossary.categoryBetting => pt.accentMuted,
    PokerGlossary.categoryConcepts => pt.positionLate,
    PokerGlossary.categoryHands => pt.straddlePrimary,
    PokerGlossary.categoryStreets => pt.seatActiveBorder,
    _ => pt.textMuted,
  };
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.7)
                  : color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: selected ? color : Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final GlossaryEntry entry;
  final String query;

  const _EntryTile({required this.entry, required this.query});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = _categoryColor(pt, entry.category);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.abbreviation,
                    style: textTheme.labelSmall?.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.term,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  entry.category,
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.definition,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String query;

  const _EmptyResult({required this.query});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: pt.textMuted),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'No entries match this filter.'
                  : 'No matches for “$query”.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: pt.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
