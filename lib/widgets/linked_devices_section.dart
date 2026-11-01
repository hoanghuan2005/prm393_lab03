import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/extension_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/extension_link_viewmodel.dart';
import 'confirm_dialog.dart';
import 'section_card.dart';

/// Cá nhân → "Thiết bị đã liên kết": browsers running the Why I Buy? Chrome extension
class LinkedDevicesSection extends StatelessWidget {
  const LinkedDevicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExtensionLinkViewModel>();
    final sessions = vm.linkedSessions;

    return SectionCard(
      title: 'Thiết bị đã liên kết',
      icon: Icons.computer_rounded,
      children: [
        if (sessions.isEmpty)
          Text(
            'Chưa có máy tính nào. Cài extension Why I Buy? trên Chrome, đăng nhập '
            'cùng tài khoản Google rồi chọn Đồng ý khi app hỏi.',
            style: AppTextStyles.bodyMedium,
          )
        else
          for (final session in sessions)
            ListTile(
              key: ValueKey('linked-${session.id}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.laptop_chromebook_rounded,
                color: AppColors.textSecondary,
              ),
              title: Text(session.deviceLabel),
              subtitle: Text(
                'Liên kết ngày ${DateFormat('dd/MM/yyyy').format(session.approvedAt ?? session.createdAt)}',
                style: AppTextStyles.caption,
              ),
              trailing: TextButton(
                onPressed: () => _revoke(context, vm, session),
                child: const Text('Huỷ liên kết'),
              ),
            ),
      ],
    );
  }

  Future<void> _revoke(
    BuildContext context,
    ExtensionLinkViewModel vm,
    ExtensionSession session,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Huỷ liên kết ${session.deviceLabel}?',
      message: 'Extension trên máy này sẽ ngừng đồng bộ. Món đã lưu trong app vẫn giữ nguyên.',
      confirmLabel: 'Huỷ liên kết',
      isDanger: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await vm.revoke(session);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã huỷ liên kết ${session.deviceLabel}.'
              : vm.actionError ?? 'Đã có lỗi, vui lòng thử lại.',
        ),
      ),
    );
  }
}
