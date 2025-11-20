import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/spacing.dart';

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
  _NoInternetConnectedState createState() => _NoInternetConnectedState();
}

class _NoInternetConnectedState extends State<NoInternetConnected>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isCanTap = true;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with the desired timeline
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Rotation duration
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

    setState(() {
      isCanTap = false;
    });

    _controller.repeat();

    Get.snackbar(
      "Just a Moment",
      'Loading please wait...',
      isDismissible: false,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      snackbarStatus: (status) {
        if (status == SnackbarStatus.CLOSED) {
          if (!mounted) return;
          _controller.stop();
          setState(() {
            isCanTap = true;
          });
          widget.onTap?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 20),

          Center(child: SvgPicture.asset("assets/images/no_net.svg")),
          spacing(height: widget.height == null ? 55 : widget.height! * .15),
          const DefaultText(
            text: "No Internet Connection",
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1E1E1E),
            letterSpacing: -0.408,
          ),
          spacing(height: 10),
          const DefaultText(
            text: "Seems like you’ve lost connection.",
            fontWeight: FontWeight.w400,
            letterSpacing: -0.408,
            fontSize: 14,
          ),
          spacing(height: 25),
          if (widget.onTap != null)
            RotationTransition(
              turns: _controller,
              child: IconButton(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh, size: 32),
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
