import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'escrow_status_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ProductModel product;
  final String pickupPoint;
  final String scheduledTime;
  final String note;

  const PaymentScreen({
    super.key,
    required this.product,
    required this.pickupPoint,
    required this.scheduledTime,
    this.note = '',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'PromptPay';
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final order = AppState().createOrder(
      product: widget.product,
      pickupPoint: widget.pickupPoint,
      scheduledTime: widget.scheduledTime,
      paymentMethod: _selectedMethod,
      note: widget.note,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EscrowStatusScreen(orderId: order.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงิน & พักเงิน (Escrow)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Escrow Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.greenLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: AppColors.greenPrimary, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เงินของคุณจะได้รับการพักไว้ในระบบ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.greenDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ผู้ขายจะได้รับเงินเมื่อคุณได้ตรวจรับสินค้าและกดยืนยันด้วยตนเองเท่านั้น',
                            style: TextStyle(fontSize: 11, color: AppColors.inkText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grayLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('สรุปรายการคำสั่งซื้อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                        Text('฿${widget.product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ค่าธรรมเนียมคุ้มครอง Escrow', style: TextStyle(fontSize: 12, color: AppColors.graySecondary)),
                        Text('ฟรี (มหาวิทยาลัยสนับสนุน)', style: TextStyle(fontSize: 12, color: AppColors.greenPrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ยอดชำระสุทธิ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.inkText)),
                        Text(
                          '฿${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method Choices
              const Text('เลือกช่องทางชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              // PromptPay Option
              _buildPaymentOption(
                title: 'พร้อมเพย์ (PromptPay QR Code)',
                subtitle: 'สแกนจ่ายผ่านแอปธนาคารทุกธนาคาร ยอดเข้าสู่ Escrow อัตโนมัติ',
                icon: Icons.qr_code_scanner_rounded,
                value: 'PromptPay',
              ),
              const SizedBox(height: 10),

              // Mobile Banking Option
              _buildPaymentOption(
                title: 'Mobile Banking (โอนผ่านบัญชีกลาง มอ.)',
                subtitle: 'ธนาคารไทยพาณิชย์ / กสิกรไทย / กรุงไทย บัญชีกองทุนพัฒนานักศึกษา',
                icon: Icons.account_balance_rounded,
                value: 'Mobile Banking',
              ),
              const SizedBox(height: 24),

              // Simulated PromptPay QR Card
              if (_selectedMethod == 'PromptPay') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grayLine),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF103F64),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PromptPay',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('ม.อ. Market Escrow Hub', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Fake QR Code graphic
                      Container(
                        width: 170,
                        height: 170,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 110, color: Color(0xFF1E293B)),
                              Text(
                                '฿${widget.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.pinkPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'บันทึกภาพ QR Code หรือเปิดแอปธนาคารเพื่อสแกน',
                        style: TextStyle(fontSize: 11, color: AppColors.graySecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Confirm Payment Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('กำลังยืนยันการพักเงิน...'),
                          ],
                        )
                      : Text(
                          'ยืนยันชำระเงิน ฿${widget.product.price.toStringAsFixed(2)} (เข้า Escrow)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pinkPale.withValues(alpha: 0.5) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.pinkPrimary : AppColors.grayLine,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.pinkPrimary : AppColors.graySecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? AppColors.pinkPrimary : AppColors.inkText, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.pinkDark : AppColors.inkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.graySecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
