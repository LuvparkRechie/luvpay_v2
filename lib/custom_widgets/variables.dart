import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pointycastle/export.dart' as crypto;
import 'package:screenshot/screenshot.dart';

import '../functions/functions.dart';

class Variables {
  static Timer? inactiveTmr;
  static Timer? bgProcess;
  static BuildContext? ctxt;
  static late Size screenSize;
  static void init(BuildContext context) {
    ctxt = context;
    screenSize = MediaQuery.of(context).size;
  }

  static String paMessageTable = 'pa_message';
  static String vhBrands = 'vehicle_brands';
  static String locSharing = 'location_sharing_table';
  static String notifTable = 'notification_table';
  static String shareLocTable = 'share_location_table';
  static String lastBooking = 'booking_table';
  static RxList subsVhList = [].obs; //Subscribed Vehicle List
  //static void Timer? backgroundTimer
  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static var maskFormatter = MaskTextInputFormatter(
    mask: '### ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  static String mobileRegex = r"^[1-9]\d{9}$";

  static String mapApiKey = 'AIzaSyCaDHmbTEr-TVnJY8dG0ZnzsoBH3Mzh4cE';
  static String popUpMessageOutsideArea =
      'Booking request denied. Location exceeds service area. Check and update location information.';
  static String popUpMessageOutsideAreas =
      'Location exceeds service area. Check and update location information. Retry booking.';
  static String version = "";
  static int loginAttemptCount = 0;
  static List civilStatusData = [
    {"text": "Single", "value": "S"},
    {"text": "Married", "value": "M"},
    {"text": "Widowed", "value": "W"},
    {"text": "Divorced/Separated", "value": "D"},
  ];
  //Data Encryption
  static String capitalizeAllWord(String value) {
    if (value.isEmpty) return "";
    var result = value[0].toUpperCase();
    for (int i = 1; i < value.length; i++) {
      if (value[i - 1] == " ") {
        result = result + value[i].toUpperCase();
      } else {
        result = result + value[i];
      }
    }
    return result;
  }

  static Future<Uint8List> encryptData(
    Uint8List secretKey,
    Uint8List iv,
    String plainText,
  ) async {
    final cipher = crypto.GCMBlockCipher(crypto.AESFastEngine());

    final keyParams = crypto.KeyParameter(secretKey);
    final cipherParams = crypto.ParametersWithIV(keyParams, iv);
    cipher.init(true, cipherParams);

    final encodedPlainText = utf8.encode(plainText);
    final cipherText = cipher.process(Uint8List.fromList(encodedPlainText));

    return Uint8List.fromList(cipherText);
  }

  static Future<bool> withinOneHourRange(DateTime targetDateTime) async {
    DateTime currentDateTime = await Functions.getTimeNow();

    DateTime oneHourAgo = currentDateTime.subtract(const Duration(hours: 1));
    return targetDateTime.isAfter(oneHourAgo) &&
        targetDateTime.isBefore(currentDateTime);
  }

  static Future<bool> withinDayRange(DateTime targetDateTime) async {
    DateTime currentDateTime = await Functions.getTimeNow();
    DateTime oneHourAgo = currentDateTime.subtract(const Duration(hours: 1));
    return targetDateTime.isAfter(oneHourAgo) &&
        targetDateTime.isBefore(currentDateTime);
  }

  static String formatDateLocal(String dateString) {
    DateTime timestamp = DateTime.parse(dateString);
    String formattedTime = DateFormat('MMM d, yyyy hh:mm a').format(timestamp);
    return formattedTime;
  }

  static String arrayBufferToBase64(ByteBuffer buffer) {
    var bytes = Uint8List.view(buffer);
    var base64String = base64.encode(bytes);
    return base64String;
  }

  static Uint8List hexStringToArrayBuffer(String hexString) {
    final result = Uint8List(hexString.length ~/ 2);
    for (var i = 0; i < hexString.length; i += 2) {
      result[(i ~/ 2)] = int.parse(hexString.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  // static String replaceNonNumbers(String input) {
  //   String inpValue = input;
  //   if(input.contains("."))

  //   return input.replaceAll(RegExp(r'[^0-9]'), '');
  // }

  static ByteBuffer concatBuffers(Uint8List buffer1, Uint8List buffer2) {
    final tmp = Uint8List(buffer1.length + buffer2.length);
    tmp.setAll(0, buffer1);
    tmp.setAll(buffer1.length, buffer2);
    return tmp.buffer;
  }

  static Uint8List generateRandomNonce() {
    var random = Random.secure();
    var iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  static String convertTime(String time) {
    // Parse the input time string
    DateTime parsedTime = DateFormat("HH:mm:ss").parse(time);
    // Format the time in 12-hour format with AM/PM
    String twelveHourFormat = DateFormat("h:mm a").format(parsedTime);

    return twelveHourFormat;
  }

  static String convertDateFormat(String dateString) {
    // Parse the original date string
    DateTime originalDate = DateTime.parse(dateString);

    // Format the date to "thu 23 jan" format
    DateFormat newDateFormat = DateFormat('E MMM dd');
    String formattedDate = newDateFormat.format(originalDate);

    return formattedDate;
  }

  static String convertBday(dateString) {
    DateTime dateTime = DateTime.parse(dateString);

    // Format the date
    String formattedDate = DateFormat('MMMM d, yyyy').format(dateTime);
    return formattedDate;
  }

  static String capitalize(String value) {
    if (value.trim().isEmpty) return "";
    return "${value[0].toUpperCase()}${value.substring(1).toLowerCase()}";
  }

  static String maskMobileNumber(
    String mobileNumber, {
    int visibleStartDigits = 4,
    int visibleEndDigits = 4,
  }) {
    if (mobileNumber.length <= (visibleStartDigits + visibleEndDigits)) {
      return mobileNumber;
    }

    // Keep the '+' sign if present
    String prefix = mobileNumber.startsWith('+') ? '+' : '';
    String cleanNumber = mobileNumber.replaceFirst('+', '');

    final startPart = cleanNumber.substring(0, visibleStartDigits);
    final maskedPart =
        '*' * (cleanNumber.length - visibleStartDigits - visibleEndDigits);
    final endPart = cleanNumber.substring(
      cleanNumber.length - visibleEndDigits,
    );

    return '$prefix$startPart$maskedPart$endPart';
  }

  static String hideName(String name) {
    if (name.isEmpty) {
      return ''; // Handle empty names as needed
    } else if (name.length == 1) {
      return name; // Show the full name if it's 2 characters or less
    } else if (name.length == 2) {
      return "${name[0]}*"; // Show the full name if it's 2 characters or less
    } else if (name.length == 3) {
      return "${name.substring(0, 2)}*"; // Show the full name if it's 2 characters or less
    } else {
      return '${name.substring(0, 2)}${'*' * (name.length - 2)}'; // Show the first two letters and the rest with asterisks
    }
  }

  static String transformFullName(String fullName) {
    if (fullName.isEmpty) {
      return ''; // Handle empty names as needed
    }

    List<String> nameParts = [];
    if (fullName.contains(" ")) {
      nameParts = fullName.split(" ");
    } else {
      nameParts = [fullName];
    }
    String transformedFullName = '';
    for (var name in nameParts) {
      if (transformedFullName.isNotEmpty) {
        transformedFullName += ' '; // Add space between names
      }
      transformedFullName += hideName(name);
    }

    return transformedFullName;
  }

  static Future<void> pageTrans(Widget param, BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => param),
    );
  }

  static String greeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  static String displayLastFourDigitsWithAsterisks(int number) {
    String numberString = number.toString();
    if (numberString.length >= 4) {
      String asterisks = '●' * (numberString.length - 4);
      return '$asterisks${numberString.substring(numberString.length - 4)}';
    } else {
      // Handle cases where the number has less than four digits
      return numberString;
    }
  }

  static var regExpRestrictFormatter = FilteringTextInputFormatter.allow(
    RegExp(r"[a-zA-Z0-9]+|\s"),
  );

  //Password strength validation
  static int getPasswordStrength(String password) {
    if (password.isEmpty) {
      return 0;
    } else if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return 4; // Strong
    } else if ((password.length >= 8 && password.contains(RegExp(r'[0-9]'))) ||
        (password.length >= 8 && password.contains(RegExp(r'[A-Z]')))) {
      return 3; // Medium
    } else if (password.length >= 8 ||
        (password.contains(RegExp(r'[0-9]')) ||
            password.contains(RegExp(r'[A-Z]')))) {
      return 2; // Weak
    } else {
      return 1; // Very Weak
    }
  }

  //Password strength validation
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 1:
        return 'Weak Password';
      case 2:
        return 'Weak Password';
      case 3:
        return 'Medium Password';
      case 4:
        return 'Strong Password';
      default:
        return '';
    }
  }

