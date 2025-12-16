import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:smart_liveliness_detection/smart_liveliness_detection.dart';
import '../main.dart';
import 'verification_controller.dart';

class VerifyIdentityScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  VerifyIdentityScreen({super.key, required this.cameras});

  final VerificationController controller = Get.put(VerificationController());
  final RetryController retryController = Get.put(RetryController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Loading cameras or verification state
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // Already verified -> show success
      if (controller.isVerified.value) {
        return const _VerifiedSuccessScreen();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Your Identity'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 80),
              const SizedBox(height: 16),
              const Text(
                'We need to confirm you are a real person before completing your account setup.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showVerificationPrompt(context),
                  child: const Text('Start Verification'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showVerificationPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Verify Your Identity'),
            content: const Text(
              'Please follow the on-screen instructions and complete the challenges.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startVerification(context);
                },
                child: const Text('Start Verification'),
              ),
            ],
          ),
    );
  }

  void _startVerification(BuildContext context) {
    if (cameras.isEmpty) {
      Get.snackbar(
        'Error',
        'No cameras found. Please restart the app.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!retryController.canRetry()) {
      Get.snackbar(
        'Too Many Attempts',
        'Please wait 5 minutes before trying again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final livenessConfig = LivenessConfig(
      maxSessionDuration: const Duration(seconds: 45),
      challengeTypes: const [
        ChallengeType.blink,
        ChallengeType.turnLeft,
        ChallengeType.turnRight,
        ChallengeType.smile,
      ],
      alwaysIncludeBlink: true,
      numberOfRandomChallenges: 3,
      enableScreenGlareDetection: true,
      enableMotionCorrelationCheck: true,
    );

    final Widget successOverlay = Container(
      color: Colors.black.withOpacity(0.6),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 16),
            Text(
              'Verification Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LivenessDetectionScreen(
              cameras: cameras,
              config: livenessConfig,
              customSuccessOverlay: successOverlay,
              showStatusIndicators: true,
              onChallengeCompleted: (challenge) {
                String hint = '';
                switch (challenge) {
                  case ChallengeType.blink:
                    hint = "Blink your eyes";
                    break;
                  case ChallengeType.turnLeft:
                    hint = "Turn your head to the left";
                    break;
                  case ChallengeType.turnRight:
                    hint = "Turn your head to the right";
                    break;
                  case ChallengeType.smile:
                    hint = "Give a big smile";
                    break;
                  default:
                    hint = "";
                }
                if (hint.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(hint),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              onLivenessCompleted: (sessionId, success, metadata) async {
                Navigator.pop(context);

                if (success) {
                  await controller.markVerified();
                  Get.snackbar(
                    'Success',
                    'Verification completed',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  retryController.recordFailure();
                  Get.snackbar(
                    'Failed',
                    'Verification failed. Please try again.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
      ),
    );
  }
}

/// Optional success screen for already verified accounts
class _VerifiedSuccessScreen extends StatelessWidget {
  const _VerifiedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Account Verified',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('You can now access all features.'),
          ],
        ),
      ),
    );
  }
}
