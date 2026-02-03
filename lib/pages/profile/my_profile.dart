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
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_profile_image.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/neumorphism.dart';
import '../../custom_widgets/upper_case_formatter.dart';
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

  TextEditingController referralController = TextEditingController();

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
          decoration: BoxDecoration(
            color: AppColorV2.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
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
                    color: AppColorV2.primaryTextColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Neumorphic(
                style: LuvNeu.card(
                  radius: BorderRadius.circular(20),
                  color: AppColorV2.background,
                  borderColor: null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
              ),
              const SizedBox(height: 8),
              LuvNeuPress.rectangle(
                radius: BorderRadius.circular(20),
                onTap: () => Get.back(),
                background: AppColorV2.background,
                borderColor: null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.close_rounded,
                      color: AppColorV2.incorrectState,
                    ),
                    title: DefaultText(
                      text: 'Cancel',
                      style: AppTextStyle.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      color: AppColorV2.incorrectState,
                    ),
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
                            child: LuvNeuPress.circle(
                              onTap: () => showBottomSheetCamera(),
                              background: AppColorV2.background,
                              borderColor: null,
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: Center(
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: AppColorV2.lpBlueBrand,
                                  ),
                                ),
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

                    LuvNeuPress.rectangle(
                      radius: BorderRadius.circular(999),
                      onTap: () => getRegions(),
                      background: AppColorV2.background,
                      borderColor: null,
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
                              color:
                                  !isVerified
                                      ? AppColorV2.lpBlueBrand
                                      : Colors.orange.shade600,
                            ),
                            const SizedBox(width: 6),
                            DefaultText(
                              text:
                                  !isVerified
                                      ? "Edit Profile"
                                      : "Verification Required",
                              style: AppTextStyle.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              color:
                                  !isVerified
                                      ? AppColorV2.lpBlueBrand
                                      : Colors.orange.shade700,
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
              _buildInfoCard(
                icon: Icons.cake_outlined,
                title: 'Birthday',
                value:
                    userData["birthday"] == null
                        ? "Not set"
                        : birthday(userData["birthday"]),
              ),
              _buildInfoCard(
                icon: _civilStatusIcon(userData["civil_status"]),
                title: 'Civil Status',
                value: getCivilStatusLabel(userData["civil_status"]),
              ),
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

                Container(
                  margin: EdgeInsets.only(left: 10, right: 10),
                  child: Neumorphic(
                    style: LuvNeu.card(
                      radius: BorderRadius.circular(18),
                      color: AppColorV2.background,
                      borderColor: null,
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
                                color: AppColorV2.lpBlueBrand,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              DefaultText(
                                text: 'My Referral Code',
                                style: AppTextStyle.h3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: AppColorV2.primaryTextColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              DefaultText(
                                text: "CMDSI-RG08099800",
                                style: AppTextStyle.h3_f22.copyWith(
                                  letterSpacing: 1.5,
                                ),
                                color: AppColorV2.lpBlueBrand,
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
                                      backgroundColor: AppColorV2.lpBlueBrand,
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
                                  color: AppColorV2.bodyTextColor,
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
                          const SizedBox(height: 8),
                          DefaultText(
                            text: "Terms and conditions Apply",
                            style: AppTextStyle.body2,
                            color: AppColorV2.lpBlueBrand,
                          ),
                          const SizedBox(height: 18),
                          DefaultText(
                            text: "Did someone refer you?",
                            style: AppTextStyle.body2,
                            color: AppColorV2.bodyTextColor,
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
                            onPressed:
                                () async => {
                                  CustomDialogStack.showComingSoon(context, () {
                                    Get.back();
                                  }),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiLine = false,
  }) {
    final radius = BorderRadius.circular(18);

    return Container(
      margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Neumorphic(
        style: LuvNeu.card(
          radius: radius,
          color: AppColorV2.background,
          borderColor: null,
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
                  color: AppColorV2.background,
                  borderColor: null,
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(icon, color: AppColorV2.lpBlueBrand, size: 20),
                  ),
                ),
              ),

              const SizedBox(width: 14),

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
                        fontWeight: FontWeight.w700,
                      ),
                      color: AppColorV2.primaryTextColor,
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
