import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class ReportScreen extends StatefulWidget {
  final String? orderId;
  final String? targetName;

  const ReportScreen({super.key, this.orderId, this.targetName});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedReason = 'สินค้าไม่ตรงกับที่ระบุ / ชำรุดเสียหาย';
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _targetNameController = TextEditingController();
  bool _attachedScreenshot = true;

  final List<String> _reasons = [
    'สินค้าไม่ตรงกับที่ระบุ / ชำรุดเสียหาย',
    'ไม่มาตามนัดหมาย',
    'ชักชวนให้โอนเงินก่อนรับสินค้า',
    'สินค้าลอกเลียนแบบ / ของปลอม / ผิดกฎหมาย',
    'ใช้คำหยาบคาย / คุกคามผ่านช่องแชท',
    'บัญชีผู้ใช้น่าสงสัย / สวมรอย',
  ];

  @override
  void initState() {
    super.initState();
    _targetNameController.text = widget.targetName ?? 'ผู้ใช้ในชุมชน';
  }

  void _submitReport() {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุรายละเอียดของปัญหา')),
      );
      return;
    }

    String? error;
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      // Order dispute
      error = AppState().disputeOrder(widget.orderId!, _selectedReason, details);
    } else {
      AppState().submitReport(
        reportedUser: _targetNameController.text.trim(),
        reason: _selectedReason,
        details: details,
      );
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ส่งรายงานแล้ว ทีมงานจะตรวจสอบข้อมูลที่ได้รับ'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานปัญหา & ข้อพิพาท')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Trust Banner
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
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.error,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ศูนย์ดูแลความปลอดภัย (Trust & Safety)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ระบุรายละเอียดและแนบข้อมูลที่เกี่ยวข้อง เพื่อให้ทีมงานตรวจสอบรายงานได้',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Target User
              const Text(
                'ผู้ใช้ที่ต้องการรายงาน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _targetNameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ),
              if (widget.orderId != null) ...[
                const SizedBox(height: 12),
                Text(
                  'เกี่ยวข้องกับคำสั่งซื้อ: ${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.graySecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Reason Radio / Dropdown
              const Text(
                'เหตุผลในการรายงาน',
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
                    value: _selectedReason,
                    items: _reasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Details
              const Text(
                'รายละเอียดข้อเท็จจริง',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'โปรดระบุรายละเอียด เช่น ความเสียหายของสินค้า, การไม่มาตามนัด, ข้อความชักชวนโอนนอกระบบ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Evidence attachment
              const Text(
                'แนบหลักฐาน (รูปถ่ายสินค้า / แคปหน้าจอแชท)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() => _attachedScreenshot = !_attachedScreenshot);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _attachedScreenshot
                        ? AppColors.successPale
                        : AppColors.grayBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _attachedScreenshot
                          ? AppColors.success
                          : AppColors.grayLine,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _attachedScreenshot
                            ? Icons.check_circle_rounded
                            : Icons.add_photo_alternate_outlined,
                        color: _attachedScreenshot
                            ? AppColors.success
                            : AppColors.graySecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _attachedScreenshot
                              ? 'แนบภาพหลักฐานเรียบร้อย (screenshot_proof.jpg)'
                              : 'แตะเพื่อแนบภาพหลักฐาน',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _attachedScreenshot
                                ? AppColors.successDark
                                : AppColors.graySecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text(
                    'ส่งรายงานให้ทีมงาน Admin ตรวจสอบ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
