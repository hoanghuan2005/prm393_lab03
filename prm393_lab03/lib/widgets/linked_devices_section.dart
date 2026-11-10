import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/extension_session.dart';
import '../screens/extension_qr_scan_screen.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_text_styles.dart';
import '../viewmodels/auth_viewmodel.dart';
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
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey('scan-extension-qr'),
            onPressed: () => _scanQr(context, vm),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Quét mã QR'),
          ),
        ),
        if (sessions.isEmpty)
          Text(
            'Chưa có máy tính nào. Cài extension Why I Buy? trên Chrome hoặc Edge, '
            'chọn Tạo mã QR rồi quét bằng nút ở trên.',
            style: AppTextStyles.bodyMedium.themed(context),
          )
        else
          for (final session in sessions)
            ListTile(
              key: ValueKey('linked-${session.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.laptop_chromebook_rounded,
                color: AppSemanticColors.of(context).textSecondary,
              ),
              title: Text(session.deviceLabel),
              subtitle: Text(
                'Liên kết ngày ${DateFormat('dd/MM/yyyy').format(session.approvedAt ?? session.createdAt)}',
                style: AppTextStyles.caption.themed(context),
              ),
              trailing: TextButton(
                onPressed: () => _revoke(context, vm, session),
                child: const Text('Huỷ liên kết'),
              ),
            ),
      ],
    );
  }

  Future<void> _scanQr(BuildContext context, ExtensionLinkViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final accountName = context.read<AuthViewModel>().displayName;
    final pairingId = await ExtensionQrScanScreen.open(context);
    if (pairingId == null || !context.mounted) return;
    final request = await vm.loadPairing(pairingId);
    if (!context.mounted) return;
    if (request == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.actionError ?? 'Đã có lỗi, vui lòng thử lại.'),
        ),
      );
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cho phép ${request.deviceLabel} liên kết?',
      message:
          'Extension trên máy này sẽ xem và đồng bộ danh sách mong muốn, giá và ngân sách '
          'của bạn. Chỉ đồng ý nếu đây là máy tính của bạn.',
      confirmLabel: 'Đồng ý',
    );
    if (!context.mounted) return;
    final ok = confirmed
        ? await vm.approvePairing(request, accountName: accountName)
        : await vm.rejectPairing(request);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? vm.actionError ?? 'Đã có lỗi, vui lòng thử lại.'
              : confirmed
              ? 'Đã liên kết ${request.deviceLabel}.'
              : 'Đã từ chối yêu cầu liên kết.',
        ),
      ),
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
