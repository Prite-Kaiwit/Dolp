import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/report.dart';
import '../../state/app_state.dart';
import '../../widgets/admin_route_guard.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    if (!appState.isAdmin) {
      return const AdminRouteGuard(child: SizedBox.shrink());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานและข้อพิพาท'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'รอตรวจ'),
            Tab(text: 'ปิดแล้ว'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final result = appState.adminReports();
          if (!result.isSuccess) {
            return Center(child: Text(result.error ?? 'โหลดรายงานไม่ได้'));
          }
          final reports = result.value!;
          return TabBarView(
            controller: _tabs,
            children: [
              _reportList(
                reports.where((report) => report.status == ReportStatus.open).toList(),
                appState,
              ),
              _reportList(
                reports.where((report) => report.status != ReportStatus.open).toList(),
                appState,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reportList(List<ReportModel> reports, AppState appState) {
    if (reports.isEmpty) return const Center(child: Text('ไม่มีรายงาน'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        final reporter = appState.userById(report.reporterId);
        final target = appState.userById(report.reportedUserId);
        final order = report.orderId == null
            ? null
            : appState.orders
                .where((item) => item.id == report.orderId)
                .firstOrNull;
        return Card(
          child: ListTile(
            title: Text(report.reason.label),
            subtitle: Text(
              '${report.id} · ${report.status.label}\n'
              '${reporter?.name ?? report.reporterId} → '
              '${target?.name ?? report.reportedUserId}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: report.status == ReportStatus.open
                ? () => _reviewReport(context, appState, report, order)
                : () => _showDetails(context, appState, report, order),
          ),
        );
      },
    );
  }

  Future<void> _reviewReport(
    BuildContext context,
    AppState appState,
    ReportModel report,
    OrderModel? order,
  ) async {
    final noteController = TextEditingController();
    var action = AdminReportAction.dismiss;
    final result = await showDialog<(AdminReportAction, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('ตรวจสอบ ${report.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reportDetails(appState, report, order),
                const SizedBox(height: 12),
                DropdownButtonFormField<AdminReportAction>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'การจัดการ'),
                  items: [
                    const DropdownMenuItem(
                      value: AdminReportAction.dismiss,
                      child: Text('ปิดเรื่อง ไม่พบความผิด'),
                    ),
                    const DropdownMenuItem(
                      value: AdminReportAction.suspendUser,
                      child: Text('ระงับบัญชีผู้ถูกรายงาน'),
                    ),
                    if (order != null &&
                        (order.status == OrderStatus.pending ||
                            order.status == OrderStatus.disputed))
                      const DropdownMenuItem(
                        value: AdminReportAction.cancelOrder,
                        child: Text('ยกเลิกออเดอร์'),
                      ),
                    if (order != null &&
                        (order.status == OrderStatus.pending ||
                            order.status == OrderStatus.disputed))
                      const DropdownMenuItem(
                        value: AdminReportAction.suspendAndCancel,
                        child: Text('ระงับบัญชีและยกเลิกออเดอร์'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => action = value);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: action == AdminReportAction.dismiss
                        ? 'บันทึกแอดมิน (ไม่บังคับ)'
                        : 'บันทึกแอดมิน (บังคับ)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('กลับ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                (action, noteController.text),
              ),
              child: const Text('บันทึกผล'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (result == null || !context.mounted) return;
    final error = appState.resolveReport(
      report.id,
      action: result.$1,
      adminNote: result.$2,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'บันทึกผลการตรวจสอบแล้ว')),
    );
  }

  void _showDetails(
    BuildContext context,
    AppState appState,
    ReportModel report,
    OrderModel? order,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.reason.label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reportDetails(appState, report, order),
              const SizedBox(height: 10),
              Text('สถานะ: ${report.status.label}'),
              if (report.adminId != null)
                Text('ผู้ดำเนินการ: ${appState.userById(report.adminId!)?.name ?? report.adminId}'),
              if (report.adminNote != null) Text('บันทึกแอดมิน: ${report.adminNote}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _reportDetails(
    AppState appState,
    ReportModel report,
    OrderModel? order,
  ) {
    final reporter = appState.userById(report.reporterId);
    final target = appState.userById(report.reportedUserId);
    final product = report.productId == null
        ? null
        : appState.products
            .where((item) => item.id == report.productId)
            .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ผู้รายงาน: ${reporter?.name ?? report.reporterId}'),
        Text('ผู้ถูกรายงาน: ${target?.name ?? report.reportedUserId}'),
        Text('เหตุผล: ${report.reason.label}'),
        const SizedBox(height: 6),
        Text(report.detail),
        if (order != null) ...[
          const Divider(),
          Text('ออเดอร์: ${order.id} · ${order.status.title}'),
          for (final event in order.events)
            Text(
              '${event.at.toLocal()} · ${appState.userById(event.actorId)?.name ?? event.actorId} · ${event.status.title}',
              style: const TextStyle(fontSize: 11),
            ),
        ],
        if (product != null) Text('สินค้า: ${product.title} (${product.id})'),
      ],
    );
  }
}
