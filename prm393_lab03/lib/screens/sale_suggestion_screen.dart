import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart'
    show SaleSuggestion, SuggestionStatus;

import '../core/formatters/date_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/sale_suggestion_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/states/ui_state_builder.dart';
import '../widgets/why_i_buy_logo.dart';

/// "Báo đợt sale" (cross-role flow): report a sale a marketplace has announced,
/// and follow what happened to each report
class SaleSuggestionScreen extends StatefulWidget {
  const SaleSuggestionScreen({super.key});

  @override
  State<SaleSuggestionScreen> createState() => _SaleSuggestionScreenState();
}

class _SaleSuggestionScreenState extends State<SaleSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _source = TextEditingController();
  DateTime? _date;
  String? _dateError;

  @override
  void dispose() {
    _name.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _pickDate(SaleSuggestionViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? vm.today,
      firstDate: vm.today,
      lastDate: vm.lastDay,
      helpText: 'Ngày diễn ra đợt sale',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateError = vm.validateDate(picked);
    });
  }

  Future<void> _submit(SaleSuggestionViewModel vm) async {
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _dateError = vm.validateDate(_date));
    if (!formOk || _dateError != null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.submit(
      name: _name.text,
      date: _date,
      source: _source.text,
    );
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.actionError ?? 'Chưa gửi được. Vui lòng thử lại.'),
        ),
      );
      return;
    }
    _formKey.currentState?.reset();
    _name.clear();
    _source.clear();
    setState(() => _date = null);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Đã gửi. Nhóm sẽ kiểm tra nguồn và trả lời trong Hộp thư của bạn.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SaleSuggestionViewModel>();
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: AppDimens.minTouchTarget,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const WhyIBuyLogo(size: 26, color: AppColors.onPrimary),
            const SizedBox(width: AppDimens.space4),
            Expanded(
              child: Text(
                'Báo đợt sale',
                style: AppTextStyles.titleLarge.withInheritedColor.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            'Sàn (Shopee, Lazada…) đã công bố một đợt sale mà Lịch sale chưa có? '
            'Báo cho nhóm kèm nơi công bố. Nhóm kiểm tra nguồn; đợt được duyệt sẽ '
            'hiện trong Lịch sale của mọi người và bạn nhận câu trả lời trong Hộp thư.',
            style: AppTextStyles.bodyMedium.themed(context),
          ),
          const SizedBox(height: AppDimens.space16),
          if (!vm.canSuggest)
            Container(
              key: const ValueKey('sale-suggestion-guest'),
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: semantic.mutedSurface,
                borderRadius: AppDimens.borderMedium,
              ),
              child: Text(
                'Cần đăng nhập bằng tài khoản Google để báo đợt sale. Chế độ khách '
                'chỉ xem được Lịch sale.',
                style: AppTextStyles.bodyMedium.themed(context),
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    key: const ValueKey('sale-suggestion-name'),
                    label: 'Tên đợt sale',
                    hint: 'Ví dụ: 12.12 Sale sinh nhật',
                    controller: _name,
                    validator: SaleSuggestionViewModel.validateName,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  OutlinedButton.icon(
                    key: const ValueKey('sale-suggestion-date'),
                    onPressed: () => _pickDate(vm),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _date == null
                          ? 'Chọn ngày diễn ra'
                          : 'Ngày: ${formatWeekdayDate(_date!)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  if (_dateError != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppDimens.space4,
                        left: AppDimens.space12,
                      ),
                      child: Text(
                        _dateError!,
                        style: AppTextStyles.labelMedium
                            .themed(context)
                            .copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppDimens.space12),
                  AppTextField(
                    key: const ValueKey('sale-suggestion-source'),
                    label: 'Nơi sàn công bố',
                    hint: 'Link bài đăng, hoặc "banner trên app Shopee"',
                    controller: _source,
                    maxLines: 2,
                    validator: SaleSuggestionViewModel.validateSource,
                  ),
                  const SizedBox(height: AppDimens.space16),
                  AppButton(
                    title: 'Gửi cho nhóm kiểm tra',
                    icon: Icons.send_outlined,
                    isLoading: vm.isSubmitting,
                    onPressed: () => _submit(vm),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppDimens.space24),
          Text(
            'Đợt sale bạn đã báo',
            style: AppTextStyles.titleLarge.themed(context),
          ),
          const SizedBox(height: AppDimens.space8),
          if (vm.canSuggest)
            UiStateBuilder<List<SaleSuggestion>>(
              state: vm.mine,
              loadingMessage: 'Đang tải...',
              emptyIcon: Icons.campaign_outlined,
              builder: (context, list) =>
                  Column(children: [for (final s in list) _SuggestionTile(s)]),
            )
          else
            Text(
              'Đăng nhập để xem các đợt bạn đã báo.',
              style: AppTextStyles.bodyMedium.themed(context),
            ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final SaleSuggestion suggestion;

  const _SuggestionTile(this.suggestion);

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final s = suggestion;
    final (icon, color) = switch (s.status) {
      SuggestionStatus.pending => (
        Icons.hourglass_top_rounded,
        semantic.subtleText,
      ),
      SuggestionStatus.approved => (
        Icons.check_circle_outline,
        semantic.emphasis,
      ),
      SuggestionStatus.rejected => (Icons.info_outline, semantic.subtleText),
    };
    return Card(
      key: ValueKey('sale-suggestion-${s.id}'),
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      child: ListTile(
        minTileHeight: AppDimens.minTouchTarget,
        leading: Icon(icon, color: color),
        title: Text(s.name, style: AppTextStyles.titleMedium.themed(context)),
        subtitle: Text(
          [
            '${formatWeekdayDate(s.date)} · ${s.status.label}',
            if (s.status == SuggestionStatus.rejected && s.reason != null)
              'Lý do: ${s.reason}',
            if (s.status == SuggestionStatus.approved) 'Đã có trong Lịch sale.',
          ].join('\n'),
          style: AppTextStyles.bodyMedium.themed(context),
        ),
        isThreeLine: s.status != SuggestionStatus.pending,
      ),
    );
  }
}
