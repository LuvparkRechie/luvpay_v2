import 'dart:io';

import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:luvpay/features/helpcenter/support_ticket_service.dart';
import 'package:luvpay/shared/widgets/tap_guard_keys.dart';

enum HelpActionType { chat, call, email }

class HelpCenterAction {
  final HelpActionType type;
  final IconData icon;
  final String label;
  final String tapGuardKey;

  const HelpCenterAction({
    required this.type,
    required this.icon,
    required this.label,
    required this.tapGuardKey,
  });
}

class SupportContact {
  final String label;
  final String phoneNumber;
  final IconData icon;

  const SupportContact({
    required this.label,
    required this.phoneNumber,
    this.icon = Iconsax.call,
  });
}

class SupportUserProfile {
  final String firstName;
  final String middleName;
  final String lastName;
  final String mobileNo;
  final String email;

  const SupportUserProfile({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.mobileNo,
    required this.email,
  });

  factory SupportUserProfile.fromMap(Map<dynamic, dynamic> data) {
    return SupportUserProfile(
        firstName: _readString(data, const ["first_name", "firstName"]),
        middleName: _readString(data, const ["middle_name", "middleName"]),
        lastName: _readString(data, const ["last_name", "lastName"]),
        mobileNo: _readString(data, const ["mobile_no", "mobileNo", "mobile"]),
        email: _readString(data, const ["email", "email_address"]));
  }

  static SupportUserProfile? tryParse(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return tryParse(data.first);
    }

    if (data is Map) {
      return SupportUserProfile.fromMap(data);
    }

    return null;
  }

  static String _readString(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != "null") return text;
    }

    return "";
  }

  bool get hasValidMobileNo => RegExp(r'^09\d{9}$').hasMatch(localMobileNo);

  bool get canUseEmailSupport =>
      firstName.isNotEmpty && email.isNotEmpty && hasValidMobileNo;

  List<String> get missingEmailSupportFields {
    final fields = <String>[];
    if (firstName.isEmpty) fields.add("first name");
    if (!hasValidMobileNo) fields.add("mobile number");
    if (email.isEmpty) fields.add("email");
    return fields;
  }

  String get displayName {
    return [firstName, middleName, lastName]
        .where((value) => value.trim().isNotEmpty)
        .join(" ")
        .trim();
  }

  String get localMobileNo {
    final digits = mobileNo.replaceAll(RegExp(r'\D'), "");

    if (digits.startsWith("63") && digits.length == 12) {
      return "0${digits.substring(2)}";
    }

    if (digits.startsWith("9") && digits.length == 10) {
      return "0$digits";
    }

    if (digits.startsWith("09") && digits.length == 11) {
      return digits;
    }

    return mobileNo;
  }

  String get databaseLookupMobileNo {
    final digits = mobileNo.replaceAll(RegExp(r'\D'), "");

    if (digits.startsWith("63") && digits.length == 12) return digits;
    if (digits.startsWith("09") && digits.length == 11) {
      return "63${digits.substring(1)}";
    }
    if (digits.startsWith("9") && digits.length == 10) return "63$digits";

    return digits;
  }
}

class HelpCenterController extends GetxController {
  static const String supportEmail = 'luvpay@luvpark.ph';
  static const String supportAvailability =
      "Available: Monday - Sunday, 8:00 AM - 5:00 PM";

  static const List<String> ticketCategories = [
    "Account Concern",
    "Payment Issue",
    "Refund",
    "Parking Issue",
    "App Bug",
    "Verification",
    "Others",
  ];

  static const List<HelpCenterAction> supportActions = [
    HelpCenterAction(
      type: HelpActionType.chat,
      icon: Iconsax.message,
      label: 'Chat with us',
      tapGuardKey: TapGuardKeys.chatSupport,
    ),
    HelpCenterAction(
      type: HelpActionType.call,
      icon: Iconsax.call,
      label: 'Call us',
      tapGuardKey: TapGuardKeys.openCallSupport,
    ),
    HelpCenterAction(
      type: HelpActionType.email,
      icon: Iconsax.direct_inbox,
      label: 'Email us',
      tapGuardKey: TapGuardKeys.emailSupport,
    ),
  ];

  static const List<SupportContact> supportContacts = [
    SupportContact(label: "Globe", phoneNumber: "09171234567"),
    SupportContact(label: "Smart", phoneNumber: "09081234567"),
    SupportContact(label: "Landline", phoneNumber: "0321234567"),
  ];

  SupportContact get primarySupportContact => supportContacts.first;

  Future<SupportUserProfile?> getEmailSupportProfile() async {
    final savedProfile =
        SupportUserProfile.tryParse(await Authentication().getUserData2());

    final mobileNo = savedProfile?.databaseLookupMobileNo ?? "";
    if (mobileNo.isEmpty) return savedProfile;

    final databaseProfile = await _fetchDatabaseProfile(mobileNo);
    return databaseProfile ?? savedProfile;
  }

  Future<SupportUserProfile?> _fetchDatabaseProfile(String mobileNo) async {
    try {
      final response = await Functions().requestHandler(
          apiKey: "${ApiKeys.getRecipient}?mobile_no=$mobileNo");

      if (response == "No Internet" || response == null) return null;

      return SupportUserProfile.tryParse(response);
    } catch (e) {
      debugPrint("Unable to fetch support user profile: $e");
      return null;
    }
  }

  Future<SupportTicketResult> submitSupportTicket({
    required SupportUserProfile profile,
    required String category,
    required String message,
    File? attachment,
  }) {
    return SupportTicketService().submitTicket(
        name: profile.displayName,
        mobileNo: profile.localMobileNo,
        email: profile.email,
        category: category,
        message: message,
        attachment: attachment);
  }
}
