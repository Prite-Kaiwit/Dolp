import 'package:flutter/material.dart';

import '../../models/report.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานของฉัน')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final reports =
              appState.reports
                  .where(
                    (report) => report.reporterId == appState.currentUser.id,
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (reports.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายงาน'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ReportCard(
              report: reports[index],
              reportedUserName:
                  appState.userById(reports[index].reportedUserId)?.displayName ??
                  'ผู้ใช้ที่ไม่พบในระบบ',
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final String reportedUserName;

  const _ReportCard({required this.report, required this.reportedUserName});

  @override
  Widget build(BuildContext context) {
    final isOpen = report.status == ReportStatus.open;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.reason.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                ),
                Text(
                  isOpen ? 'รอตรวจสอบ' : 'ปิดแล้ว',
                  style: TextStyle(
                    color: isOpen
                        ? AppColors.warningDark
                        : AppColors.successDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text('ผู้ถูกรายงาน: $reportedUserName'),
            Text(report.detail),
            if (report.adminNote != null && report.adminNote!.isNotEmpty) ...[
              const Divider(),
              Text(
                'บันทึกจากทีมงาน: ${report.adminNote}',
                style: const TextStyle(color: AppColors.graySecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
