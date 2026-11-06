import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import '../services/admin_ai_service.dart';
import '../utils/tokens.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../viewmodels/shell_viewmodel.dart';
import '../widgets/admin_page.dart';
import '../widgets/message_box.dart';
import '../widgets/status_badge.dart';

/// "AI gợi ý câu hỏi tiếp theo": Gemini drafts a self-reflection question and a
/// message from aggregate numbers only. Its output is labelled and only fills
/// the announcement form, where staff edit it before anything is sent.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topic = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _suggest() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AiAssistantViewModel>().suggest(_topic.text);
  }

  void _useIdea(String idea) {
    _topic.text = idea;
    _suggest();
  }

  void _apply(AdminAiResult result) {
    context.read<AnnouncementsViewModel>().prefill(
      AnnouncementDraft(
        title: result.suggestion.suggestedTitle,
        body: result.suggestion.suggestedBody,
        source: result.fromAi
            ? 'AI gợi ý (${result.model})'
            : 'Câu mẫu của nhóm',
      ),
    );
    context.read<ShellViewModel>().goTo(AdminSection.announcements);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiAssistantViewModel>();
    final t = context.tokens;
    // A suggestion asked from another page (dashboard) fills the field too
    final asked = vm.lastTopic;
    if (asked != null && _topic.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _topic.text.isEmpty) _topic.text = asked;
      });
    }

    return AdminPage(
      title: 'Trợ lý AI',
      subtitle:
          'Gemini gợi ý câu hỏi tự vấn và lời nhắn cho người dùng. Chỉ gửi số liệu '
          'tổng hợp, không gửi tên, email hay UID của ai.',
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppDimens.space32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Wrap(
                spacing: AppDimens.space24,
                runSpacing: AppDimens.space16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StatusBadge(
                          label: 'GEMINI · FIREBASE AI LOGIC',
                          tone: BadgeTone.primary,
                          icon: Icons.auto_awesome,
                        ),
                        const SizedBox(height: AppDimens.space8),
                        Text(
                          'Câu hỏi tự vấn và thông điệp đồng cảm',
                          style: t.text(AppTextStyles.titleLarge),
                        ),
                        const SizedBox(height: AppDimens.space4),
                        Text(
                          'Theo triết lý Why I Buy: không phán xét hay ngăn cản, mà '
                          'đồng hành bằng những câu hỏi gợi mở trước khi mua.',
                          style: t.text(AppTextStyles.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: t.surfaceMuted,
                      borderRadius: AppDimens.borderMedium,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Mô hình',
                          style: t.text(AppTextStyles.labelMedium),
                        ),
                        Text(
                          vm.model,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Remote Config: ${AdminAiService.modelKey}',
                          style: t.text(AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          SectionCard(
            title: 'Tạo gợi ý theo chủ đề',
            icon: Icons.bolt_outlined,
            children: [
              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final field = AppTextField(
                      controller: _topic,
                      hint: 'Ví dụ: Giày thể thao hàng hiệu, Trà sữa mỗi ngày…',
                      validator: AiAssistantViewModel.validateTopic,
                    );
                    final button = AppButton(
                      title: 'Tạo Gợi Ý Thông Minh',
                      icon: Icons.auto_awesome,
                      width: 240,
                      isLoading: vm.isLoading,
                      onPressed: _suggest,
                    );
                    return c.maxWidth < 640
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              field,
                              const SizedBox(height: AppDimens.space12),
                              button,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: field),
                              const SizedBox(width: AppDimens.space12),
                              button,
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(height: AppDimens.space12),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  for (final idea in AiAssistantViewModel.topicIdeas)
                    ActionChip(
                      avatar: const Icon(Icons.lightbulb_outline, size: 18),
                      label: Text(idea),
                      onPressed: vm.isLoading ? null : () => _useIdea(idea),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          switch (vm.state) {
            UiSuccess<AdminAiResult>(:final data) => _ResultCard(
              result: data,
              onApply: () => _apply(data),
            ),
            UiLoading<AdminAiResult>() => const SizedBox(
              height: 160,
              child: LoadingView(message: 'Gemini đang viết…'),
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AdminAiResult result;
  final VoidCallback onApply;

  const _ResultCard({required this.result, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = result.suggestion;
    Widget block(String label, String text, {bool quote = false}) => Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.text(AppTextStyles.labelMedium)),
          const SizedBox(height: AppDimens.space4),
          Text(
            quote ? '"$text"' : text,
            style: t.text(
              quote ? AppTextStyles.titleMedium : AppTextStyles.bodyLarge,
            ),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(
                  label: result.fromAi
                      ? 'AI · ${result.model}'
                      : 'CÂU MẪU (AI KHÔNG DÙNG ĐƯỢC)',
                  tone: result.fromAi ? BadgeTone.primary : BadgeTone.neutral,
                  icon: result.fromAi ? Icons.auto_awesome : Icons.edit_note,
                ),
                StatusBadge(
                  label: s.category == 'dormant'
                      ? 'Người cài app chưa dùng'
                      : 'Mọi người dùng',
                ),
              ],
            ),
            if (result.fallbackReason != null) ...[
              const SizedBox(height: AppDimens.space12),
              MessageBox(message: result.fallbackReason!),
            ],
            const SizedBox(height: AppDimens.space16),
            block('Câu hỏi tự vấn', s.question, quote: true),
            block('Vì sao hỏi câu này', s.psychologyInsight),
            block('Tiêu đề thông báo', s.suggestedTitle),
            block('Nội dung thông báo', s.suggestedBody),
            const SizedBox(height: AppDimens.space4),
            const MessageBox(
              tone: MessageTone.warning,
              message:
                  'Đây là bản nháp. Bấm "Dùng cho thông báo" để điền vào form, '
                  'đọc và sửa tiêu đề, nội dung ở mục Thông báo rồi mới đăng.',
            ),
            const SizedBox(height: AppDimens.space16),
            AppButton(
              title: 'Dùng cho thông báo',
              icon: Icons.campaign_outlined,
              width: 240,
              onPressed: onApply,
            ),
          ],
        ),
      ),
    );
  }
}
