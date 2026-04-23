import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../../auth/authentication.dart';
import '../../../core/network/http/api_keys.dart';
import '../../../core/network/http/http_request.dart';

class ShareUserBottomSheet extends StatefulWidget {
  final String? initialValue;
  final Function(String mobile, String name, bool isValid) onSelected;
  const ShareUserBottomSheet({
    super.key,
    this.initialValue,
    required this.onSelected,
  });

  @override
  State<ShareUserBottomSheet> createState() => _ShareUserBottomSheetState();
}

class _ShareUserBottomSheetState extends State<ShareUserBottomSheet> {
  final TextEditingController controller = TextEditingController();
  Map<String, dynamic>? recipientData;
  String? displayName;
  bool isLoadingUser = false;
  bool isValidUser = true;
  Timer? _debounce;
  String? errorText;
  bool canShare = false;
  bool isLoading = false;
  String? currentUserMobile;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await Authentication().getUserData2();
    currentUserMobile = data["mobile_no"]?.toString();
  }

  String? normalizeMobile(String input) {
    var s = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return null;

    if (s.length == 12 && s.startsWith('63')) return s;
    if (s.length == 11 && s.startsWith('09')) return '63${s.substring(1)}';
    if (s.length == 10 && s.startsWith('9')) return '63$s';

    if (s.length >= 10) {
      final last10 = s.substring(s.length - 10);
      if (last10.startsWith('9')) return '63$last10';
    }

    return null;
  }

  void _validate(String value) {
    final clean = value.replaceAll(" ", "");

    if (clean.isEmpty) {
      errorText = null;
      canShare = false;
      setState(() {});
      return;
    }

    if (clean.length != 10 || clean.startsWith('0')) {
      errorText = "Invalid mobile number";
      canShare = false;
      setState(() {});
      return;
    }

    final normalized = normalizeMobile(clean);

    if (normalized == null) {
      errorText = "Invalid mobile number";
      canShare = false;
      setState(() {});
      return;
    }

    if (currentUserMobile != null && normalized == currentUserMobile) {
      errorText = "You cannot share to your own number";
      canShare = false;
      setState(() {});
      return;
    }
    errorText = null;
    canShare = true;

    setState(() {});
  }

  Future<void> _lookupUser(String mobile) async {
    final normalized = normalizeMobile(mobile);
    if (normalized == null) return;

    setState(() {
      isLoadingUser = true;
      displayName = null;
      isValidUser = true;
    });

    try {
      final api = "${ApiKeys.getRecipient}?mobile_no=$normalized";

      final result = await HttpRequestApi(api: api).get();

      if (result == null || result["user_id"] == 0) {
        setState(() {
          isValidUser = false;
          displayName = "Unknown user";
        });
        return;
      }

      final rawName = Functions().getDisplayName(result);
      final masked = maskName(rawName);

      setState(() {
        recipientData = result;
        displayName = masked;
        isValidUser = true;
      });
    } catch (_) {
      setState(() {
        isValidUser = false;
        displayName = "Error fetching user";
      });
    } finally {
      setState(() => isLoadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: Container(
        color: cs.surface,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            LuvpayText(
              text: "Share Subwallet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            CustomMobileNumber(
              controller: controller,
              hintText: "9XXXXXXXXX",
              onChange: (value) {
                final clean = value.replaceAll(" ", "");

                _validate(value);

                _debounce?.cancel();
                _debounce = Timer(
                  Duration(milliseconds: 100),
                  () {
                    if (clean.length == 10 && canShare) {
                      _lookupUser(clean);
                    }
                  },
                );
              },
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              LuvpayText(
                text: errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (isLoadingUser) ...[
              const SizedBox(height: 10),
              Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Checking account..."),
                ],
              ),
            ],
            if (!isLoadingUser && displayName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isValidUser ? Icons.verified : Icons.error,
                    size: 16,
                    color: isValidUser ? Colors.blue : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LuvpayText(
                      text: displayName!,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isValidUser ? Colors.blue : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            LuvNeuPress.rectangle(
              onTap: (canShare &&
                      !isLoading &&
                      !isLoadingUser &&
                      isValidUser &&
                      displayName != null)
                  ? () async {
                      final normalized = normalizeMobile(controller.text);

                      widget.onSelected(
                        normalized!,
                        displayName ?? "",
                        isValidUser,
                      );

                      Navigator.pop(context);
                    }
                  : null,
              background: (canShare &&
                      !isLoadingUser &&
                      isValidUser &&
                      displayName != null)
                  ? cs.primary
                  : cs.primary.withOpacity(0.4),
              radius: BorderRadius.circular(16),
              child: SizedBox(
                height: 50,
                child: Center(
                  child: LuvpayText(
                    text: isLoadingUser ? "Checking..." : "Share",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColorV2.background,
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
}
