import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/brand_logo.dart';
import '../main_navigation_screen.dart';
import 'location_permission_screen.dart';
import 'phone_otp_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  void _requestOtp() {
    final phone = _phoneController.text.trim();
    String? error;
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      error = 'กรุณากรอกเบอร์โทร 10 หลักขึ้นต้นด้วย 0';
    } else if (!AppState().isPhoneRegistered(phone)) {
      error = 'ยังไม่มีบัญชีสำหรับเบอร์นี้ กรุณาลงทะเบียนใหม่';
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhoneOtpScreen(phone: phone)),
    );
  }

  /// Debug builds only: signs in to a seed account without an SMS code.
  void _debugLogin(String phone) {
    if (AppState().signInVerifiedPhone(phone) != PhoneSignInResult.signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppState().lastLoginError ?? 'เข้าสู่ระบบไม่สำเร็จ'),
        ),
      );
      return;
    }
    final user = AppState().currentUser;
    final nextScreen =
        user.homeLat == null || user.homeLng == null || user.homeLabel.isEmpty
        ? const LocationPermissionScreen()
        : const MainNavigationScreen();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Brand Logo & Title
              Center(
                child: Column(
                  children: [
                    const BrandLogo(size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'เข้าสู่ระบบด้วยเบอร์โทรศัพท์',
                      style: TextStyle(
                        color: AppColors.graySecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'เบอร์โทรศัพท์',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '08XXXXXXXX',
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'เราจะส่งรหัส OTP 6 หลักทาง SMS เพื่อยืนยันตัวตน',
                style: TextStyle(color: AppColors.graySecondary, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _requestOtp,
                  child: const Text(
                    'ขอรหัส OTP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (kDebugMode)
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
                      const Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: AppColors.oceanBlue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'บัญชีตัวอย่างสำหรับทดสอบ (Debug only):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _debugLogin('0800000001'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: const BorderSide(
                                  color: AppColors.oceanBlue,
                                ),
                              ),
                              child: const Text(
                                'สมาชิกตัวอย่าง',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _debugLogin('0800000009'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: const BorderSide(
                                  color: AppColors.successDark,
                                ),
                                foregroundColor: AppColors.successDark,
                              ),
                              child: const Text(
                                'แอดมิน / Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ยังไม่มีบัญชี? ',
                    style: TextStyle(
                      color: AppColors.graySecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'ลงทะเบียนใหม่',
                      style: TextStyle(
                        color: AppColors.oceanBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
