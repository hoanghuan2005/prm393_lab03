import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/core/utils/price_history_ids.dart';

const _key = 'shopee:446089250:44081797761';

void main() {
  test('dayKey uses Vietnam time (UTC+7)', () {
    // 2026-11-05 17:00 UTC is already 2026-11-06 00:00 in Vietnam
    expect(PriceHistoryIds.dayKey(DateTime.utc(2026, 11, 5, 17)), '20261106');
    expect(
      PriceHistoryIds.dayKey(DateTime.utc(2026, 11, 5, 16, 59)),
      '20261105',
    );
    expect(PriceHistoryIds.dayKey(DateTime.utc(2026, 1, 2, 3)), '20260102');
  });

  test('userReportId matches a sha256 computed by hand', () {
    // python: hashlib.sha256(b"alice|shopee:446089250:44081797761|none|20261106")
    expect(
      PriceHistoryIds.userReportId(
        'alice',
        _key,
        'none',
        DateTime.utc(2026, 11, 6, 3),
      ),
      '5f149803fb5fa6aa974194316c6401c385699c08d25c250ae3c06289ab6408e1',
    );
  });

  test('userReportId changes with the day, the variant and the person', () {
    final day = DateTime.utc(2026, 11, 6, 3);
    final id = PriceHistoryIds.userReportId('alice', _key, 'none', day);
    expect(id, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(
      PriceHistoryIds.userReportId(
        'alice',
        _key,
        'none',
        day.add(const Duration(days: 1)),
      ),
      isNot(id),
    );
    expect(PriceHistoryIds.userReportId('alice', _key, '123', day), isNot(id));
    expect(PriceHistoryIds.userReportId('bob', _key, 'none', day), isNot(id));
  });

  test('demoReportId', () {
    expect(
      PriceHistoryIds.demoReportId(3, 'none', DateTime.utc(2026, 11, 5, 18)),
      'demo3_none_20261106',
    );
  });
}
