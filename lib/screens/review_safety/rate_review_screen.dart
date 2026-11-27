import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class RateReviewScreen extends StatefulWidget {
  final OrderModel order;

  const RateReviewScreen({super.key, required this.order});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _tags = const [
    'ตรงต่อเวลา',
    'สินค้าตรงตามที่แจ้ง',
    'สุภาพเป็นกันเอง',
    'ตอบแชทรวดเร็ว',
  ];
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final reviewerId = appState.currentUser.id;
    final revieweeId = reviewerId == widget.order.buyerId
        ? widget.order.sellerId
        : widget.order.buyerId;
    final reviewee = appState.userById(revieweeId);
    final revieweeName = reviewee?.displayName ?? revieweeId;

    return Scaffold(
      appBar: AppBar(title: const Text('ให้คะแนนและรีวิว')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.aquaPale,
              child: Text(
                revieweeName.isEmpty ? 'U' : revieweeName[0],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              revieweeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            Text(
              'คำสั่งซื้อ ${widget.order.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.graySecondary),
            ),
            const SizedBox(height: 20),
            Text(
              'คะแนน $_rating จาก 5',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  iconSize: 38,
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.warning,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'จุดเด่นที่ประทับใจ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ความคิดเห็น (ไม่เกิน 500 ตัวอักษร)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final error = appState.submitReview(
                  orderId: widget.order.id,
                  rating: _rating,
                  tags: _selectedTags.toList(),
                  comment: _commentController.text,
                );
                if (error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกรีวิวแล้ว')),
                );
                Navigator.pop(context);
              },
              child: const Text('ส่งรีวิว'),
            ),
          ],
        ),
      ),
    );
  }
}