  //Password strength validation
  static Color getColorForPasswordStrength(int strength) {
    switch (strength) {
      case 1:
        return AppColorV2.incorrectState;
      case 2:
        return AppColorV2.incorrectState;
      case 3:
        return AppColorV2.partialState;
      case 4:
        return AppColorV2.correctState;
      default:
        return AppColorV2.incorrectState;
    }
  }

  //Convert to minutes
  static String convertToTime(int totalMinutes) {
    // Calculate hours and minutes
    // int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    // Format the time as HH:MM
    // String formattedTime = '$hours:${minutes.toString().padLeft(2, '0')}';

    return minutes.toString().padLeft(2, '0');
  }

  static double convertToMeters(String distanceString) {
    // Extract numeric part of the string
    String numericPart = distanceString.replaceAll(RegExp(r'[^0-9.]'), '');

    // Parse numeric part to double
    double distanceValue = double.tryParse(numericPart) ?? 0;

    // Convert to meters
    return distanceValue * 1000;
  }

  static String convertDistance(String distanceString) {
    // Extract numeric part of the string
    String numericPart = distanceString.replaceAll(RegExp(r'[^0-9.]'), '');

    // Parse numeric part to double
    double distanceValue = double.tryParse(numericPart) ?? 0;
    // Convert to meters

    double dist = distanceValue * 1000;
    if (distanceValue < 1)
      return "$dist meters";
    else
      return "$distanceValue km";
  }

