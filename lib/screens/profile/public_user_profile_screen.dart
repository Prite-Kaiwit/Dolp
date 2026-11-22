import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

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
        final reviews = appState.reviewsForUser(user.id).take(5).toList();
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
