import 'package:flutter/widgets.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [DefaultText(text: "Card Screen")],
    );
  }
}