  static double convertToMeters3(String distanceString) {
    // Extract numeric part of the string
    String numericPart = distanceString.replaceAll(RegExp(r'[^0-9.]'), '');

    // Parse numeric part to double
    double distanceValue = double.tryParse(numericPart) ?? 0;

    // Check if "km" (kilometers) is present in the string
    bool isKilometers = distanceString.toLowerCase().contains('km');

    // Convert to meters
    return isKilometers ? distanceValue * 1000 : distanceValue;
  }

  static double convertToMeters2(String distanceString) {
    // Extract numeric part of the string
    String numericPart = distanceString.replaceAll(RegExp(r'[^0-9.]'), '');

    // Parse numeric part to double
    double distanceValue = double.tryParse(numericPart) ?? 0;

    // Check if "km" (kilometers) is present in the string
    bool isKilometers = distanceString.toLowerCase().contains('km');

    // Convert to meters
    return isKilometers ? distanceValue * 1000 : distanceValue;
  }

  static String parseDistance(double distance) {
    if (distance >= 1000) {
      // Convert to kilometers
      double kilometers = distance / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${double.parse(distance.toStringAsFixed(1)).round()} m';
    }
  }

  static String parseDistanceKm(double distance) {
    if (distance >= 1) {
      // Convert to kilometers
      double kilometers = distance / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${double.parse(distance.toStringAsFixed(1)).round()} m';
    }
  }

  //COnvert 12 hours format sample:18:00
  static String convert24HourTo12HourFormat(String time24Hour) {
    List<String> parts = time24Hour.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);

    String period = hours < 12 ? 'AM' : 'PM';
    hours = hours % 12;
    hours = hours == 0 ? 12 : hours; // Convert 0 to 12 for 12-hour format

