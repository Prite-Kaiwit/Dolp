import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();

  setUp(() => appState.loginAsGuest());

  test('phone login validates credentials and reads the account role', () {
    expect(
      appState.loginWithPhoneAndPassword('0800000001', 'wrong-password'),
      isFalse,
    );
    expect(appState.currentUser.role, UserRole.guest);

    expect(
      appState.loginWithPhoneAndPassword('0800000009', 'password123'),
      isTrue,
    );
    expect(appState.currentUser.role, UserRole.admin);
  });

  test('registration rejects duplicate phones and adds verified accounts', () {
    expect(
      appState.registerPhoneAccount(
        name: 'ชื่อซ้ำ',
        phone: '0800000001',
        password: 'password123',
      ),
      isFalse,
    );

    const phone = '0891234567';
    expect(
      appState.registerPhoneAccount(
        name: 'ผู้ใช้ใหม่',
        phone: phone,
        password: 'new-password',
      ),
      isTrue,
    );
    expect(appState.currentUser.phoneVerified, isTrue);

    appState.loginAsGuest();
    expect(appState.loginWithPhoneAndPassword(phone, 'new-password'), isTrue);
    expect(appState.currentUser.name, 'ผู้ใช้ใหม่');
  });
}
