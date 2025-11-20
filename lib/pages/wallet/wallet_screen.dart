import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/functions/functions.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../http/api_keys.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLoading = false;
  List userData = [];
  bool hasNet = true;
  List logs = [];
  Timer? _timer;
  Map<String, dynamic> userInfo = {};

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getUserData();
    getLogs();
    _startAutoRefresh();
  }

  void getUserInfo() async {
    userInfo = await Authentication().getUserData2();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      getUserData();
      getLogs();
    });
  }

  Future<void> getUserData() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final data = await Functions.getUserBalance();

      if (mounted) {
        setState(() {
          userData = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getLogs() async {
    DateTime timeNow = await Functions.getTimeNow();
    String toDate = timeNow.toString().split(" ")[0];
    String fromDate =
        timeNow.subtract(const Duration(days: 1)).toString().split(" ")[0];
    String userId = userInfo["user_id"].toString();

    String subApi =
        "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=$fromDate&tran_date_to=$toDate";
    HttpRequestApi(api: subApi).get().then((response) async {
      if (response is Map && response["items"].isNotEmpty) {
        DateTime timeNow = await Functions.getTimeNow();
        DateTime today = timeNow.toUtc();

        String todayString = today.toIso8601String().substring(0, 10);

        if (mounted) {
          List items = response["items"];
          setState(() {
            logs =
                items
                    .where((transaction) {
                      String transactionDate =
                          transaction['tran_date'].toString().split("T")[0];
                      return transactionDate == todayString;
                    })
                    .toList()
                    .take(5)
                    .toList();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: RefreshIndicator.adaptive(
        onRefresh: getUserData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(child: _WalletHeaderSection(userInfo: userInfo)),

            // Balance Card Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: _ModernBalanceCardWithBgImage(
                  userInfo: userInfo,
                  userData: userData,
                ),
              ),
            ),

            // Quick Actions Section
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.only(top: 20, bottom: 10),
                child: _ModernQuickActionsSection(),
              ),
            ),

            // Bills Payment Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _BillsPaymentSection(),
              ),
            ),

            // Transaction History Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 30),
                child: _ModernTransactionHistorySection(logs: logs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHeaderSection extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  const _WalletHeaderSection({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColorV2.primaryVariant.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColorV2.primaryVariant,
                      AppColorV2.primaryVariant.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorV2.primaryVariant.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.inter(
                        color: AppColorV2.onSurface.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Functions().getDisplayName(userInfo),
                      style: GoogleFonts.poppins(
                        color: AppColorV2.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColorV2.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern Balance Card with Original Background Image
class _ModernBalanceCardWithBgImage extends StatelessWidget {
  final Map<String, dynamic> userInfo;
  final List userData;
  const _ModernBalanceCardWithBgImage({
    required this.userData,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        image: const DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage("assets/images/wallet_card_bg.png"),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryVariant.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "•••••••${userInfo["mobile_no"].toString().substring(userInfo["mobile_no"].toString().length - 4)}",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          Text(
            userData.isEmpty || userData[0]["items"].isEmpty
                ? "•••••"
                : toCurrencyString(userData[0]["items"][0]["amount_bal"]),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColorV2.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernQuickActionsSection extends StatelessWidget {
  const _ModernQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Top Up Methods',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorV2.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choose your preferred top-up method',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColorV2.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 90,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 4),
              _buildModernTopUpButton("assets/images/w_unionbank.png", () {
                Get.toNamed(
                  Routes.walletrechargeload,
                  arguments: {
                    "bank_type": "UnionBank",
                    "image": "assets/images/wt_unionbank.png",
                    "bank_code": " UB ONLINE",
                  },
                );
              }),
              const SizedBox(width: 10),
              _buildModernTopUpButton("assets/images/w_instapay.png", () {
                Get.toNamed(
                  Routes.walletrechargeload,
                  arguments: {
                    "bank_type": "UnionBank",
                    "image": "assets/images/wt_instapay.png",
                    "bank_code": "instapay",
                  },
                );
              }),
              const SizedBox(width: 10),
              _buildModernTopUpButton("assets/images/w_pesonet.png", () {
                Get.toNamed(
                  Routes.walletrechargeload,
                  arguments: {
                    "bank_type": "UnionBank",
                    "image": "assets/images/wt_pesonet.png",
                    "bank_code": "paygate",
                  },
                );
              }),
              const SizedBox(width: 10),
              _buildModernTopUpButton("assets/images/w_maya.png", () {
                Get.toNamed(
                  Routes.walletrechargeload,
                  arguments: {
                    "bank_type": "Maya",
                    "image": "assets/images/wt_maya.png",
                    "bank_code": " Maya",
                  },
                );
              }),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTopUpButton(String assetPath, Function onTap) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 70,
        height: 70,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}

// Enhanced Bills Payment Section with Category Selection
class _BillsPaymentSection extends StatefulWidget {
  const _BillsPaymentSection();

  @override
  State<_BillsPaymentSection> createState() => _BillsPaymentSectionState();
}

class _BillsPaymentSectionState extends State<_BillsPaymentSection> {
  final Map<String, List<Map<String, dynamic>>> billersByCategory = {
    'Utilities': [
      {
        'name': 'Electricity',
        'icon': Icons.lightbulb_outline_rounded,
        'color': Colors.amber,
        'biller': 'Meralco',
      },
      {
        'name': 'Water',
        'icon': Icons.water_drop_outlined,
        'color': Colors.blue,
        'biller': 'Maynilad',
      },
      {
        'name': 'Internet',
        'icon': Icons.wifi_rounded,
        'color': Colors.green,
        'biller': 'PLDT',
      },
      {
        'name': 'Mobile',
        'icon': Icons.phone_iphone_rounded,
        'color': Colors.purple,
        'biller': 'Globe',
      },
      {
        'name': 'Cable TV',
        'icon': Icons.live_tv_rounded,
        'color': Colors.purple,
        'biller': 'Sky Cable',
      },
    ],
    'Loans': [
      {
        'name': 'Bank Loan',
        'icon': Icons.account_balance_rounded,
        'color': Colors.orange,
        'biller': 'BPI',
      },
      {
        'name': 'Credit Card',
        'icon': Icons.credit_card_rounded,
        'color': Colors.indigo,
        'biller': 'BDO',
      },
      {
        'name': 'Personal Loan',
        'icon': Icons.money_rounded,
        'color': Colors.teal,
        'biller': 'Security Bank',
      },
      {
        'name': 'Car Loan',
        'icon': Icons.directions_car_rounded,
        'color': Colors.red,
        'biller': 'Metrobank',
      },
      {
        'name': 'Home Loan',
        'icon': Icons.house_rounded,
        'color': Colors.brown,
        'biller': 'PNB',
      },
    ],
    'Government': [
      {
        'name': 'SSS',
        'icon': Icons.assignment_rounded,
        'color': Colors.blueGrey,
        'biller': 'Social Security',
      },
      {
        'name': 'Pag-IBIG',
        'icon': Icons.home_work_rounded,
        'color': Colors.brown,
        'biller': 'Pag-IBIG Fund',
      },
      {
        'name': 'PhilHealth',
        'icon': Icons.local_hospital_rounded,
        'color': Colors.green,
        'biller': 'PhilHealth',
      },
      {
        'name': 'BIR',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.red,
        'biller': 'Bureau of Internal Revenue',
      },
      {
        'name': 'LGU',
        'icon': Icons.account_balance_rounded,
        'color': Colors.blue,
        'biller': 'Local Government',
      },
    ],
    'Insurance': [
      {
        'name': 'Life Insurance',
        'icon': Icons.family_restroom_rounded,
        'color': Colors.pink,
        'biller': 'Sun Life',
      },
      {
        'name': 'Car Insurance',
        'icon': Icons.car_crash_rounded,
        'color': Colors.orange,
        'biller': 'Malayan Insurance',
      },
      {
        'name': 'Health Insurance',
        'icon': Icons.health_and_safety_rounded,
        'color': Colors.green,
        'biller': 'Maxicare',
      },
      {
        'name': 'Home Insurance',
        'icon': Icons.house_rounded,
        'color': Colors.blue,
        'biller': 'Prudential',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final categories = billersByCategory.keys.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bills Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColorV2.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select a category to pay bills',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColorV2.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColorV2.primaryVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${categories.length} Categories',
                  style: GoogleFonts.inter(
                    color: AppColorV2.primaryVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Categories Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final billers = billersByCategory[category]!;
              return _buildCategoryCard(category, billers);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String category,
    List<Map<String, dynamic>> billers,
  ) {
    // Get category icon and color based on category
    final categoryData = _getCategoryData(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showBillersBottomSheet(category, billers);
        },
        child: Container(
          decoration: BoxDecoration(
            color: categoryData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: categoryData['color'].withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryData['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryData['icon'],
                    color: categoryData['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorV2.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${billers.length} billers',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColorV2.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryData(String category) {
    switch (category) {
      case 'Utilities':
        return {'icon': Icons.bolt_rounded, 'color': Colors.blue};
      case 'Loans':
        return {'icon': Icons.money_rounded, 'color': Colors.green};
      case 'Government':
        return {'icon': Icons.account_balance_rounded, 'color': Colors.orange};
      case 'Insurance':
        return {'icon': Icons.security_rounded, 'color': Colors.purple};
      default:
        return {'icon': Icons.receipt_rounded, 'color': Colors.grey};
    }
  }

  void _showBillersBottomSheet(
    String category,
    List<Map<String, dynamic>> billers,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${billers.length} billers',
                      style: GoogleFonts.inter(
                        color: AppColorV2.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Billers List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: billers.length,
                  itemBuilder: (context, index) {
                    final biller = billers[index];
                    return _buildBillerListItem(
                      name: biller['name'] as String,
                      icon: biller['icon'] as IconData,
                      color: biller['color'] as Color,
                      billerName: biller['biller'] as String,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillerListItem({
    required String name,
    required IconData icon,
    required Color color,
    required String billerName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context); // Close bottom sheet
            Get.toNamed(Routes.billsPayment, arguments: {'biller': billerName});
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColorV2.onSurface,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTransactionHistorySection extends StatelessWidget {
  final List logs;
  const _ModernTransactionHistorySection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorV2.onSurface,
                ),
              ),
              if (logs.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColorV2.primaryVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppColorV2.primaryVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildModernTransactionList(),
        ],
      ),
    );
  }

  Widget _buildModernTransactionList() {
    String formatDate(String dateString) {
      try {
        DateTime date = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy • HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    // Sample logs data
    List<Map<String, dynamic>> sampleLogs = [
      {
        'category': 'Bank Transfer',
        'tran_desc': 'Funds received from John Doe',
        'tran_date': '2024-01-15T14:30:00Z',
        'amount': '+₱1,500.00',
      },
      {
        'category': 'Electricity Bill',
        'tran_desc': 'Meralco Payment',
        'tran_date': '2024-01-15T10:15:00Z',
        'amount': '-₱2,347.50',
      },
      {
        'category': 'Top Up',
        'tran_desc': 'Bank Deposit - UnionBank',
        'tran_date': '2024-01-14T16:45:00Z',
        'amount': '+₱5,000.00',
      },
    ];

    final displayLogs = logs.isEmpty ? sampleLogs : logs.take(3).toList();

    if (displayLogs.isEmpty) {
      return _buildBeautifulEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < displayLogs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _ModernTransactionTile(
              name: displayLogs[i]['category'] as String,
              category: displayLogs[i]['tran_desc'] as String,
              date: formatDate(displayLogs[i]['tran_date']),
              amount: displayLogs[i]['amount'] as String,
              isPositive: !displayLogs[i]['amount'].toString().contains("-"),
            ),
          ),
      ],
    );
  }

  Widget _buildBeautifulEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColorV2.primaryVariant.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: AppColorV2.primaryVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorV2.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transactions will appear here',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColorV2.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTransactionTile extends StatelessWidget {
  final String name;
  final String category;
  final String date;
  final String amount;
  final bool isPositive;

  const _ModernTransactionTile({
    required this.name,
    required this.category,
    required this.date,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        isPositive
                            ? AppColorV2.success.withOpacity(0.1)
                            : AppColorV2.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isPositive ? AppColorV2.success : AppColorV2.error,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColorV2.onSurface,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          color: AppColorV2.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color:
                            isPositive ? AppColorV2.success : AppColorV2.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPositive
                                ? AppColorV2.success.withOpacity(0.1)
                                : AppColorV2.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPositive ? 'CREDIT' : 'DEBIT',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color:
                              isPositive
                                  ? AppColorV2.success
                                  : AppColorV2.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
