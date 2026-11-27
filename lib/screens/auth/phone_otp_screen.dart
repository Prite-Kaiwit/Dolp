import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/phone_auth_service.dart';
import '../../models/shop_profile.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';
import 'location_permission_screen.dart';

/// Sends an SMS code to [phone] and checks it. With [name] set this
/// registers a new account; without it, it signs in to an existing one.
class PhoneOtpScreen extends StatefulWidget {
  final String phone;
  final String? name;
  final AccountType accountType;
  final ShopProfile? shop;

  const PhoneOtpScreen({
    super.key,
    required this.phone,
    this.name,
    this.accountType = AccountType.person,
    this.shop,
  });

  bool get isRegistration => name != null;

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
  PhoneCodeRequest? _request;
  bool _sending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _otpError = null;
    });
    try {
      // A reCAPTCHA check left unanswered never completes, so give up
      // after a while and let the user ask for a new code.
      final request = await AppState().phoneAuth
          .sendCode(widget.phone)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw const PhoneAuthFailure(
              'ส่งรหัสไม่สำเร็จ กรุณากดส่งรหัสอีกครั้ง',
            ),
          );
      if (!mounted) return;
      setState(() {
        _request = request;
        _sending = false;
      });
      _startCountdown(notify: true);
      if (request.autoVerifiedUid != null) await _verifyCode();
    } on PhoneAuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resendSeconds = 0;
        _otpError = error.message;
      });
    }
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
    if (_resendSeconds > 0 || _sending) return;
    _sendCode();
  }

  Future<void> _verifyCode() async {
    final request = _request;
    if (request == null || _verifying) return;
    final code = _otpControllers.map((controller) => controller.text).join();
    if (request.autoVerifiedUid == null && code.length != 6) {
      setState(() => _otpError = 'กรุณากรอกรหัส OTP ให้ครบ 6 หลัก');
      return;
    }
    setState(() {
      _verifying = true;
      _otpError = null;
    });
    final String authUid;
    try {
      authUid = await AppState().phoneAuth.verifyCode(request, code);
    } on PhoneAuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _otpError = error.message;
        });
      }
      return;
    }
    if (!mounted) return;

    final state = AppState();
    if (widget.isRegistration) {
      final registered = state.registerVerifiedPhone(
        name: widget.name!,
        phone: widget.phone,
        authUid: authUid,
        accountType: widget.accountType,
        shop: widget.shop,
      );
      if (!registered) {
        setState(() {
          _verifying = false;
          _otpError = 'เบอร์โทรนี้มีบัญชีแล้ว กรุณาเข้าสู่ระบบ';
        });
        return;
      }
    } else {
      final result = state.signInVerifiedPhone(widget.phone, authUid: authUid);
      if (result != PhoneSignInResult.signedIn) {
        setState(() {
          _verifying = false;
          _otpError = state.lastLoginError;
        });
        return;
      }
    }

    final user = state.currentUser;
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
                color: AppColors.oceanBlue,
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
                  color: AppColors.oceanBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _sending ? 'กำลังส่งรหัส OTP...' : 'รหัสมีอายุ 5 นาที',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.graySecondary,
                ),
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
                onPressed: _resendSeconds == 0 && !_sending
                    ? _resendCode
                    : null,
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
                  onPressed: _request == null || _verifying
                      ? null
                      : _verifyCode,
                  child: _verifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          widget.isRegistration
                              ? 'ยืนยันและสมัครสมาชิก'
                              : 'ยืนยันและเข้าสู่ระบบ',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
