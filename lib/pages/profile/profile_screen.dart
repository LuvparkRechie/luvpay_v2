// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_buttons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/smooth_route.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/profile/profile_update/profile_update.dart';
import 'package:luvpay/pages/qr/view.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../custom_widgets/luvpay/custom_tile.dart';
import '../../custom_widgets/luvpay/statusbar_manager.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../web_view/webview.dart';
import '../routes/routes.dart';
import '../transaction/transaction_screen.dart';
import '../wallet/notifications.dart';
import 'my_profile.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final parameter = Get.arguments;

  Map<String, dynamic> userData = {};
  bool isLoading = true;
  bool isLoadingExec = false;
  List provinceData = [];
  String myprofile = "";
  List cityData = [];
  List brgyData = [];

  final AddressExecutionController _addressController =
      AddressExecutionController();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    final objData = await Authentication().getUserData2();
    final profilepic = await Authentication().getUserProfilePic();
    myprofile = profilepic;
    userData = objData;
    if (objData["created_on"] != null) {
      try {
        if (objData["created_on"] is String) {
          objData["created_on"] = DateTime.parse(objData["created_on"]);
        } else if (objData["created_on"] is int) {
          objData["created_on"] = DateTime.fromMillisecondsSinceEpoch(
            objData["created_on"],
          );
        }
      } catch (e) {
        print("Invalid date format for created_on: $e");
      }
    }

    userData["complete_add"] =
        objData["province_name"] == null
            ? "No address"
            : "Province of ${objData["province_name"]} brgy ${objData["brgy_name"]}, ${objData["city_name"]} ";

    setState(() {
      isLoading = false;
    });
  }

  Future<void> executeAddressFlow() async {
    if (userData["region_id"] != 0) {
      _showMinimalLoading(context, "Preparing address data...");

      final success = await _addressController.executeAddressChain(
        regionId: userData['region_id'].toString(),
        provinceId: userData['province_id'].toString(),
        cityId: userData['city_id'].toString(),
        onProgress: (progress) {
          if (mounted) {
            _updateLoadingMessage(progress);
          }
        },
        onSuccess: (provinceData, cityData, brgyData) {
          if (mounted) {
            setState(() {
              provinceData = provinceData;
              cityData = cityData;
              brgyData = brgyData;
            });
            _showMinimalSuccess(context, "Address data loaded!");
          }
        },
        onError: (error) {
          if (mounted) {
            _handleAddressError(error);
          }
        },
      );

      if (!success && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    getRegions();
  }

  void _updateLoadingMessage(String progress) {}

  void _handleAddressError(String error) {
    Navigator.of(context, rootNavigator: true).pop();

    if (error.contains("Internet")) {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  void getRegions() async {
    CustomDialogStack.showLoading(Get.context!);
    var returnData = await HttpRequestApi(api: ApiKeys.getRegion).get();
    Get.back();

    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData["items"].isNotEmpty) {
      SmoothRoute(
        // ignore: use_build_context_synchronously
        context: context,
        child: ProfileUpdateScreen(
          userData: userData,
          regionData: returnData["items"],
          provinceData: provinceData,
          cityData: cityData,
          brgyData: brgyData,
        ),
      ).route();
      return;
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  void _showMinimalLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernMinimalLoading(message: message),
    );
  }

  void _showMinimalSuccess(BuildContext context, String message) {
    Navigator.of(context, rootNavigator: true).pop();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ModernMinimalSuccess(message: message),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.of(Get.context!, rootNavigator: true).canPop()) {
        Navigator.of(Get.context!, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);
    final bool isVerified = userData["is_verified"] == "N";
    final Color secondaryTeal = const Color(0xFF009688);
    return ConsistentStatusBarWrapper(
      child: CustomScaffoldV2(
        leading: SizedBox.shrink(),
        canPop: false,
        showAppBar: false,
        padding: EdgeInsets.zero,
        scaffoldBody:
            isLoading
                ? LoadingCard()
                : CustomGradientBackground(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 19, 10, 0),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        headerProfile(primaryBlue, secondaryTeal, isVerified),
                        SliverToBoxAdapter(child: SizedBox(height: 20)),
                        !isVerified
                            ? SliverToBoxAdapter(child: SizedBox.shrink())
                            : VerifiedWidget(isVerified: isVerified),
                        SliverToBoxAdapter(
                          child: Column(
                            spacing: 14,
                            children: [
                              SizedBox(height: 16),
                              Container(
                                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _profile(),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _helpAndSupport(),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _legal(),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(19, 0, 19, 0),
                                width: double.infinity,
                                child: CustomButtons.no(
                                  text: "Logout",
                                  onPressed: () {
                                    CustomDialogStack.showConfirmation(
                                      isAllBlueColor: false,
                                      context,
                                      "Logout",
                                      "Are you sure you want to logout?",
                                      leftText: "No",
                                      rightText: "Yes",
                                      () {
                                        Get.back();
                                      },
                                      () async {
                                        Get.back();
                                        final uData =
                                            await Authentication()
                                                .getUserData2();

                                        Functions.logoutUser(
                                          uData["session_id"].toString(),
                                          (isSuccess) async {
                                            if (isSuccess["is_true"]) {
                                              Authentication().setLogoutStatus(
                                                true,
                                              );
                                              Get.offAllNamed(Routes.login);
                                            }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  SliverAppBar headerProfile(
    Color primaryBlue,
    Color secondaryTeal,
    isVerified,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double maxHeight = 100;
          final double minHeight = kToolbarHeight;
          final double currentHeight = constraints.biggest.height;

          final double t = ((currentHeight - minHeight) /
                  (maxHeight - minHeight))
              .clamp(0.0, 1.0);

          final double avatarSize = 70 * t + 50 * (1 - t);
          final double nameFont = 18 * t + 14 * (1 - t);
          final double emailFont = 12 * t + 10 * (1 - t);
          final double horizontalPadding = 10 * t + 4 * (1 - t);

          return FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColorV2.background,
              ),
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 120),
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 3,
                        color: AppColorV2.lpBlueBrand.withAlpha(50),
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        height: 130,
                        width: 130,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child:
                            myprofile.isEmpty
                                ? Image.asset(
                                  "assets/images/d_unverified_img.png",
                                  height: 60,
                                )
                                : Image.memory(
                                  base64Decode(myprofile),
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10 * t + 4 * (1 - t)),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultText(
                          text: Functions().getDisplayName(userData),
                          maxLines: 1,
                          style: AppTextStyle.h3_semibold.copyWith(
                            fontSize: nameFont,
                          ),
                        ),
                        DefaultText(
                          text: userData["email"] ?? "No email",
                          style: AppTextStyle.textbox.copyWith(
                            fontSize: emailFont,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Transform.scale(
                    scale: 0.8 + (0.2 * t),
                    child: CustomButtons.nextCircle(
                      onPressed: () {
                        Get.to(() => MyProfile())!.then((value) {
                          if (value == "refresh") initialize();
                        });
                      },
                      isActive: true,
                      size: 30,
                      activeColor: AppColorV2.lpBlueBrand,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profile() {
    return DefaultContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRowTile(
            icon: Icons.qr_code_rounded,
            title: 'Personal QR Code ',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return QR(qrCode: userData["mobile_no"]);
                },
              );
            },
          ),
          InfoRowTile(
            icon: LucideIcons.ticket,
            title: 'Vouchers',
            onTap: () {
              // CustomDialogStack.showUnderDevelopment(context, () {
              //   Get.back();
              // });
              Get.toNamed(Routes.vouchers);
            },
          ),
          InfoRowTile(
            icon: LucideIcons.bell,
            title: 'Notifications',
            onTap: () {
              Get.to(WalletNotifications(fromTab: false));
            },
          ),
          InfoRowTile(
            icon: LucideIcons.history,
            title: 'Transaction History',
            onTap: () {
              Get.to(TransactionHistory());
            },
          ),
          InfoRowTile(
            icon: LucideIcons.lock,
            title: 'App Security',
            onTap: () {
              Get.toNamed(Routes.securitySettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _helpAndSupport() {
    return DefaultContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(text: 'Help & Support', style: AppTextStyle.h3),
          SizedBox(height: 8),
          InfoRowTile(
            icon: Icons.info_outline,
            title: 'About Us',
            onTap: () async {
              CustomDialogStack.showLoading(context);
              final response = await HttpRequestApi(api: "").linkToPage();
              Get.back();
              if (response == "Success") {
                Get.to(
                  const WebviewPage(
                    urlDirect: "https://luvpark.ph/about-us/",
                    label: "About Us",
                    isBuyToken: false,
                    bodyPadding: EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 10,
                    ),
                  ),
                );
              } else {
                CustomDialogStack.showConnectionLost(context, () {
                  Get.back();
                });
              }
            },
          ),
          InfoRowTile(
            icon: LucideIcons.messageCircle,
            title: 'FAQs',
            onTap: () {
              Get.toNamed(Routes.faqpage);
            },
          ),
        ],
      ),
    );
  }

  Widget _legal() {
    return DefaultContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(text: 'Legal', style: AppTextStyle.h3),
          SizedBox(height: 8),

          InfoRowTile(
            icon: LucideIcons.bookmark,
            title: 'Terms of Use',
            onTap: () async {
              CustomDialogStack.showLoading(context);
              final response = await HttpRequestApi(api: "").linkToPage();
              Get.back();
              if (response == "Success") {
                Get.to(
                  const WebviewPage(
                    urlDirect: "https://luvpark.ph/terms-of-use/",
                    label: "Terms of Use",
                    isBuyToken: false,
                    bodyPadding: EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 10,
                    ),
                  ),
                );
              } else {
                CustomDialogStack.showConnectionLost(context, () {
                  Get.back();
                });
              }
              // CustomDialogStack.showUnderDevelopment(context, () {
              //   Get.back();
              // });
            },
          ),
          InfoRowTile(
            icon: LucideIcons.shield,
            title: 'Privacy Policy',
            onTap: () async {
              CustomDialogStack.showLoading(context);
              final response = await HttpRequestApi(api: "").linkToPage();
              Get.back();
              if (response == "Success") {
                Get.to(
                  const WebviewPage(
                    urlDirect: "https://luvpark.ph/privacy-policy/",
                    label: "Privacy Policy",
                    isBuyToken: false,
                    bodyPadding: EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 10,
                    ),
                  ),
                );
              } else {
                CustomDialogStack.showConnectionLost(context, () {
                  Get.back();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class VerifiedWidget extends StatelessWidget {
  final bool isVerified;
  const VerifiedWidget({super.key, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColorV2.lpBlueBrand.withAlpha(200),
        ),
        padding: EdgeInsets.all(19),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColorV2.background.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.crown, color: AppColorV2.lpBlueBrand),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DefaultText(
                text:
                    !isVerified
                        ? "Verified Account\nEnjoy all features available!"
                        : "Verify your account\nto unlock more features!",

                style: AppTextStyle.body1,
                color: AppColorV2.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressExecutionController {
  bool _isExecuting = false;
  final List<String> _executionSteps = [
    "Loading provinces...",
    "Loading cities...",
    "Loading barangays...",
  ];

  void dispose() {
    _isExecuting = false;
  }

  Future<bool> executeAddressChain({
    required String regionId,
    required String provinceId,
    required String cityId,
    required Function(String) onProgress,
    required Function(List, List, List) onSuccess,
    required Function(String) onError,
  }) async {
    if (_isExecuting) return false;

    _isExecuting = true;

    try {
      onProgress(_executionSteps[0]);

      final provinceResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getProvince}?p_region_id=$regionId",
          ).get();

      if (!_handleResponse(provinceResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      onProgress(_executionSteps[1]);

      final cityResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getCity}?p_province_id=$provinceId",
          ).get();

      if (!_handleResponse(cityResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      onProgress(_executionSteps[2]);

      final brgyResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getBrgy}?p_city_id=$cityId",
          ).get();

      if (!_handleResponse(brgyResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      onSuccess(
        provinceResponse["items"],
        cityResponse["items"],
        brgyResponse["items"],
      );

      _isExecuting = false;
      return true;
    } catch (e) {
      _isExecuting = false;
      onError("Execution failed: ${e.toString()}");
      return false;
    }
  }

  bool _handleResponse(dynamic response, Function(String) onError) {
    if (response == "No Internet") {
      onError("No Internet");
      return false;
    }
    if (response == null) {
      onError("Server Error");
      return false;
    }
    if (response["items"] == null || response["items"].isEmpty) {
      onError("No data available");
      return false;
    }
    return true;
  }
}

class ModernMinimalLoading extends StatefulWidget {
  final String message;

  const ModernMinimalLoading({super.key, required this.message});

  @override
  State<ModernMinimalLoading> createState() => _ModernMinimalLoadingState();
}

class _ModernMinimalLoadingState extends State<ModernMinimalLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,

      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColorV2.background,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColorV2.primaryTextColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(
                        0xFF0078FF,
                      ).withOpacity(0.6 + _animation.value * 0.4),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
            DefaultText(
              text: widget.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColorV2.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernMinimalSuccess extends StatelessWidget {
  final String message;

  const ModernMinimalSuccess({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColorV2.background,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColorV2.primaryTextColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColorV2.bodyTextColor, size: 24),
            const SizedBox(width: 15),
            DefaultText(
              text: message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColorV2.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
