import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppState().isAdmin) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        navigator.pop();
        messenger?.showSnackBar(
          const SnackBar(content: Text('เฉพาะผู้ดูแลระบบเท่านั้น')),
        );
      }
    });
    return const Scaffold(
      body: Center(
        child: Text(
          'ไม่มีสิทธิ์เข้าถึงหน้านี้',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
