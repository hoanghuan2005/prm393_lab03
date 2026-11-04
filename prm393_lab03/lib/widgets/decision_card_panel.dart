import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/decision_rules.dart';
import '../models/wishlist_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/decision_support_viewmodel.dart';
import 'insight_source_chip.dart';

/// Label, reason and signals of the Decision Card (spec 7.3, 7.4, screen 20).
/// Neutral colours on purpose: the label is an observation, not advice, and the three
/// decision buttons below it stay equally prominent.
class DecisionCardPanel extends StatefulWidget {
  final WishlistItem item;

  /// Label 5: mark the item as (not) a duplicate of something owned or bought
  final ValueChanged<bool>? onSetDuplicate;

  const DecisionCardPanel({super.key, required this.item, this.onSetDuplicate});

  @override
  State<DecisionCardPanel> createState() => _DecisionCardPanelState();
}

class _DecisionCardPanelState extends State<DecisionCardPanel> {
  String? _reasonKey;
  DecisionReason? _reason;

  @override
  void initState() {
    super.initState();
    _loadSavedPrice();
  }

  @override
  void didUpdateWidget(covariant DecisionCardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.latestPriceAt != widget.item.latestPriceAt) {
      _loadSavedPrice();
    }
  }

  void _loadSavedPrice() {
    final vm = context.read<DecisionSupportViewModel?>();
    if (vm != null) vm.loadPriceHistory(widget.item);
  }

  /// A new assessment (price, budget, sale changed) asks for a new sentence
  void _requestReason(DecisionSupportViewModel vm, DecisionAssessment a) {
    final key = a.cacheKey;
    if (key == _reasonKey) return;
    _reasonKey = key;
    _reason = null;
    vm.reasonFor(a).then((reason) {
      if (!mounted || _reasonKey != key) return;
      setState(() => _reason = reason);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DecisionSupportViewModel?>();
    if (vm == null) return const SizedBox.shrink();
    final assessment = vm.assess(widget.item);
    _requestReason(vm, assessment);
    final reason =
        _reason ?? DecisionReason(assessment.templateReason, fromAi: false);
    final sale = assessment.input.upcomingSale;

    return Container(
      key: const ValueKey('decision-card'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderMedium,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Nhận định', style: AppTextStyles.labelLarge),
              ),
              Container(
                key: const ValueKey('decision-label'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space12,
                  vertical: AppDimens.space4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppDimens.borderPill,
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  assessment.label.text,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          Semantics(
            liveRegion: true,
            child: Text(reason.text, style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: AppDimens.space4),
          InsightSourceChip(fromAi: reason.fromAi),
          if (assessment.signals.isNotEmpty) ...[
            const Divider(height: AppDimens.space24),
            for (final signal in assessment.signals)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.space4),
                child: Text('• $signal', style: AppTextStyles.bodyMedium),
              ),
          ],
          Wrap(
            spacing: AppDimens.space8,
            children: [
              // A-15
              if (assessment.input.sameGroupCount > 0)
                TextButton.icon(
                  key: const ValueKey('compare-same-group'),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.wishlistCompare,
                    arguments: ItemDetailArgs(widget.item),
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: Text(
                    'So sánh ${assessment.input.sameGroupCount + 1} món cùng nhóm',
                  ),
                ),
              // S5 + label 5: confirm or undo "trùng với đồ đang có"
              if (widget.onSetDuplicate case final setDuplicate?)
                if (widget.item.confirmedDuplicate)
                  TextButton.icon(
                    onPressed: () => setDuplicate(false),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Bỏ đánh dấu trùng'),
                  )
                else if (assessment.input.ownedMatches.isNotEmpty)
                  TextButton.icon(
                    key: const ValueKey('confirm-owned-duplicate'),
                    onPressed: () => setDuplicate(true),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Trùng với đồ đang có'),
                  ),
              if (sale != null)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.saleList,
                    arguments: SaleArgs(sale),
                  ),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text('Danh sách cho ${sale.name}'),
                ),
              if (assessment.input.available == null &&
                  widget.item.budgetGroupId != null)
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.budget),
                  icon: const Icon(Icons.pie_chart_outline, size: 18),
                  label: const Text('Đặt hạn mức nhóm'),
                ),
              if (widget.item.budgetGroupId == null)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.wishlistEdit,
                    arguments: ItemDetailArgs(widget.item),
                  ),
                  icon: const Icon(Icons.category_outlined, size: 18),
                  label: const Text('Chọn nhóm ngân sách'),
                ),
            ],
          ),
          Text(
            'Nhãn chỉ là quan sát từ số liệu; quyết định vẫn là của bạn.',
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
