import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/viewmodels/vouchers_admin_viewmodel.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

/// "Mã giảm giá" (decision D-3: real Shopee vouchers the app suggests)
void main() {
  final now = DateTime(2026, 11, 12, 10);

  VoucherDraft draft(
    String code, {
    String? shopId,
    int discount = 50000,
    VoucherKind kind = VoucherKind.discount,
    DateTime? until,
  }) => VoucherDraft(
    code: code,
    title: 'Mã $code',
    kind: kind,
    discountVnd: discount,
    minOrderVnd: 250000,
    category: VoucherCategory.all,
    validUntil: until ?? DateTime(2026, 11, 30),
    shopId: shopId,
  );

  VoucherRecord record(
    String id,
    VoucherDraft d, {
    bool active = true,
    bool legacy = false,
  }) => VoucherRecord(id: id, draft: d, isActive: active, isLegacy: legacy);

  late FakeVoucherRecordService service;
  late VouchersAdminViewModel vm;

  setUp(() async {
    service = FakeVoucherRecordService();
    vm = VouchersAdminViewModel(service, byUid: 'staff-1', now: () => now);
    expect(vm.state, isA<UiLoading>());
    service.controller.add([
      record('a', draft('SHOPEE50K')),
      record('b', draft('PERSEPER15K', shopId: '111')),
      record('c', draft('CU', until: DateTime(2026, 11, 1))),
      record('d', draft('LUUTRU'), active: false),
      record('e', draft('CUCU'), active: false, legacy: true),
    ]);
    await pump();
  });

  tearDown(() => vm.dispose());

  test('bộ lọc: đang dùng, hết hạn, đã lưu trữ', () {
    expect(vm.countFor(VoucherFilter.active), 2);
    expect(vm.countFor(VoucherFilter.expired), 1);
    expect(vm.countFor(VoucherFilter.archived), 2);
    expect(vm.countFor(VoucherFilter.all), 5);
    final shown = (vm.state as UiSuccess<List<VoucherRecord>>).data;
    expect(shown.map((v) => v.id), ['a', 'b']);
  });

  test('tìm không dấu theo mã hoặc mô tả', () {
    vm.setQuery('perseper');
    final shown = (vm.state as UiSuccess<List<VoucherRecord>>).data;
    expect(shown.single.id, 'b');
    vm.setQuery('khong co');
    expect(vm.state, isA<UiEmpty>());
  });

  test('kiểm tra dữ liệu giống firestore.rules', () {
    expect(VouchersAdminViewModel.validateCode('sale50k'), isNull);
    expect(VouchersAdminViewModel.validateCode('AB'), isNotNull);
    expect(VouchersAdminViewModel.validateCode('MÃ-1'), isNotNull);
    expect(VouchersAdminViewModel.parseVnd('50k'), 50000);
    expect(VouchersAdminViewModel.parseVnd('50.000 ₫'), 50000);
    expect(
      VouchersAdminViewModel.validateDiscount('0', VoucherKind.discount),
      isNotNull,
    );
    expect(
      VouchersAdminViewModel.validateDiscount('0', VoucherKind.freeship),
      isNull,
    );
    expect(
      VouchersAdminViewModel.validateSourceUrl('https://shopee.vn/m/1'),
      isNull,
    );
    expect(
      VouchersAdminViewModel.validateSourceUrl('https://example.com/x'),
      isNotNull,
    );
    expect(
      VouchersAdminViewModel.validateShopLink('shopee.vn/username'),
      isNotNull,
    );
  });

  test('shopId từ link Shopee', () {
    expect(
      shopIdFromShopeeLink('https://shopee.vn/Ao-thun-i.123456.789012?sp=1'),
      '123456',
    );
    expect(shopIdFromShopeeLink('https://shopee.vn/product/42/7'), '42');
    expect(shopIdFromShopeeLink('https://shopee.vn/shop/99'), '99');
    expect(shopIdFromShopeeLink('  555 '), '555');
    expect(shopIdFromShopeeLink('https://shopee.vn/perseper'), isNull);
  });

  test('thêm mã mới', () async {
    expect(await vm.save(draft('MOI20K')), isNull);
    expect(service.created.single.code, 'MOI20K');
  });

  test('không thêm trùng mã cho cùng shop đang dùng', () async {
    final error = await vm.save(draft('PERSEPER15K', shopId: '111'));
    expect(error, contains('đã có'));
    expect(service.created, isEmpty);
    // Same code for another shop is a different voucher
    expect(await vm.save(draft('PERSEPER15K', shopId: '222')), isNull);
  });

  test('hạn dùng đã qua thì không lưu', () async {
    final error = await vm.save(draft('CU2', until: DateTime(2026, 11, 11)));
    expect(error, contains('Hạn dùng đã qua'));
  });

  test('sửa giữ trạng thái lưu trữ', () async {
    expect(await vm.save(draft('LUUTRU'), id: 'd'), isNull);
    expect(service.updated['d']!.$2, isFalse);
  });

  test('lưu trữ và dùng lại; mã cũ thiếu thông tin phải sửa trước', () async {
    expect(await vm.setActive(record('a', draft('SHOPEE50K')), false), isNull);
    expect(service.active['a'], isFalse);
    final legacy = record('e', draft('CUCU'), active: false, legacy: true);
    expect(await vm.setActive(legacy, true), contains('màn quản trị cũ'));
    expect(service.active.containsKey('e'), isFalse);
  });

  test('lỗi quyền hiện câu tiếng Việt', () async {
    service.failWrites = permissionDenied();
    expect(await vm.save(draft('MOI')), contains('không có quyền'));
  });
}
