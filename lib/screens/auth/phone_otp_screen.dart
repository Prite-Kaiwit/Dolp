import 'dart:async';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'location_permission_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String password;

  const PhoneOtpScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.password,
  });

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _countdownTimer;
  int _resendSeconds = 60;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown({bool notify = false}) {
    _countdownTimer?.cancel();
    if (notify) {
      setState(() => _resendSeconds = 60);
    } else {
      _resendSeconds = 60;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
      } else if (mounted) {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _resendCode() {
    if (_resendSeconds > 0) return;
    // TODO: Replace the mock resend action with an SMS provider.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งรหัส OTP ใหม่แล้ว (โหมดทดสอบ)')),
    );
    _startCountdown(notify: true);
  }

  void _verifyCode() {
    final code = _otpControllers.map((controller) => controller.text).join();
    if (code != '123456') {
      setState(() => _otpError = 'รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
      return;
    }

    final registered = AppState().registerPhoneAccount(
      name: widget.name,
      phone: widget.phone,
      password: widget.password,
    );
    if (!registered) {
      setState(() => _otpError = 'เบอร์โทรนี้มีบัญชีแล้ว กรุณาเข้าสู่ระบบ');
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันเบอร์โทรศัพท์')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.sms_outlined,
                size: 64,
                color: AppColors.pinkPrimary,
              ),
              const SizedBox(height: 20),
              const Text(
                'กรอกรหัสยืนยัน 6 หลัก',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ส่งรหัส OTP ไปยังเบอร์โทรศัพท์',
                style: TextStyle(fontSize: 14, color: AppColors.graySecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pinkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'รหัสทดสอบ: 123456',
                style: TextStyle(fontSize: 12, color: AppColors.graySecondary),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 54,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.grayBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _otpError = null);
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              if (_otpError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _otpError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: _resendSeconds == 0 ? _resendCode : null,
                child: Text(
                  _resendSeconds == 0
                      ? 'ส่งรหัสอีกครั้ง'
                      : 'ส่งรหัสอีกครั้งใน $_resendSeconds วินาที',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifyCode,
                  child: const Text('ยืนยันเบอร์โทรศัพท์'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
