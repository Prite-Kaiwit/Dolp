import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/report.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการรายงานและปัญหา')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.reports.isEmpty) {
            return const Center(child: Text('ไม่มีรายงานที่ค้างอยู่'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appState.reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = appState.reports[index];
              final pending =
                  report.status == ReportStatus.pending ||
                  report.status == ReportStatus.investigating;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            report.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                          Text(
                            report.status.label,
                            style: TextStyle(
                              color: pending
                                  ? AppColors.warningDark
                                  : AppColors.successDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Text('ผู้ร้องเรียน: ${report.reporterName}'),
                      Text('ผู้ถูกรายงาน: ${report.reportedUserName}'),
                      if (report.orderId.isNotEmpty)
                        Text('คำสั่งซื้อ: ${report.orderId}'),
                      const SizedBox(height: 8),
                      Text(
                        'เหตุผล: ${report.reason}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(report.details),
                      if (pending) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _resolve(
                                context,
                                appState,
                                report.id,
                                ReportResolution.close,
                              ),
                              child: const Text('ปิดเรื่อง (กลับสถานะก่อนหน้า)'),
                            ),
                            if (report.orderId.isNotEmpty)
                              ElevatedButton(
                                onPressed: () => _resolve(
                                  context,
                                  appState,
                                  report.id,
                                  ReportResolution.cancelOrder,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('ยกเลิกออเดอร์'),
                              ),
                            IconButton(
                              tooltip: 'ระงับบัญชี',
                              onPressed: () => _resolve(
                                context,
                                appState,
                                report.id,
                                ReportResolution.accountSuspended,
                              ),
                              icon: const Icon(
                                Icons.person_off_outlined,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _resolve(
    BuildContext context,
    AppState appState,
    String reportId,
    ReportResolution resolution,
  ) {
    final error = appState.resolveDispute(reportId, resolution);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'อัปเดตสถานะรายงานแล้ว')),
    );
  }
}
