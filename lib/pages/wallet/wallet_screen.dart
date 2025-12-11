import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_profile_image.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/custom_buttons.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';
import '../transaction/transaction_details.dart';
import '../transaction/transaction_screen.dart';
import 'notifications.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedTab = 0;
  bool isLoading = false;
  List userData = [];
  bool hasNet = true;
  List logs = [];
  Timer? _timer;
  Map<String, dynamic> userInfo = {};
  int unreadMsg = 0;
  int notifCount = 0;
  final PageController _pageController = PageController();
  bool isOpen = false;
  String myprofile = "";
  bool _isDialogVisible = false;

  // Add merchant grid items with SVG paths
  final List<Map<String, dynamic>> _merchantGridItems = [
    {
      'icon': "assets/svg/merchant.svg",
      'label': 'Merchant',
      'color': Colors.blue,
      'onTap': () {
        print("Merchant pressed");
        // Get.to(() => MerchantScreen());
      },
    },
    {
      'icon': "assets/svg/bills.svg", // Changed to SVG path
      'label': 'Bills',
      'color': Colors.green,
      'onTap': () {
        print("Bills pressed");
        // Get.to(() => BillsScreen());
      },
    },
    {
      'icon': "assets/svg/top_up.svg", // Assuming you have this SVG
      'label': 'Top-up',
      'color': Colors.orange,
      'onTap': () {
        print("Mobile Top-up pressed");
        // Get.to(() => MobileTopUpScreen());
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    getUserData();
    getLogs();
    getNotificationCount();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      getUserData();
      getLogs();
      getNotificationCount();
      final hour = DateTime.now().hour;
      if (hour == 12 || hour == 17 || hour == 21) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  openEye(bool value) {
    setState(() {
      isOpen = !isOpen;
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

  Future<void> getUserData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getLogs() async {
    try {
      userInfo = await Authentication().getUserData2();
      final profilepic = await Authentication().getUserProfilePic();
      myprofile = profilepic;
      DateTime timeNow = await Functions.getTimeNow();
      String toDate = timeNow.toString().split(" ")[0];
      String fromDate =
          timeNow.subtract(const Duration(days: 1)).toString().split(" ")[0];
      String userId = userInfo["user_id"].toString();

      String subApi =
          "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=$fromDate&tran_date_to=$toDate";
      HttpRequestApi(api: subApi).get().then((response) async {
        if (response == "No Internet") {
          hasNet = false;
          isLoading = false;
          _startAutoRefresh();
          if (!_isDialogVisible) {
            _isDialogVisible = true;
            CustomDialogStack.showConnectionLost(Get.context!, () {
              _isDialogVisible = false;
              Get.back();
              getLogs();
            });
          }
          return;
        }

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
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
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
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 19, 19, 0),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildBalanceCard(),

              SizedBox(height: 20),
              _buildMerchantBillsGrid(),

              SizedBox(height: 20),
              Expanded(
                child: PageView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                  children: [_buildTransactionsTab(), _buildTopUpTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ADDED: Merchant & Bills & Top-up Grid Widget
  Widget _buildMerchantBillsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: _merchantGridItems.length,
      itemBuilder: (context, index) {
        final item = _merchantGridItems[index];
        return _buildMerchantGridItem(item);
      },
    );
  }

  // ADDED: Merchant Grid Item Widget
  Widget _buildMerchantGridItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: item['onTap'],
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SvgPicture.asset(item['icon'], width: 50, height: 50),
            ),
            SizedBox(height: 8),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColorV2.primaryTextColor,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String greeting = _getTimeBasedGreeting();

    return Row(
      children: [
        LpProfileAvatar(base64Image: myprofile, size: 50, borderWidth: 3),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(
                text: greeting,
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
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  Widget _buildBalanceCard() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: AppColorV2.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.lpBlueBrand.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DefaultText(
                      text: 'Total Balance',
                      style: AppTextStyle.paragraph1,
                      color: AppColorV2.background,
                      fontWeight: FontWeight.w600,
                    ),

                    InkWell(
                      onTap: () {
                        openEye(isOpen);
                      },
                      child: Icon(
                        isOpen
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                DefaultText(
                  text:
                      userData.isEmpty ||
                              userData[0]["items"].isEmpty ||
                              !isOpen
                          ? "•••••••"
                          : toCurrencyString(
                            userData[0]["items"][0]["amount_bal"],
                          ),
                  fontSize: 32,
                  style: AppTextStyle.body1,
                  color: AppColorV2.background,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DefaultText(
                        maxFontSize: 12,
                        minFontSize: 8,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColorV2.pastelBlueAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _selectedTab == 0
                          ? [
                            BoxShadow(
                              color: AppColorV2.boxStroke.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: DefaultText(
                    text: 'Transactions',
                    style: TextStyle(
                      color:
                          _selectedTab == 0
                              ? AppColorV2.lpBlueBrand
                              : AppColorV2.bodyTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _selectedTab == 1
                          ? [
                            BoxShadow(
                              color: AppColorV2.boxStroke.withOpacity(0.5),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: DefaultText(
                    text: 'Top Up',
                    style: TextStyle(
                      color:
                          _selectedTab == 1
                              ? AppColorV2.lpBlueBrand
                              : AppColorV2.bodyTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultText(
              text: 'Recent Transactions',
              style: TextStyle(
                color: AppColorV2.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              onTap: () {
                Get.to(TransactionHistory());
              },
              child: DefaultText(
                text: 'See all',
                color: AppColorV2.lpBlueBrand,
                style: AppTextStyle.body1,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await getLogs();
            },
            child: TransactionSectionListView(
              sectionTitle: '',
              transactions: logs.cast<Map<String, dynamic>>(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (logs.isEmpty) {
      return NoTransactionsWidget();
    }

    return ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: logs.length + 1,
      itemBuilder: (context, index) {
        if (index == logs.length) {
          return SizedBox(height: MediaQuery.of(context).size.height * 0.1);
        }

        final transaction = logs[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    String formatDate(String dateString) {
      try {
        DateTime date = DateTime.parse(dateString).toLocal();
        return DateFormat('MMM dd, yyyy • HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    final amountString = transaction['amount']?.toString() ?? '0';
    final isPositive = !amountString.contains("-");

    final transactionData = _getTransactionData(
      transaction['category']?.toString() ?? 'Transaction',
      isPositive,
    );

    return InkWell(
      onTap: () {
        Get.to(
          TransactionDetails(index: 0, data: [transaction], isHistory: true),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColorV2.boxStroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transactionData['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transactionData['icon'],
                color: transactionData['color'],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: transaction['category']?.toString() ?? 'Transaction',
                    style: AppTextStyle.body1,
                    color: AppColorV2.primaryTextColor,
                  ),
                  SizedBox(height: 4),
                  DefaultText(
                    text:
                        transaction['tran_desc']?.toString() ??
                        'No description',
                    maxLines: 1,
                    maxFontSize: 12,
                  ),
                  SizedBox(height: 4),
                  DefaultText(
                    text: formatDate(
                      transaction['tran_date']?.toString() ?? '',
                    ),
                    style: AppTextStyle.body1,
                    maxFontSize: 10,
                    minFontSize: 8,
                  ),
                ],
              ),
            ),
            DefaultText(
              text: toCurrencyString(amountString),
              style: TextStyle(
                color: isPositive ? AppColorV2.success : AppColorV2.error,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTransactionData(String category, bool isPositive) {
    final categoryLower = category.toLowerCase();

    if (isPositive) {
      return {
        'icon': Icons.arrow_downward_rounded,
        'color': AppColorV2.success,
      };
    }

    if (categoryLower.contains('electric') ||
        categoryLower.contains('utility')) {
      return {'icon': Icons.bolt_rounded, 'color': AppColorV2.warning};
    } else if (categoryLower.contains('water')) {
      return {'icon': Icons.water_drop_rounded, 'color': Colors.blue};
    } else if (categoryLower.contains('internet') ||
        categoryLower.contains('mobile')) {
      return {'icon': Icons.wifi_rounded, 'color': Colors.purple};
    } else if (categoryLower.contains('grocery') ||
        categoryLower.contains('food')) {
      return {
        'icon': Icons.shopping_bag_rounded,
        'color': AppColorV2.secondary,
      };
    } else if (categoryLower.contains('shopping') ||
        categoryLower.contains('store')) {
      return {'icon': Icons.shopping_cart_rounded, 'color': Colors.orange};
    } else {
      return {'icon': Icons.arrow_upward_rounded, 'color': AppColorV2.error};
    }
  }

  Widget _buildTopUpTab() {
    final banks = [
      {
        'name': 'Maya',
        'image': 'assets/images/w_maya.png',
        'color': AppColorV2.lpBlueBrand,
      },
      {
        'name': 'Landbank',
        'image': 'assets/images/w_landbank.png',
        'color': AppColorV2.success,
      },
      {
        'name': 'UnionBank',
        'image': 'assets/images/w_unionbank.png',
        'color': AppColorV2.secondary,
      },
      {
        'name': 'InstaPay',
        'image': 'assets/images/w_instapay.png',
        'color': AppColorV2.warning,
      },
    ];

    return ListView(
      children: [
        DefaultText(
          text: 'Top Up Methods',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        DefaultText(
          text: 'Select your preferred bank to top up your wallet',
          style: TextStyle(color: AppColorV2.bodyTextColor, fontSize: 14),
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: banks.length,
          itemBuilder: (context, index) {
            final bank = banks[index];
            return _buildBankCard(bank, context);
          },
        ),
        SizedBox(height: 20),
        _buildQuickTopUpSection(),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
      ],
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorV2.boxStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      bank['image'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: bank['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getFallbackIcon(bank['name']),
                            color: bank['color'],
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  DefaultText(
                    text: bank['name'],
                    style: TextStyle(
                      color: AppColorV2.primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon(String bankName) {
    switch (bankName) {
      case 'Maya':
        return Icons.account_balance_wallet_rounded;
      case 'Landbank':
        return Icons.account_balance_rounded;
      case 'UnionBank':
        return Icons.business_rounded;
      case 'InstaPay':
        return Icons.flash_on_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildQuickTopUpSection() {
    final amounts = [100, 500, 1000, 2000, 5000, 10000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(
          text: 'Quick Top Up',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              amounts.map((amount) {
                return _buildAmountChip(amount);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountChip(int amount) {
    return GestureDetector(
      onTap: () {
        _showTopUpBottomSheet('Quick Top Up', amount: amount);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColorV2.pastelBlueAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: DefaultText(
          text: '₱${amount.toString()}',
          style: TextStyle(
            color: AppColorV2.lpBlueBrand,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showTopUpBottomSheet(String method, {int? amount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColorV2.boxStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                DefaultText(
                  text: 'Top Up via $method',
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                DefaultText(
                  text: 'Enter the amount you want to add to your wallet',
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 30),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorV2.lpBlueBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: DefaultText(
                      text: 'Continue to Top Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NoTransactionsWidget extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final VoidCallback? onActionTap;

  const NoTransactionsWidget({
    super.key,
    this.message,
    this.subtitle,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColorV2.pastelBlueAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: AppColorV2.lpBlueBrand.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          DefaultText(
            text: subtitle ?? 'Your recent transactions will appear here',
            style: TextStyle(
              color: AppColorV2.bodyTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
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

class TransactionSectionListView extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, dynamic>> transactions;

  const TransactionSectionListView({
    super.key,
    required this.sectionTitle,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return NoTransactionsWidget();
    }

    return Container(
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultText(
              text: sectionTitle,
              style: TextStyle(
                color: AppColorV2.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionItem(context, transaction);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    String formatDate(String dateString) {
      try {
        DateTime date = DateTime.parse(dateString).toLocal();
        return DateFormat('MMM dd, yyyy • HH:mm').format(date);
      } catch (e) {
        return dateString;
      }
    }

    final amountString = transaction['amount']?.toString() ?? '0';
    final isPositive = !amountString.contains("-");

    final transactionData = _getTransactionData(
      transaction['category']?.toString() ?? 'Transaction',
      isPositive,
    );

    return InkWell(
      onTap: () {
        Get.to(
          TransactionDetails(index: 0, data: [transaction], isHistory: true),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColorV2.boxStroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transactionData['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transactionData['icon'],
                color: transactionData['color'],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: transaction['category']?.toString() ?? 'Transaction',
                    style: AppTextStyle.body1,
                    color: AppColorV2.primaryTextColor,
                  ),
                  SizedBox(height: 4),
                  DefaultText(
                    text:
                        transaction['tran_desc']?.toString() ??
                        'No description',
                    maxLines: 1,
                    maxFontSize: 12,
                  ),
                  SizedBox(height: 4),
                  DefaultText(
                    text: formatDate(
                      transaction['tran_date']?.toString() ?? '',
                    ),
                    style: AppTextStyle.body1,
                    maxFontSize: 10,
                    minFontSize: 8,
                  ),
                ],
              ),
            ),
            DefaultText(
              text: toCurrencyString(amountString),
              style: TextStyle(
                color: isPositive ? AppColorV2.success : AppColorV2.error,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTransactionData(String category, bool isPositive) {
    final categoryLower = category.toLowerCase();

    if (isPositive) {
      return {
        'icon': Icons.arrow_downward_rounded,
        'color': AppColorV2.success,
      };
    }

    if (categoryLower.contains('electric') ||
        categoryLower.contains('utility')) {
      return {'icon': Icons.bolt_rounded, 'color': AppColorV2.warning};
    } else if (categoryLower.contains('water')) {
      return {'icon': Icons.water_drop_rounded, 'color': Colors.blue};
    } else if (categoryLower.contains('internet') ||
        categoryLower.contains('mobile')) {
      return {'icon': Icons.wifi_rounded, 'color': Colors.purple};
    } else if (categoryLower.contains('grocery') ||
        categoryLower.contains('food')) {
      return {
        'icon': Icons.shopping_bag_rounded,
        'color': AppColorV2.secondary,
      };
    } else if (categoryLower.contains('shopping') ||
        categoryLower.contains('store')) {
      return {'icon': Icons.shopping_cart_rounded, 'color': Colors.orange};
    } else {
      return {'icon': Icons.arrow_upward_rounded, 'color': AppColorV2.error};
    }
  }
}
