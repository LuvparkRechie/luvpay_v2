// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

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
    this.emissionFrequency = 0.08,
    this.gravity = 0.28,
    this.minBlastForce = 10,
    this.maxBlastForce = 26,
    this.confettiColors = const [
      Color(0xFF2D8CFF),
      Color(0xFF2EE59D),
      Color(0xFFFFC857),
      Color(0xFFFF5C8A),
      Color(0xFF8B5CF6),
      Color(0xFF00D4FF),
    ],
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _entranceCtrl;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    if (widget.showConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _tapContinue() {
    (widget.onButtonPressed ?? () => Navigator.pop(context))();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final onSurfaceVar = cs.onSurfaceVariant;

    final brand = AppColorV2.lpBlueBrand;
    final btnRadius = BorderRadius.circular(18);

    final pressed = _pressed;
    final pressScale = pressed ? 0.988 : 1.0;
    final pressDy = pressed ? 1.4 : 0.0;

    final card = AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_entranceCtrl.value);
        final slideY = lerpDouble(14, 0, t)!;
        final scaleIn = lerpDouble(0.985, 1.0, t)!;

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Transform.scale(scale: scaleIn, child: child),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Neumorphic(
              style: NeumorphicStyle(
                color: surface,
                depth: isDark ? 4 : 7,
                intensity: isDark ? 0.35 : 0.55,
                surfaceIntensity: isDark ? 0.06 : 0.10,
                shadowLightColorEmboss:
                    (isDark ? Colors.white10 : Colors.white.withOpacity(0.7)),
                shadowDarkColorEmboss:
                    (isDark
                        ? Colors.black.withOpacity(0.55)
                        : Colors.black.withOpacity(0.06)),
                boxShape: NeumorphicBoxShape.roundRect(
                  BorderRadius.circular(26),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (isDark
                                  ? Colors.white.withOpacity(0.10)
                                  : Colors.white.withOpacity(0.22)),
                              (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.06)),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: -60,
                      top: -60,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isDark
                                  ? Colors.white.withOpacity(0.10)
                                  : Colors.white.withOpacity(0.22)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconHalo(
                            bg: surface,
                            icon: widget.icon,
                            iconColor: widget.iconColor,
                          ),
                          const SizedBox(height: 14),

                          LuvpayText(
                            text: widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.15,
                            ),
                            color: onSurface,
                          ),

                          const SizedBox(height: 8),

                          LuvpayText(
                            text: widget.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.6,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVar.withOpacity(0.82),
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Container(
                            height: 1,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  onSurface.withOpacity(isDark ? 0.16 : 0.07),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

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
                                    ..translate(0.0, pressDy)
                                    ..scale(pressScale, pressScale),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: btnRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.iconColor.withOpacity(
                                        isDark ? 0.12 : 0.18,
                                      ),
                                      blurRadius: 22,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Neumorphic(
                                  style: NeumorphicStyle(
                                    color: brand,
                                    shape: NeumorphicShape.flat,
                                    boxShape: NeumorphicBoxShape.roundRect(
                                      btnRadius,
                                    ),
                                    depth:
                                        pressed ? -1.2 : (isDark ? 2.0 : 3.2),
                                    intensity: isDark ? 0.40 : 0.48,
                                    surfaceIntensity: isDark ? 0.08 : 0.12,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: Center(
                                      child: LuvpayText(
                                        text: widget.buttonText,
                                        color: cs.onPrimary,
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
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          _AestheticBackdropAnimated(tint: brand, isDark: isDark),

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

class _IconHalo extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;

  const _IconHalo({
    required this.bg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(isDark ? 0.12 : 0.18),
                blurRadius: 26,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        Neumorphic(
          style: NeumorphicStyle(
            color: bg,
            shape: NeumorphicShape.convex,
            boxShape: const NeumorphicBoxShape.circle(),
            depth: isDark ? 3 : 4,
            intensity: isDark ? 0.42 : 0.55,
            surfaceIntensity: isDark ? 0.06 : 0.08,
          ),
          child: SizedBox(
            width: 86,
            height: 86,
            child: Center(child: Icon(icon, color: iconColor, size: 44)),
          ),
        ),
      ],
    );
  }
}

class _AestheticBackdropAnimated extends StatefulWidget {
  final Color tint;
  final bool isDark;

  const _AestheticBackdropAnimated({required this.tint, required this.isDark});

  @override
  State<_AestheticBackdropAnimated> createState() =>
      _AestheticBackdropAnimatedState();
}

class _AestheticBackdropAnimatedState extends State<_AestheticBackdropAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a1 = widget.isDark ? 0.10 : 0.18;
    final a2 = widget.isDark ? 0.08 : 0.26;
    final a3 = widget.isDark ? 0.08 : 0.14;

    return IgnorePointer(
      child: Stack(
        children: [
          _AnimatedBlob(
            controller: _ctrl,
            size: 240,
            color: widget.tint.withOpacity(a1),
            begin: const Offset(-80, -80),
            floatOffset: const Offset(16, 18),
            phase: 0.0,
          ),
          _AnimatedBlob(
            controller: _ctrl,
            size: 220,
            color: Colors.white.withOpacity(a2),
            begin: const Offset(280, 140),
            floatOffset: const Offset(-12, -14),
            phase: 0.35,
          ),
          _AnimatedBlob(
            controller: _ctrl,
            size: 320,
            color: widget.tint.withOpacity(a3),
            begin: const Offset(20, 520),
            floatOffset: const Offset(10, 22),
            phase: 0.7,
          ),
        ],
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;
  final Offset begin;
  final Offset floatOffset;
  final double phase;

  const _AnimatedBlob({
    required this.controller,
    required this.size,
    required this.color,
    required this.begin,
    required this.floatOffset,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final floatAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        phase,
        (phase + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeInOutSine,
      ),
    );

    final scaleAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        phase,
        (phase + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeInOut,
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final f = floatAnim.value;
        final s = lerpDouble(1.0, 1.04, scaleAnim.value)!;

        return Positioned(
          left: begin.dx + (floatOffset.dx * f),
          top: begin.dy + (floatOffset.dy * f),
          child: Transform.scale(
            scale: s,
            child: _Blob(size: size, color: color),
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.85),
            color.withOpacity(0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final pageController = PageController();
  final box = GetStorage();
  final notifCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLogin());
  }

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  void _checkFirstLogin() {
    final isFirstLogin = box.read('isFirstLogin') ?? true;
    if (!isFirstLogin) return;

    Get.to(
      () => CelebrationScreen(
        title: "Welcome to luvpay!",
        message:
            "This looks like your first time logging in on this device.\nStart exploring now.",
        buttonText: "Let's Go!",
        icon: Icons.waving_hand_rounded,
        iconColor: AppColorV2.lpBlueBrand,
        showConfetti: true,
        onButtonPressed: () {
          box.write('isFirstLogin', false);
          Get.back();
        },
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 260),
    );
  }
}
