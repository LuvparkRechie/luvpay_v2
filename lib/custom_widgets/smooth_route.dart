import 'package:flutter/material.dart';

class SmoothRoute {
  final BuildContext context;
  final Widget child;
  const SmoothRoute({required this.context, required this.child});

  Future<T?> route<T>() {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}
