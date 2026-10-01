import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../main_navigation_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'karn.r@mou.ac.th');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  void _handleLogin() {
    AppState().loginAsMember();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ'),
      ),
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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.pinkPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('🛍️', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'มอ.Market',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pinkPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'เข้าสู่ระบบด้วยอีเมลมหาวิทยาลัย',
                      style: TextStyle(color: AppColors.graySecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Email Field
              const Text('อีเมลมหาวิทยาลัย (@mou.ac.th)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'student@mou.ac.th',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text('รหัสผ่าน', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.pinkPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.graySecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                      const SnackBar(content: Text('ระบบได้ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณ')),
                    );
                  },
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(color: AppColors.pinkPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
                  child: const Text('เข้าสู่ระบบ (Member Login)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // Fast Demo Roles Section (Member, Admin, Guest)
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
                        Icon(Icons.touch_app_rounded, size: 16, color: AppColors.pinkPrimary),
                        SizedBox(width: 6),
                        Text(
                          'ทดสอบระบบด้วยบทบาทต่าง ๆ (Quick Demo Switch):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.inkText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AppState().loginAsMember();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.pinkPrimary),
                            ),
                            child: const Text('นักศึกษา / Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AppState().loginAsAdmin();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.greenDark),
                              foregroundColor: AppColors.greenDark,
                            ),
                            child: const Text('แอดมิน / Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  const Text('ยังไม่มีบัญชี? ', style: TextStyle(color: AppColors.graySecondary, fontSize: 14)),
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
