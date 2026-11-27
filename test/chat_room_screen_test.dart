import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/report.dart';
import 'package:moor_market/screens/chat/chat_room_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/shop_badge.dart';

void main() {
  testWidgets('initialDraft pre-fills the message field without sending', (
    tester,
  ) async {
    final appState = AppState();
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    final conversation = appState.openConversationForProduct('prod_1')!;
    final before = conversation.messages.length;
    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomScreen(
          conversation: conversation,
          initialDraft: 'ร่างข้อความ',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'ร่างข้อความ');
    expect(conversation.messages.length, before);
  });

  testWidgets(
    'shop inquiry room shows inquiry header, no meetup, keeps draft',
    (tester) async {
      final appState = AppState();
      appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
      final shop = appState.users.firstWhere((u) => u.phone == '0800000011');
      final conversation = appState.openShopInquiry(shop.id)!;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            conversation: conversation,
            initialDraft: 'ร่าง',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('สอบถามร้านค้า'), findsOneWidget);
      expect(find.text('ร้านมือถือเจริญ'), findsWidgets);
      expect(find.byType(ShopBadge), findsOneWidget);
      expect(find.text('นัดรับ'), findsNothing);
      expect(find.byKey(const ValueKey('share-exact-address')), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'ร่าง');
    },
  );

  testWidgets('reporting a shop from an inquiry room succeeds', (tester) async {
    final appState = AppState();
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    final shop = appState.users.firstWhere((u) => u.phone == '0800000011');
    final conversation = appState.openShopInquiry(shop.id)!;
    expect(conversation.productId, isEmpty);
    final before = appState.reports.length;
    expect(
      appState.submitReport(
        reportedUserId: shop.id,
        reason: ReportReason.values.first,
        detail: 'ทดสอบรายงานร้านค้า',
        productId: conversation.productId,
      ),
      isNull,
    );
    expect(appState.reports.length, before + 1);
  });

  testWidgets('product chat still shows product strip and meetup button', (
    tester,
  ) async {
    final appState = AppState();
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    final conversation = appState.openConversationForProduct('prod_1')!;
    await tester.pumpWidget(
      MaterialApp(home: ChatRoomScreen(conversation: conversation)),
    );
    await tester.pumpAndSettle();
    expect(find.text('สอบถามร้านค้า'), findsNothing);
    expect(find.text('นัดรับ'), findsOneWidget);
  });

  testWidgets(
    'meetup response and address sharing are visible to the correct side',
    (tester) async {
      final appState = AppState();
      appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
      appState.conversations.clear();
      appState.meetupAgreements.clear();
      final conversation = appState.openConversationForProduct('prod_1')!;
      expect(
        appState.proposeMeetup(
          conversationId: conversation.id,
          pickupType: PickupType.sellerHome,
          placeLabel: '',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        isNull,
      );
      await tester.pumpWidget(
        MaterialApp(home: ChatRoomScreen(conversation: conversation)),
      );
      await tester.pumpAndSettle();
      expect(find.text('ตกลง'), findsNothing);
      expect(find.text('ขอเปลี่ยน'), findsNothing);
      expect(find.byKey(const ValueKey('share-exact-address')), findsNothing);

      appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
      await tester.pumpAndSettle();
      expect(find.text('ตกลง'), findsOneWidget);
      expect(find.text('ขอเปลี่ยน'), findsOneWidget);
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-exact-address')), findsOneWidget);

      appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-exact-address')), findsNothing);

      await tester.enterText(find.byType(TextField), 'x' * 900);
      await tester.pump();
      expect(find.text('เหลือ 100 ตัวอักษร'), findsOneWidget);
    },
  );
}
