// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:luvpay/shared/widgets/colors.dart';

class LuvPayDiagonalLinesBackground extends StatefulWidget {
  final Widget? child;
  const LuvPayDiagonalLinesBackground({super.key, this.child});

  @override
  State<LuvPayDiagonalLinesBackground> createState() =>
      _LuvPayDiagonalLinesBackgroundState();
}

class _LuvPayDiagonalLinesBackgroundState
    extends State<LuvPayDiagonalLinesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rand = Random();
  late List<_Line> _lines;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 600))
          ..repeat();

    _lines = List.generate(25, (index) {
      return _Line(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        length: 120 + _rand.nextDouble() * 180,
        speed: 0.00005 + _rand.nextDouble() * 0.00008,
        thickness: 1.0 + _rand.nextDouble() * 1.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(Size size) {
    for (var line in _lines) {
      line.x += line.speed;
      line.y += line.speed;

      if (line.x * size.width > size.width + line.length) {
        line.x = -0.2;
        line.y = _rand.nextDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseLineColor = isDark
        ? AppColorV2.lpBlueBrand.withOpacity(0.02)
        : AppColorV2.lpBlueBrand.withOpacity(0.06);

    final blobColor = isDark
        ? AppColorV2.lpTealBrand.withOpacity(0.10)
        : AppColorV2.lpTealBrand.withOpacity(0.06);

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;

        return Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final progress = _controller.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -120 + sin(progress * 2 * pi) * 25,
                      right: -80,
                      child: _blob(blobColor, 260),
                    ),
                    Positioned(
                      bottom: -120,
                      left: -80 + cos(progress * 2 * pi) * 25,
                      child: _blob(blobColor, 320),
                    ),
                  ],
                );
              },
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                _update(size);

                return CustomPaint(
                  size: Size.infinite,
                  painter: _GlassLinesPainterWithShimmer(
                    _lines,
                    baseLineColor,
                    isDark,
                    _controller.value,
                  ),
                );
              },
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Line {
  double x;
  double y;
  final double length;
  final double speed;
  final double thickness;

  _Line({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.thickness,
  });
}

class _GlassLinesPainterWithShimmer extends CustomPainter {
  final List<_Line> lines;
  final Color color;
  final bool isDark;
  final double progress;

  _GlassLinesPainterWithShimmer(
      this.lines, this.color, this.isDark, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final layers = isDark ? 1 : 2;
      for (var i = 0; i < layers; i++) {
        final paint = Paint()
          ..strokeWidth =
              line.thickness * (isDark ? 0.5 : 0.008) * (1 + i * 0.4)
          ..color = color.withOpacity(
            isDark ? 0.006 / (i + 1) : 0.0004 / (i + 6),
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isDark ? 0.8 * i : 1.2 * i,
          );

        final startX = line.x * size.width - i * 2;
        final startY = line.y * size.height - i * 2;

        final endX = startX + line.length;
        final endY = startY + line.length;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );

        final shimmerPaint = Paint()
          ..strokeWidth = line.thickness * (isDark ? 0.7 : 0.85)
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(
                isDark ? 0.015 : 0.02,
              ),
              Colors.transparent,
            ],
            stops: [
              0.0,
              (progress * 0.5 + i * 0.08) % 1.0,
              1.0,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromLTWH(startX, startY, line.length, line.length),
          );

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          shimmerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
