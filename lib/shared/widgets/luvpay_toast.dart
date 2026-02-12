// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class FloatingToastManager {
  static OverlayEntry? _currentToast;
  static OverlayState? _overlayState;

  FloatingToastManager({
    required BuildContext context,
    required String message,
    required GlobalKey targetKey,
    required Color textColor,
    required String image,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    bool showCloseButton = false,
  }) {
    showFloatingToast(
      context: context,
      message: message,
      targetKey: targetKey,
      textColor: textColor,
      image: image,
      backgroundColor: backgroundColor,
      duration: duration,
      showCloseButton: showCloseButton,
    );
  }

  static void showFloatingToast({
    required BuildContext context,
    required String message,
    required GlobalKey targetKey,
    required Color textColor,
    required String image,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    bool showCloseButton = false,
  }) {
    _removeCurrentToast();
    _overlayState = Overlay.of(context);

    final targetContext = targetKey.currentContext;
    if (targetContext == null || _overlayState == null) return;

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    _currentToast = OverlayEntry(
      builder:
          (context) => Positioned(
            top: position.dy + size.height + 8,
            left: position.dx,
            width: size.width,
            child: Material(
              color: Colors.transparent,
              child: ToastWidget(
                imageAsset: "assets/images/$image.png",
                message: message,
                primaryColor: textColor,
                backgroundColor: backgroundColor ?? Colors.white,
                showCloseButton: showCloseButton,
                onDismiss: _removeCurrentToast,
              ),
            ),
          ),
    );

    _overlayState!.insert(_currentToast!);

    Future.delayed(duration, _removeCurrentToast);
  }

  static void _removeCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }

  static void dismiss() => _removeCurrentToast();
}

class ToastWidget extends StatelessWidget {
  final String imageAsset;
  final String message;
  final Color primaryColor;
  final Color backgroundColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool showCloseButton;
  final VoidCallback? onDismiss;

  const ToastWidget({
    super.key,
    required this.imageAsset,
    required this.message,
    required this.primaryColor,
    required this.backgroundColor,
    this.iconSize = 28,
    this.padding = const EdgeInsets.all(10),
    this.showCloseButton = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              imageAsset,
              height: iconSize,
              width: iconSize,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            if (showCloseButton) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
