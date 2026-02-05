import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/spacing.dart';

class CustomBottomSheet extends StatefulWidget {
  final VoidCallback callback;
  const CustomBottomSheet({super.key, required this.callback});

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  int _remainingTime = 30; // Starting time in seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          Get.back();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        Get.context!,
      ).copyWith(textScaler: TextScaler.linear(1)),
      child: PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                fit: StackFit.loose,
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: MediaQuery.of(Get.context!).size.width,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        spacing(height: 40),
                        DefaultText(text: "One-Time Password", fontSize: 16),
                        spacing(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 6; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: DefaultText(
                                  text: "$i",
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColorV2.lpBlueBrand,
                                ),
                              ),
                          ],
                        ),
                        spacing(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: "Cancel",
                                btnColor: Colors.white,
                                bordercolor: AppColorV2.bodyTextColor,
                                textColor: Colors.black,
                                onPressed: () {
                                  Get.back();
                                },
                              ),
                            ),
                            Container(width: 10),
                            Expanded(
                              child: CustomButton(
                                text: "Confirm",
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColorV2.lpBlueBrand,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(25),
                      child: DefaultText(
                        text: _remainingTime.toString(),
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
