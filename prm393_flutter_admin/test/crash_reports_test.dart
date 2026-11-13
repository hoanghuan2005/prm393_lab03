import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/viewmodels/crash_reports_viewmodel.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

/// "Sự cố": crash reports the app writes, read live on the web admin
void main() {
  CrashReport report(
    String id, {
    String feature = 'Màn hình Hồ sơ',
    String code = 'FATAL_TEST_CRASH',
    CrashSeverity severity = CrashSeverity.fatal,
    bool resolved = false,
    String user = 'uid-aaaaaa',
  }) => CrashReport(
    id: id,
    feature: feature,
    errorCode: code,
    errorMessage: 'Lỗi $id',
    severity: severity,
    userId: user,
    isResolved: resolved,
    createdAt: DateTime(2026, 11, 13, 8),
  );

  late FakeCrashReportService service;
  late CrashReportsViewModel vm;

  setUp(() async {
    service = FakeCrashReportService();
    vm = CrashReportsViewModel(service, byUid: 'staff-1');
    expect(vm.state, isA<UiLoading>());
    service.controller.add([
      report('a'),
      report('b', severity: CrashSeverity.warning, feature: 'Thêm món'),
      report('c', resolved: true),
      report('d', code: 'ERR_NON_FATAL_TEST', user: 'uid-bbbbbb'),
    ]);
    await pump();
  });

  tearDown(() => vm.dispose());

  test('mặc định chỉ hiện báo cáo chưa xử lý, có số đếm từng mục', () {
    final shown = (vm.state as UiSuccess<List<CrashReport>>).data;
    expect(shown.map((c) => c.id), ['a', 'b', 'd']);
    expect(vm.countFor(CrashFilter.open), 3);
    expect(vm.countFor(CrashFilter.resolved), 1);
    expect(vm.countFor(CrashFilter.all), 4);
    expect(vm.openFatalCount, 2);
  });

  test('lọc theo đã xử lý và tất cả', () {
    vm.setFilter(CrashFilter.resolved);
    expect((vm.state as UiSuccess<List<CrashReport>>).data.single.id, 'c');
    vm.setFilter(CrashFilter.all);
    expect((vm.state as UiSuccess<List<CrashReport>>).data, hasLength(4));
  });

  test('tìm không dấu theo màn hình, mã lỗi hoặc người dùng', () {
    vm.setQuery('them mon');
    expect((vm.state as UiSuccess<List<CrashReport>>).data.single.id, 'b');
    vm.setQuery('non_fatal');
    expect((vm.state as UiSuccess<List<CrashReport>>).data.single.id, 'd');
    vm.setQuery('bbbbbb');
    expect((vm.state as UiSuccess<List<CrashReport>>).data.single.id, 'd');
    vm.setQuery('khong co');
    expect(vm.state, isA<UiEmpty>());
  });

  test('danh sách rỗng báo chưa có sự cố nào', () async {
    final empty = FakeCrashReportService();
    final other = CrashReportsViewModel(empty, byUid: 'staff-1');
    empty.controller.add(const []);
    await pump();
    expect((other.state as UiEmpty).message, contains('Chưa có báo cáo'));
    other.dispose();
  });

  test('đánh dấu đã xử lý và mở lại', () async {
    expect(await vm.setResolved(report('a'), true), isNull);
    expect(service.resolved['a'], isTrue);
    expect(await vm.setResolved(report('c', resolved: true), false), isNull);
    expect(service.resolved['c'], isFalse);
  });

  test('lỗi quyền hiện câu tiếng Việt', () async {
    service.failWrites = permissionDenied();
    expect(await vm.setResolved(report('a'), true), contains('không có quyền'));
  });

  test('lỗi đọc dữ liệu hiện nút thử lại', () async {
    service.controller.addError(permissionDenied());
    await pump();
    expect(vm.state, isA<UiError<List<CrashReport>>>());
  });
}
