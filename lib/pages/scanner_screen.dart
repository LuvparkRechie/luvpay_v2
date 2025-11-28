import 'dart:async';
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
import 'package:luvpay/custom_widgets/brightness_setter.dart';
import 'package:luvpay/custom_widgets/loading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../custom_widgets/alert_dialog.dart';
import '../custom_widgets/app_color_v2.dart';
import '../custom_widgets/custom_button.dart';
import '../custom_widgets/custom_text_v2.dart';

class ScannerScreenV2 extends StatefulWidget {
  final Function(String) onchanged;
  final Function? onGenerateQR;
  final bool? isWallet;
  const ScannerScreenV2({
    super.key,
    required this.onchanged,
    this.isBack = true,
    this.onGenerateQR,
    this.isWallet,
  });

  final bool isBack;

  @override
  _ScannerScreenV2State createState() => _ScannerScreenV2State();
}

class _ScannerScreenV2State extends State<ScannerScreenV2>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool isScanning = false;
  bool flashOn = false;
  QRViewController? controller;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() async {
    try {
      BrightnessSetter.setFullBrightness();

      // Initialize scan animation
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _scanAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_animationController);

      await checkCameraPermission();
      load();
    } catch (e) {
      print("Scanner initialization error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        await Permission.camera.request();
      } else if (status.isPermanentlyDenied) {
        AppSettings.openAppSettings();
      }
    } catch (e) {
      print("Permission error: $e");
    }
  }

  void load() {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleFlash() async {
    try {
      if (controller != null) {
        await controller?.toggleFlash();
        if (mounted) {
          setState(() {
            flashOn = !flashOn;
          });
        }
      }
    } catch (e) {
      print("Flash toggle error: $e");
    }
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    _animationController.dispose();
    _scanSubscription?.cancel();
    controller?.disposed;
    BrightnessSetter.restoreBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leadingWidth: 80,
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          "QR Scanner",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading:
            widget.isBack
                ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: Colors.white,
                        size: 24,
                      ),
                      splashColor: AppColorV2.lpBlueBrand.withAlpha(50),
                    ),
                  ),
                )
                : const SizedBox(),
        actions: [
          // Flash Toggle Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: toggleFlash,
                icon: Icon(
                  flashOn ? LucideIcons.flashlight : LucideIcons.flashlightOff,
                  color: Colors.white,
                  size: 24,
                ),
                splashColor: AppColorV2.lpBlueBrand.withAlpha(50),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child:
            isLoading
                ? _buildLoadingState()
                : Stack(
                  children: [
                    // QR Scanner View
                    QRView(
                      key: GlobalKey(debugLabel: 'QR'),
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: AppColorV2.lpBlueBrand,
                        borderRadius: 16,
                        borderLength: 40,
                        borderWidth: 6,
                        cutOutSize: 280,
                      ),
                    ),

                    // Animated Scan Line
                    _buildAnimatedScanLine(),

                    // Instructions
                    _buildInstructions(),

                    // Bottom Controls
                    _buildBottomControls(),
                  ],
                ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColorV2.lpBlueBrand, AppColorV2.lpTealBrand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.qrCode,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          DefaultText(
            text: "Initializing Scanner...",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          LoadingCard(),
        ],
      ),
    );
  }

  Widget _buildAnimatedScanLine() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScanLinePainter(
                  scanPosition: _scanAnimation.value,
                  color: AppColorV2.lpTealBrand,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Column(
          children: [
            DefaultText(
              text: 'Align QR Code within Frame',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DefaultText(
              text:
                  'Position the QR code inside the frame to scan automatically',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Upload QR Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColorV2.lpBlueBrand, AppColorV2.lpTealBrand],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColorV2.lpBlueBrand.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
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
              borderRadius: 16,
              btnHeight: 56,
              text: 'Upload QR Code from Gallery',
              onPressed: () => uploadPhoto(ImageSource.gallery),
            ),
          ),
          if (widget.isWallet != null) const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    // Cancel any existing subscription
    _scanSubscription?.cancel();

    _scanSubscription = controller.scannedDataStream.listen(
      (scanData) {
        _handleScannedData(scanData);
      },
      onError: (error) {
        print("QR Scan error: $error");
      },
    );
  }

  void _handleScannedData(Barcode scanData) {
    if (!isScanning && scanData.code != null && mounted) {
      setState(() {
        isScanning = true;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Use a delay to ensure UI updates before navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onchanged(scanData.code!);
        }
      });

      // Reset scanning state after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isScanning = false;
          });
        }
      });
    }
  }

  Future<void> uploadPhoto(ImageSource source) async {
    try {
      XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Reduced quality for better performance
        maxWidth: 800,
        requestFullMetadata: false,
      );

      if (pickedFile == null) {
        _showErrorDialog(
          "Invalid Image",
          "Please select a valid QR code image.",
        );
        return;
      }

      // Show loading
      CustomDialogStack.showLoading(context);

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final barcodeScanner = BarcodeScanner();

      try {
        final barcodes = await barcodeScanner.processImage(inputImage);

        // Close loading
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first;
          if (barcode.displayValue != null) {
            // Add haptic feedback
            HapticFeedback.lightImpact();

            // Close scanner and return result
            if (mounted) {
              Navigator.of(context).pop();
              widget.onchanged(barcode.displayValue!);
            }
            return;
          }
        } else {
          _showErrorDialog(
            "No QR Code Found",
            "The selected image doesn't contain a valid QR code.",
          );
        }
      } finally {
        barcodeScanner.close();
        // Clean up the temporary file
        try {
          await File(pickedFile.path).delete();
        } catch (e) {
          print("Error deleting temp file: $e");
        }
      }
    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorDialog("Scan Error", "Error scanning image: ${e.toString()}");
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      CustomDialogStack.showError(context, title, message, () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
}

// Custom painter for animated scan line
class ScanLinePainter extends CustomPainter {
  final double scanPosition;
  final Color color;

  const ScanLinePainter({required this.scanPosition, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color,
              color.withValues(alpha: 0.1),
            ],
          ).createShader(
            Rect.fromPoints(
              Offset(0, size.height * scanPosition),
              Offset(size.width, size.height * scanPosition + 2),
            ),
          );

    // Draw scan line
    canvas.drawLine(
      Offset(0, size.height * scanPosition),
      Offset(size.width, size.height * scanPosition),
      paint,
    );

    // Draw glow effect
    final glowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(0, size.height * scanPosition),
      Offset(size.width, size.height * scanPosition),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) {
    return scanPosition != oldDelegate.scanPosition ||
        color != oldDelegate.color;
  }
}
