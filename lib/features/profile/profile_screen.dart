// ignore_for_file: use_build_context_synchronously, unreachable_switch_default, deprecated_member_use

import 'dart:convert';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/features/profile/profile_update/profile_update.dart';
import 'package:luvpay/features/qr/view.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_loading.dart';
import '../../shared/widgets/theme_mode_controller.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import '../../shared/components/web_view/webview.dart';
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
        debugPrint("Invalid date format for created_on: $e");
      }
    }

    userData["complete_add"] =
        objData["province_name"] == null
            ? "No address"
            : "Province of ${objData["province_name"]} brgy ${objData["brgy_name"]}, ${objData["city_name"]} ";

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> executeAddressFlow() async {
    if (userData["region_id"] != 0) {
      _showMinimalLoading(context, "Preparing address data...");

      final success = await _addressController.executeAddressChain(
        regionId: userData['region_id'].toString(),
        provinceId: userData['province_id'].toString(),
        cityId: userData['city_id'].toString(),
        onProgress: (_) {},
        onSuccess: (provinceData, cityData, brgyData) {
          if (!mounted) return;
          setState(() {
            this.provinceData = provinceData;
            this.cityData = cityData;
            this.brgyData = brgyData;
          });
          _showMinimalSuccess(context, "Address data loaded!");
        },
        onError: (error) {
          if (mounted) _handleAddressError(error);
        },
      );

      if (!success && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    getRegions();
  }

  void _handleAddressError(String error) {
    Navigator.of(context, rootNavigator: true).pop();

    if (error.contains("Internet")) {
      CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
    } else {
      CustomDialogStack.showServerError(Get.context!, () => Get.back());
    }
  }

  void getRegions() async {
    CustomDialogStack.showLoading(Get.context!);
    final returnData = await HttpRequestApi(api: ApiKeys.getRegion).get();
    Get.back();

    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
      return;
    }
    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () => Get.back());
      return;
    }

    if (returnData["items"].isNotEmpty) {
      SmoothRoute(
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
    }

    CustomDialogStack.showServerError(Get.context!, () => Get.back());
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
    final bool isVerified = userData["is_verified"] == "N";
    final themeCtrl = Get.find<ThemeModeController>();

    return SafeArea(
      child: Scaffold(
        body:
            isLoading
                ? const LoadingCard()
                : CustomGradientBackground(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 19, 10, 0),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        headerProfile(isVerified),
                        !isVerified
                            ? const SliverToBoxAdapter(child: SizedBox.shrink())
                            : VerifiedWidget(isVerified: isVerified),
                        SliverToBoxAdapter(
                          child: Column(
                            spacing: 14,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _profile(themeCtrl),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _helpAndSupport(),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: _legal(),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(19, 0, 19, 0),
                                width: double.infinity,
                                child: CustomButton(
                                  text: "Logout",
                                  onPressed: () {
                                    CustomDialogStack.showConfirmation(
                                      isAllBlueColor: false,
                                      context,
                                      "Logout",
                                      "Are you sure you want to logout?",
                                      leftText: "No",
                                      rightText: "Yes",
                                      () => Get.back(),
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

  SliverAppBar headerProfile(bool isVerified) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          const double maxHeight = 100;
          final double minHeight = kToolbarHeight;
          final double currentHeight = constraints.biggest.height;

          final double t = ((currentHeight - minHeight) /
                  (maxHeight - minHeight))
              .clamp(0.0, 1.0);

          final double avatarSize = 70 * t + 50 * (1 - t);
          final double nameFont = 18 * t + 14 * (1 - t);
          final double emailFont = 12 * t + 10 * (1 - t);
          final double horizontalPadding = 10 * t + 4 * (1 - t);

          final double iconBox = 44 * t + 40 * (1 - t);

          return FlexibleSpaceBar(
            background: Container(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: InfoRowTile(
                onTap: () {
                  Get.to(() => const MyProfile())?.then((value) {
                    if (value == "refresh") initialize();
                  });
                },

                iconWidget: Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 3,
                      color: AppColorV2.lpBlueBrand.withOpacity(
                        isDark ? 0.22 : 0.16,
                      ),
                    ),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child:
                          myprofile.isEmpty
                              ? Image.asset(
                                "assets/images/d_unverified_img.png",
                                fit: BoxFit.cover,
                              )
                              : Image.memory(
                                base64Decode(myprofile),
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ),

                title: Functions().getDisplayName(userData),

                subtitle: (userData["email"] ?? "No email").toString(),
                subtitleMaxlines: 1,

                maxLines: 1,

                trailing: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: cs.onSurfaceVariant.withOpacity(isDark ? 0.70 : 0.65),
                ),

                iconBoxSize: 44,
                iconBoxRadius: BorderRadius.circular(999),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profile(ThemeModeController themeCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRowTile(
          icon: Icons.qr_code_rounded,
          title: 'Personal QR Code ',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => QR(qrCode: userData["mobile_no"]),
            );
          },
        ),
        InfoRowTile(
          icon: LucideIcons.ticket,
          title: 'Vouchers',
          onTap: () => Get.toNamed(Routes.vouchers),
        ),
        InfoRowTile(
          icon: LucideIcons.bell,
          title: 'Notifications',
          onTap: () => Get.to(WalletNotifications(fromTab: false)),
        ),
        InfoRowTile(
          icon: LucideIcons.history,
          title: 'Transaction History',
          onTap: () => Get.to(const TransactionHistory()),
        ),

        InfoRowTile(
          icon: LucideIcons.lock,
          title: 'App Security',
          onTap: () => Get.toNamed(Routes.securitySettings),
        ),
        const SizedBox(height: 10),

        Obx(
          () => InfoRowTile(
            icon: themeCtrl.iconOf(themeCtrl.mode.value),
            title: "Theme (${themeCtrl.labelOf(themeCtrl.mode.value)})",
            subtitle: "Choose light, dark, or system.",
            subtitleMaxlines: 2,
            onTap: () => _showThemePopup(context),
          ),
        ),
      ],
    );
  }

  void _showThemePopup(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final themeCtrl = Get.find<ThemeModeController>();

    final cardColor = cs.surface;
    final subtleBorder = cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.55);
    final closeColor = cs.onSurfaceVariant.withOpacity(0.75);
    final titleColor = cs.onSurface;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(isDark ? 0.55 : 0.35),
      builder: (_) {
        final radius = BorderRadius.circular(18);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Neumorphic(
            style: LuvNeu.card(
              radius: radius,
              depth: isDark ? 1.2 : 2.0,
              pressedDepth: -1.0,
              color: cardColor,
              borderColor: subtleBorder,
              borderWidth: 0.8,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.palette,
                            size: 18,
                            color: AppColorV2.lpBlueBrand,
                          ),
                          const SizedBox(width: 10),
                          LuvpayText(
                            text: "Choose Theme",
                            style: AppTextStyle.h3(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: closeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _themeRadioTile(
                        context: context,
                        cs: cs,
                        isDark: isDark,
                        title: "System",
                        subtitle: "Follow device settings",
                        icon: LucideIcons.monitor,
                        value: ThemeMode.system,
                        groupValue: themeCtrl.mode.value,
                        onChanged: (v) {
                          themeCtrl.setMode(v);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _themeRadioTile(
                        context: context,
                        cs: cs,
                        isDark: isDark,
                        title: "Light",
                        subtitle: "Always light mode",
                        icon: LucideIcons.sun,
                        value: ThemeMode.light,
                        groupValue: themeCtrl.mode.value,
                        onChanged: (v) {
                          themeCtrl.setMode(v);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _themeRadioTile(
                        context: context,
                        cs: cs,
                        isDark: isDark,
                        title: "Dark",
                        subtitle: "Always dark mode",
                        icon: LucideIcons.moon,
                        value: ThemeMode.dark,
                        groupValue: themeCtrl.mode.value,
                        onChanged: (v) {
                          themeCtrl.setMode(v);
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _themeRadioTile({
    required BuildContext context,
    required ColorScheme cs,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    final selected = value == groupValue;
    final r = BorderRadius.circular(14);

    final base = cs.surface;
    final onBase = cs.onSurface;
    final sub = cs.onSurfaceVariant.withOpacity(isDark ? 0.75 : 0.80);

    final selectedBg = AppColorV2.lpBlueBrand.withOpacity(isDark ? 0.18 : 0.10);

    final tileBg = selected ? selectedBg : base;
    final tileBorder = cs.outlineVariant.withOpacity(isDark ? 0.30 : 0.45);

    return LuvNeuPress(
      onTap: () => onChanged(value),
      radius: r,
      depth: isDark ? 0.9 : 1.2,
      pressedDepth: -0.6,
      background: tileBg,
      overlayOpacity: isDark ? 0.03 : 0.02,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Neumorphic(
              style: LuvNeu.icon(
                radius: BorderRadius.circular(12),
                color: base,
                borderColor: tileBorder,
                borderWidth: 0.8,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color:
                        selected
                            ? AppColorV2.lpBlueBrand
                            : sub.withOpacity(.95),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuvpayText(
                    text: title,
                    style: AppTextStyle.body1(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900, color: onBase),
                  ),
                  const SizedBox(height: 2),
                  LuvpayText(
                    text: subtitle,
                    style: AppTextStyle.paragraph2(
                      context,
                    ).copyWith(color: sub),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 18,
              color:
                  selected
                      ? AppColorV2.lpBlueBrand
                      : cs.onSurfaceVariant.withOpacity(isDark ? 0.40 : 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpAndSupport() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuvpayText(
          text: 'Help & Support',
          style: AppTextStyle.h3(context).copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 10),
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
              CustomDialogStack.showConnectionLost(context, () => Get.back());
            }
          },
        ),
        InfoRowTile(
          icon: LucideIcons.messageCircle,
          title: 'FAQs',
          onTap: () => Get.toNamed(Routes.faqpage),
        ),
      ],
    );
  }

  Widget _legal() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuvpayText(
          text: 'Legal',
          style: AppTextStyle.h3(context).copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 10),
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
              CustomDialogStack.showConnectionLost(context, () => Get.back());
            }
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
              CustomDialogStack.showConnectionLost(context, () => Get.back());
            }
          },
        ),
      ],
    );
  }
}

class VerifiedWidget extends StatelessWidget {
  final bool isVerified;
  const VerifiedWidget({super.key, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = AppColorV2.lpBlueBrand.withOpacity(isDark ? 0.85 : 0.92);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: bg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(19),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withOpacity(isDark ? 0.10 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.crown, color: cs.onPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LuvpayText(
                  text:
                      !isVerified
                          ? "Verified Account\nEnjoy all features available!"
                          : "Verify your account\nto unlock more features!",
                  style: AppTextStyle.body1(context),
                  color: cs.onPrimary,
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(isDark ? 0.45 : 0.70),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
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
                      AppColorV2.lpBlueBrand.withOpacity(
                        0.55 + _animation.value * 0.45,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
            LuvpayText(
              text: widget.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(isDark ? 0.45 : 0.70),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColorV2.success, size: 24),
            const SizedBox(width: 15),
            LuvpayText(
              text: message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmoothRoute {
  final BuildContext context;
  final Widget child;
  const SmoothRoute({required this.context, required this.child});

  Future<T?> route<T>() {
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}
