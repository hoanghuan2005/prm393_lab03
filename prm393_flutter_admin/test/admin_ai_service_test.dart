import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/app/admin_theme.dart';
import 'package:prm393_flutter_admin/screens/ai_assistant_screen.dart';
import 'package:prm393_flutter_admin/services/admin_ai_service.dart';
import 'package:prm393_flutter_admin/viewmodels/ai_assistant_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/announcements_viewmodel.dart';
import 'package:prm393_flutter_admin/viewmodels/shell_viewmodel.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

String _reply({
  String question = 'Điều gì khiến bạn muốn có món này vào lúc này?',
  String title = 'Bạn đang cân nhắc món nào?',
  String body = 'Ghi lại vì sao bạn muốn có nó trước khi quyết định.',
  String category = 'dormant',
}) => jsonEncode({
  'question': question,
  'insight': 'Nhiều người cài app nhưng chưa lưu món nào.',
  'title': title,
  'body': body,
  'category': category,
  'screen': 'wishlist_add',
});

void main() {
  const metrics = AdminAiMetrics(
    totalUsers: 1428,
    newUsersToday: 48,
    activeUsersToday: 382,
    dormantUsers: 176,
    totalWishlistItems: 842,
  );

  test('the prompt only holds aggregate numbers, no user data', () {
    final prompt = AdminAiService.buildPrompt('Trà sữa mỗi ngày', metrics);
    expect(prompt, contains('"caiAppChuaDung":176'));
    expect(prompt, isNot(contains('@')));
    expect(prompt, isNot(contains('uid')));
  });

  test('a valid reply becomes an AI suggestion', () async {
    final ai = AdminAiService(generator: (model, prompt) async => _reply());
    final result = await ai.suggest('Trà sữa', metrics);
    expect(result.fromAi, isTrue);
    expect(result.suggestion.category, 'dormant');
    expect(result.suggestion.targetScreen, 'wishlist_add');
  });

  test(
    'advice, numbers, overlong text or broken JSON fall back to the template',
    () {
      expect(
        AdminAiService.parse(_reply(body: 'Bạn nên mua ngay hôm nay.'), 't'),
        isNull,
      );
      expect(
        AdminAiService.parse(_reply(title: 'Giảm 50% hôm nay'), 't'),
        isNull,
      );
      expect(AdminAiService.parse(_reply(body: 'a' * 181), 't'), isNull);
      expect(AdminAiService.parse('{not json', 't'), isNull);
      // The insight may only quote numbers that were sent
      final quoted = jsonEncode({
        ...jsonDecode(_reply()) as Map,
        'insight': 'Có 176 người cài app chưa dùng.',
      });
      final invented = jsonEncode({
        ...jsonDecode(_reply()) as Map,
        'insight': 'Tương tác tăng 42%.',
      });
      expect(
        AdminAiService.parse(quoted, 't', allowedNumbers: {176}),
        isNotNull,
      );
      expect(
        AdminAiService.parse(invented, 't', allowedNumbers: {176}),
        isNull,
      );
      // An unknown category is not trusted
      expect(
        AdminAiService.parse(_reply(category: 'vip'), 't')!.category,
        'all',
      );
    },
  );

  test('an AI error gives the template and says why', () async {
    final ai = AdminAiService(
      generator: (model, prompt) async => throw Exception('Failed to fetch'),
    );
    final result = await ai.suggest('Trà sữa', metrics);
    expect(result.fromAi, isFalse);
    expect(result.suggestion.id, 'template_custom');
    expect(result.fallbackReason, 'Không kết nối được tới AI.');
  });

  Future<(ShellViewModel, AnnouncementsViewModel)> pumpScreen(
    WidgetTester tester,
    AdminAiService ai,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final shell = ShellViewModel();
    final announcements = AnnouncementsViewModel(
      FakeAnnouncementService(),
      FakePushService(),
      byUid: 'staff-1',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: shell),
          ChangeNotifierProvider.value(value: announcements),
          ChangeNotifierProvider(
            create: (_) => AiAssistantViewModel(ai, () async => metrics),
          ),
        ],
        child: MaterialApp(
          theme: buildAdminTheme(Brightness.light),
          home: const Scaffold(body: AiAssistantScreen()),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Trà sữa mỗi ngày');
    await tester.tap(find.text('Tạo Gợi Ý Thông Minh'));
    await tester.pumpAndSettle();
    return (shell, announcements);
  }

  testWidgets('the screen labels AI output and hands the draft to the form', (
    tester,
  ) async {
    final (shell, announcements) = await pumpScreen(
      tester,
      AdminAiService(generator: (m, p) async => _reply()),
    );
    expect(find.text('AI · ${AdminAiService.defaultModel}'), findsOneWidget);
    expect(
      find.text('"Điều gì khiến bạn muốn có món này vào lúc này?"'),
      findsOneWidget,
    );
    expect(find.textContaining('đọc và sửa tiêu đề, nội dung'), findsOneWidget);

    await tester.tap(find.text('Dùng cho thông báo'));
    await tester.pump();
    expect(shell.section, AdminSection.announcements);
    expect(announcements.pendingDraft!.title, 'Bạn đang cân nhắc món nào?');
  });

  testWidgets('the screen says when it shows the template', (tester) async {
    await pumpScreen(
      tester,
      AdminAiService(
        generator: (m, p) async => throw Exception('quota exceeded'),
      ),
    );
    expect(find.text('CÂU MẪU (AI KHÔNG DÙNG ĐƯỢC)'), findsOneWidget);
    expect(find.text('AI đã hết lượt dùng.'), findsOneWidget);
  });
}
