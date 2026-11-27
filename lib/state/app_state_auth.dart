part of 'app_state.dart';

/// Result of signing in with a phone number whose OTP has been verified.
enum PhoneSignInResult { signedIn, needsRegistration, suspended }

/// Phone OTP sign-in, registration, guest sessions, and suspension checks.
extension AppStateAuth on AppState {
  bool isPhoneRegistered(String phone) =>
      users.any((user) => user.phone == phone);

  /// Signs in the account that owns [phone], after its OTP was verified by
  /// [phoneAuth]. [authUid] is the Firebase user ID for that phone.
  PhoneSignInResult signInVerifiedPhone(String phone, {String authUid = ''}) {
    final userIndex = users.indexWhere((user) => user.phone == phone);
    if (userIndex == -1) {
      lastLoginError = 'ยังไม่มีบัญชีสำหรับเบอร์นี้ กรุณาสมัครสมาชิก';
      return PhoneSignInResult.needsRegistration;
    }
    if (users[userIndex].isSuspended) {
      lastLoginError = 'บัญชีนี้ถูกระงับ ติดต่อผู้ดูแล';
      return PhoneSignInResult.suspended;
    }
    var user = users[userIndex];
    if (!user.phoneVerified ||
        (authUid.isNotEmpty && user.authUid != authUid)) {
      user = user.copyWith(
        phoneVerified: true,
        authUid: authUid.isEmpty ? null : authUid,
      );
      users[userIndex] = user;
    }
    currentUser = user;
    lastLoginError = null;
    notifyListeners();
    return PhoneSignInResult.signedIn;
  }

  /// Creates an account for [phone] after its OTP was verified.
  /// Returns false when the phone already has an account.
  bool registerVerifiedPhone({
    required String name,
    required String phone,
    String authUid = '',
  }) {
    if (isPhoneRegistered(phone)) return false;

    final user = UserModel(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone,
      phoneVerified: true,
      role: UserRole.member,
      authUid: authUid,
    );
    users.add(user);
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
    final wasLoggedIn = isLoggedIn;
    currentUser = _guestUser();
    lastLoginError = null;
    notifyListeners();
    if (_initialized) unawaited(flush());
    if (wasLoggedIn) {
      unawaited(
        phoneAuth.signOut().catchError(
          (Object error) => debugPrint('Phone sign-out failed: $error'),
        ),
      );
    }
  }

  bool get isCurrentUserSuspended => currentUser.isSuspended;

  String? _expireSuspendedSession() {
    if (!isLoggedIn || !currentUser.isSuspended) return null;
    final reason = currentUser.suspensionReason ?? 'ติดต่อผู้ดูแลระบบ';
    loginAsGuest();
    return 'บัญชีนี้ถูกระงับ: $reason';
  }
}
