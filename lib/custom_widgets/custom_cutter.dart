import 'package:flutter/material.dart';

import 'flex_widget.dart';

class LineCutter extends StatelessWidget {
  const LineCutter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 20,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10))),
          ),
          Expanded(
              child: FlexWidget(
            width: 4,
            height: 1,
            color: Colors.grey.shade500,
            constrainDivisor: 8,
            direction: Axis.horizontal,
          )),
          Container(
            width: 10,
            height: 20,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10))),
          )
        ],
      ),
    );
  }
}
