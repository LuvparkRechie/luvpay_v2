import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    show BarcodeScanner, InputImage;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/loading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScannerScreen extends StatefulWidget {
  final Function onchanged;
  const ScannerScreen({super.key, required this.onchanged, this.isBack = true});

  final bool isBack;

  @override
  // ignore: library_private_types_in_public_api
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool isScanning = false;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkCameraPermission();
      load();
    });
  }

  void checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    } else if (status.isPermanentlyDenied) {
      AppSettings.openAppSettings();
    } else {}
  }

  @override
  void dispose() {
    controller!.disposed;
    super.dispose();
  }

  load() {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        elevation: 0,
        toolbarHeight: 56,
        backgroundColor: AppColorV2.lpBlueBrand,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.lpBlueBrand,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text("QR Code"),

        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Row(
            children: [
              Icon(CupertinoIcons.back, color: Colors.white),
              DefaultText(text: "Back", color: AppColorV2.background),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColorV2.lpBlueBrand,
        child:
            isLoading
                ? LoadingCard()
                : Stack(
                  children: [
                    QRView(
                      key: GlobalKey(debugLabel: 'QR'),
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: AppColorV2.lpBlueBrand,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 300,
                      ),
                    ),
                    Positioned(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: DefaultText(
                            text: 'Make sure the QR code is within the frame.',
                            style: GoogleFonts.openSans(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: CustomButton(
                          margin: EdgeInsets.only(bottom: 40),
                          width: 200,
                          btnColor: AppColorV2.background,
                          textColor: AppColorV2.lpBlueBrand,
                          bordercolor: AppColorV2.lpBlueBrand,
                          leading: Icon(
                            LucideIcons.uploadCloud,
                            color: AppColorV2.lpBlueBrand,
                          ),
                          borderRadius: 10,
                          btnHeight: 50,
                          text: 'Upload QR Code',
                          onPressed: () => uploadPhoto(ImageSource.gallery),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanning && scanData.code != null) {
        setState(() {
          isScanning = true;
        });

        Get.back();
        widget.onchanged(scanData.code!);

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              isScanning = false;
            });
            return;
          }
        });
      } else if (scanData.code == null) {
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          "No QR code detected. Please try again.",
          () {
            Get.back();
          },
        );
      }
    });
  }

  void uploadPhoto(ImageSource source) async {
    String qrCode = "";
    XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: Platform.isIOS ? 18 : 20,
      maxWidth: Platform.isIOS ? 300 : 400,
      requestFullMetadata: true,
    );
    File? imageFile;

    imageFile = pickedFile != null ? File(pickedFile.path) : null;

    if (imageFile == null) {
      CustomDialogStack.showError(
        context,
        "luvpay",
        "Invalid QR code image, please select valid QR code image.",
        () {
          Get.back();
        },
      );
    } else {
      final inputImage = InputImage.fromFilePath(pickedFile!.path);
      final barcodeScanner = BarcodeScanner();

      try {
        final barcodes = await barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first;
          setState(() {
            qrCode = barcode.displayValue!;
          });

          Get.back();
          widget.onchanged(barcode.displayValue!);
          return;
        } else {
          setState(() {
            qrCode = 'No QR code found';
          });
          return;
        }
      } catch (e) {
        setState(() {
          qrCode = 'Error scanning image: $e';
        });
      }
    }
  }
}
