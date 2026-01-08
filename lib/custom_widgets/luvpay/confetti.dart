import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CelebrationScreen extends StatefulWidget {
  /// Icon and color
  final IconData icon;
  final Color iconColor;

  /// Title and message
  final String title;
  final String message;

  /// Button text and optional callback
  final String buttonText;
  final VoidCallback? onButtonPressed;

  /// Confetti settings
  final bool showConfetti;
  final bool loopConfetti;
  final double blastDirection; // in radians, default pi/2 (down)
  final int numberOfParticles;
  final double emissionFrequency;
  final double gravity;
  final double minBlastForce;
  final double maxBlastForce;
  final List<Color> confettiColors;

  const CelebrationScreen({
    super.key,
    this.icon = Icons.emoji_events_rounded,
    this.iconColor = Colors.amber,
    this.title = "Congratulations!",
    this.message = "Your action was successful.",
    this.buttonText = "Continue",
    this.onButtonPressed,
    this.showConfetti = true,
    this.loopConfetti = false,
    this.blastDirection = pi / 2,
    this.numberOfParticles = 40,
    this.emissionFrequency = 0.1,
    this.gravity = 0.4,
    this.minBlastForce = 10,
    this.maxBlastForce = 30,
    this.confettiColors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
    ],
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    if (widget.showConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confetti
          if (widget.showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: widget.blastDirection,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: widget.emissionFrequency,
                numberOfParticles: widget.numberOfParticles,
                gravity: widget.gravity,
                minBlastForce: widget.minBlastForce,
                maxBlastForce: widget.maxBlastForce,
                shouldLoop: widget.loopConfetti,
                colors: widget.confettiColors,
              ),
            ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 80),

                  const SizedBox(height: 16),

                  DefaultText(
                    text: widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DefaultText(
                    text: widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          widget.onButtonPressed ??
                          () {
                            Navigator.pop(context);
                          },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: DefaultText(
                        text: widget.buttonText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
