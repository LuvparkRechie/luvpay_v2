import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class NoDataFound extends StatelessWidget {
  final double? size;
  final Function? onTap;
  final String? text;
  const NoDataFound({super.key, this.size, this.onTap, this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/images/nodata.svg"),
                Container(height: 10),
                DefaultText(
                  text: text ?? "No data found",
                  textAlign: TextAlign.center,
                ),
                Container(height: 10),
                onTap != null
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 17),
                        DefaultText(
                          text: " Tap to refresh",
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
                      ],
                    )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
