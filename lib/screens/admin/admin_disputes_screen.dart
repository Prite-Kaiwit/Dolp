import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class AdminDisputesScreen extends StatelessWidget {
  const AdminDisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการรายงาน & ข้อพิพาท Escrow'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 56, color: AppColors.success),
                  SizedBox(height: 12),
                  Text('ไม่มีข้อพิพาทหรือรายงานที่ค้างอยู่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appState.reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final report = appState.reports[index];
              return _buildReportCard(context, appState, report);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, AppState appState, ReportModel report) {
    final isPending = report.status == ReportStatus.pending || report.status == ReportStatus.investigating;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(report.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.deepNavy)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.error.withValues(alpha: 0.1) : AppColors.successPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending ? AppColors.error : AppColors.successDark,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Disputed parties
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.graySecondary),
                const SizedBox(width: 6),
                Text('ผู้ร้องเรียน: ${report.reporterName}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.gavel_outlined, size: 16, color: AppColors.error),
                const SizedBox(width: 6),
                Text('ผู้ถูกร้องเรียน: ${report.reportedUserName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
              ],
            ),
            if (report.amount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('ยอดเงิน Escrow ที่ถูกพักไว้: ฿${report.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successDark)),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Reason & Details
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grayBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เหตุผล: ${report.reason}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(report.details, style: const TextStyle(fontSize: 12, color: AppColors.deepNavy)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Admin Decision Actions
            if (isPending) ...[
              const Text('คำตัดสินของเจ้าหน้าที่แอดมิน (Admin Verdict):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.graySecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Refund buyer
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appState.resolveDispute(report.id, ReportStatus.refunded);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ตัดสิน: คืนเงินให้ผู้ซื้อเรียบร้อย')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('คืนเงินผู้ซื้อ', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Release to seller
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appState.resolveDispute(report.id, ReportStatus.released);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ตัดสิน: ปล่อยเงินให้ผู้ขายเรียบร้อย')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('ปล่อยเงินผู้ขาย', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Suspend account
                  IconButton(
                    icon: const Icon(Icons.block_flipped, color: AppColors.error),
                    tooltip: 'ระงับบัญชีผู้กระทำผิด',
                    onPressed: () {
                      appState.resolveDispute(report.id, ReportStatus.accountSuspended);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ระงับบัญชีผู้ใช้ที่ฉ้อโกงเรียบร้อย')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
