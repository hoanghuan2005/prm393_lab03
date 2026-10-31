import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/date_format.dart';
import '../core/formatters/money_format.dart';
import '../models/budget_group.dart';
import '../models/item_suggestion.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/item_suggestion_viewmodel.dart';
import 'insight_source_chip.dart';

/// Waits for typing to pause, then asks [ItemSuggestionViewModel]. Shows nothing when
/// the view model is not provided (e.g. widget tests of other flows).
abstract class _DebouncedState<W extends StatefulWidget, R> extends State<W> {
  static const Duration debounce = Duration(milliseconds: 600);

  Timer? _timer;
  int _request = 0;
  R? result;

  /// The item title the suggestion is about
  String titleOf(W widget);

  /// Everything that, when changed, needs a new answer
  String keyOf(W widget) => titleOf(widget);

  Future<R> load(ItemSuggestionViewModel vm);

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (keyOf(oldWidget) != keyOf(widget)) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _request++;
    if (context.read<ItemSuggestionViewModel?>() == null) return;
    // Called from initState/didUpdateWidget, so the next build already shows this
    if (normalizeTitle(titleOf(widget)).length < 2) {
      result = null;
      return;
    }
    _timer = Timer(debounce, _run);
  }

  Future<void> _run() async {
    final vm = context.read<ItemSuggestionViewModel?>();
    if (vm == null) return;
    final request = _request;
    final value = await load(vm);
    if (!mounted || request != _request) return;
    setState(() => result = value);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// "Gợi ý nhóm: Công nghệ" under a budget group field (spec AI feature 3).
/// Only a suggestion: the field changes when the user taps it.
class BudgetGroupSuggestion extends StatefulWidget {
  final String title;
  final List<BudgetGroup> groups;
  final String? selectedGroupId;
  final bool enabled;
  final ValueChanged<String> onApply;

  const BudgetGroupSuggestion({
    super.key,
    required this.title,
    required this.groups,
    required this.selectedGroupId,
    required this.onApply,
    this.enabled = true,
  });

  @override
  State<BudgetGroupSuggestion> createState() => _BudgetGroupSuggestionState();
}

class _BudgetGroupSuggestionState
    extends _DebouncedState<BudgetGroupSuggestion, GroupSuggestion?> {
  @override
  String titleOf(BudgetGroupSuggestion widget) => widget.title;

  @override
  Future<GroupSuggestion?> load(ItemSuggestionViewModel vm) =>
      vm.suggestGroup(widget.title, widget.groups);

  @override
  Widget build(BuildContext context) {
    final suggestion = result;
    if (suggestion == null || suggestion.groupId == widget.selectedGroupId) {
      return const SizedBox.shrink();
    }
    final group = widget.groups
        .where((g) => g.id == suggestion.groupId)
        .firstOrNull;
    if (group == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space8),
      child: Wrap(
        spacing: AppDimens.space8,
        runSpacing: AppDimens.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ActionChip(
            key: const ValueKey('budget-group-suggestion'),
            avatar: const Icon(Icons.lightbulb_outline_rounded, size: 18),
            label: Text('Gợi ý nhóm: ${group.name}'),
            tooltip: 'Chạm để chọn nhóm này',
            onPressed: widget.enabled
                ? () => widget.onApply(suggestion.groupId)
                : null,
          ),
          if (suggestion.fromAi) const InsightSourceChip(fromAi: true),
        ],
      ),
    );
  }
}

/// Things already bought (30 days) or being considered that look like the same kind of
/// item (spec AI feature 4). Information only: it never blocks or recommends a decision.
class DuplicateHint extends StatefulWidget {
  final String title;
  final String? excludeItemId;
  final String? budgetGroupId;

  const DuplicateHint({
    super.key,
    required this.title,
    this.excludeItemId,
    this.budgetGroupId,
  });

  @override
  State<DuplicateHint> createState() => _DuplicateHintState();
}

class _DuplicateHintState
    extends _DebouncedState<DuplicateHint, List<DuplicateMatch>> {
  @override
  String titleOf(DuplicateHint widget) => widget.title;

  @override
  String keyOf(DuplicateHint widget) =>
      '${widget.title}|${widget.budgetGroupId}';

  @override
  Future<List<DuplicateMatch>> load(ItemSuggestionViewModel vm) =>
      vm.findDuplicates(
        widget.title,
        excludeItemId: widget.excludeItemId,
        budgetGroupId: widget.budgetGroupId,
      );

  static String _detail(DuplicateCandidate c) =>
      c.source == DuplicateSource.purchase
      ? 'đã mua ${formatDate(c.date)} · ${formatVnd(c.amountVnd)}'
      // An unknown price is left out, never shown as 0 ₫
      : c.amountVnd == null
      ? 'đang cân nhắc'
      : 'đang cân nhắc · ${formatVnd(c.amountVnd)}';

  @override
  Widget build(BuildContext context) {
    final matches = result;
    if (matches == null || matches.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const ValueKey('duplicate-hint'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppDimens.space16),
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppDimens.borderMedium,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    'Bạn đã có món tương tự',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
                if (matches.any((m) => m.fromAi))
                  const InsightSourceChip(fromAi: true),
              ],
            ),
            const SizedBox(height: AppDimens.space8),
            for (final m in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space4),
                child: Text(
                  '• ${m.candidate.title} · ${_detail(m.candidate)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            const SizedBox(height: AppDimens.space4),
            Text(
              'Thông tin để bạn đối chiếu, không ảnh hưởng tới lựa chọn.',
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
