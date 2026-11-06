import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../models/item_suggestion.dart';
import '../models/pre_purchase_check.dart';
import '../models/pre_purchase_facts.dart';
import '../models/ui_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/pre_purchase_viewmodel.dart';
import '../viewmodels/purchase_viewmodel.dart';
import '../viewmodels/shopping_profile_viewmodel.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/insight_source_chip.dart';

/// Flow 9: screen 17 "AI đang phân tích" then screen 18 "Nhận định trước khi mua".
/// "Để mình nghĩ thêm" returns home without saving; "Vẫn mua" opens Flow 1 pre-filled.
class PrePurchaseResultScreen extends StatefulWidget {
  final PrePurchaseAnswers answers;

  const PrePurchaseResultScreen({super.key, required this.answers});

  @override
  State<PrePurchaseResultScreen> createState() =>
      _PrePurchaseResultScreenState();
}

class _PrePurchaseResultScreenState extends State<PrePurchaseResultScreen> {
  late final PrePurchaseViewModel _vm = context.read<PrePurchaseViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.analyze(widget.answers, facts: _collectFacts());
    });
  }

  /// Reads what the app already knows about the user. Each source is optional:
  /// a screen opened without it (tests) simply shows fewer facts.
  List<PrePurchaseFact> _collectFacts() {
    T? read<T>() {
      try {
        return context.read<T>();
      } on ProviderNotFoundException {
        return null;
      }
    }

    final answers = widget.answers;
    final now = DateTime.now();
    final budget = read<BudgetViewModel>();
    final groupId = guessBudgetGroup(answers.title);
    final group = groupId == null
        ? null
        : budget?.groups.where((g) => g.id == groupId).firstOrNull;
    // Limits and spending are those of the month shown on Home; use only this month
    final isThisMonth =
        budget != null &&
        budget.month.year == now.year &&
        budget.month.month == now.month;
    return PrePurchaseFacts.build(
      answers: answers,
      now: now,
      purchases: read<PurchaseViewModel>()?.allPurchases ?? const [],
      wishlist: read<WishlistViewModel>()?.allItems ?? const [],
      owned: read<ShoppingProfileViewModel>()?.ownedItems ?? const [],
      groupName: group?.name,
      available: group != null && isThisMonth
          ? budget.availableBreakdown(group.id)
          : null,
    );
  }

  @override
  void dispose() {
    _vm.reset();
    super.dispose();
  }

  void _thinkMore() => Navigator.popUntil(context, (route) => route.isFirst);

  void _buyAnyway() {
    final a = widget.answers;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.recordPurchase,
      (route) => route.isFirst,
      arguments: RecordPurchaseArgs(
        initialTitle: a.title,
        initialAmount: a.priceVnd,
        initialMotive: a.suggestedMotive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PrePurchaseViewModel>().state;
    final insight = state is UiSuccess<PrePurchaseInsight> ? state.data : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          insight == null ? 'AI đang phân tích' : 'Nhận định trước khi mua',
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: insight == null
              ? _Analyzing(answers: widget.answers)
              : _Result(
                  answers: widget.answers,
                  insight: insight,
                  onThinkMore: _thinkMore,
                  onBuyAnyway: _buyAnyway,
                ),
        ),
      ),
    );
  }
}

// ---------- Screen 17 ----------
class _Analyzing extends StatelessWidget {
  final PrePurchaseAnswers answers;

  const _Analyzing({required this.answers});

  @override
  Widget build(BuildContext context) {
    final looked = [
      answers.why.label,
      if (answers.influence != InfluenceAnswer.none) answers.influence.label,
    ].join(', ');
    final extra = answers.withoutSale == null
        ? ''
        : ' và câu trả lời "${answers.withoutSale!.label}"';
    return ListView(
      key: const ValueKey('pre-purchase-analyzing'),
      padding: const EdgeInsets.all(AppDimens.space24),
      children: [
        const SizedBox(height: AppDimens.space48),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space24),
        Text(
          'Đang xem kỹ hơn',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          'Đang nhìn lại $looked$extra.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppDimens.space24),
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.borderLarge,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [answers.title, ?answers.priceText].join(' · '),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppDimens.space12),
              const ClipRRect(
                borderRadius: AppDimens.borderPill,
                child: LinearProgressIndicator(minHeight: 6),
              ),
              const SizedBox(height: AppDimens.space12),
              Text(
                'Đang kết nối các câu trả lời của bạn...',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space24),
        Text(
          'Hiểu trước khi thay đổi.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

// ---------- Screen 18 ----------
class _Result extends StatelessWidget {
  final PrePurchaseAnswers answers;
  final PrePurchaseInsight insight;
  final VoidCallback onThinkMore;
  final VoidCallback onBuyAnyway;

  const _Result({
    required this.answers,
    required this.insight,
    required this.onThinkMore,
    required this.onBuyAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('pre-purchase-result'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.space16),
            children: [
              Text(
                'Rõ hơn một chút trước khi mua',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppDimens.space16),
              Text(answers.title, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppDimens.space4),
              Text(
                [
                  ?answers.priceText,
                  'Dựa trên câu trả lời của bạn',
                ].join(' · '),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space16),
              for (final o in insight.observations) ...[
                _ObservationCard(observation: o),
                const SizedBox(height: AppDimens.space12),
              ],
              if (insight.facts.isNotEmpty) ...[
                const SizedBox(height: AppDimens.space12),
                _FactsPanel(facts: insight.facts),
                const SizedBox(height: AppDimens.space16),
              ],
              const SizedBox(height: AppDimens.space4),
              Text(
                '${insight.summary} Đây là gợi ý từ điều bạn chia sẻ, không phải '
                'dự đoán việc bạn sẽ làm.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Align(
                alignment: Alignment.centerLeft,
                child: InsightSourceChip(fromAi: insight.usesAi),
              ),
              const SizedBox(height: AppDimens.space24),
              Text('Gợi mở', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppDimens.space8),
              Text(
                insight.question,
                key: const ValueKey('pre-purchase-question'),
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppDimens.space24),
              Text(
                'Không có lựa chọn đúng hay sai. Quyết định là của bạn.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space16,
          ),
          child: Column(
            children: [
              AppButton(
                key: const ValueKey('pre-purchase-think-more'),
                title: 'Để mình nghĩ thêm',
                onPressed: onThinkMore,
              ),
              const SizedBox(height: AppDimens.space8),
              AppButton(
                key: const ValueKey('pre-purchase-buy-anyway'),
                title: 'Vẫn mua',
                variant: AppButtonVariant.secondary,
                onPressed: onBuyAnyway,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Từ dữ liệu của bạn": facts read from the user's own records
class _FactsPanel extends StatelessWidget {
  final List<PrePurchaseFact> facts;

  const _FactsPanel({required this.facts});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('pre-purchase-facts'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppDimens.borderLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Từ dữ liệu của bạn', style: AppTextStyles.titleMedium),
          for (final f in facts) ...[
            const SizedBox(height: AppDimens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(f.icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Text(
                    f.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final PrePurchaseObservation observation;

  const _ObservationCard({required this.observation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppDimens.borderMedium,
            ),
            child: Icon(observation.icon, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: AppDimens.space4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppDimens.borderPill,
                  ),
                  child: Text(observation.chip, style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
