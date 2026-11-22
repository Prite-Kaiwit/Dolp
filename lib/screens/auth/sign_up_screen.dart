import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'phone_otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  bool get _formIsValid {
    final phone = _phoneController.text.trim();
    return _nameController.text.trim().isNotEmpty &&
        RegExp(r'^0\d{9}$').hasMatch(phone) &&
        !AppState().isPhoneRegistered(phone) &&
        _passwordController.text.length >= 8 &&
        _passwordController.text == _confirmPasswordController.text &&
        _agreedToTerms;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ชื่อที่แสดง',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'เช่น สมชาย ใจดี',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรุณากรอกชื่อที่แสดง'
                      : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  'เบอร์โทรศัพท์',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '08XXXXXXXX',
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
                      return 'กรุณากรอกเบอร์โทร 10 หลักขึ้นต้นด้วย 0';
                    }
                    if (AppState().isPhoneRegistered(phone)) {
                      return 'เบอร์โทรนี้มีบัญชีแล้ว กรุณาเข้าสู่ระบบ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'รหัสผ่าน',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) {
                    setState(() {});
                    _formKey.currentState?.validate();
                  },
                  decoration: InputDecoration(
                    hintText: 'อย่างน้อย 8 ตัวอักษร',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.oceanBlue,
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
                  validator: (value) => (value?.length ?? 0) < 8
                      ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'
                      : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  'ยืนยันรหัสผ่าน',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'กรอกรหัสผ่านอีกครั้ง',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'รหัสผ่านไม่ตรงกัน'
                      : null,
                ),
                const SizedBox(height: 16),

                // Terms Agreement Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'ฉันยอมรับข้อกำหนดการใช้งานและแนวทางซื้อขายอย่างระมัดระวัง',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.graySecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _formIsValid
                        ? () {
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhoneOtpScreen(
                                  name: _nameController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  password: _passwordController.text,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text(
                      'ลงทะเบียนและรับรหัส OTP',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
