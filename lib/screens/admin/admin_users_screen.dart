import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_route_guard.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    if (!appState.isAdmin) {
      return const AdminRouteGuard(child: SizedBox.shrink());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการผู้ใช้')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final result = appState.adminUsers(query: _searchController.text);
          if (!result.isSuccess) {
            return Center(
              child: Text(result.error ?? 'โหลดข้อมูลผู้ใช้ไม่ได้'),
            );
          }
          final users = result.value!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ค้นหาด้วยชื่อหรือเบอร์โทร',
                  ),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('ไม่พบผู้ใช้'))
                    : ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _buildUserTile(context, appState, users[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    AppState appState,
    UserModel user,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isSuspended
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.aquaPale,
        child: Icon(
          user.isSuspended ? Icons.person_off_outlined : Icons.person_outline,
          color: user.isSuspended ? AppColors.error : AppColors.deepNavy,
        ),
      ),
      title: Text(user.name),
      subtitle: Text(
        [
          if (user.phone.isNotEmpty) user.phone,
          user.role.name,
          if (user.isSuspended) 'ระงับ: ${user.suspensionReason ?? ''}',
        ].join(' · '),
      ),
      trailing: user.role == UserRole.admin
          ? const Text('แอดมิน')
          : TextButton(
              onPressed: () => user.isSuspended
                  ? _unsuspend(context, appState, user.id)
                  : _suspend(context, appState, user),
              child: Text(user.isSuspended ? 'ปลดระงับ' : 'ระงับ'),
            ),
    );
  }

  Future<void> _suspend(
    BuildContext context,
    AppState appState,
    UserModel user,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ระงับบัญชี ${user.name}'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'เหตุผลที่ต้องบันทึก'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('กลับ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ยืนยันระงับ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    final error = appState.suspendUser(user.id, reason);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'ระงับบัญชีแล้ว')));
  }

  void _unsuspend(BuildContext context, AppState appState, String userId) {
    final error = appState.unsuspendUser(userId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'ปลดระงับบัญชีแล้ว')));
  }
}
