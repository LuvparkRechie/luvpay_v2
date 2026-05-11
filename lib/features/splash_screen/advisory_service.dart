import 'package:flutter/foundation.dart';

import '../../core/network/http/api_keys.dart';
import '../../core/utils/functions/functions.dart';
import 'advisory_model.dart';

class SplashAdvisoryService {
  const SplashAdvisoryService();

  Future<List<SplashAdvisory>> fetchSplashAdvisories() async {
    try {
      final response = await Functions().requestHandler(
        apiKey: ApiKeys.getSplashAdvisories,
        method: "GET",
        timeout: const Duration(seconds: 8),
      );

      return SplashAdvisory.listFromResponse(response);
    } catch (error) {
      debugPrint("Splash advisory fetch failed: $error");
      return const [];
    }
  }
}
