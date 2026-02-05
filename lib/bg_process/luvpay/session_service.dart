import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../pages/routes/routes.dart';

class SessionService {
  SessionService._();

  static final _box = GetStorage();
  static Timer? _idleLockTimer;

  static const Duration idleLockAfter = Duration(seconds: 10);
  static const Duration forceLogoutAfter = Duration(seconds: 20);

  static DateTime _now() => DateTime.now();

  static void touchActivity() {
    final now = _now();
    _box.write('lastActiveAt', now.toIso8601String());
    _box.write('wasBackgrounded', false);
  }

  static void markBackgrounded() {
    _box.write('wasBackgrounded', true);
    _box.write('lastActiveAt', _now().toIso8601String());
    _idleLockTimer?.cancel();
  }

  static void startIdleTimer() {
    _idleLockTimer?.cancel();

    _idleLockTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final lastStr = _box.read('lastActiveAt') as String?;
      if (lastStr == null) return;

      final last = DateTime.parse(lastStr);
      final diff = _now().difference(last);

      if (diff >= forceLogoutAfter) {
        _idleLockTimer?.cancel();
        await forceLogout();
        return;
      }
      if (diff >= idleLockAfter && Get.currentRoute != Routes.lock) {
        await lockApp();
      }
    });
  }

  static Future<void> enforce() async {
    final lastStr = _box.read('lastActiveAt') as String?;
    if (lastStr == null) {
      touchActivity();
      startIdleTimer();
      return;
    }

    final last = DateTime.parse(lastStr);
    final diff = _now().difference(last);

    if (diff >= forceLogoutAfter) {
      await forceLogout();
      return;
    }

    final wasBg = _box.read('wasBackgrounded') == true;
    if (diff >= idleLockAfter || wasBg) {
      await lockApp();
    }

    touchActivity();
    startIdleTimer();
  }

  static Future<void> lockApp() async {
    if (Get.currentRoute == Routes.lock) return;
    Get.toNamed(Routes.lock);
  }

  static Future<void> forceLogout() async {
    _idleLockTimer?.cancel();

    // TODO: clear your auth/session keys here (token/user/etc.)
    // _box.remove('token');
    // _box.remove('refreshToken');
    // _box.remove('user');

    _box.remove('lastActiveAt');
    _box.remove('wasBackgrounded');

    Get.offAllNamed(Routes.login);
  }
}
