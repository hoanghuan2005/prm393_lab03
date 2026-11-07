import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03/models/extension_session.dart';
import 'package:prm393_lab03/models/price_insights.dart';
import 'package:prm393_lab03/models/price_snapshot.dart';
import 'package:prm393_lab03/models/purchase_draft.dart';
import 'package:prm393_lab03/models/wishlist_item.dart';
import 'package:prm393_lab03/models/wishlist_status.dart';
import 'package:prm393_lab03/services/extension_session_service.dart';
import 'package:prm393_lab03/services/purchase_service.dart';
import 'package:prm393_lab03/services/wishlist_service.dart';
import 'package:prm393_lab03/viewmodels/extension_link_viewmodel.dart';

const _uid = 'u1';
final _now = DateTime(2026, 11, 1, 10);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

CollectionReference<Map<String, dynamic>> _items(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('wishlistItems');

CollectionReference<Map<String, dynamic>> _sessions(FakeFirebaseFirestore db) =>
    db.collection('users').doc(_uid).collection('extensionSessions');

void main() {
  group('Extension fields on WishlistItem', () {
    test('an item saved by the extension reads every field', () async {
      final db = FakeFirebaseFirestore();
      await _items(db).doc('w_abc').set({
        'title': 'Tai nghe bluetooth',
        'status': 'considering',
        'saveChannel': 'extension',
        'productKey': 'shopee:1:2',
        'variantLabel': 'Màu đen',
        'modelId': '99',
        'imageUrl': 'https://cf.shopee.vn/a.jpg',
        'buyIntentAt': Timestamp.fromDate(_now),
        'createdAt': Timestamp.fromDate(_now),
      });
      final item = WishlistItem.fromFirestore(
        await _items(db).doc('w_abc').get(),
      );
      expect(item.isFromExtension, isTrue);
      expect(item.productKey, 'shopee:1:2');
      expect(item.variantLabel, 'Màu đen');
      expect(item.modelId, '99');
      expect(item.imageUrl, 'https://cf.shopee.vn/a.jpg');
      expect(item.buyIntentAt, _now);
      expect(item.hasBuyIntent, isTrue);
      expect(item.toMap()['productKey'], 'shopee:1:2');
    });

    test('an app item has no extension fields and never writes them', () {
      final item = WishlistItem(id: 'a', title: 'Áo', createdAt: _now);
      final map = item.toMap();
      for (final key in [
        'productKey',
        'variantLabel',
        'modelId',
        'imageUrl',
        'buyIntentAt',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
      expect(item.hasBuyIntent, isFalse);
      expect(
        item.copyWith(buyIntentAt: _now).copyWith(clearBuyIntent: true),
        item,
      );
    });

    test('a decided item never counts as a buy intent', () {
      final item = WishlistItem(
        id: 'a',
        title: 'Áo',
        createdAt: _now,
        status: WishlistStatus.skipped,
        buyIntentAt: _now,
      );
      expect(item.hasBuyIntent, isFalse);
    });

    test('app edits keep the fields the extension wrote', () async {
      final db = FakeFirebaseFirestore();
      await _items(db).doc('w_abc').set({
        'title': 'Tai nghe',
        'status': 'considering',
        'variantLabel': 'Màu đen',
        'buyIntentAt': Timestamp.fromDate(_now),
        'createdAt': Timestamp.fromDate(_now),
      });
      final service = FirestoreWishlistService(db);
      final item = WishlistItem.fromFirestore(
        await _items(db).doc('w_abc').get(),
      );
      await service.update(_uid, item.copyWith(priority: 5));
      final data = (await _items(db).doc('w_abc').get()).data()!;
      expect(data['variantLabel'], 'Màu đen');
      expect(data['priority'], 5);

      await service.clearBuyIntent(_uid, 'w_abc');
      final cleared = WishlistItem.fromFirestore(
        await _items(db).doc('w_abc').get(),
      );
      expect(cleared.buyIntentAt, isNull);
      expect(cleared.status, WishlistStatus.considering);
    });

    test('recording the purchase clears the buy intent', () async {
      final db = FakeFirebaseFirestore();
      await _items(db).doc('w_abc').set({
        'title': 'Tai nghe',
        'status': 'considering',
        'saveChannel': 'extension',
        'buyIntentAt': Timestamp.fromDate(_now),
        'createdAt': Timestamp.fromDate(_now),
      });
      final item = WishlistItem.fromFirestore(
        await _items(db).doc('w_abc').get(),
      );
      await FirestorePurchaseService(db).buyFromWishlist(
        _uid,
        item,
        const PurchaseDraft(amountVnd: 250000, fromWishlistId: 'w_abc'),
      );
      final bought = WishlistItem.fromFirestore(
        await _items(db).doc('w_abc').get(),
      );
      expect(bought.status, WishlistStatus.purchased);
      expect(bought.buyIntentAt, isNull);
    });
  });

  group('Extension price snapshots', () {
    test('old snapshots read as single confirmed prices', () async {
      final db = FakeFirebaseFirestore();
      final ref = _items(db).doc('a').collection('priceSnapshots').doc('s');
      await ref.set({'amountVnd': 100000, 'observedAt': Timestamp.now()});
      final s = PriceSnapshot.fromFirestore(await ref.get());
      expect(s.source, PriceSource.manual);
      expect(s.priceType, PriceType.single);
      expect(s.confirmed, isTrue);
      expect(s.isRange, isFalse);
    });

    test('a page range read by the extension keeps its bounds', () async {
      final db = FakeFirebaseFirestore();
      final ref = _items(db).doc('a').collection('priceSnapshots').doc('s');
      await ref.set({
        'amountVnd': 90000,
        'minVnd': 90000,
        'maxVnd': 120000,
        'priceType': 'range',
        'source': 'extensionPage',
        'confirmation': 'unconfirmed',
        'variantLabel': 'Size M',
        'observedAt': Timestamp.now(),
      });
      final s = PriceSnapshot.fromFirestore(await ref.get());
      expect(s.source, PriceSource.extensionPage);
      expect(s.isRange, isTrue);
      expect(s.maxVnd, 120000);
      expect(s.confirmed, isFalse);
      expect(s.variantLabel, 'Size M');
      expect(s.toMap()['confirmation'], 'unconfirmed');
    });

    test('after-voucher prices are listed but never compared', () {
      PriceSnapshot snap(
        int vnd,
        int daysAgo, [
        PriceType t = PriceType.single,
      ]) => PriceSnapshot(
        id: '$vnd',
        amountVnd: vnd,
        observedAt: _now.subtract(Duration(days: daysAgo)),
        priceType: t,
      );
      final insights = PriceInsights([
        snap(200000, 5),
        snap(180000, 1),
        snap(120000, 0, PriceType.afterVoucher),
      ], now: _now);
      expect(insights.history, hasLength(3));
      expect(insights.latest!.amountVnd, 180000);
      expect(insights.changeSinceSavedPercent, -10);
      expect(insights.lowest, isNull); // only 2 comparable records
    });

    test(
      'sale prices (SteamDB) are listed apart from the regular price',
      () async {
        final db = FakeFirebaseFirestore();
        final ref = _items(db).doc('a').collection('priceSnapshots').doc('s');
        await ref.set({
          'amountVnd': 140000,
          'originalVnd': 200000,
          'priceType': 'sale',
          'saleLabel': '11.11',
          'observedAt': Timestamp.fromDate(_now),
        });
        final sale = PriceSnapshot.fromFirestore(await ref.get());
        expect(sale.priceType, PriceType.sale);
        expect(sale.saleLabel, '11.11');
        expect(sale.discountPercent, 30);
        expect(sale.toMap()['saleLabel'], '11.11');

        final regular = PriceSnapshot(
          id: 'r',
          amountVnd: 200000,
          observedAt: _now,
        );
        final insights = PriceInsights([regular, sale], now: _now);
        expect(
          insights.latest!.amountVnd,
          200000,
        ); // the regular price stays the main one
        expect(insights.lowestSale!.saleLabel, '11.11');
        expect(insights.notes.last, contains('Giảm thấp nhất: '));
        expect(insights.notes.last, contains('-30%'));
        // Only sale prices recorded: they are still compared
        expect(PriceInsights([sale], now: _now).latest!.amountVnd, 140000);
      },
    );
  });

  group('ExtensionLinkViewModel', () {
    Future<(FakeFirebaseFirestore, ExtensionLinkViewModel)> setUp() async {
      final db = FakeFirebaseFirestore();
      final vm = ExtensionLinkViewModel(
        service: FirestoreExtensionSessionService(db),
        now: () => _now,
      );
      vm.updateUid(_uid);
      await _settle();
      return (db, vm);
    }

    Future<void> addSession(
      FakeFirebaseFirestore db,
      String id, {
      required String status,
      required DateTime createdAt,
    }) => _sessions(db).doc(id).set({
      'deviceLabel': 'Chrome – Windows',
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt),
    });

    test('only a pending request under 5 minutes old is asked', () async {
      final (db, vm) = await setUp();
      await addSession(
        db,
        'old',
        status: 'pending',
        createdAt: _now.subtract(const Duration(minutes: 6)),
      );
      await _settle();
      expect(vm.pendingSession, isNull);

      await addSession(
        db,
        'new',
        status: 'pending',
        createdAt: _now.subtract(const Duration(minutes: 1)),
      );
      await _settle();
      expect(vm.pendingSession?.id, 'new');
      expect(vm.unpromptedPending?.id, 'new');

      vm.markPrompted('new');
      expect(vm.unpromptedPending, isNull);
      expect(vm.pendingSession?.id, 'new');
      vm.dispose();
    });

    test('approve links the browser, revoke unlinks it', () async {
      final (db, vm) = await setUp();
      await addSession(db, 's1', status: 'pending', createdAt: _now);
      await _settle();

      expect(await vm.approve(vm.pendingSession!), isTrue);
      await _settle();
      final approved = (await _sessions(db).doc('s1').get()).data()!;
      expect(approved['status'], 'approved');
      expect(approved['approvedAt'], isNotNull);
      expect(vm.pendingSession, isNull);
      expect(vm.linkedSessions.map((s) => s.id), ['s1']);

      expect(await vm.revoke(vm.linkedSessions.single), isTrue);
      await _settle();
      expect(
        (await _sessions(db).doc('s1').get()).data()!['status'],
        'revoked',
      );
      expect(vm.linkedSessions, isEmpty);
      vm.dispose();
    });

    test('reject closes the request without linking', () async {
      final (db, vm) = await setUp();
      await addSession(db, 's1', status: 'pending', createdAt: _now);
      await _settle();
      expect(await vm.reject(vm.pendingSession!), isTrue);
      await _settle();
      expect(vm.pendingSession, isNull);
      expect(vm.linkedSessions, isEmpty);
      expect(
        ExtensionSessionStatus.fromKey(
          (await _sessions(db).doc('s1').get()).data()!['status'] as String,
        ),
        ExtensionSessionStatus.rejected,
      );
      vm.dispose();
    });

    test('signed out: writes fail with a message', () async {
      final vm = ExtensionLinkViewModel(
        service: FirestoreExtensionSessionService(FakeFirebaseFirestore()),
      );
      final session = ExtensionSession(
        id: 'x',
        deviceLabel: 'Chrome',
        status: ExtensionSessionStatus.pending,
        createdAt: _now,
      );
      expect(await vm.approve(session), isFalse);
      expect(vm.actionError, isNotNull);
      vm.dispose();
    });
  });

  group('QR linking', () {
    const pid = 'AbCdEfGhIjKlMnOpQrSt';

    Future<void> addPairing(
      FakeFirebaseFirestore db, {
      required DateTime createdAt,
      String status = 'pending',
    }) => db.collection('extensionPairings').doc(pid).set({
      'anonUid': 'anon1',
      'deviceLabel': 'Edge – Windows',
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    });

    test('only a Why I Buy? QR gives a pairing id', () {
      expect(ExtensionPairingRequest.idFromQr('whyibuy-link:$pid'), pid);
      expect(ExtensionPairingRequest.idFromQr(' whyibuy-link:$pid\n'), pid);
      expect(ExtensionPairingRequest.idFromQr(pid), isNull);
      expect(ExtensionPairingRequest.idFromQr('https://shopee.vn'), isNull);
      expect(ExtensionPairingRequest.idFromQr('whyibuy-link:../users'), isNull);
      expect(ExtensionPairingRequest.idFromQr(null), isNull);
    });

    test('approve makes the anonymous extension a linked session', () async {
      final db = FakeFirebaseFirestore();
      final vm = ExtensionLinkViewModel(
        service: FirestoreExtensionSessionService(db),
        now: () => _now,
      );
      vm.updateUid(_uid);
      await addPairing(
        db,
        createdAt: _now.subtract(const Duration(minutes: 1)),
      );
      await _settle();

      final request = await vm.loadPairing(pid);
      expect(request?.deviceLabel, 'Edge – Windows');
      expect(await vm.approvePairing(request!, accountName: 'Huan'), isTrue);
      await _settle();

      final pairing = (await db.collection('extensionPairings').doc(pid).get())
          .data()!;
      expect(pairing['status'], 'approved');
      expect(pairing['ownerUid'], _uid);
      expect(pairing['ownerName'], 'Huan');
      final session = (await _sessions(db).doc('anon1').get()).data()!;
      expect(session['status'], 'approved');
      expect(session['deviceLabel'], 'Edge – Windows');
      expect(vm.linkedSessions.map((s) => s.id), ['anon1']);
      vm.dispose();
    });

    test(
      'an expired, used or missing QR is refused; reject closes it',
      () async {
        final db = FakeFirebaseFirestore();
        final vm = ExtensionLinkViewModel(
          service: FirestoreExtensionSessionService(db),
          now: () => _now,
        );
        vm.updateUid(_uid);
        expect(await vm.loadPairing(pid), isNull);
        expect(vm.actionError, isNotNull);

        await addPairing(
          db,
          createdAt: _now.subtract(const Duration(minutes: 6)),
        );
        expect(await vm.loadPairing(pid), isNull);

        await addPairing(db, createdAt: _now, status: 'approved');
        expect(await vm.loadPairing(pid), isNull);

        await addPairing(db, createdAt: _now);
        final request = await vm.loadPairing(pid);
        expect(await vm.rejectPairing(request!), isTrue);
        expect(
          (await db.collection('extensionPairings').doc(pid).get())
              .data()!['status'],
          'rejected',
        );
        expect(
          await _sessions(db).doc('anon1').get().then((d) => d.exists),
          isFalse,
        );
        vm.dispose();
      },
    );
  });
}
