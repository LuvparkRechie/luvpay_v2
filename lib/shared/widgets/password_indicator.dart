import 'package:flutter/material.dart';

import 'package:luvpay/shared/widgets/colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    Key? key,
    required this.currentStrength,
    required this.strength,
    this.color,
  }) : super(key: key);

  final int currentStrength;
  final int strength;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color:
              strength <= currentStrength
                  ? color ?? AppColorV2.lpBlueBrand
                  : Colors.grey.shade400,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(15),
            left: Radius.circular(15),
          ),
        ),
      ),
    );
  }
}
