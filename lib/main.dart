import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_dimens.dart';
import 'models/buying_motive.dart';
import 'widgets/app_button.dart';
import 'widgets/motive_chip.dart';
import 'widgets/states/loading_view.dart';
import 'widgets/states/empty_view.dart';
import 'widgets/states/error_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhyIBuyApp());
}

class WhyIBuyApp extends StatelessWidget {
  const WhyIBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Why I Buy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DesignSystemPreviewScreen(),
    );
  }
}

class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  @override
  State<DesignSystemPreviewScreen> createState() => _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState extends State<DesignSystemPreviewScreen> {
  BuyingMotive _selectedMotive = BuyingMotive.emotion;
  int _activeStateTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Why I Buy – Design System'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '8 Động cơ mua sắm (Why I Buy)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Chọn động cơ để kích hoạt cơ chế hoãn tâm lý 3 ngày hoặc canh sale:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),
            Wrap(
              spacing: AppDimens.space8,
              runSpacing: AppDimens.space8,
              children: BuyingMotive.values.map((motive) {
                return MotiveChip(
                  motive: motive,
                  isSelected: _selectedMotive == motive,
                  onSelected: (m) {
                    setState(() => _selectedMotive = m);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Các loại nút bấm (>=48dp touch target)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.space12),
            AppButton(
              title: 'Lưu vào Wishlist (Primary)',
              icon: Icons.bookmark_add_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: AppDimens.space12),
            AppButton(
              title: 'Xem chi tiết (Secondary)',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            const SizedBox(height: AppDimens.space12),
            AppButton(
              title: 'Bỏ qua - Tiết kiệm (Danger)',
              variant: AppButtonVariant.danger,
              onPressed: () {},
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              '3 Trạng thái bắt buộc (Section 5)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimens.space12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Loading')),
                ButtonSegment(value: 1, label: Text('Empty')),
                ButtonSegment(value: 2, label: Text('Error')),
              ],
              selected: {_activeStateTab},
              onSelectionChanged: (set) => setState(() => _activeStateTab = set.first),
            ),
            const SizedBox(height: AppDimens.space16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppDimens.borderLarge,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: _buildSelectedStateView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedStateView() {
    switch (_activeStateTab) {
      case 0:
        return const SizedBox(
          height: 180,
          child: LoadingView(message: 'Đang tải danh sách cân nhắc...'),
        );
      case 1:
        return SizedBox(
          height: 240,
          child: EmptyView(
            title: 'Chưa có món nào',
            subtitle: 'Dán link Shopee hoặc nhấn thêm món mới để bắt đầu cân nhắc.',
            actionTitle: 'Thêm món đầu tiên',
            onAction: () {},
          ),
        );
      case 2:
      default:
        return SizedBox(
          height: 240,
          child: ErrorView(
            message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
            onRetry: () {},
          ),
        );
    }
  }
}
