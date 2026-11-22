import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/screens/chat/chat_room_screen.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  testWidgets(
    'meetup response and address sharing are visible to the correct side',
    (tester) async {
      final appState = AppState();
      appState.loginWithPhoneAndPassword('0800000001', 'password123');
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

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      await tester.pumpAndSettle();
      expect(find.text('ตกลง'), findsOneWidget);
      expect(find.text('ขอเปลี่ยน'), findsOneWidget);
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-exact-address')), findsOneWidget);

      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('share-exact-address')), findsNothing);

      await tester.enterText(find.byType(TextField), 'x' * 900);
      await tester.pump();
      expect(find.text('เหลือ 100 ตัวอักษร'), findsOneWidget);
    },
  );
}
