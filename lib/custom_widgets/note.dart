// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class NoteWidget extends StatelessWidget {
  const NoteWidget({
    super.key,
    required this.message,
    this.radius,
    this.title = '',
    this.icon,
  });

  final String message;
  final double? radius;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(width: .7, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        horizontalTitleGap: 10,
        minVerticalPadding: 5,
        title:
            title.isEmpty
                ? null
                : Row(
                  children: [
                    Icon(
                      icon ?? Icons.info,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: AutoSizeText(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isEmpty)
                Icon(
                  icon ?? Icons.info,
                  color: AppColorV2.bodyTextColor,
                  size: 20,
                ),
              SizedBox(width: title.isEmpty ? 5 : 25),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
