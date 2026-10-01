import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';
import '../../state/app_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Pre-fill demo OTP
    _otpControllers[0].text = '1';
    _otpControllers[1].text = '2';
    _otpControllers[2].text = '3';
    _otpControllers[3].text = '4';
    _otpControllers[4].text = '5';
    _otpControllers[5].text = '6';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันอีเมลมหาวิทยาลัย'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.pinkPale,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ตรวจสอบกล่องข้อความของคุณ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.inkText),
              ),
              const SizedBox(height: 8),
              Text(
                'ระบบได้ส่งรหัสยืนยัน 6 หลัก (OTP) ไปยัง',
                style: TextStyle(fontSize: 14, color: AppColors.graySecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
              ),
              const SizedBox(height: 32),

              // OTP 6 input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.inkText),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.grayBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.grayLine),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.pinkPrimary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend code timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ไม่ได้รับรหัส? ', style: TextStyle(color: AppColors.graySecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ส่งรหัส OTP ใหม่อีกครั้งเรียบร้อยแล้ว')),
                      );
                    },
                    child: const Text('ส่งรหัสอีกครั้ง (Resend)', style: TextStyle(color: AppColors.pinkPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const Spacer(),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    AppState().loginAsMember();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ยืนยันตัวตนสำเร็จ! ยินดีต้อนรับสู่ มอ.Market'),
                        backgroundColor: AppColors.greenPrimary,
                      ),
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('ยืนยันและเข้าสู่ระบบ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
