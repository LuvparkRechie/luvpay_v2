// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_buttons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_profile_image.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/variables.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';
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
    setState(() {
      userData = data;
    });
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
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColorV2.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.camera_alt_rounded,
                        color: AppColorV2.lpBlueBrand,
                      ),
                      title: DefaultText(
                        text: 'Take Photo',
                        style: AppTextStyle.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        color: AppColorV2.primaryTextColor,
                      ),
                      onTap: () {
                        Get.back();
                        takePhoto(ImageSource.camera);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 24,
                      endIndent: 24,
                      color: Colors.grey.shade200,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.photo_library_rounded,
                        color: AppColorV2.lpBlueBrand,
                      ),
                      title: DefaultText(
                        text: 'Choose from Gallery',
                        style: AppTextStyle.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        color: AppColorV2.primaryTextColor,
                      ),
                      onTap: () {
                        Get.back();
                        takePhoto(ImageSource.gallery);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColorV2.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.close_rounded,
                    color: Colors.red.shade400,
                  ),
                  title: DefaultText(
                    text: 'Cancel',
                    style: AppTextStyle.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    color: Colors.red.shade400,
                  ),
                  onTap: () {
                    Get.back();
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
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
      setState(() {
        imageBase64 = null;
      });
    }
  }

  void submitProfilePic() async {
    CustomDialogStack.showLoading(context);
    final myData = await Authentication().getUserData2();

    Map<String, dynamic> parameters = {
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
        CustomDialogStack.showConnectionLost(context, () {
          Get.back();
        });
        return;
      }

      if (res == null) {
        CustomDialogStack.showServerError(context, () {
          Get.back();
        });
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
        CustomDialogStack.showError(context, "luvpay", res["msg"], () {
          Get.back();
        });
      }
    });
  }

  void getRegions() async {
    CustomDialogStack.showLoading(context);
    var returnData = await HttpRequestApi(api: ApiKeys.getRegion).get();
    Get.back();

    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(context, () {
        Get.back();
      });
      return;
    }

    if (returnData == null) {
      CustomDialogStack.showServerError(context, () {
        Get.back();
      });
      return;
    }

    if (returnData["items"].isNotEmpty) {
      regionData = returnData["items"];
      Navigator.pushNamed(context, Routes.updProfile, arguments: regionData);
    } else {
      CustomDialogStack.showServerError(context, () {
        Get.back();
      });
    }
  }

  void getProvince(regionId) async {
    String params = "${ApiKeys.getProvince}?p_region_id=$regionId";
    isLoading = false;

    var returnData = await HttpRequestApi(api: params).get();

    if (returnData == "No Internet") {
      isNetConn = false;
      CustomDialogStack.showConnectionLost(context, () {
        Get.back();
      });
      return;
    }

    if (returnData == null) {
      CustomDialogStack.showServerError(context, () {
        Get.back();
      });
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
    CustomDialogStack.showServerError(context, () {
      Get.back();
    });
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
    final bool isVerified = userData["is_verified"] == "N";
    final displayName = Functions().getDisplayName(userData);

    return CustomScaffoldV2(
      appBarTitle: 'Profile',
      onPressedLeading: () {
        Get.back(result: "refresh");
      },
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.back(result: "refresh");
        }
      },
      scaffoldBody: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                              AppColorV2.lpBlueBrand.withAlpha(50),
                              AppColorV2.lpBlueBrand.withAlpha(20),
                            ],
                          ),
                          border: Border.all(
                            color: AppColorV2.lpBlueBrand.withAlpha(100),
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
                        child: GestureDetector(
                          onTap: () => showBottomSheetCamera(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColorV2.lpBlueBrand,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColorV2.background,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DefaultText(
                    text: displayName,
                    style: AppTextStyle.h3_f22,
                    maxLines: 1,
                    color: AppColorV2.primaryTextColor,
                  ),
                  if (userData["email"] != null && userData["email"] != "")
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: DefaultText(
                        text: userData["email"],
                        style: AppTextStyle.body1,
                        maxLines: 1,
                        color: AppColorV2.bodyTextColor,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 6),
                          DefaultText(
                            text: 'Verification Required',
                            style: AppTextStyle.body1.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ),
                    ),
                  if (!isVerified)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomButtons(
                        text: 'Edit Profile',
                        onPressed: () => getRegions(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DefaultText(
                text: 'Personal Information',
                style: AppTextStyle.h4.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                color: AppColorV2.primaryTextColor,
              ),
            ),
            _buildInfoCard(
              icon: Icons.phone_outlined,
              title: 'Mobile Number',
              value: userData["mobile_no"] ?? "Not set",
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.cake_outlined,
              title: 'Birthday',
              value:
                  userData["birthday"] == null
                      ? "Not set"
                      : birthday(userData["birthday"]),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: _civilStatusIcon(userData["civil_status"]),
              title: 'Civil Status',
              value: getCivilStatusLabel(userData["civil_status"]),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
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
            const SizedBox(height: 12),
            _buildInfoCard(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DefaultText(
                  text: 'Referral Program',
                  style: AppTextStyle.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  color: AppColorV2.primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColorV2.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColorV2.lpBlueBrand.withAlpha(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorV2.primaryTextColor.withAlpha(20),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColorV2.lpBlueBrand,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        DefaultText(
                          text: 'Your Referral Code',
                          style: AppTextStyle.h3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          color: AppColorV2.primaryTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorV2.lpBlueBrand.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColorV2.lpBlueBrand.withAlpha(100),
                              ),
                            ),
                            child: DefaultText(
                              text: "ABCD1234",
                              style: AppTextStyle.h3_f22.copyWith(
                                letterSpacing: 1.5,
                              ),
                              color: AppColorV2.lpBlueBrand,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              const ClipboardData(text: "ABCD1234"),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Copied to clipboard'),
                                backgroundColor: AppColorV2.lpBlueBrand,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColorV2.lpBlueBrand,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorV2.lpBlueBrand.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Iconsax.copy,
                              color: AppColorV2.background,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DefaultText(
                      text:
                          "Share your code with friends and earn rewards when they sign up!",
                      style: AppTextStyle.body1,
                      color: AppColorV2.bodyTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButtons(
                  text: 'Verify Account',
                  onPressed: () => getRegions(),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorV2.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorV2.lpBlueBrand.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withAlpha(10),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorV2.lpBlueBrand.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColorV2.lpBlueBrand, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: title,
                  style: AppTextStyle.body1.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                  color: AppColorV2.bodyTextColor,
                ),
                const SizedBox(height: 4),
                DefaultText(
                  text: value,
                  style: AppTextStyle.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  color: AppColorV2.primaryTextColor,
                  maxLines: isMultiLine ? 3 : 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
