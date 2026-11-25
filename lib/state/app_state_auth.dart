part of 'app_state.dart';

/// Phone sign-in, registration, guest sessions, and suspension checks.
extension AppStateAuth on AppState {
  bool isPhoneRegistered(String phone) =>
      _credentialsByPhone.containsKey(phone);

  bool loginWithPhoneAndPassword(String phone, String password) {
    final credential = _credentialsByPhone[phone];
    if (credential == null ||
        credential.passwordHash != _passwordDigest(credential.salt, password)) {
      lastLoginError = 'เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง';
      return false;
    }

    final userIndex = users.indexWhere((user) => user.id == credential.userId);
    if (userIndex == -1) {
      throw StateError(
        'Mock credential references a missing user: ${credential.userId}',
      );
    }

    if (users[userIndex].isSuspended) {
      lastLoginError = 'บัญชีนี้ถูกระงับ ติดต่อผู้ดูแล';
      return false;
    }
    currentUser = users[userIndex];
    lastLoginError = null;
    notifyListeners();
    return true;
  }

  bool registerPhoneAccount({
    required String name,
    required String phone,
    required String password,
  }) {
    if (_credentialsByPhone.containsKey(phone)) return false;

    final user = UserModel(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone,
      phoneVerified: true,
      role: UserRole.member,
    );
    users.add(user);
    _credentialsByPhone[phone] = _createCredential(user.id, password);
    currentUser = user;
    lastLoginError = null;
    notifyListeners();
    return true;
  }

  void updateCurrentUserArea({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    if (_expireSuspendedSession() != null) return;
    currentUser = currentUser.copyWith(
      homeLat: latitude,
      homeLng: longitude,
      homeLabel: label,
    );
    final userIndex = users.indexWhere((user) => user.id == currentUser.id);
    if (userIndex != -1) users[userIndex] = currentUser;
    final subscription = _areaAlertSubscriptions[currentUser.id];
    if (subscription != null) {
      _areaAlertSubscriptions[currentUser.id] = subscription.copyWith(
        center: GeoLocation(latitude, longitude),
      );
    }
    notifyListeners();
  }

  void loginAsGuest() {
    currentUser = _guestUser();
    lastLoginError = null;
    notifyListeners();
    if (_initialized) unawaited(flush());
  }

  bool get isCurrentUserSuspended => currentUser.isSuspended;

  String? _expireSuspendedSession() {
    if (!isLoggedIn || !currentUser.isSuspended) return null;
    final reason = currentUser.suspensionReason ?? 'ติดต่อผู้ดูแลระบบ';
    loginAsGuest();
    return 'บัญชีนี้ถูกระงับ: $reason';
  }
}
