import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'phone_otp_screen.dart';
import 'shop_setup_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  AccountType _accountType = AccountType.person;

  bool get _formIsValid {
    final phone = _phoneController.text.trim();
    return _nameController.text.trim().isNotEmpty &&
        RegExp(r'^0\d{9}$').hasMatch(phone) &&
        !AppState().isPhoneRegistered(phone) &&
        _agreedToTerms;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (_accountType == AccountType.person) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhoneOtpScreen(name: name, phone: phone),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (setupContext) => ShopSetupScreen(
          mode: ShopSetupMode.register,
          onSubmitted: (profile) => Navigator.push(
            setupContext,
            MaterialPageRoute(
              builder: (_) => PhoneOtpScreen(
                name: name,
                phone: phone,
                accountType: AccountType.shop,
                shop: profile,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard(AccountType type, String label, IconData icon) {
    final selected = _accountType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _accountType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.aquaPale : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.oceanBlue : AppColors.grayLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.oceanBlue),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                Row(
                  children: [
                    _typeCard(
                      AccountType.person,
                      'บุคคลทั่วไป',
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    _typeCard(
                      AccountType.shop,
                      'ร้านค้า',
                      Icons.storefront_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _accountType == AccountType.shop
                      ? 'ชื่อเจ้าของบัญชี'
                      : 'ชื่อที่แสดง',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
                            _continue();
                          }
                        : null,
                    child: Text(
                      _accountType == AccountType.shop
                          ? 'ถัดไป: ตั้งค่าร้าน'
                          : 'ลงทะเบียนและรับรหัส OTP',
                      style: const TextStyle(
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
