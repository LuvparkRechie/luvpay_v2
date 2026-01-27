// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CelebrationScreen extends StatefulWidget {
  final IconData icon;
  final Color iconColor;

  final String title;
  final String message;

  final String buttonText;
  final VoidCallback? onButtonPressed;

  final bool showConfetti;
  final bool loopConfetti;
  final double blastDirection;
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
    this.gravity = 0.35,
    this.minBlastForce = 10,
    this.maxBlastForce = 28,
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
  late final ConfettiController _confettiController;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    if (widget.showConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _tapContinue() {
    (widget.onButtonPressed ?? () => Navigator.pop(context))();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColorV2.background;

    final btnRadius = BorderRadius.circular(18);

    final pressedVisual = _pressed;
    final scale = pressedVisual ? 0.985 : 1.0;
    final dy = pressedVisual ? 1.2 : 0.0;

    final card = Center(
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.10), Colors.transparent],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Neumorphic(
                  style: NeumorphicStyle(
                    color: bg,
                    shape: NeumorphicShape.convex,
                    boxShape: const NeumorphicBoxShape.circle(),
                    depth: 3,
                    intensity: 0.42,
                    surfaceIntensity: 0.06,
                  ),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 42,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                DefaultText(
                  text: widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 6),

                DefaultText(
                  text: widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withAlpha(125),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 18),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTap: _tapContinue,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    transform:
                        Matrix4.identity()
                          ..translate(0.0, dy)
                          ..scale(scale, scale),
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        color: AppColorV2.lpBlueBrand,
                        shape: NeumorphicShape.flat,
                        boxShape: NeumorphicBoxShape.roundRect(btnRadius),
                        depth: pressedVisual ? -1.0 : 2.0,
                        intensity: 0.40,
                        surfaceIntensity: 0.10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Center(
                          child: DefaultText(
                            text: widget.buttonText,
                            color: bg,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
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

          SafeArea(child: card),
        ],
      ),
    );
  }
}
