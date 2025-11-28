import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/smooth_route.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/profile/profile_update/profile_update.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';

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

  List cityData = [];
  List brgyData = [];

  // Enhanced address execution state
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
    userData = objData;
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

    return CustomScaffoldV2(
      enableToolBar: false,

      scaffoldBody:
          isLoading
              ? LoadingCard()
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    expandedHeight: 200,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          Positioned(
                            top: 20,
                            right: 20,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: executeAddressFlow,
                              icon: Icon(Icons.edit, size: 20),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 3,
                                      color: AppColorV2.lpBlueBrand.withAlpha(
                                        50,
                                      ),
                                    ),
                                    gradient:
                                        userData["image_base64"] == null
                                            ? LinearGradient(
                                              colors: [
                                                primaryBlue,
                                                secondaryTeal,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                            : null,
                                  ),
                                  child: _buildProfileImage(),
                                ),
                                const SizedBox(height: 16),
                                DefaultText(
                                  text: Functions().getDisplayName(userData),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isVerified
                                            ? AppColorV2.inactiveState
                                            : AppColorV2.lpBlueBrand,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: DefaultText(
                                    style: AppTextStyle.body1,
                                    text:
                                        isVerified
                                            ? "Unverified"
                                            : "Fully Verified",
                                    color: AppColorV2.background,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProfileInfoCard(),
                        const SizedBox(height: 24),
                        _buildSettingsSection(),
                        const SizedBox(height: 24),
                        _buildSupportSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildProfileImage() {
    final String? base64Image = userData["image_base64"];

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        String imageString = base64Image;
        if (base64Image.contains(',')) {
          imageString = base64Image.split(',').last;
        }

        return ClipOval(
          child: Image.memory(
            base64Decode(imageString),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfileIcon();
            },
          ),
        );
      } catch (e) {
        print("Error decoding base64 image: $e");
        return _buildDefaultProfileIcon();
      }
    } else {
      return _buildDefaultProfileIcon();
    }
  }

  Widget _buildDefaultProfileIcon() {
    return Icon(Icons.person, size: 40, color: AppColorV2.background);
  }

  Widget _buildProfileInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorV2.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withValues(alpha: .05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.phone,
            title: 'Mobile Number',
            value: userData["mobile_no"],
            onTap: () {},
          ),
          const Divider(),
          _buildInfoRow(
            icon: Icons.email,
            title: 'Email',
            value: userData["email"] ?? "No email",
            onTap: () {},
          ),
          const Divider(),
          _buildInfoRow(
            icon: Icons.location_on,
            title: 'Address',
            value: userData["complete_add"],
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorV2.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColorV2.primary, size: 20),
      ),
      title: DefaultText(
        text: title,
        style: TextStyle(
          fontSize: 14,
          color: AppColorV2.bodyTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: DefaultText(
        text: value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColorV2.primaryTextColor,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColorV2.lpTealBrand.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.edit, color: AppColorV2.lpTealBrand, size: 16),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorV2.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(
            text: 'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorV2.bodyTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingSwitch(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            value: true,
            onChanged: (value) {},
          ),
          _buildSettingSwitch(
            icon: Icons.vpn_key,
            title: 'Change Password',
            subtitle: 'Account security',
            value: true,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorV2.lpTealBrand.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColorV2.primary, size: 20),
      ),
      title: DefaultText(
        text: title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: DefaultText(
        text: subtitle,
        style: TextStyle(fontSize: 12, color: AppColorV2.bodyTextColor),
      ),
      trailing:
          title.toString().toLowerCase().contains("change")
              ? IconButton(
                onPressed: () {},
                icon: Icon(Icons.arrow_forward_ios, size: 16),
              )
              : Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColorV2.accent,
                activeTrackColor: AppColorV2.accent.withOpacity(0.3),
              ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorV2.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(
            text: 'Support & About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorV2.bodyTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            icon: Icons.help,
            title: 'Help Center',
            onTap: () {},
          ),
          _buildSupportOption(
            icon: Icons.description,
            title: 'Terms & Conditions',
            onTap: () {},
          ),
          _buildSupportOption(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSupportOption(
            icon: Icons.info,
            title: 'About LuvPay',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColorV2.incorrectState!),
                foregroundColor: AppColorV2.incorrectState.withAlpha(200),
              ),
              child: const DefaultText(
                text: 'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorV2.bodyTextColor.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColorV2.bodyTextColor, size: 20),
      ),
      title: DefaultText(
        text: title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColorV2.bodyTextColor,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ========== ENHANCED ADDRESS EXECUTION CONTROLLER ==========
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

      // Execute province API
      final provinceResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getProvince}?p_region_id=$regionId",
          ).get();

      if (!_handleResponse(provinceResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      onProgress(_executionSteps[1]);

      // Execute city API
      final cityResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getCity}?p_province_id=$provinceId",
          ).get();

      if (!_handleResponse(cityResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      onProgress(_executionSteps[2]);

      // Execute barangay API
      final brgyResponse =
          await HttpRequestApi(
            api: "${ApiKeys.getBrgy}?p_city_id=$cityId",
          ).get();

      if (!_handleResponse(brgyResponse, onError)) {
        _isExecuting = false;
        return false;
      }

      // All calls successful
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

// ========== ENHANCED MODERN LOADING COMPONENTS ==========
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
