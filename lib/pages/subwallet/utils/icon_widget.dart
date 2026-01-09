import 'dart:convert'; // Add this import at the top
import 'package:flutter/foundation.dart';

// Helper function to create a widget from icon data (handles both string names and Base64)
Widget _getIconWidget(dynamic iconData, {double size = 24, Color? color}) {
  if (iconData == null) {
    return Icon(Iconsax.wallet, size: size, color: color);
  }

  final iconString = iconData.toString();

  // Check if it's a Base64 encoded image (starts with data:image/)
  if (iconString.startsWith('data:image/')) {
    try {
      // Extract the Base64 part from the data URL
      final base64String = iconString.split(',').last;
      final bytes = base64.decode(base64String);

      return Image.memory(
        bytes,
        width: size,
        height: size,
        color: color,
        fit: BoxFit.contain,
      );
    } catch (e) {
      print('Error decoding Base64 icon: $e');
      return Icon(Iconsax.wallet, size: size, color: color);
    }
  }

  // If it's a simple string like "wallet", "car", etc., use Icon
  return Icon(_mapIconFromString(iconString), size: size, color: color);
}
