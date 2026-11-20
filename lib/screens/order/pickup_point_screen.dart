// This screen still reads the legacy pickupPoint and zone fields pending
// the meetup flow and suggested-spot UI migration.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/pickup_point.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'payment_screen.dart';

class PickupPointScreen extends StatefulWidget {
  final ProductModel product;

  const PickupPointScreen({super.key, required this.product});

  @override
  State<PickupPointScreen> createState() => _PickupPointScreenState();
}

class _PickupPointScreenState extends State<PickupPointScreen> {
  late PickupPointModel _selectedPoint;
  String _selectedTimeSlot = 'วันนี้ 17:00 - 18:00 น.';
  final TextEditingController _noteController = TextEditingController();

  final List<String> _timeSlots = [
    'วันนี้ 12:00 - 13:00 น. (พักเที่ยง)',
    'วันนี้ 17:00 - 18:00 น. (หลังเลิกเรียน)',
    'พรุ่งนี้ 12:00 - 13:00 น. (พักเที่ยง)',
    'พรุ่งนี้ 16:30 - 17:30 น.',
    'วันเสาร์ 10:00 - 12:00 น.',
  ];

  @override
  void initState() {
    super.initState();
    final points = AppState().pickupPoints;
    _selectedPoint = points.firstWhere(
      (p) => p.name == widget.product.pickupPoint,
      orElse: () => points.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกจุดนัดรับ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grayLine),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.pinkPale,
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.type == ListingType.donate
                                ? 'ส่งต่อฟรี (ไม่มีค่าใช้จ่าย)'
                                : 'ยอดชำระ: ฿${widget.product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.product.type == ListingType.donate
                                  ? AppColors.greenDark
                                  : AppColors.pinkPrimary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'ผู้ขาย: ${widget.product.sellerName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.graySecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Suggested meeting points header.
              const Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    color: AppColors.greenPrimary,
                    size: 22,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'จุดนัดรับสินค้า',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'เลือกสถานที่สาธารณะที่สะดวก แล้วตกลงรายละเอียดกับผู้ขาย',
                style: TextStyle(fontSize: 12, color: AppColors.graySecondary),
              ),
              const SizedBox(height: 14),

              // List of points (Radio selectable)
              ...appState.pickupPoints.map((point) {
                final isSelected = _selectedPoint.id == point.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPoint = point),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.greenPale : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.greenPrimary
                            : AppColors.grayLine,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? AppColors.greenPrimary
                              : AppColors.graySecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    point.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppColors.greenDark
                                          : AppColors.inkText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.grayBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      point.zone,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.graySecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                point.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.graySecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: AppColors.graySecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'เวลาให้บริการ: ${point.openHours}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.graySecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Time selection
              const Text(
                'ช่วงเวลาที่สะดวกนัดรับ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grayLine),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTimeSlot,
                    items: _timeSlots
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeSlot = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note to seller
              const Text(
                'ข้อความถึงผู้ขาย (สถานที่นัดเจาะจง / เสื้อที่ใส่)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText:
                      'เช่น สวมเสื้อสีขาว รอที่โต๊ะม้าหินอ่อนฝั่งทิศเหนือ',
                ),
              ),
              const SizedBox(height: 32),

              // Continue to Payment CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          product: widget.product,
                          pickupPoint: _selectedPoint.name,
                          scheduledTime: _selectedTimeSlot,
                          note: _noteController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    widget.product.type == ListingType.donate
                        ? 'ยืนยันการนัดรับฟรี'
                        : 'ถัดไป: สรุปการชำระเงิน',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
