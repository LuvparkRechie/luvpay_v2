import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/smooth_route.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/profile/profile_update/profile_update.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
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
    final Color secondaryTeal = const Color(0xFF009688);

    return Scaffold(
      backgroundColor: AppColorV2.background,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body:
          isLoading
              ? const _ModernShimmerLoading()
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        children: [
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: executeAddressFlow,
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
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
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    gradient: LinearGradient(
                                      colors: [primaryBlue, secondaryTeal],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  Functions().getDisplayName(userData),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData["email"] ?? "No email",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                  ),
                ],
              ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
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
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
                side: BorderSide(color: Colors.red[300]!),
                foregroundColor: Colors.red[600],
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
            Text(
              widget.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 15),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== MODERN SHIMMER LOADING ==========
class _ModernShimmerLoading extends StatelessWidget {
  const _ModernShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF009688)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: List.generate(3, (index) => _buildShimmerRow()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 16, color: Colors.grey[300]),
                const SizedBox(height: 4),
                Container(width: 150, height: 14, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
