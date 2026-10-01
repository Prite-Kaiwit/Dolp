import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'student@mou.ac.th');
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedFaculty = 'คณะวิศวกรรมศาสตร์';
  bool _agreedToTerms = true;
  bool _obscurePassword = true;

  final List<String> _faculties = [
    'คณะวิศวกรรมศาสตร์',
    'คณะวิทยาศาสตร์',
    'คณะแพทยศาสตร์',
    'คณะพยาบาลศาสตร์',
    'คณะวิทยาการจัดการ',
    'คณะศิลปศาสตร์',
    'คณะศึกษาศาสตร์',
    'คณะนิติศาสตร์',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenPale,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.greenLight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.greenPrimary, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'เฉพาะนักศึกษาและบุคลากรมหาวิทยาลัยเท่านั้น กรุณาใช้อีเมลสถาบัน (@mou.ac.th) เพื่อความปลอดภัยของระบบ',
                        style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name
              const Text('ชื่อ - นามสกุล', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'เช่น นายสมชาย ใจดี',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // University Email
              const Text('อีเมลมหาวิทยาลัย (@mou.ac.th)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'student.id@mou.ac.th',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // Student ID & Faculty
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('รหัสนักศึกษา', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _studentIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '6610110001',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.pinkPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Faculty Dropdown
              const Text('คณะ / หน่วยงาน', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
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
                    value: _selectedFaculty,
                    items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFaculty = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              const Text('รหัสผ่าน', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'อย่างน้อย 8 ตัวอักษร',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.pinkPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.graySecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              const Text('ยืนยันรหัสผ่าน', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  hintText: 'กรอกรหัสผ่านอีกครั้ง',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.pinkPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // Terms Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppColors.pinkPrimary,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'ฉันยอมรับข้อกำหนดการใช้งาน และนโยบายความปลอดภัยการซื้อขาย/ระบบพักเงิน (Escrow Protection) ภายในมหาวิทยาลัย',
                        style: TextStyle(fontSize: 12, color: AppColors.graySecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button -> Email Verification
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _agreedToTerms
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmailVerificationScreen(
                                email: _emailController.text.isNotEmpty
                                    ? _emailController.text
                                    : 'student@mou.ac.th',
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('ลงทะเบียนและรับรหัส OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
