import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/why_i_buy_logo.dart';

/// Screen 05a "Xin quyền thông báo": offered once, after the first saved purchase
/// (Figma Flow 1). Both buttons go back; the system permission dialog is only shown
/// after "Bật nhắc nhở".
class ReminderPermissionScreen extends StatefulWidget {
  const ReminderPermissionScreen({super.key});

  @override
  State<ReminderPermissionScreen> createState() =>
      _ReminderPermissionScreenState();
}

class _ReminderPermissionScreenState extends State<ReminderPermissionScreen> {
  bool _isEnabling = false;

  @override
  void initState() {
    super.initState();
    // Shown once per device, whichever button is chosen (or back)
    context.read<SettingsViewModel>().markDailyReminderOffered();
  }

  Future<void> _enable() async {
    final vm = context.read<SettingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isEnabling = true);
    final ok = await vm.enableDailyReminder();
    if (!mounted) return;
    setState(() => _isEnabling = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã bật nhắc ghi khoản mua lúc ${vm.dailyReminderTimeText} mỗi tối.'
              : 'Chưa được phép gửi thông báo. Bạn có thể bật lại trong Cá nhân '
                    'hoặc cài đặt của máy.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final time = context.select<SettingsViewModel, String>(
      (vm) => vm.dailyReminderTimeText,
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.space24,
            AppDimens.space48,
            AppDimens.space24,
            AppDimens.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppSemanticColors.of(context).primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: AppSemanticColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.space24),
              Text(
                'Để Why I Buy? nhắc bạn mỗi tối?',
                style: AppTextStyles.displayMedium.themed(context),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                'Một lời nhắc lúc $time giúp bạn ghi lại khoản mua trong ngày '
                'khi còn nhớ rõ lý do.',
                style: AppTextStyles.bodyLarge
                    .themed(context)
                    .copyWith(
                      color: AppSemanticColors.of(context).textSecondary,
                    ),
              ),
              const SizedBox(height: AppDimens.space16),
              _NotificationPreview(time: time),
              const SizedBox(height: AppDimens.space24),
              AppButton(
                key: const ValueKey('enable-daily-reminder'),
                title: 'Bật nhắc nhở',
                icon: Icons.notifications_none_rounded,
                isLoading: _isEnabling,
                onPressed: _isEnabling ? null : _enable,
              ),
              const SizedBox(height: AppDimens.space8),
              Center(
                child: TextButton(
                  onPressed: _isEnabling
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Để sau'),
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Center(
                child: Text(
                  'Bạn có thể đổi giờ nhắc trong Cá nhân.',
                  style: AppTextStyles.caption.themed(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sample of the notification the user will get
class _NotificationPreview extends StatelessWidget {
  final String time;

  const _NotificationPreview({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppSemanticColors.of(context).cardSurface,
        borderRadius: AppDimens.borderLarge,
        border: Border.all(color: AppSemanticColors.of(context).divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppDimens.borderSmall,
            ),
            alignment: Alignment.center,
            child: const WhyIBuyLogo(size: 22),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why I Buy? · $time',
                  style: AppTextStyles.caption.themed(context),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  'Hôm nay bạn có mua gì không? Ghi lại trong 10 giây.',
                  style: AppTextStyles.bodyMedium
                      .themed(context)
                      .copyWith(
                        color: AppSemanticColors.of(context).textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
