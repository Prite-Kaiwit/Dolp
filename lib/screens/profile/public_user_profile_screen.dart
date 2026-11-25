import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../review_safety/report_screen.dart';

class PublicUserProfileScreen extends StatelessWidget {
  final String userId;

  const PublicUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.userById(userId);
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('โปรไฟล์ผู้ใช้')),
            body: const Center(child: Text('ไม่พบข้อมูลผู้ใช้นี้')),
          );
        }
        final reviews = appState.reviewsForUser(user.id).take(10).toList();
        final isOwnProfile = appState.currentUser.id == user.id;
        return Scaffold(
          appBar: AppBar(title: const Text('โปรไฟล์ผู้ใช้')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.aquaPale,
                child: Text(
                  user.name.isEmpty ? 'U' : user.name[0],
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    user.phoneVerified
                        ? Icons.verified
                        : Icons.verified_outlined,
                    size: 17,
                    color: user.phoneVerified
                        ? AppColors.success
                        : AppColors.graySecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    user.phoneVerified
                        ? 'ยืนยันเบอร์โทรศัพท์แล้ว'
                        : 'ยังไม่ยืนยันเบอร์โทรศัพท์',
                    style: const TextStyle(color: AppColors.graySecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileMetric(
                        label: 'คะแนนเฉลี่ย',
                        value: user.rating.toStringAsFixed(1),
                      ),
                      _ProfileMetric(
                        label: 'จำนวนรีวิว',
                        value: '${user.reviewCount}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'สมาชิกตั้งแต่ ${_joinedDate(user.createdAt)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.graySecondary),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.success,
                  ),
                  title: Text('${user.successfulDeals} รายการสำเร็จ'),
                ),
              ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ReportScreen(
                              targetUserId: user.id,
                              targetName: user.name,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: AppColors.error,
                        ),
                        label: const Text('รายงานผู้ใช้'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final blocked = appState.isBlocked(user.id);
                          final error = blocked
                              ? appState.unblockUser(user.id)
                              : appState.blockUser(user.id);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                        icon: const Icon(Icons.block_outlined),
                        label: Text(
                          appState.isBlocked(user.id) ? 'ปลดบล็อก' : 'บล็อก',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'รีวิวล่าสุด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'ยังไม่มีรีวิว',
                    style: TextStyle(color: AppColors.graySecondary),
                  ),
                )
              else
                ...reviews.map((review) {
                  final reviewer = appState.userById(review.reviewerId);
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Text(reviewer?.name ?? 'ผู้ใช้ชุมชน'),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 17,
                          ),
                          Text('${review.rating}'),
                        ],
                      ),
                      subtitle: Text(
                        review.comment.isEmpty
                            ? review.tags.join(' · ')
                            : review.comment,
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _joinedDate(DateTime value) {
    final date = value.toLocal();
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProfileMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.oceanBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.graySecondary)),
      ],
    );
  }
}
