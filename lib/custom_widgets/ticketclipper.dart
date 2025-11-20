import 'package:flutter/material.dart';

class RoundedEdgeClipper extends CustomClipper<Path> {
  RoundedEdgeClipper({
    this.edge = Edge.bottom,
    this.points = 20,
    this.depth = 10,
  });

  final double depth;
  final Edge edge;
  final int points;

  @override
  Path getClip(Size size) {
    var h = size.height;
    var w = size.width;
    Path path = Path();

    // Left or Horizontal
    path.moveTo(0, 0);
    double x = 0;
    double y = 0;
    double c = w - depth;
    double i = h / points;

    if (edge == Edge.left || edge == Edge.horizontal || edge == Edge.all) {
      while (y < h) {
        path.quadraticBezierTo(depth, y + i / 2, 0, y + i);
        y += i;
      }
    }

    // Bottom or Vertical
    path.lineTo(0, h);
    x = 0;
    y = h;
    c = h - depth;
    i = w / points;

    if (edge == Edge.bottom || edge == Edge.vertical || edge == Edge.all) {
      while (x < w) {
        path.quadraticBezierTo(x + i / 2, c, x + i, y);
        x += i;
      }
    }

    // Right or Horizontal
    path.lineTo(w, h);
    x = w;
    y = h;
    c = w - depth;
    i = h / points;

    if (edge == Edge.right || edge == Edge.horizontal || edge == Edge.all) {
      while (y > 0) {
        path.quadraticBezierTo(c, y - i / 2, w, y - i);
        y -= i;
      }
    }

    // Top or Vertical
    path.lineTo(w, 0);
    x = w;
    y = 0;
    c = h - depth;
    i = w / points;

    if (edge == Edge.top || edge == Edge.vertical || edge == Edge.all) {
      while (x > 0) {
        path.quadraticBezierTo(x - i / 2, depth, x - i, 0);
        x -= i;
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

// -----------------------------------------------------------------
enum Edge { vertical, horizontal, top, bottom, left, right, all }

// -----------------------------------------------------------------

class ShadowRadius {
  ShadowRadius({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });

  ShadowRadius.all(Radius radius)
      : this.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        );

  ShadowRadius.circular(double radius)
      : this.all(
          Radius.circular(radius),
        );

  ShadowRadius.horizontal({
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) : this.only(
          topLeft: left,
          topRight: right,
          bottomLeft: left,
          bottomRight: right,
        );

  const ShadowRadius.only({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });

  ShadowRadius.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : this.only(
          topLeft: top,
          topRight: top,
          bottomLeft: bottom,
          bottomRight: bottom,
        );

  final Radius bottomLeft;
  final Radius bottomRight;
  final Radius topLeft;
  final Radius topRight;

  static ShadowRadius get zero => ShadowRadius.all(Radius.zero);
}

// -----------------------------------------------------------------
class TicketClipper extends StatelessWidget {
  const TicketClipper(
      {super.key,
      required this.clipper,
      this.shadow,
      required this.child,
      this.shadowRadius});

  final Widget child;
  final CustomClipper<Path> clipper;
  final BoxShadow? shadow;
  final ShadowRadius? shadowRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TicketShadowPainter(
        clipper: clipper,
        shadow: shadow,
        shadowRadius: shadowRadius ?? ShadowRadius.zero,
      ),
      child: ClipPath(clipper: clipper, child: child),
    );
  }
}

// -----------------------------------------------------------------
class TicketShadowPainter extends CustomPainter {
  TicketShadowPainter(
      {required this.clipper, required this.shadowRadius, this.shadow});

  final CustomClipper<Path> clipper;
  final BoxShadow? shadow;
  final ShadowRadius shadowRadius;

  @override
  void paint(Canvas canvas, Size size) {
    var h = size.height;
    var w = size.width;
    Offset centerOffset = Offset(w * 0.5, h * 0.5);
    if (shadow != null) {
      final paint = shadow!.toPaint();
      final spreadRadius = shadow!.spreadRadius;
      final shadowOffset = shadow!.offset;

      final spreadSize = Size(w + spreadRadius * 2, h + spreadRadius * 2);
      final clipPath = clipper.getClip(spreadSize).shift(
            Offset(
                shadowOffset.dx - spreadRadius, shadowOffset.dy - spreadRadius),
          );
      Offset offset = Offset(
          shadowOffset.dx - spreadRadius, shadowOffset.dy - spreadRadius);

      canvas.clipPath(clipPath);
      canvas.drawPath(
          Path()
            ..addRRect(RRect.fromRectAndCorners(
                Rect.fromCenter(
                    center: Offset(
                      centerOffset.dx + offset.dx,
                      centerOffset.dy + offset.dy,
                    ),
                    width: w,
                    height: h),
                topLeft: shadowRadius.topLeft,
                topRight: shadowRadius.topRight,
                bottomLeft: shadowRadius.bottomLeft,
                bottomRight: shadowRadius.bottomRight)),
          paint);
    } else {
      canvas.drawPath(
          clipper.getClip(size), Paint()..color = Colors.transparent);
    }
  }

// -----------------------------------------------------------------
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
