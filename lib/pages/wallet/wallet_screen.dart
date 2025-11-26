// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/functions/functions.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/dashboard/index.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../custom_widgets/no_data_found.dart';
import '../../http/api_keys.dart';
import 'notifications.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  bool isLoading = false;
  List userData = [];
  bool hasNet = true;
  List logs = [];
  Timer? _timer;
  Map<String, dynamic> userInfo = {};
  int unreadMsg = 0;
  int notifCount = 0;
  @override
  void initState() {
    super.initState();
    getUserInfo();
    getUserData();
    getNotificationCount();
    getLogs();
    _startAutoRefresh();
  }

  // void getNotif() async {
  //   List<dynamic> msgdata =
  //       await PaMessageDatabase.instance.getUnreadMessages();
  //   unreadMsg = msgdata.length;
  // }

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

  Future<void> getNotificationCount() async {
    try {
      final item = await Authentication().getUserData();
      String userId = jsonDecode(item!)['user_id'].toString();

      String subApi = "${ApiKeys.notificationApi}$userId";
      HttpRequestApi(api: subApi).get().then((response) async {
        if (response["items"].isNotEmpty) {
          notifCount = response["items"].length;
        } else {
          notifCount = 0;
        }
      });
    } catch (e) {
      notifCount = 0;
    }
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(19, 19, 19, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WalletHeaderSection(
              userInfo: userInfo,
              unreadMsg: unreadMsg,
              notifCount: notifCount,
            ),
            SizedBox(height: 10),
            _ModernBalanceCardWithBgImage(
              userInfo: userInfo,
              userData: userData,
            ),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: getUserData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _BillsPaymentSection()),
                    SliverToBoxAdapter(child: SizedBox(height: 30)),
                    SliverToBoxAdapter(
                      child: _ModernTransactionHistorySection(logs: logs),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHeaderSection extends StatelessWidget {
  final int unreadMsg;
  final int notifCount;
  final Map<String, dynamic> userInfo;
  const _WalletHeaderSection({
    required this.userInfo,
    required this.unreadMsg,
    required this.notifCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SafeArea(
        child: Row(
          children: [
            _buildProfileImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: 'Welcome back,',
                    style: AppTextStyle.body1,
                    color: AppColorV2.primaryTextColor,
                  ),
                  DefaultText(
                    text: Functions().getDisplayName(userInfo),
                    style: AppTextStyle.h4,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.to(WalletNotifications());
                      },
                      child: SvgPicture.asset(
                        "assets/images/${notifCount != 0 ? "wallet_active_notification" : "wallet_inactive_notification"}.svg",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final String? base64Image = userInfo["image_base64"];

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        String imageString = base64Image;
        if (base64Image.contains(',')) {
          imageString = base64Image.split(',').last;
        }

        // Check if we have a cached image provider
        ImageProvider? cachedImage = ImageCacheHelper.getCachedImage(
          base64Image,
        );

        if (cachedImage == null) {
          // Create and cache new image provider
          final bytes = base64Decode(imageString);
          cachedImage = MemoryImage(bytes);
          ImageCacheHelper.cacheImage(base64Image, cachedImage);
        }

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColorV2.primaryVariant.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image(
              image: cachedImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading profile image: $error");
                return _buildDefaultProfileIcon();
              },
            ),
          ),
        );
      } catch (e) {
        print("Error decoding base64 image in wallet: $e");
        return _buildDefaultProfileIcon();
      }
    } else {
      return _buildDefaultProfileIcon();
    }
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
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
      child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
    );
  }
}

class ImageCacheHelper {
  static final Map<String, ImageProvider> _cache = {};

  static ImageProvider? getCachedImage(String base64String) {
    if (_cache.containsKey(base64String)) {
      return _cache[base64String];
    }
    return null;
  }

