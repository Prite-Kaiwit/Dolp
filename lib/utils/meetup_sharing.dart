import 'package:share_plus/share_plus.dart';

import '../models/meetup_agreement.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../state/app_state.dart';

String meetupPlanText({
  required String productTitle,
  required String partnerName,
  required String placeLabel,
  required DateTime scheduledAt,
}) {
  final time = scheduledAt.toLocal();
  final date = '${time.day}/${time.month}/${time.year}';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return 'แผนนัดรับ dolp\n'
      'สินค้า: $productTitle\n'
      'นัดกับ: $partnerName\n'
      'สถานที่: $placeLabel\n'
      'เวลา: $date $hour:$minute';
}

Future<void> shareMeetupAgreement({
  required MeetupAgreement agreement,
  required String partnerName,
  required String productTitle,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      text: meetupPlanText(
        productTitle: productTitle,
        partnerName: partnerName,
        placeLabel: agreement.placeLabel,
        scheduledAt: agreement.scheduledAt,
      ),
    ),
  );
}

Future<void> shareOrderMeetupPlan(AppState appState, OrderModel order) async {
  final otherUserId = appState.currentUser.id == order.buyerId
      ? order.sellerId
      : order.buyerId;
  final partner = appState.userById(otherUserId);
  final title = order.items.map((item) => item.title).join(', ');
  final place = order.agreedPlaceLabel ??
      (order.pickupType == PickupType.sellerHome
          ? 'บ้านผู้ขาย'
          : 'ยังไม่ได้ระบุสถานที่');
  await SharePlus.instance.share(
    ShareParams(
      text: meetupPlanText(
        productTitle: title,
        partnerName: partner?.name ?? 'คู่ค้า',
        placeLabel: place,
        scheduledAt: order.agreedTime ?? order.createdAt,
      ),
    ),
  );
}
