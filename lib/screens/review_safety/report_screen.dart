import 'package:flutter/material.dart';

import '../../constants/trust_safety_limits.dart';
import '../../models/report.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String? orderId;
  final String? productId;
  final String? targetUserId;
  final String? targetName;

  const ReportScreen({
    super.key,
    this.orderId,
    this.productId,
    this.targetUserId,
    this.targetName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportReason _selectedReason = ReportReason.other;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitReport() {
    final appState = AppState();
    String? error;
    if (widget.orderId case final orderId?) {
      final order = appState.orders
          .where((item) => item.id == orderId)
          .firstOrNull;
      if (order == null) {
        error = 'ไม่พบคำสั่งซื้อนี้';
      } else {
        error = appState.disputeOrder(
          orderId,
          _selectedReason.label,
          _detailsController.text,
        );
      }
    } else {
      final targetId = widget.targetUserId;
      if (targetId == null) {
        error = 'ไม่พบผู้ใช้ที่ต้องการรายงาน';
      } else {
        error = appState.submitReport(
          reportedUserId: targetId,
          productId: widget.productId,
          reason: _selectedReason,
          detail: _detailsController.text,
        );
      }
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(error),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งรายงานแล้ว ทีมงานจะตรวจสอบข้อมูล')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานปัญหา')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flag_outlined, color: AppColors.error, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'กรุณาเล่ารายละเอียดตามข้อเท็จจริง เพื่อให้ทีมงานตรวจสอบได้',
                      style: TextStyle(color: AppColors.deepNavy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.orderId != null
                  ? 'รายงานปัญหาคำสั่งซื้อ ${widget.orderId}'
                  : 'ผู้ใช้: ${widget.targetName ?? 'ผู้ใช้ในชุมชน'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'เหตุผลในการรายงาน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              initialValue: _selectedReason,
              items: ReportReason.values
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedReason = value);
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'รายละเอียดข้อเท็จจริง (บังคับ)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              maxLength: kReportDetailMaxLength,
              decoration: const InputDecoration(
                hintText: 'อธิบายเหตุการณ์หรือปัญหาที่พบ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('ส่งรายงาน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
