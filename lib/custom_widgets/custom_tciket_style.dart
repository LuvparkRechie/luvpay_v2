import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class TicketStyle extends StatelessWidget {
  final Color? dtColor;
  const TicketStyle({super.key, this.dtColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Row(
                      children: List.generate(
                        700 ~/ 10,
                        (index) => Expanded(
                          child: Container(
                            color:
                                index % 2 == 0
                                    ? Colors.grey
                                    : Theme.of(context).canvasColor,
                            height: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -15,
          bottom: 0,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: dtColor ?? AppColorV2.background,
          ),
        ),
        Positioned(
          right: -15,
          bottom: 0,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: dtColor ?? AppColorV2.background,
          ),
        ),
      ],
    );
  }
}
