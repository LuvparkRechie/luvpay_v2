// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/shared/widgets/custom_profile_image.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../shared/widgets/upper_case_formatter.dart';
import '../../shared/widgets/variables.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import '../../core/network/http/http_request.dart';
import '../routes/routes.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  Map<String, dynamic> userData = {};
  String civilStatuss = "";
  final ImagePicker _picker = ImagePicker();
  String? imageBase64;
  File? imageFile;
  List regionData = [];
  String myName = "";
  String province = "";
  String myprofile = "";
  bool isLoading = true;
  bool isNetConn = true;
  ImageProvider? profileImage;

  final TextEditingController referralController = TextEditingController();

  bool get _isVerified => userData["is_verified"] == "N";

  @override
  void initState() {
    super.initState();
    initialize();
    getUserData();
  }

  Future<void> initialize() async {
    final profilepic = await Authentication().getUserProfilePic();
    myprofile = profilepic;

    if (profilepic.isNotEmpty) {
      final bytes = base64Decode(profilepic);
      profileImage = MemoryImage(bytes);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> getUserData() async {
    final data = await Authentication().getUserData2();
    if (data == null || data.isEmpty) return;

    if (!mounted) return;
    setState(() => userData = data);
  }

  String birthday(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return rawDate;
    }
  }

  void showBottomSheetCamera() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext cont) {
        final theme = Theme.of(cont);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final bg = cs.surface;
        final surface2 = cs.surfaceContainerHighest;
        final stroke = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.35);
        final titleColor = cs.onSurface;
        final bodyColor = cs.onSurface.withOpacity(0.72);

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(color: stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(isDark ? 0.22 : 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Neumorphic(
                style: LuvNeu.card(
                  radius: BorderRadius.circular(20),
                  color: bg,
                  borderColor: stroke,
                  borderWidth: 1,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.camera_alt_rounded,
                          color: cs.primary,
                        ),
                        title: LuvpayText(
                          text: 'Take Photo',
                          style: AppTextStyle.body1(
                            cont,
                          ).copyWith(fontWeight: FontWeight.w600),
                          color: titleColor,
                        ),
                        subtitle: LuvpayText(
                          text: 'Use your camera',
                          style: AppTextStyle.body2(cont),
                          color: bodyColor,
                        ),
                        onTap: () {
                          Get.back();
                          takePhoto(ImageSource.camera);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        tileColor: surface2,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                        color: stroke.withOpacity(0.8),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.photo_library_rounded,
                          color: cs.primary,
                        ),
                        title: LuvpayText(
                          text: 'Choose from Gallery',
                          style: AppTextStyle.body1(
                            cont,
                          ).copyWith(fontWeight: FontWeight.w600),
                          color: titleColor,
                        ),
                        subtitle: LuvpayText(
                          text: 'Select an existing photo',
                          style: AppTextStyle.body2(cont),
                          color: bodyColor,
                        ),
                        onTap: () {
                          Get.back();
                          takePhoto(ImageSource.gallery);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        tileColor: surface2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              LuvNeuPress.rectangle(
                radius: BorderRadius.circular(20),
                onTap: () => Get.back(),
                background: cs.surface,
                borderColor: stroke,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.close_rounded, color: cs.error),
                    title: LuvpayText(
                      text: 'Cancel',
                      style: AppTextStyle.body1(
                        cont,
                      ).copyWith(fontWeight: FontWeight.w700),
                      color: cs.error,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(cont).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void takePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      preferredCameraDevice: CameraDevice.front,
      source: source,
      imageQuality: Platform.isIOS ? 14 : 20,
      maxWidth: Platform.isIOS ? 200 : 400,
      requestFullMetadata: true,
    );

    imageFile = pickedFile != null ? File(pickedFile.path) : null;

    if (imageFile != null) {
      imageFile!.readAsBytes().then((data) {
        imageBase64 = base64.encode(data);
        submitProfilePic();
      });
    } else {
      if (!mounted) return;
      setState(() => imageBase64 = null);
    }
  }

  void submitProfilePic() async {
    final ctx = Get.overlayContext ?? context;
    CustomDialogStack.showLoading(ctx);

    final myData = await Authentication().getUserData2();

    final Map<String, dynamic> parameters = {
      "mobile_no": myData["mobile_no"],
      "last_name": myData["last_name"],
      "first_name": myData["first_name"],
      "middle_name": myData["middle_name"],
      "birthday": myData["birthday"]?.toString().split("T")[0] ?? "",
      "gender": myData["gender"],
      "civil_status": myData["civil_status"],
      "address1": myData["address1"],
      "address2": myData["address2"],
      "brgy_id": myData["brgy_id"] ?? "",
      "city_id": myData["city_id"] ?? "",
      "province_id": myData["province_id"] ?? "",
      "region_id": myData["region_id"] ?? "",
      "zip_code": myData["zip_code"] ?? "",
      "email": myData["email"],
      "secq_id1": myData["secq_id1"] ?? "",
      "secq_id2": myData["secq_id2"] ?? "",
      "secq_id3": myData["secq_id3"] ?? "",
      "seca1": myData["seca1"],
      "seca2": myData["seca2"],
      "seca3": myData["seca3"],
      "image_base64": imageBase64!,
    };

    HttpRequestApi(
      api: ApiKeys.putUpdateUserProf,
      parameters: parameters,
    ).putBody().then((res) async {
      Get.back();

      if (res == "No Internet") {
        CustomDialogStack.showConnectionLost(ctx, () => Get.back());
        return;
      }

      if (res == null) {
        CustomDialogStack.showServerError(ctx, () => Get.back());
        return;
      }

      if (res["success"] == "Y") {
        if (myprofile != imageBase64) {
          myprofile = imageBase64!;
          profileImage = MemoryImage(base64Decode(myprofile));
        }

        Authentication().setProfilePic(jsonEncode(myprofile));

        if (!mounted) return;
        setState(() {});
      } else {
        CustomDialogStack.showError(
          ctx,
          "luvpay",
          res["msg"],
          () => Get.back(),
        );
      }
    });
  }

  void getRegions() async {
    final ctx = Get.overlayContext ?? context;
    CustomDialogStack.showLoading(ctx);

    final returnData = await HttpRequestApi(api: ApiKeys.getRegion).get();
    Get.back();

    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(ctx, () => Get.back());
      return;
    }

    if (returnData == null) {
      CustomDialogStack.showServerError(ctx, () => Get.back());
      return;
    }

    if (returnData["items"].isNotEmpty) {
      regionData = returnData["items"];
      Navigator.pushNamed(context, Routes.updProfile, arguments: regionData);
    } else {
      CustomDialogStack.showServerError(ctx, () => Get.back());
    }
  }

  void getProvince(regionId) async {
    final ctx = Get.overlayContext ?? context;
    final params = "${ApiKeys.getProvince}?p_region_id=$regionId";
    isLoading = false;

    final returnData = await HttpRequestApi(api: params).get();

    if (returnData == "No Internet") {
      isNetConn = false;
      CustomDialogStack.showConnectionLost(ctx, () => Get.back());
      return;
    }

    if (returnData == null) {
      CustomDialogStack.showServerError(ctx, () => Get.back());
      isNetConn = true;
      return;
    }

    if (returnData["items"].isNotEmpty) {
      isNetConn = true;
      province =
          returnData["items"]
              .where(
                (element) => element["value"] == userData[0]["province_id"],
              )
              .toList()[0]["text"];
      return;
    }

    isNetConn = true;
    CustomDialogStack.showServerError(ctx, () => Get.back());
  }

  String getCivilStatusLabel(String? value) {
    if (value == null || value.isEmpty) return "Not set";

    final match = Variables.civilStatusData.firstWhere(
      (item) => item["value"].toString().toLowerCase() == value.toLowerCase(),
      orElse: () => null,
    );

    return match != null ? match["text"] : "Not set";
  }

  IconData _civilStatusIcon(String? status) {
    if (status == null) return Icons.person_outline_rounded;
    final s = status.toLowerCase();
    return s == "w"
        ? LucideIcons.user
        : s == "m"
        ? LucideIcons.users
        : s == "s"
        ? LucideIcons.user
        : Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = cs.surface;
    final surface = cs.surface;
    final surface2 = cs.surfaceContainerHighest;
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.35);

    final displayName = Functions().getDisplayName(userData);
    final isVerified = _isVerified;

    return CustomScaffoldV2(
      appBarTitle: 'Profile',
      onPressedLeading: () => Get.back(result: "refresh"),
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Get.back(result: "refresh");
      },
      padding: EdgeInsets.zero,
      scaffoldBody: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(isDark ? 0.18 : 0.12),
                                cs.primary.withOpacity(isDark ? 0.08 : 0.06),
                              ],
                            ),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.30),
                              width: 2,
                            ),
                          ),
                        ),
                        LpProfileAvatar(
                          imageProvider: profileImage,
                          size: 108,
                          borderWidth: 3,
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: LuvNeuPress.circle(
                            onTap: showBottomSheetCamera,
                            background: surface,
                            borderColor: stroke,
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: Center(
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LuvpayText(
                      text: displayName,
                      style: AppTextStyle.h3(context),
                      maxLines: 1,
                      color: cs.onSurface,
                    ),
                    if (userData["email"] != null && userData["email"] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: LuvpayText(
                          text: userData["email"],
                          style: AppTextStyle.body1(context),
                          maxLines: 1,
                          color: cs.onSurface.withOpacity(0.70),
                        ),
                      ),
                    const SizedBox(height: 16),

                    LuvNeuPress.rectangle(
                      radius: BorderRadius.circular(999),
                      onTap: () => getRegions(),
                      background: surface,
                      borderColor: stroke,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: !isVerified ? cs.primary : cs.tertiary,
                            ),
                            const SizedBox(width: 6),
                            LuvpayText(
                              text:
                                  !isVerified
                                      ? "Edit Profile"
                                      : "Verification Required",
                              style: AppTextStyle.body1(
                                context,
                              ).copyWith(fontWeight: FontWeight.w700),
                              color: !isVerified ? cs.primary : cs.tertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 10),
                child: LuvpayText(
                  text: 'Personal Information',
                  style: AppTextStyle.h4(context).copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                  color: cs.onSurface,
                ),
              ),

              _buildInfoCard(
                context,
                icon: Icons.phone_outlined,
                title: 'Mobile Number',
                value: userData["mobile_no"] ?? "Not set",
              ),
              _buildInfoCard(
                context,
                icon: Icons.cake_outlined,
                title: 'Birthday',
                value:
                    userData["birthday"] == null
                        ? "Not set"
                        : birthday(userData["birthday"]),
              ),
              _buildInfoCard(
                context,
                icon: _civilStatusIcon(userData["civil_status"]),
                title: 'Civil Status',
                value: getCivilStatusLabel(userData["civil_status"]),
              ),
              _buildInfoCard(
                context,
                icon:
                    userData["gender"]?.toString().toLowerCase() == "m"
                        ? Icons.male_outlined
                        : Icons.female_outlined,
                title: 'Gender',
                value:
                    userData["gender"]?.toString().toLowerCase() == "m"
                        ? "Male"
                        : "Female",
              ),
              _buildInfoCard(
                context,
                icon: Icons.location_on_outlined,
                title: 'Address',
                value:
                    userData["brgy_name"] == null ||
                            userData["city_name"] == null ||
                            userData["province_name"] == null ||
                            userData["zip_code"] == null
                        ? "Not set"
                        : "${userData["brgy_name"]}, ${userData["city_name"]}, ${userData["province_name"]}, ${userData["zip_code"]}",
                isMultiLine: true,
              ),

              if (isVerified) ...[
                const SizedBox(height: 32),

                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  child: Neumorphic(
                    style: LuvNeu.card(
                      radius: BorderRadius.circular(18),
                      color: surface,
                      borderColor: stroke,
                      borderWidth: 1,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              LuvpayText(
                                text: 'My Referral Code',
                                style: AppTextStyle.h3(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w800),
                                color: cs.onSurface,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: LuvpayText(
                                  text: "CMDSI-RG08099800",
                                  style: AppTextStyle.h3(
                                    context,
                                  ).copyWith(letterSpacing: 1.5),
                                  minFontSize: 8,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    const ClipboardData(text: "ABCD-1234"),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Copied to clipboard',
                                      ),
                                      backgroundColor: cs.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Iconsax.copy,
                                  size: 22,
                                  color: cs.onSurface.withOpacity(0.70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LuvpayText(
                            text:
                                "Share your code with friends and earn rewards when they sign up!",
                            style: AppTextStyle.body1(context),
                            color: cs.onSurface.withOpacity(0.72),
                          ),
                          const SizedBox(height: 8),
                          LuvpayText(
                            text: "Terms and conditions Apply",
                            style: AppTextStyle.body2(context),
                            color: cs.primary,
                          ),
                          const SizedBox(height: 18),
                          LuvpayText(
                            text: "Did someone refer you?",
                            style: AppTextStyle.body2(context),
                            color: cs.onSurface.withOpacity(0.72),
                          ),
                          CustomTextField(
                            controller: referralController,
                            hintText: "Enter your friend's referral code",
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              UpperCaseTextFormatter(),
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            onChange: (value) {},
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            width: MediaQuery.of(context).size.width / 3,
                            text: "Submit",
                            onPressed: () async {
                              CustomDialogStack.showComingSoon(context, () {
                                Get.back();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.35);

    final radius = BorderRadius.circular(18);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Neumorphic(
        style: LuvNeu.card(
          radius: radius,
          color: surface,
          borderColor: stroke,
          borderWidth: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                isMultiLine
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
            children: [
              Neumorphic(
                style: LuvNeu.circle(
                  color: surface,
                  borderColor: stroke,
                  borderWidth: 1,
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: Icon(icon, color: cs.primary, size: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuvpayText(
                      text: title,
                      style: AppTextStyle.body1(context).copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      color: cs.onSurface.withOpacity(0.70),
                    ),
                    const SizedBox(height: 4),
                    LuvpayText(
                      text: value,
                      style: AppTextStyle.body1(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                      color: cs.onSurface,
                      maxLines: isMultiLine ? 3 : 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