  static void cacheImage(String base64String, ImageProvider imageProvider) {
    _cache[base64String] = imageProvider;
  }
}

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
            blurRadius: 50,
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
              DefaultText(
                text: 'Total Balance',
                style: AppTextStyle.h3_semibold,
                color: AppColorV2.surface,
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
                child: DefaultText(
                  text:
                      userInfo["mobile_no"] != null
                          ? "•••••••${userInfo["mobile_no"].toString().substring(userInfo["mobile_no"].toString().length - 4)}"
                          : "•••••••••••",

                  style: AppTextStyle.body1,
                  color: AppColorV2.background,
                ),
              ),
            ],
          ),

          DefaultText(
            text:
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
                    DefaultText(
                      text: 'Active',
                      style: AppTextStyle.body1,
                      color: AppColorV2.background,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: 'Bills Payment',
                  color: AppColorV2.onSurface,
                  style: AppTextStyle.h3,
                ),
                const SizedBox(height: 2),
                DefaultText(
                  text: 'Select a category to pay bills',
                  color: AppColorV2.bodyTextColor,
                ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColorV2.primaryVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DefaultText(
                  textAlign: TextAlign.center,
                  text: '${categories.length} Categories',
                  maxLines: 1,
                  color: AppColorV2.primaryVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

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
    );
  }

  Widget _buildCategoryCard(
    String category,
    List<Map<String, dynamic>> billers,
  ) {
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
            child: Wrap(
              children: [
                Column(
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
                    DefaultText(
                      text: category,
                      color: AppColorV2.onSurface,
                      style: AppTextStyle.body1,
                    ),
                    const SizedBox(height: 4),
                    DefaultText(
                      text: '${billers.length} billers',
                      color: AppColorV2.bodyTextColor,
                      maxLines: 1,
                      maxFontSize: 12,
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
                    DefaultText(text: category, style: AppTextStyle.h3),
                    const Spacer(),
                    DefaultText(
                      text: '${billers.length} billers',
                      style: AppTextStyle.h3_semibold,
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
                  child: DefaultText(
                    text: name,
                    color: AppColorV2.onSurface,
                    style: AppTextStyle.paragraph1,
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
    final DashboardController controller = Get.put(DashboardController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultText(
              text: 'Recent Transactions',
              color: AppColorV2.onSurface,
              style: AppTextStyle.h3,
            ),
            if (logs.isNotEmpty)
              TextButton(
                onPressed: () {
                  controller.changePage(1);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColorV2.primaryVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
                child: DefaultText(
                  text: 'View All',
                  color: AppColorV2.primaryVariant,
                  style: AppTextStyle.body1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildModernTransactionList(),
      ],
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

    final displayLogs =
        logs.isEmpty
            ? []
            : logs.length <= 5
            ? logs
            : logs.sublist(0, 5);

    if (displayLogs.isEmpty) {
      return Center(child: NoDataFound());
    }

    return ListView.separated(
      separatorBuilder: (context, index) {
        return const SizedBox(height: 14);
      },
      padding: EdgeInsets.zero,
      itemCount: displayLogs.length,
      itemBuilder: (context, index) {
        return _ModernTransactionTile(
          name: displayLogs[index]['category'] as String,
          category: displayLogs[index]['tran_desc'] as String,
          date: formatDate(displayLogs[index]['tran_date']),
          amount: displayLogs[index]['amount'] as String,
          isPositive: !displayLogs[index]['amount'].toString().contains("-"),
        );
      },
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                    DefaultText(
                      text: name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColorV2.onSurface,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    DefaultText(
                      text: category,
                      style: AppTextStyle.body1,
                      maxFontSize: 12,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DefaultText(
                    text: amount,
                    style: AppTextStyle.body1,
                    color: isPositive ? AppColorV2.success : AppColorV2.error,
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
                    child: DefaultText(
                      text: isPositive ? 'CREDIT' : 'DEBIT',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color:
                            isPositive ? AppColorV2.success : AppColorV2.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
