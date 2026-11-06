import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../core/formatters/money_format.dart';
import '../core/validators/validators.dart';
import '../models/pre_purchase_check.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/amount_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// Steps of "Trước khi mua"; [sale] only after "Khuyến mãi"
enum _Step { item, motive, sale, usage }

/// Flow 9 "Trước khi mua", screens 14–16 plus the "cách dùng" step added after
/// testing: quick questions about an item the user is weighing. Nothing is saved;
/// "Xem nhận định" opens screen 17/18.
class PrePurchaseScreen extends StatefulWidget {
  const PrePurchaseScreen({super.key});

  @override
  State<PrePurchaseScreen> createState() => _PrePurchaseScreenState();
}

class _PrePurchaseScreenState extends State<PrePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();

  _Step _step = _Step.item;
  WhyAnswer? _why;
  InfluenceAnswer? _influence;
  WithoutSaleAnswer? _withoutSale;
  UsageAnswer? _usage;
  SimilarOwnedAnswer? _similar;
  MoodAnswer? _mood;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// 3 steps, or 4 once "Khuyến mãi" is chosen
  List<_Step> get _steps => [
    _Step.item,
    _Step.motive,
    if (PrePurchaseAnswers.asksAboutSale(_influence)) _Step.sale,
    _Step.usage,
  ];

  int get _stepNumber => _steps.indexOf(_step) + 1;
  bool get _isLast => _step == _steps.last;

  String get _title => _titleController.text.trim();
  int? get _price {
    final value = parseVnd(_priceController.text);
    return value == null || value <= 0 ? null : value;
  }

  /// "Tai nghe Bluetooth · 389.000 ₫"
  String get _itemLine =>
      _price == null ? _title : '$_title · ${formatVnd(_price!)}';

  void _back() {
    final index = _steps.indexOf(_step);
    if (index > 0) {
      setState(() => _step = _steps[index - 1]);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _next() {
    if (_step == _Step.item) {
      if (_formKey.currentState?.validate() != true) return;
      FocusScope.of(context).unfocus();
    }
    if (_isLast) {
      _showResult();
    } else {
      setState(() => _step = _steps[_steps.indexOf(_step) + 1]);
    }
  }

  void _showResult() {
    Navigator.pushNamed(
      context,
      AppRoutes.prePurchaseResult,
      arguments: PrePurchaseArgs(
        PrePurchaseAnswers(
          title: _title,
          priceVnd: _price,
          why: _why!,
          influence: _influence!,
          withoutSale: _withoutSale,
          usage: _usage!,
          similar: _similar!,
          mood: _mood,
        ),
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    _Step.item => true,
    _Step.motive => _why != null && _influence != null,
    _Step.sale => _withoutSale != null,
    _Step.usage =>
      _usage != null &&
          _similar != null &&
          (!PrePurchaseAnswers.asksMood(_why) || _mood != null),
  };

  @override
  Widget build(BuildContext context) {
    final (appBarTitle, heading) = switch (_step) {
      _Step.item => ('Trước khi mua', 'Bạn đang cân nhắc món gì?'),
      _Step.motive => ('Câu hỏi nhanh', 'Điều gì đứng sau lựa chọn?'),
      _Step.sale => ('Câu hỏi về khuyến mãi', 'Thử bỏ qua ưu đãi'),
      _Step.usage => ('Câu hỏi nhanh', 'Bạn sẽ dùng nó ra sao?'),
    };
    return PopScope(
      canPop: _step == _Step.item,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Quay lại',
            onPressed: _back,
          ),
          title: Text(appBarTitle),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StepHeader(
                        step: _stepNumber,
                        total: _steps.length,
                        heading: heading,
                      ),
                      const SizedBox(height: AppDimens.space16),
                      switch (_step) {
                        _Step.item => _buildItemStep(),
                        _Step.motive => _buildMotiveStep(),
                        _Step.sale => _buildSaleStep(),
                        _Step.usage => _buildUsageStep(),
                      },
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.space16,
                  AppDimens.space8,
                  AppDimens.space16,
                  AppDimens.space16,
                ),
                child: AppButton(
                  key: const ValueKey('pre-purchase-next'),
                  title: _isLast ? 'Xem nhận định' : 'Tiếp tục',
                  onPressed: _canContinue ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Screen 14 ----------
  Widget _buildItemStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bắt đầu với món bạn đang cân nhắc. Bước này không ghi khoản mua.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          _Panel(
            child: Column(
              children: [
                AppTextField(
                  key: const ValueKey('pre-purchase-title'),
                  label: 'Tên món',
                  hint: 'Ví dụ: Tai nghe Bluetooth',
                  controller: _titleController,
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: Validators.validateTitle,
                ),
                const SizedBox(height: AppDimens.space16),
                AmountField(
                  key: const ValueKey('pre-purchase-price'),
                  label: 'Giá dự kiến (không bắt buộc)',
                  hint: 'Để trống nếu chưa biết giá',
                  controller: _priceController,
                  optional: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space24),
          Text('Một chút để hiểu mình', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Tiếp theo, bạn sẽ xem vì sao mình muốn món này, điều gì thu hút bạn '
            'và bạn sẽ dùng nó ra sao. App cũng đối chiếu với dữ liệu bạn đã '
            'ghi. Không có câu trả lời đúng hay sai.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            'AI chỉ gợi ý để nhìn lại. Quyết định vẫn là của bạn.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // ---------- Screen 15 ----------
  Widget _buildMotiveStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_itemLine, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimens.space16),
        const _Question(
          title: 'Vì sao bạn muốn món này?',
          hint: 'Chọn động cơ gần nhất với cảm nhận của bạn.',
        ),
        _OptionGrid(
          options: [
            for (final a in WhyAnswer.values)
              _Option(
                key: ValueKey('why-${a.name}'),
                label: a.label,
                icon: a.icon,
                selected: _why == a,
                onTap: () => setState(() {
                  _why = a;
                  if (!PrePurchaseAnswers.asksMood(a)) _mood = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.space24),
        const _Question(
          title: 'Điều gì tác động đến lần mua này?',
          hint: 'Chọn tác động rõ nhất.',
        ),
        _OptionGrid(
          options: [
            for (final a in InfluenceAnswer.values)
              _Option(
                key: ValueKey('influence-${a.name}'),
                label: a.label,
                icon: a.icon,
                selected: _influence == a,
                onTap: () => setState(() {
                  _influence = a;
                  if (!PrePurchaseAnswers.asksAboutSale(a)) _withoutSale = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        Text(
          'Không có câu trả lời đúng hay sai.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // ---------- Screen 16 (only after "Khuyến mãi") ----------
  Widget _buildSaleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppDimens.space4),
              Text(
                [
                  if (_price != null) formatVnd(_price!),
                  '${_why?.label} + ${_influence?.label}',
                ].join(' · '),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space24),
        const _Question(
          title: 'Không có khuyến mãi, bạn vẫn muốn món này chứ?',
          hint: 'Hãy nghĩ về món đó, tách khỏi ưu đãi.',
        ),
        _OptionList(
          options: [
            for (final a in WithoutSaleAnswer.values)
              _Option(
                key: ValueKey('without-sale-${a.name}'),
                label: a.label,
                icon: a.icon,
                selected: _withoutSale == a,
                onTap: () => setState(() => _withoutSale = a),
              ),
          ],
        ),
        Text(
          'Chưa chắc cũng không sao. Câu trả lời giúp gợi ý sát hơn.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // ---------- Added after testing: how the item would be used ----------
  Widget _buildUsageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_itemLine, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimens.space16),
        const _Question(
          title: 'Bạn sẽ dùng món này thường xuyên thế nào?',
          hint: 'Hình dung một tuần bình thường của bạn.',
        ),
        _OptionGrid(
          options: [
            for (final a in UsageAnswer.values)
              _Option(
                key: ValueKey('usage-${a.name}'),
                label: a.label,
                icon: a.icon,
                selected: _usage == a,
                onTap: () => setState(() => _usage = a),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.space24),
        const _Question(
          title: 'Bạn đã có món nào làm được việc tương tự chưa?',
          hint: 'Kể cả món không giống hệt nhưng dùng được cho cùng việc.',
        ),
        _OptionList(
          options: [
            for (final a in SimilarOwnedAnswer.values)
              _Option(
                key: ValueKey('similar-${a.name}'),
                label: a.label,
                icon: a.icon,
                selected: _similar == a,
                onTap: () => setState(() => _similar = a),
              ),
          ],
        ),
        if (PrePurchaseAnswers.asksMood(_why)) ...[
          const SizedBox(height: AppDimens.space12),
          const _Question(
            title: 'Lúc này bạn đang cảm thấy thế nào?',
            hint: 'Bạn chọn Cảm xúc, nên tâm trạng lúc này cũng đáng để ý.',
          ),
          _OptionGrid(
            options: [
              for (final a in MoodAnswer.values)
                _Option(
                  key: ValueKey('mood-${a.name}'),
                  label: a.label,
                  icon: a.icon,
                  selected: _mood == a,
                  onTap: () => setState(() => _mood = a),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
        ],
        Text(
          'Không có câu trả lời đúng hay sai.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// One option per row
class _OptionList extends StatelessWidget {
  final List<Widget> options;

  const _OptionList({required this.options});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          SizedBox(width: double.infinity, child: option),
          const SizedBox(height: AppDimens.space12),
        ],
      ],
    );
  }
}

/// "BƯỚC 2/3", heading and progress dots
class _StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String heading;

  const _StepHeader({
    required this.step,
    required this.total,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BƯỚC $step/$total',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accentNeutral,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(heading, style: AppTextStyles.headlineMedium),
            ],
          ),
        ),
        Semantics(
          label: 'Bước $step trên $total',
          child: Row(
            children: [
              for (var i = 1; i <= total; i++)
                Container(
                  margin: const EdgeInsets.only(left: AppDimens.space4),
                  width: i == step ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.divider,
                    borderRadius: AppDimens.borderPill,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  final String title;
  final String hint;

  const _Question({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimens.space4),
          Text(hint, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

/// Two columns of equal options
class _OptionGrid extends StatelessWidget {
  final List<Widget> options;

  const _OptionGrid({required this.options});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppDimens.space12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: options[i]),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: i + 1 < options.length
                      ? options[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Selectable card: icon, label, check mark when chosen
class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderLarge,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppDimens.borderLarge,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
