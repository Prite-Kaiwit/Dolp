import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

Future<void> showSafetyTipsSheet(
  BuildContext context, {
  bool force = false,
}) async {
  final appState = AppState();
  if (!force && !appState.shouldShowSafetyTips) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'คำแนะนำก่อนนัดรับ',
            style: TextStyle(
              color: AppColors.deepNavy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final tip in const [
            'นัดในสถานที่สาธารณะและช่วงกลางวันเมื่อทำได้',
            'ชวนเพื่อนไปด้วย และแจ้งคนใกล้ตัวว่าจะไปที่ไหน',
            'ตรวจสินค้าให้เรียบร้อยก่อนชำระเงิน',
            'ไม่โอนก่อนเห็นสินค้า หากยังไม่มั่นใจ',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.oceanBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                appState.acknowledgeSafetyTips();
                Navigator.pop(sheetContext);
              },
              child: const Text('รับทราบ'),
            ),
          ),
        ],
      ),
    ),
  );
}
