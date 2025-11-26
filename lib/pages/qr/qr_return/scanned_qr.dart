import 'package:flutter/cupertino.dart';
import 'package:luvpay/custom_widgets/custom_scaffold.dart';

import '../../../custom_widgets/brightness_setter.dart';
import '../../../custom_widgets/custom_text_v2.dart';

class ScannedQR extends StatefulWidget {
  final String args;
  const ScannedQR({super.key, required this.args});

  @override
  State<ScannedQR> createState() => _ScannedQRState();
}

class _ScannedQRState extends State<ScannedQR> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BrightnessSetter.setFullBrightness();
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BrightnessSetter.restoreBrightness();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      scaffoldBody: Center(
        child: DefaultText(
          text: 'Scanned QR Data: ${widget.args}',
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
