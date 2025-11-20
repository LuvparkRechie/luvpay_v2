// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'flex_widget.dart';

class TopRowDecoration extends StatelessWidget {
  final Color color;

  const TopRowDecoration({Key? key, required this.color}) : super(key: key);

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
              color: color,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: FlexWidget(
              width: 4,
              height: 1,
              color: Colors.transparent,
              constrainDivisor: 8,
              direction: Axis.horizontal,
            ),
          ),
          Container(
            width: 10,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomRowDecoration extends StatelessWidget {
  final Color color;

  const BottomRowDecoration({
    Key? key,
    required this.color,
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
              color: color,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: FlexWidget(
              width: 4,
              height: 1,
              color: Colors.transparent,
              constrainDivisor: 8,
              direction: Axis.horizontal,
            ),
          ),
          Container(
            width: 10,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
