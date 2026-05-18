import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

enum InAppNotificationType { info, success, warning, error }

class InAppNotificationService {
  static OverlayEntry? _currentEntry;
  static Completer<void>? _dismissCompleter;
  static bool _isShowing = false;
  static final Queue<_NotificationRequest> _queue = Queue();

  static const int maxQueueSize = 10;

  static Future<bool> show({
    required String title,
    required String message,
    InAppNotificationType type = InAppNotificationType.info,
    IconData icon = Icons.notifications_active_outlined,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) async {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      return false;
    }

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return false;

    _queue.add(_NotificationRequest(
      title: title,
      message: message,
      type: type,
      icon: icon,
      onTap: onTap,
      duration: duration,
    ));

    while (_queue.length > maxQueueSize) {
      _queue.removeFirst();
    }

    if (!_isShowing) {
      _processQueue();
    }

    return true;
  }

  static void dismiss() {
    _dismissCompleter?.complete();
  }

  static void dismissAll() {
    _queue.clear();
    dismiss();
  }

  static Future<void> _processQueue() async {
    if (_isShowing) return;
    _isShowing = true;

    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      await _showNotification(request);
    }

    _isShowing = false;
  }

  static Future<void> _showNotification(_NotificationRequest request) async {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    OverlayState overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return;
    }

    _removeCurrentEntry();

    _dismissCompleter = Completer<void>();

    _currentEntry = OverlayEntry(
      builder: (_) => _InAppNotificationBanner(
        title: request.title,
        message: request.message,
        type: request.type,
        icon: request.icon,
        onTap: request.onTap,
        onClose: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);

    await Future.any([
      Future.delayed(request.duration),
      _dismissCompleter!.future,
    ]);

    _removeCurrentEntry();
  }

  static void _removeCurrentEntry() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
    _dismissCompleter = null;
  }
}

class _NotificationRequest {
  const _NotificationRequest({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    this.onTap,
    required this.duration,
  });

  final String title;
  final String message;
  final InAppNotificationType type;
  final IconData icon;
  final VoidCallback? onTap;
  final Duration duration;
}

class _InAppNotificationBanner extends StatelessWidget {
  const _InAppNotificationBanner({
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.onClose,
    this.onTap,
  });

  final String title;
  final String message;
  final InAppNotificationType type;
  final IconData icon;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(type);
    final hasBody = message.trim().isNotEmpty;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -18, end: 0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => Transform.translate(
            offset: Offset(0, offset),
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap == null
                  ? null
                  : () {
                      onClose();
                      onTap!();
                    },
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.32 : 0.22),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LuvpayText(
                              text: title.trim().isEmpty
                                  ? "Notification"
                                  : title.trim(),
                              style: AppTextStyle.h3(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: cs.onSurface,
                            ),
                            if (hasBody) ...[
                              const SizedBox(height: 3),
                              LuvpayText(
                                text: message.trim(),
                                style: AppTextStyle.paragraph2(context),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant, size: 22),
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                            width: 30, height: 30),
                        onPressed: onClose,
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurfaceVariant, size: 18),
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

  Color _accentColor(InAppNotificationType type) {
    switch (type) {
      case InAppNotificationType.success:
        return AppColorV2.correctState;
      case InAppNotificationType.warning:
        return AppColorV2.partialState;
      case InAppNotificationType.error:
        return AppColorV2.incorrectState;
      case InAppNotificationType.info:
        return AppColorV2.lpBlueBrand;
    }
  }
}
