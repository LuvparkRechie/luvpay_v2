// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../../custom_widgets/luvpay/custom_tile.dart';
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
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext cont) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Get.back();
                takePhoto(ImageSource.camera);
              },
              child: const Text('Use Camera'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Get.back();
                takePhoto(ImageSource.gallery);
              },
              child: const Text('Upload from files'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
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
    if (status == null) return Icons.heart_broken_outlined;
    final s = status.toLowerCase();
    return s == "w"
        ? LucideIcons.userX
        : s == "m"
        ? LucideIcons.users
        : s == "s"
        ? LucideIcons.user
        : Icons.heart_broken_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = userData["is_verified"] == "N";

    return CustomScaffoldV2(
      onPressedLeading: () {
        Get.back(result: "refresh");
      },
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.back(result: "refresh");
        }
      },
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 10),
      scaffoldBody: Column(
        children: [
          header(isVerified),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: personalDetails(),
            ),
          ),
        ],
      ),
    );
  }

  SectionListView personalDetails() {
    final items = [
      {'icon': LucideIcons.phone, 'title': userData["mobile_no"] ?? "Not set"},
      {
        'icon': LucideIcons.gift,
        'title':
            userData["birthday"] == null
                ? "Birthday not set"
                : birthday(userData["birthday"]),
      },
      {
        'icon': _civilStatusIcon(userData["civil_status"]),
        'title': getCivilStatusLabel(userData["civil_status"]),
      },
      {
        'icon':
            userData["gender"].toString().toLowerCase() == "m"
                ? Icons.male
                : Icons.female,
        'title':
            userData["gender"].toString().toLowerCase() == "m"
                ? "Male"
                : "Female",
      },
      {
        'icon': LucideIcons.home,
        'title':
            "${userData["brgy_name"]}, ${userData["city_name"]}, ${userData["province_name"]}, ${userData["zip_code"]}",
        'maxLines': 5,
      },
    ];

    return SectionListView(sectionTitle: 'Personal Details', items: items);
  }

  Column header(bool isVerified) {
    return Column(
      children: [
        Stack(
          children: [
            LpProfileAvatar(
              imageProvider: profileImage,
              size: 130,
              borderWidth: 3,
            ),

            Positioned(
              right: 0,
              bottom: 1,
              child: InkWell(
                onTap: () => showBottomSheetCamera(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColorV2.background),
                    shape: BoxShape.circle,
                    color: AppColorV2.lpBlueBrand,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColorV2.background,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DefaultText(
          text: Functions().getDisplayName(userData),
          maxLines: 1,
          style: AppTextStyle.h2,
          color: AppColorV2.primaryTextColor.withAlpha(200),
        ),
        (userData["email"] == null || userData["email"] == "")
            ? const SizedBox.shrink()
            : DefaultText(
              text: "${userData["email"]}",
              maxLines: 1,
              style: AppTextStyle.body1,
              color: AppColorV2.primaryTextColor.withAlpha(200),
            ),
        const SizedBox(height: 10),
        CustomButtons(
          text: isVerified ? "Verify Account" : "Edit Profile",
          onPressed: () => getRegions(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
