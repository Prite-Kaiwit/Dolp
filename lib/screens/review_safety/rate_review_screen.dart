import 'package:flutter/material.dart';
import '../../models/order.dart';
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

  final List<String> _tags = [
    'ตรงต่อเวลามาก',
    'สินค้าสภาพดีตรงปก',
    'สุภาพเป็นกันเอง',
    'ตอบแชทรวดเร็ว',
    'แนะนำจุดนัดรับสะดวก',
  ];
  final Set<String> _selectedTags = {'ตรงต่อเวลามาก', 'สินค้าสภาพดีตรงปก'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ให้คะแนนและรีวิวผู้ขาย'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Seller avatar & name
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.pinkPale,
                child: Text(
                  widget.order.sellerName.isNotEmpty ? widget.order.sellerName[0] : 'S',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.order.sellerName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.inkText),
              ),
              Text(
                'คำสั่งซื้อ: ${widget.order.productTitle}',
                style: const TextStyle(fontSize: 13, color: AppColors.graySecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Star Rating
              const Text('ระดับความพึงพอใจในการทำรายการ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              Text(
                _getRatingLabel(_rating),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.pinkDark),
              ),
              const SizedBox(height: 24),

              // Feedback Tags
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('จุดเด่นที่ประทับใจ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.pinkPale,
                    backgroundColor: AppColors.grayBg,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.pinkDark : AppColors.inkText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.pinkPrimary : AppColors.grayLine,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Comment field
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('เขียนความคิดเห็นเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'แชร์ประสบการณ์การซื้อขาย และการนัดรับสินค้า ณ จุดนัดรับใน มอ....',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Review CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ขอบคุณสำหรับการรีวิว! คะแนนของคุณจะช่วยสร้างสังคม มอ.Market ที่น่าอยู่และปลอดภัย'),
                        backgroundColor: AppColors.greenPrimary,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('ส่งคะแนนรีวิว', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 5:
        return 'ยอดเยี่ยมมาก ⭐⭐⭐⭐⭐';
      case 4:
        return 'ดีมาก ⭐⭐⭐⭐';
      case 3:
        return 'ปานกลาง ⭐⭐⭐';
      case 2:
        return 'ควรปรับปรุง ⭐⭐';
      default:
        return 'ไม่ประทับใจ ⭐';
    }
  }
}
