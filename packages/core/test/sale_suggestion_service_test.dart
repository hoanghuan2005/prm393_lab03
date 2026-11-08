import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_i_buy_core/why_i_buy_core.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSaleSuggestionService service;

  Future<SaleSuggestion> submitted() async {
    await service.submit(
      uid: 'user-1',
      name: ' 11.11 Shopee ',
      date: DateTime(2026, 11, 11, 15, 30),
      note: 'Shopee đã công bố',
    );
    final snapshot = await db.collection('saleSuggestions').get();
    return SaleSuggestion.fromFirestore(snapshot.docs.single);
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    service = FirestoreSaleSuggestionService(db);
  });

  test('submit stores a pending suggestion with a day-only date', () async {
    final s = await submitted();
    expect(s.uid, 'user-1');
    expect(s.name, '11.11 Shopee');
    expect(s.date, DateTime(2026, 11, 11));
    expect(s.status, SuggestionStatus.pending);
  });

  test('approve publishes the event, links it and writes the inbox', () async {
    final s = await submitted();
    final eventId = await service.approve(
      suggestion: s,
      byUid: 'staff-1',
      event: SaleEventDraft(
        name: s.name,
        date: s.date,
        type: SaleType.doubleDay,
        confirmed: true,
      ),
    );

    final event = SaleEvent.fromFirestore(
      await db.collection('saleEvents').doc(eventId).get(),
    );
    expect(event.status, SaleEventStatus.published);
    expect(event.fromSuggestion, isTrue);
    expect(event.suggestionId, s.id);
    expect(event.confirmed, isTrue);

    final reviewed = SaleSuggestion.fromFirestore(
      await db.collection('saleSuggestions').doc(s.id).get(),
    );
    expect(reviewed.status, SuggestionStatus.approved);
    expect(reviewed.saleEventId, eventId);

    final inbox = await db.collection('users/user-1/inbox').get();
    final message = InboxMessage.fromFirestore(inbox.docs.single);
    expect(message.kind, InboxKind.suggestionReply);
    expect(message.refId, s.id);
    expect(message.isRead, isFalse);
    expect(message.body, contains('11/11/2026'));
  });

  test('reject stores the reason and tells the user why', () async {
    final s = await submitted();
    await service.reject(
      suggestion: s,
      byUid: 'staff-1',
      reason: '  Trùng với đợt đã có  ',
    );

    final reviewed = SaleSuggestion.fromFirestore(
      await db.collection('saleSuggestions').doc(s.id).get(),
    );
    expect(reviewed.status, SuggestionStatus.rejected);
    expect(reviewed.reason, 'Trùng với đợt đã có');
    expect((await db.collection('saleEvents').get()).docs, isEmpty);

    final inbox = await db.collection('users/user-1/inbox').get();
    final message = InboxMessage.fromFirestore(inbox.docs.single);
    expect(message.kind, InboxKind.suggestionReply);
    expect(message.body, contains('Trùng với đợt đã có'));
  });

  test('approve writes exactly the fields firestore.rules allows', () async {
    final s = await submitted();
    final eventId = await service.approve(
      suggestion: s,
      byUid: 'staff-1',
      event: ReviewQueueDraft.of(s),
    );
    final event = (await db.collection('saleEvents').doc(eventId).get())
        .data()!;
    expect(event.keys.toSet(), {
      'name',
      'date',
      'type',
      'confirmed',
      'status',
      'suggestionId',
      'updatedAt',
      'updatedBy',
    });
    final inbox = (await db.collection('users/user-1/inbox').get()).docs.single
        .data();
    expect(inbox.keys.toSet(), {
      'title',
      'body',
      'kind',
      'refId',
      'createdAt',
      'createdBy',
    });
    expect(inbox['createdBy'], 'staff-1');
  });

  test('unknown role reads as user', () {
    expect(AppRole.fromKey(null), AppRole.user);
    expect(AppRole.fromKey('owner'), AppRole.user);
    expect(AppRole.fromKey('staff').canUseWebAdmin, isTrue);
    expect(AppRole.user.canUseWebAdmin, isFalse);
    expect(AppRole.fromKey('admin'), AppRole.admin);
  });
}

/// Same pre-fill as the web review queue, kept local to the test
extension ReviewQueueDraft on SaleEventDraft {
  static SaleEventDraft of(SaleSuggestion s) => SaleEventDraft(
    name: s.name,
    date: s.date,
    type: SaleType.doubleDay,
    confirmed: true,
  );
}
