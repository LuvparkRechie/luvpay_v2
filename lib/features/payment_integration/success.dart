import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/widgets/luvpay_loading.dart';
import '../../shared/widgets/custom_scaffold.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage>
    with SingleTickerProviderStateMixin {
  final params = Get.arguments;
  late AnimationController _controller;
  final int _duration = 5; // in seconds
  bool pageLoad = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _duration),
    );

    // Start the animation

    // When animation is complete, close the page
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.back(); // Close the page
        Get.back();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _timerText {
    final secondsLeft = (_duration * (1.0 - _controller.value)).ceil();
    return "$secondsLeft s";
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: false,
      canPop: true,
      appBar: null,

      scaffoldBody:
          pageLoad
              ? Center(child: Text("Loading..."))
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder:
                        (context, child) => Stack(
                          alignment: Alignment.center,
                          children: [
                            LoadingCard(),
                            Text(_timerText, style: TextStyle(fontSize: 24)),
                          ],
                        ),
                  ),
                ],
              ),
    );
  }
}
