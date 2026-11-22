import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/brand_logo.dart';
import '../main_navigation_screen.dart';
import 'location_permission_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '0800000001');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  void _handleLogin() {
    _login(_phoneController.text.trim(), _passwordController.text);
  }

  void _login(String phone, String password) {
    if (!AppState().loginWithPhoneAndPassword(phone, password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง')),
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
    _passwordController.dispose();
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
                    color: AppColors.pinkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text(
                'รหัสผ่าน',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่าน',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.pinkPrimary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.graySecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'กรุณาติดต่อศูนย์ช่วยเหลือเพื่อรีเซ็ตรหัสผ่าน',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(
                      color: AppColors.pinkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text(
                    'เข้าสู่ระบบ',
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
                            color: AppColors.pinkPrimary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'บัญชีตัวอย่างสำหรับทดสอบ (Debug only):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _login('0800000001', 'password123'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: const BorderSide(
                                  color: AppColors.pinkPrimary,
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
                              onPressed: () =>
                                  _login('0800000009', 'password123'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                side: const BorderSide(
                                  color: AppColors.greenDark,
                                ),
                                foregroundColor: AppColors.greenDark,
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
                        color: AppColors.pinkPrimary,
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
