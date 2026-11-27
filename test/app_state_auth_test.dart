import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/auth/phone_auth_service.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();

  setUp(() => appState.loginAsGuest());

  test('verified phone signs in to its account and reads the role', () {
    expect(
      appState.signInVerifiedPhone('0899999999'),
      PhoneSignInResult.needsRegistration,
    );
    expect(appState.currentUser.role, UserRole.guest);

    expect(
      appState.signInVerifiedPhone('0800000009', authUid: 'uid-admin'),
      PhoneSignInResult.signedIn,
    );
    expect(appState.currentUser.role, UserRole.admin);
    expect(appState.currentUser.authUid, 'uid-admin');
    expect(appState.userById('admin_01')!.authUid, 'uid-admin');
  });

  test('suspended accounts cannot sign in', () {
    final index = appState.users.indexWhere((user) => user.id == 'user_02');
    final original = appState.users[index];
    appState.users[index] = original.copyWith(isSuspended: true);
    expect(
      appState.signInVerifiedPhone('0800000002'),
      PhoneSignInResult.suspended,
    );
    expect(appState.currentUser.role, UserRole.guest);
    appState.users[index] = original;
  });

  test('registration rejects duplicate phones and adds verified accounts', () {
    expect(
      appState.registerVerifiedPhone(name: 'ชื่อซ้ำ', phone: '0800000001'),
      isFalse,
    );

    const phone = '0891234567';
    expect(
      appState.registerVerifiedPhone(
        name: 'ผู้ใช้ใหม่',
        phone: phone,
        authUid: 'uid-new',
      ),
      isTrue,
    );
    expect(appState.currentUser.phoneVerified, isTrue);
    expect(appState.currentUser.authUid, 'uid-new');

    appState.loginAsGuest();
    expect(appState.signInVerifiedPhone(phone), PhoneSignInResult.signedIn);
    expect(appState.currentUser.name, 'ผู้ใช้ใหม่');
  });

  test('Thai numbers convert to international format', () {
    expect(toThaiE164('0812345678'), '+66812345678');
    expect(toThaiE164('081-234-5678'), '+66812345678');
    expect(toThaiE164('66812345678'), '+66812345678');
  });

  test('local phone auth accepts only its fixed code', () async {
    final service = LocalPhoneAuthService();
    final request = await service.sendCode('0812345678');
    await expectLater(
      service.verifyCode(request, '000000'),
      throwsA(isA<PhoneAuthFailure>()),
    );
    expect(await service.verifyCode(request, '123456'), isNotEmpty);
  });
}