    return "$hours:${minutes.toString().padLeft(2, '0')} $period";
  }

  //Split by 2 sample:1800
  static List<String> splitNumberIntoPairs(String numberString, int pairSize) {
    List<String> digitPairs = [];

    for (int i = 0; i < numberString.length; i += pairSize) {
      int end = i + pairSize;
      if (end > numberString.length) {
        end = numberString.length;
      }
      digitPairs.add(numberString.substring(i, end));
    }

    return digitPairs;
  }

  //Generate a list of number  with a specified length
  static List<int> generateNumberList(int length) {
    return List.generate(length, (index) => index + 1);
  }

  //2020-20-20 to 2020/20/20
  static String formatDate(String inputDateString) {
    String twoDigits(int n) {
      // Helper function to add leading zeros to single-digit numbers
      return n.toString().padLeft(2, '0');
    }

    // Parse the input date string into a DateTime object
    DateTime dateTime = DateTime.parse(inputDateString);

    // Format the DateTime object into the desired string format
    String formattedDateString =
        "${dateTime.year}/${twoDigits(dateTime.month)}/${twoDigits(dateTime.day)}";

    return formattedDateString;
  }

  //convert widget to image and display on map or capture as png
  static Future<Uint8List> capturePng(
    BuildContext context,
    Widget printWidget,
    int size,
    bool isOval,
  ) async {
    Uint8List markerBeytes;
    Uint8List bytes = await ScreenshotController().captureFromWidget(
      printWidget,
      delay: const Duration(milliseconds: 10),
    );
    Uint8List pngBytes = bytes.buffer.asUint8List();

    markerBeytes =
        isOval
            // ignore: use_build_context_synchronously
            ? await createOvalImage(context, base64Encode(pngBytes), size)
            // ignore: use_build_context_synchronously
            : await getMarkerIcon(context, base64Encode(pngBytes), size);

    return markerBeytes;
  }

  static Future<Uint8List> createOvalImage(
    BuildContext context,
    String base64String,
    int width,
  ) async {
    Uint8List bytes = base64Decode(base64String);
    double targetWidth = MediaQuery.of(context).devicePixelRatio * width;

    // Compress the image
    Uint8List compressedBytes = await compressImage(bytes);

    // Decode the compressed image as a ui.Image
    ui.Image image = await decodeImageFromList(compressedBytes);

    // Create an oval canvas with the target width
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    Rect ovalRect = Rect.fromLTWH(
      0,
      0,
      targetWidth,
      targetWidth * 0.5,
    ); // Adjust the height ratio to make it oval
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        ovalRect,
        Radius.circular(targetWidth / 10), // Adjust the radius as needed
      ),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ovalRect,
      Paint(),
    );

    // Encode the oval image as PNG
    ui.Picture picture = recorder.endRecording();
    ui.Image encodedImage = await picture.toImage(
      targetWidth.round(),
      (targetWidth * 0.5).round(),
    );
    ByteData? byteData = await encodedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> getMarkerIcon(
    BuildContext context,
    String base64String,
    int width,
  ) async {
    // tawga ne
    // Uint8List iconBytes =  await _getMarkerIcon(dataRow['profile_pic'], 50);
    //   BitmapDescriptor icon = BitmapDescriptor.fromBytes(iconBytes);
    Uint8List bytes = base64Decode(base64String);
    double targetWidth = MediaQuery.of(context).devicePixelRatio * width;
    ui.Image image = await decodeImageFromList(bytes);
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, targetWidth, targetWidth),
        Radius.circular(targetWidth / 2),
      ),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth, targetWidth),
      Paint(),
    );

    ui.Picture picture = recorder.endRecording();
    ui.Image encodedImage = await picture.toImage(
      targetWidth.round(),
      targetWidth.round(),
    );
    ByteData? byteData = await encodedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  //Reduce Image size
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    // Compress the image
    List<int> compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: 500, // Set a lower minimum height
      minWidth: 900, // Set a lower minimum width
      quality: 50,
      format: CompressFormat.png, // Specify the desired format
    );

    // Convert compressed bytes to Uint8List
    return Uint8List.fromList(compressedBytes);
  }

  //Format sample August 16,1998
  static String timeNow() {
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat('MMMM d, yyyy h:mm a');
    String formattedDate = dateFormat.format(now);
    return formattedDate;
  }

  static String formatDistance(dynamic distance) {
    if (distance < 1000) {
      // Assume distance is in meters
      return '${distance.toStringAsFixed(2)} meters';
    } else {
      // Assume distance is in kilometers
      double distanceInMeters = distance * 1000;
      return '${distanceInMeters.toStringAsFixed(2)} km';
    }
  }

  static String gagi(dynamic distance) {
    if (distance < 1000) {
      // Assume distance is in meters
      return '$distance meters';
    } else {
      // Assume distance is in kilometers
      double distanceKm = double.parse(distance.toString()) / 1000;

      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  static String formatTimeLeft(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'second' : 'seconds'} left';
    } else {
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);
      if (hours == 0) {
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} left';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} & $minutes ${minutes == 1 ? 'minute' : 'minutes'} left';
      }
    }
  }

  static Future<Uint8List> getBytesFromAsset(
    String path,
    double scaleFactor,
  ) async {
    ByteData data = await rootBundle.load(path);

    // Load the image data and get the original size
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    final originalImage = frameInfo.image;

    // Calculate new dimensions
    final originalWidth = originalImage.width.toDouble();
    final originalHeight = originalImage.height.toDouble();
    final targetWidth = (originalWidth * scaleFactor).toInt();
    final targetHeight = (originalHeight * scaleFactor).toInt();

    // Create a new codec to decode the resized image
    ui.Codec resizedCodec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    ui.FrameInfo resizedFrameInfo = await resizedCodec.getNextFrame();
    ByteData? resizedByteData = await resizedFrameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return resizedByteData!.buffer.asUint8List();
  }

  static Future<Uint8List> getResizedImage(
    String assetPath,
    int targetWidth,
    int targetHeight,
  ) async {
    final Uint8List bytes =
        (await rootBundle.load(assetPath)).buffer.asUint8List();

    // Resize using flutter_image_compress with high quality
    final List<int> result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: 88, // Adjust quality as needed
    );

    return Uint8List.fromList(result);
  }

  // '16:30'; format
  static String timeFormatter(String time) {
    try {
      // Parse the 24-hour time into a DateTime object
      DateFormat format24Hour = DateFormat('HH:mm');
      DateTime dateTime = format24Hour.parse(time.trim());

      // Convert to 12-hour format with AM/PM
      DateFormat format12Hour = DateFormat('h:mm a');
      return format12Hour.format(dateTime);
    } catch (e) {
      // Handle parsing errors if necessary

      return 'Invalid time'; // Return a default value or error message
    }
  } // '16:30'; format

  static String timeFormatter2(String time) {
    try {
      // Parse the 24-hour time into a DateTime object
      DateFormat format24Hour = DateFormat('HH:mm');
      DateTime dateTime = format24Hour.parse(time.trim());

      // Convert to 12-hour format with AM/PM
      DateFormat format12Hour = DateFormat('h:mm a');

      return format12Hour.format(dateTime);
    } catch (e) {
      // Handle parsing errors if necessary

      return 'Invalid time'; // Return a default value or error message
    }
  }

  //TEXT TO SPEECH Variables
  // static TextToSpeech tts = TextToSpeech();
  static String defaultLanguage = 'en-US';

  static double volume = 1; // Range: 0-1
  static double rate = 1.0; // Range: 0-2
  static double pitch = 1.0; // Range: 0-2

  static String? language;
  static String? languageCode;
  static List<String> languages = <String>[];
  static List<String> languageCodes = <String>[];
  static String? voice;
  static double computeZoomLevel(double latitude, double radius) {
    const double initialMapSize = 156543.03; // Meters at zoom level 0
    double metersPerPixel = initialMapSize * cos(latitude * pi / 180);
    double zoom = log(metersPerPixel / radius) / log(2);
    return zoom.toDouble();
  }

  static showSecurityPopUp(String msg) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        margin: EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: MediaQuery.of(Get.context!).size.width * 0.27,
        ),
        elevation: 5.0,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0)),
        content: Wrap(
          children: [
            Center(
              child: Text(
                'Your device is $msg. '
                'For security reasons, the app will now close.',
              ),
            ),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 4), () {
      FlutterExitApp.exitApp(iosForceExit: true);
    });
  }
  // haversineDistance Formula to get distance between lat long

  double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of Earth in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  //dynamic dialog

  static snackbarDynamicDialog(String msg, {context}) {
    ScaffoldMessenger.of(context ?? Get.context!).showSnackBar(
      SnackBar(
        margin: EdgeInsets.only(
          // horizontal: 20.0,
          // vertical: MediaQuery.of(Get.context!).size.width * 0.27,
          bottom: 20, // 20px from the bottom
          left: 20, // Optional left padding
          right: 20, // Optional right padding
        ),
        elevation: 5.0,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0)),
        content: Wrap(children: [Center(child: Text(msg))]),
      ),
    );
  }
}
