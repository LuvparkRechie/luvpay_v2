import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VerificationController extends GetxController {
  final _storage = const FlutterSecureStorage();

  final isVerified = false.obs;
  final isLoading = true.obs;

  static const _keyVerified = 'account_verified';

  @override
  void onInit() {
    super.onInit();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final value = await _storage.read(key: _keyVerified);
    isVerified.value = value == 'true';
    isLoading.value = false;
  }

  Future<void> markVerified() async {
    await _storage.write(key: _keyVerified, value: 'true');
    isVerified.value = true;
  }
}

/// Retry controller to prevent brute-force attempts
class RetryController extends GetxController {
  final RxInt retryCount = 0.obs;
  final int maxRetries = 3;
  final Duration cooldown = const Duration(minutes: 5);
  DateTime? lastFailed;

  bool canRetry() {
    if (lastFailed == null) return true;
    if (DateTime.now().difference(lastFailed!) >= cooldown) {
      retryCount.value = 0;
      lastFailed = null;
      return true;
    }
    return retryCount.value < maxRetries;
  }

  void recordFailure() {
    retryCount.value++;
    lastFailed = DateTime.now();
  }
}
