import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Sends and checks SMS one-time codes for a Thai phone number.
abstract interface class PhoneAuthService {
  /// Sends a code to [localPhone] (format `0XXXXXXXXX`).
  /// Throws [PhoneAuthFailure] when sending fails.
  Future<PhoneCodeRequest> sendCode(String localPhone);

  /// Checks [code] and returns the signed-in Firebase user ID.
  /// Throws [PhoneAuthFailure] when the code is wrong or expired.
  Future<String> verifyCode(PhoneCodeRequest request, String code);

  /// Ends the phone session. The app then signs in anonymously again so
  /// guests can still browse.
  Future<void> signOut();
}

class PhoneCodeRequest {
  PhoneCodeRequest({
    required this.localPhone,
    this.verificationId,
    this.confirmation,
    this.resendToken,
    this.autoVerifiedUid,
  });

  final String localPhone;
  final String? verificationId;
  final ConfirmationResult? confirmation;
  final int? resendToken;

  /// Set when Android read the SMS itself and already signed the user in.
  final String? autoVerifiedUid;
}

class PhoneAuthFailure implements Exception {
  const PhoneAuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// `0812345678` -> `+66812345678`.
String toThaiE164(String localPhone) {
  final digits = localPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('66')) return '+$digits';
  if (digits.startsWith('0')) return '+66${digits.substring(1)}';
  return '+66$digits';
}

class FirebasePhoneAuthService implements PhoneAuthService {
  FirebasePhoneAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<PhoneCodeRequest> sendCode(String localPhone) async {
    final phone = toThaiE164(localPhone);
    try {
      if (kIsWeb) {
        // Web shows an invisible reCAPTCHA check before sending.
        final confirmation = await _auth.signInWithPhoneNumber(phone);
        return PhoneCodeRequest(
          localPhone: localPhone,
          confirmation: confirmation,
        );
      }
      final completer = Completer<PhoneCodeRequest>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (completer.isCompleted) return;
          try {
            final result = await _auth.signInWithCredential(credential);
            completer.complete(
              PhoneCodeRequest(
                localPhone: localPhone,
                autoVerifiedUid: result.user!.uid,
              ),
            );
          } on FirebaseAuthException catch (error) {
            completer.completeError(_failure(error));
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) completer.completeError(_failure(error));
        },
        codeSent: (verificationId, resendToken) {
          if (completer.isCompleted) return;
          completer.complete(
            PhoneCodeRequest(
              localPhone: localPhone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return completer.future;
    } on FirebaseAuthException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<String> verifyCode(PhoneCodeRequest request, String code) async {
    if (request.autoVerifiedUid case final uid?) return uid;
    try {
      final UserCredential result;
      if (request.confirmation case final confirmation?) {
        result = await confirmation.confirm(code);
      } else {
        result = await _auth.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: request.verificationId!,
            smsCode: code,
          ),
        );
      }
      return result.user!.uid;
    } on FirebaseAuthException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  static PhoneAuthFailure _failure(FirebaseAuthException error) {
    debugPrint('Phone auth failed: ${error.code} ${error.message}');
    return PhoneAuthFailure(switch (error.code) {
      'invalid-verification-code' => 'รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
      'session-expired' || 'code-expired' => 'รหัส OTP หมดอายุ กรุณาขอรหัสใหม่',
      'invalid-phone-number' => 'เบอร์โทรศัพท์ไม่ถูกต้อง',
      'too-many-requests' => 'ขอรหัสบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่',
      'quota-exceeded' => 'ระบบส่ง SMS เกินโควต้า กรุณาลองใหม่ภายหลัง',
      'operation-not-allowed' => 'ยังไม่ได้เปิดการเข้าสู่ระบบด้วยเบอร์โทร',
      'billing-not-enabled' =>
        'ส่ง SMS จริงไม่ได้ในแพ็กเกจฟรี ใช้เบอร์ทดสอบแทน',
      'network-request-failed' => 'เชื่อมต่ออินเทอร์เน็ตไม่ได้',
      _ => 'ส่งหรือตรวจรหัส OTP ไม่สำเร็จ (${error.code})',
    });
  }
}

/// Offline stand-in used by tests and by builds without Firebase. Accepts
/// only the fixed code [code]; no SMS is sent.
class LocalPhoneAuthService implements PhoneAuthService {
  LocalPhoneAuthService({this.code = '123456'});

  final String code;

  @override
  Future<PhoneCodeRequest> sendCode(String localPhone) async =>
      PhoneCodeRequest(localPhone: localPhone);

  @override
  Future<String> verifyCode(PhoneCodeRequest request, String code) async {
    if (code != this.code) {
      throw const PhoneAuthFailure('รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
    }
    return 'local_${request.localPhone}';
  }

  @override
  Future<void> signOut() async {}
}
