import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class Lock extends StatefulWidget {
  const Lock({super.key});

  @override
  State<Lock> createState() => _LockState();
}

class _LockState extends State<Lock> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          Get.back();
        },
        child: DefaultText(text: "Unlock"),
      ),
    );
  }
}
