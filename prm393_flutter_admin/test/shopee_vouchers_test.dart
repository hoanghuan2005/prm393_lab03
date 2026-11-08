import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_flutter_admin/models/shopee_voucher.dart';
import 'package:prm393_flutter_admin/viewmodels/shopee_vouchers_viewmodel.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

import 'fakes.dart';

void main() {
  group('ShopeeVoucher', () {
    test('percent voucher with cap and conditions', () {
      const v = ShopeeVoucher(
        id: 'v_1',
        raw: 'Giảm 10% tối đa ₫50k',
        kind: 'percent',
        scope: VoucherScope.shop,
        percent: 10,
        capVnd: 50000,
        minSpendVnd: 99000,
        usedPct: 80,
        expiresText: '30.11',
      );
      expect(VoucherScope.fromKey('shop'), VoucherScope.shop);
      expect(v.valueLabel, 'Giảm 10% tối đa 50.000 ₫');
      expect(
        v.conditionLabel,
        'Đơn tối thiểu 99.000 ₫ · HSD 30.11 · Đã dùng 80%',
      );
    });

    test('value labels for each kind', () {
      const amount = ShopeeVoucher(
        id: 'a',
        raw: '',
        kind: 'amount',
        amountVnd: 20000,
      );
      const ship = ShopeeVoucher(id: 'b', raw: '', kind: 'shipping');
      const coin = ShopeeVoucher(id: 'c', raw: '', kind: 'coin', percent: 5);
      const other = ShopeeVoucher(id: 'd', raw: '');
      expect(amount.valueLabel, 'Giảm 20.000 ₫');
      expect(ship.valueLabel, 'Miễn phí vận chuyển');
      expect(coin.valueLabel, 'Hoàn 5% xu');
      expect(other.valueLabel, 'Voucher');
      expect(VoucherScope.fromKey('weird'), VoucherScope.unknown);
    });
  });

  group('ShopeeVouchersViewModel', () {
    late FakeShopeeVoucherService service;
    late ShopeeVouchersViewModel vm;

    const shopVoucher = ShopeeVoucher(
      id: 'v1',
      raw: 'Giảm 20k cho đơn từ 100k',
      kind: 'amount',
      amountVnd: 20000,
      scope: VoucherScope.shop,
      shopId: '1',
      shopName: 'Cửa Hàng Điện Thoại',
    );
    const platformVoucher = ShopeeVoucher(
      id: 'v2',
      raw: 'Miễn phí vận chuyển',
      kind: 'shipping',
      scope: VoucherScope.platform,
      unavailable: true,
    );

    setUp(() {
      service = FakeShopeeVoucherService();
      vm = ShopeeVouchersViewModel(service);
    });

    tearDown(() => vm.dispose());

    test('loading, then empty, then the vouchers', () async {
      expect(vm.state, isA<UiLoading<List<ShopeeVoucher>>>());
      service.controller.add([]);
      await pump();
      expect(vm.state, isA<UiEmpty<List<ShopeeVoucher>>>());
      service.controller.add([shopVoucher, platformVoucher]);
      await pump();
      final state = vm.state as UiSuccess<List<ShopeeVoucher>>;
      expect(state.data, hasLength(2));
      expect(vm.shopCount, 1);
      expect(vm.countFor(VoucherScope.shop), 1);
    });

    test('filters by scope, unavailable and accent-free search', () async {
      service.controller.add([shopVoucher, platformVoucher]);
      await pump();

      vm.setScope(VoucherScope.platform);
      expect((vm.state as UiSuccess).data, [platformVoucher]);

      vm.setHideUnavailable(true);
      expect(vm.state, isA<UiEmpty<List<ShopeeVoucher>>>());

      vm.setScope(null);
      vm.setHideUnavailable(false);
      vm.setQuery('dien thoai');
      expect((vm.state as UiSuccess).data, [shopVoucher]);
    });

    test('a stream error shows a retryable error', () async {
      service.controller.addError(permissionDenied());
      await pump();
      expect(vm.state, isA<UiError<List<ShopeeVoucher>>>());
    });

    test('delete calls the service and reports permission errors', () async {
      expect(await vm.delete(shopVoucher), isNull);
      expect(service.deleted, ['v1']);

      service.deleteError = permissionDenied();
      expect(await vm.delete(shopVoucher), contains('quyền'));
      expect(vm.isBusy('v1'), isFalse);
    });
  });
}
