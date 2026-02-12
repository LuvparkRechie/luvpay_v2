import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/spacing.dart';

class NoInternetConnected extends StatefulWidget {
  final Function? onTap;
  final double? width;
  final double? height;

  const NoInternetConnected({
    super.key,
    this.onTap,
    this.width = 220,
    this.height = 300,
  });

  @override
  State<NoInternetConnected> createState() => _NoInternetConnectedState();
}

class _NoInternetConnectedState extends State<NoInternetConnected>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool isCanTap = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onRefresh() {
    if (!isCanTap) return;

    setState(() => isCanTap = false);
    _controller.repeat();

    final cs = Theme.of(context).colorScheme;

    Get.snackbar(
      "Just a Moment",
      "Loading please wait...",
      isDismissible: false,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      backgroundColor: cs.surface,
      colorText: cs.onSurface,
      borderRadius: 14,
      margin: const EdgeInsets.all(12),
      snackbarStatus: (status) {
        if (status == SnackbarStatus.CLOSED) {
          if (!mounted) return;
          _controller.stop();
          setState(() => isCanTap = true);
          widget.onTap?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: SvgPicture.asset(
              "assets/images/no_net.svg",
              width: widget.width,
              colorFilter: ColorFilter.mode(
                cs.onSurface.withOpacity(isDark ? 0.85 : 0.80),
                BlendMode.srcIn,
              ),
            ),
          ),
          spacing(height: widget.height == null ? 55 : widget.height! * .15),
          LuvpayText(
            text: "No Internet Connection",
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: cs.onSurface,
            letterSpacing: -0.408,
          ),
          spacing(height: 10),
          LuvpayText(
            text: "Seems like you’ve lost connection.",
            fontWeight: FontWeight.w400,
            letterSpacing: -0.408,
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
          spacing(height: 25),
          if (widget.onTap != null)
            RotationTransition(
              turns: _controller,
              child: IconButton(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh, size: 32),
                color:
                    isCanTap
                        ? cs.onSurface.withOpacity(isDark ? 0.70 : 0.55)
                        : cs.onSurface.withOpacity(isDark ? 0.40 : 0.30),
              ),
            ),
        ],
      ),
    );
  }
}
