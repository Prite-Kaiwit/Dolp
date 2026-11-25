import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(title: const Text('รายชื่อที่บล็อก')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final users = appState.blockedUsersForCurrentUser();
          if (users.isEmpty)
            return const Center(child: Text('ไม่มีผู้ใช้ที่บล็อก'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.aquaPale,
                  child: Icon(Icons.person_outline, color: AppColors.deepNavy),
                ),
                title: Text(user.name),
                trailing: TextButton(
                  onPressed: () {
                    final error = appState.unblockUser(user.id);
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  child: const Text('ปลดบล็อก'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
