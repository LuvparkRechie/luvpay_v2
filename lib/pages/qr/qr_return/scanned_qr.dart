import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class ScannedQR extends StatefulWidget {
  final String args;
  const ScannedQR({super.key, required this.args});

  @override
  State<ScannedQR> createState() => _ScannedQRState();
}

class _ScannedQRState extends State<ScannedQR> {
  Map<String, dynamic> qrData = {};

  @override
  void initState() {
    super.initState();
    _parseQRData();
  }

  void _parseQRData() {
    try {
      String jsonString = widget.args.replaceAll("'", '"');
      qrData = json.decode(jsonString);
    } catch (e) {
      qrData = {};
      print('Error parsing QR data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      canPop: false,
      onPressedLeading: _goBack,
      enableToolBar: true,
      scaffoldBody: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DefaultText(
              text: 'QR Code Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (qrData.isNotEmpty) ...[
              _buildDetailRow(
                'Merchant Name:',
                qrData['merchant_name']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Processing Fee:',
                '\$${qrData['processing_fee']?.toStringAsFixed(2) ?? '0.00'}',
              ),
            ] else ...[
              const DefaultText(text: 'Failed to parse QR data'),
              const SizedBox(height: 8),
              DefaultText(text: 'Raw data: ${widget.args}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DefaultText(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(flex: 3, child: DefaultText(text: value)),
      ],
    );
  }

  void _goBack() {
    Get.back();
  }
}
