// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';

class UpdateInfoSuccess extends StatefulWidget {
  const UpdateInfoSuccess({super.key});

  @override
  State<UpdateInfoSuccess> createState() => _UpdateInfoSuccessState();
}

class _UpdateInfoSuccessState extends State<UpdateInfoSuccess>
    with SingleTickerProviderStateMixin {
  final Duration countdownDuration = const Duration(seconds: 3);

  late Duration _remaining = countdownDuration;
  Timer? _timer;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _anim.forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = countdownDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final next = _remaining - const Duration(seconds: 1);

      setState(() {
        _remaining = next;
      });

      if (next.inSeconds <= 0) {
        _timer?.cancel();
        Get.offAllNamed(Routes.login);
      }
    });
  }

  double get _progress {
    final totalMs = countdownDuration.inMilliseconds;
    if (totalMs <= 0) return 0.0;

    final v = _remaining.inMilliseconds / totalMs;
    return v.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final seconds = _twoDigits(_remaining.inSeconds.remainder(60));

    final borderOpacity = isDark ? 0.05 : 0.01;

    final bg = cs.surface;
    final fg = cs.onSurface;

    final card = cs.surfaceContainerHighest;
    final stroke = cs.onSurface.withOpacity(borderOpacity);

    final shadowColor =
        isDark
            ? Colors.black.withOpacity(0.45)
            : Colors.black.withOpacity(0.10);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: AnimatedBuilder(
                animation: CurvedAnimation(
                  parent: _anim,
                  curve: Curves.easeOutCubic,
                ),
                builder: (context, child) {
                  final t = _anim.value;
                  final scale = 0.96 + (0.04 * t);
                  final dy = (1 - t) * 16;

                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: Container(
                  width: math.min(MediaQuery.of(context).size.width, 420),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: stroke),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: isDark ? 28 : 18,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withOpacity(
                                isDark ? 0.16 : 0.12,
                              ),
                            ),
                          ),
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withOpacity(
                                isDark ? 0.20 : 0.16,
                              ),
                            ),
                          ),
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withOpacity(
                                    isDark ? 0.35 : 0.25,
                                  ),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 34,
                              color: cs.onPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "Congratulations!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "You have successfully updated your account.\nWe’re redirecting you to the Login page.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: fg.withOpacity(0.70),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: stroke),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Redirecting in ",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: fg.withOpacity(0.70),
                                  ),
                                ),
                                Text(
                                  seconds,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: cs.primary,
                                  ),
                                ),
                                Text(
                                  "s",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: fg.withOpacity(0.70),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 7,
                                backgroundColor: cs.onSurface.withOpacity(
                                  isDark ? 0.10 : 0.06,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Get.offAllNamed(Routes.login),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text("Go to Login now"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
