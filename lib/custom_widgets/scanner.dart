// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    show BarcodeScanner, InputImage;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_button.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/luvpay_loading.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScannerScreen extends StatefulWidget {
  final Function onchanged;
  const ScannerScreen({super.key, required this.onchanged, this.isBack = true});

  final bool isBack;

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool isScanning = false;
  QRViewController? controller;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final Color primaryTeal = Color(0xFF008080);
  final Color primaryBlue = Color(0xFF1E90FF);
  final Color darkBlue = Color(0xFF0066CC);
  final Color lightTeal = Color(0xFF40E0D0);
  final Color backgroundColor = Color(0xFF0A1F35);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

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
    controller?.stopCamera();
    controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  load() {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      enableToolBar: false,
      scaffoldBody: Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor,
        child:
            isLoading
                ? LoadingCard()
                : Stack(
                  children: [
                    QRView(
                      key: GlobalKey(debugLabel: 'QR'),
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.transparent,
                        borderRadius: 30,
                        borderLength: 35,
                        borderWidth: 5,
                        cutOutSize: 200,
                        cutOutBottomOffset: 40,
                      ),
                    ),

                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 - 180,
                      left: MediaQuery.of(context).size.width / 2 - 150,
                      child: Container(
                        width: 300,
                        height: 300,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 35,
                                height: 35,
                                child: CustomPaint(
                                  painter: _CornerPainter(
                                    gradient: LinearGradient(
                                      colors: [lightTeal, primaryBlue],
                                    ),
                                    corner: Corner.topLeft,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 35,
                                height: 35,
                                child: CustomPaint(
                                  painter: _CornerPainter(
                                    gradient: LinearGradient(
                                      colors: [lightTeal, primaryBlue],
                                    ),
                                    corner: Corner.topRight,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 35,
                                height: 35,
                                child: CustomPaint(
                                  painter: _CornerPainter(
                                    gradient: LinearGradient(
                                      colors: [lightTeal, primaryBlue],
                                    ),
                                    corner: Corner.bottomLeft,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 35,
                                height: 35,
                                child: CustomPaint(
                                  painter: _CornerPainter(
                                    gradient: LinearGradient(
                                      colors: [lightTeal, primaryBlue],
                                    ),
                                    corner: Corner.bottomRight,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _animation.value * 300),
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            lightTeal,
                                            primaryBlue,
                                            lightTeal,
                                            Colors.transparent,
                                          ],
                                          stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryBlue.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              backgroundColor.withOpacity(0.9),
                              backgroundColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Column(
                              children: [
                                DefaultText(
                                  text: 'Scan QR Code',
                                  style: GoogleFonts.openSans(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                DefaultText(
                                  text:
                                      'Make sure the QR code is within the frame',
                                  style: GoogleFonts.openSans(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              backgroundColor.withOpacity(0.9),
                              backgroundColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: 0.8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryTeal, primaryBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CustomButton(
                                    btnColor: Colors.transparent,
                                    textColor: Colors.white,
                                    bordercolor: Colors.transparent,
                                    leading: Icon(
                                      LucideIcons.qrCode,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    borderRadius: 12,
                                    btnHeight: 56,
                                    text: 'Generate QR',
                                    onPressed: () {
                                      Get.toNamed(Routes.qr);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryBlue, primaryTeal],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryTeal.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CustomButton(
                                  btnColor: Colors.transparent,
                                  textColor: Colors.white,
                                  bordercolor: Colors.transparent,
                                  leading: Icon(
                                    LucideIcons.uploadCloud,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  borderRadius: 12,
                                  btnHeight: 56,
                                  text: 'Upload',
                                  onPressed:
                                      () => uploadPhoto(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isScanning)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryTeal, primaryBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  DefaultText(
                                    text: 'Scanning...',
                                    style: GoogleFonts.openSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

        HapticFeedback.lightImpact();

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
          "Scan Error",
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
        "Upload Error",
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
          HapticFeedback.selectionClick();

          Get.back();
          widget.onchanged(barcode.displayValue!);
          return;
        } else {
          setState(() {
            qrCode = 'No QR code found';
          });
          CustomDialogStack.showError(
            context,
            "Scan Error",
            "No QR code found in the selected image.",
            () {
              Get.back();
            },
          );
          return;
        }
      } catch (e) {
        setState(() {
          qrCode = 'Error scanning image: $e';
        });
        CustomDialogStack.showError(
          context,
          "Scan Error",
          "Error scanning image. Please try again.",
          () {
            Get.back();
          },
        );
      }
    }
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  final Gradient gradient;
  final Corner corner;

  _CornerPainter({required this.gradient, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height),
          )
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case Corner.topLeft:
        path.moveTo(size.width, 0);
        path.lineTo(0, 0);
        path.lineTo(0, size.height);
        break;
      case Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case Corner.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
