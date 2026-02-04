// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/no_data_found.dart';
import 'package:luvpay/pages/billers/index.dart';
import 'package:luvpay/pages/billers/utils/allbillers.dart';
import 'package:luvpay/pages/routes/routes.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/neumorphism.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';
import '../dashboard/refresh_wallet.dart';
import '../transaction/transaction_details.dart';
import '../transaction/transaction_screen.dart';

class WalletScreen extends StatefulWidget {
  final bool? fromTab;
  const WalletScreen({super.key, this.fromTab});

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
  int unreadMsg = 0;
  int notifCount = 0;
  final PageController _pageController = PageController();
  bool isOpen = false;
  String myprofile = "";
  bool _isDialogVisible = false;

  List<Map<String, dynamic>> get _merchantGridItems => [
    {
      'icon': "assets/images/luvpay_bills.png",
      'label': 'Bills',
      'color': Colors.green,
      'onTap': () async {
        final billController = Get.put(BillersController());
        billController.getBillers((billers) async {
          final result = await Get.to(
            () => Allbillers(),
            arguments: {'source': 'pay'},
          );
          if (result != null) {
            _startAutoRefresh();
            getUserData();
            getLogs();
          }
        });
      },
    },
    {
      'icon': "assets/images/luvpay_topup.png",
      'label': 'Top-up',
      'color': Colors.orange,
      'onTap': () {
        showTopUpMethod();
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      getLogs();
    });
    getUserData();
    _loadProfile();
    _startAutoRefresh();

    ever(WalletRefreshBus.refresh, (_) {
      getUserData();
      getLogs();
    });
  }

  void _startAutoRefresh() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      getUserData();
      getLogs();
    });
  }

  openEye(bool value) {
    setState(() {
      isOpen = !isOpen;
    });
  }

  Future<void> getUserData() async {
    if (isLoading || !mounted) return;

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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  ImageProvider? profileImage;

  Future<void> _loadProfile({bool force = false}) async {
    final pic = await Authentication().getUserProfilePic();
    if (!mounted) return;

    if (pic.isEmpty) return;

    if (force || pic != myprofile) {
      final cached = ImageCacheHelper.getCachedImage(pic);

      if (cached != null) {
        profileImage = cached;
      } else {
        final bytes = base64Decode(pic);
        final provider = MemoryImage(bytes);
        ImageCacheHelper.cacheImage(pic, provider);
        profileImage = provider;
      }

      setState(() {
        myprofile = pic;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final data = await Authentication().getUserData2();
    if (!mounted) return;

    setState(() {
      userInfo = data;
    });
  }

  Future<void> getLogs() async {
    if (userInfo["user_id"] == null) return;

    try {
      DateTime timeNow = await Functions.getTimeNow();
      String toDate = timeNow.toString().split(" ")[0];
      String fromDate =
          timeNow.subtract(const Duration(days: 1)).toString().split(" ")[0];

      String subApi =
          "${ApiKeys.getTransLogs}?user_id=${userInfo["user_id"]}&tran_date_from=$fromDate&tran_date_to=$toDate";

      final response = await HttpRequestApi(api: subApi).get();

      if (!mounted) return;

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
        final today = (await Functions.getTimeNow())
            .toUtc()
            .toIso8601String()
            .substring(0, 10);

        setState(() {
          logs =
              response["items"]
                  .where(
                    (e) => e['tran_date'].toString().split("T")[0] == today,
                  )
                  .take(5)
                  .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  Future<void> showTopUpMethod() async {
    final banks = [
      {
        'name': 'UnionBank',
        'image': 'assets/images/w_unionbank.png',
        'color': AppColorV2.lpTealBrand,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "UnionBank",
              "image": "assets/images/wt_unionbank.png",
              "bank_code": " UB ONLINE",
            },
          );
        },
      },
      {
        'name': 'InstaPay',
        'image': 'assets/images/w_instapay.png',
        'color': AppColorV2.partialState,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "UnionBank",
              "image": "assets/images/wt_instapay.png",
              "bank_code": " InstaPay",
            },
          );
        },
      },
      {
        'name': 'Pesonet',
        'image': 'assets/images/w_pesonet.png',
        'color': AppColorV2.lpTealBrand,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "UnionBank",
              "image": "assets/images/wt_pesonet.png",
              "bank_code": "paygate",
            },
          );
        },
      },
      {
        'name': 'Landbank',
        'image': 'assets/images/w_landbank.png',
        'color': AppColorV2.correctState,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "Landbank",
              "image": "assets/images/wt_landbank.png",
              "bank_code": " LandBank",
            },
          );
        },
      },
      {
        'name': 'Maya',
        'image': "assets/images/w_maya.png",
        'color': AppColorV2.correctState,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "Maya",
              "image": "assets/images/wt_maya.png",
              "bank_code": " Maya",
            },
          );
        },
      },
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(isDark ? 0.05 : .01),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.05 : .01),
                blurRadius: 18,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DefaultText(
                text: 'Select Top-Up Method',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: banks.length,
                  itemBuilder: (context, index) {
                    final bank = banks[index];
                    return _buildBankCard(bank, context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: (isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 19, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildBalanceCard(),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DefaultText(
                      text: 'Recent Transactions',
                      style: AppTextStyle.h3(context),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => TransactionHistory());
                      },
                      child: DefaultText(
                        text: 'See all',
                        color: AppColorV2.lpBlueBrand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildTransactionsTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantBillsGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 10,
        mainAxisExtent: 50,
      ),
      itemCount: _merchantGridItems.length,
      itemBuilder: (context, index) {
        final item = _merchantGridItems[index];
        return _buildMerchantGridItem(item);
      },
    );
  }

  Widget _buildMerchantGridItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: item['onTap'],
      child: FittedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeoNavIcon.icon(
              assetPath: item['icon'],
              onTap: item['onTap'],
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String greeting = _getTimeBasedGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("assets/images/luvpay_text.png", height: 30),
                DefaultText(
                  text: greeting,
                  style: AppTextStyle.body1(context),
                  color: cs.onSurface.withOpacity(0.70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  Widget _buildBalanceCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 198,
      width: 350,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/luvpay_card.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          if (isDark)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
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
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          "assets/images/onboardluvpay.png",
                          width: 100,
                          height: 30,
                        ),
                        InkWell(
                          onTap: () {
                            openEye(isOpen);
                          },
                          child: Image.asset(
                            isOpen
                                ? "assets/images/eye_show.png"
                                : "assets/images/eye_hide.png",
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DefaultText(
                          text: 'Available Balance',
                          style: AppTextStyle.paragraph1(context),
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    DefaultText(
                      text:
                          userData.isEmpty ||
                                  userData[0]["items"].isEmpty ||
                                  !isOpen
                              ? "PHP •••••••"
                              : "PHP ${toCurrencyString(userData[0]["items"][0]["amount_bal"])}",
                      fontSize: 32,
                      style: AppTextStyle.body1(context),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DefaultText(
                            minFontSize: 8,
                            text:
                                userInfo["mobile_no"] != null
                                    ? "•••••••${userInfo["mobile_no"].toString().substring(userInfo["mobile_no"].toString().length - 4)}"
                                    : "•••••••••••",
                            style: AppTextStyle.body1(context),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 120,
                        child: _buildMerchantBillsGrid(),
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

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: TransactionSectionListView(
        transactions: logs.cast<Map<String, dynamic>>(),
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank, BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(isDark ? 0.05 : .01),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.back();
            bank["onTap"]();
          },
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
                            color: (bank['color'] as Color).withValues(
                              alpha: 0.12,
                            ),
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
                  const SizedBox(height: 8),
                  DefaultText(
                    text: bank['name'],
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
  final List<Map<String, dynamic>> transactions;

  const TransactionSectionListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return NoDataFound();
    }

    return Container(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionItem(context, transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    String formatDate(String dateString) {
      try {
        final date = DateTime.parse(dateString).toLocal();
        return DateFormat('MMM dd, yyyy • HH:mm').format(date);
      } catch (_) {
        return dateString;
      }
    }

    final amountString = transaction['amount']?.toString() ?? '0';
    final amount = double.tryParse(amountString) ?? 0.0;
    final isPositive = amount >= 0;

    final accent =
        isPositive ? AppColorV2.correctState : AppColorV2.incorrectState;

    final tileBg = cs.surface;
    final tileBorder = cs.outlineVariant.withOpacity(isDark ? 0.55 : 1.0);

    return CustomRowTile(
      onTap: () {
        Get.to(
          TransactionDetails(index: 0, data: [transaction], isHistory: true),
        );
      },

      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: accent.withOpacity(isDark ? 0.16 : 0.10),
        ),
        child: Icon(
          isPositive
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: accent,
          size: 20,
        ),
      ),

      title: DefaultText(
        text: transaction['category']?.toString() ?? 'Transaction',
        style: AppTextStyle.body1(context),
        maxFontSize: 14,
        minFontSize: 8,
        color: cs.onSurface,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(
            text: transaction['tran_desc']?.toString() ?? 'No description',
            maxLines: 1,
            maxFontSize: 12,
            style: AppTextStyle.paragraph2(context),
            color: cs.onSurfaceVariant.withOpacity(0.85),
          ),
          const SizedBox(height: 4),
          DefaultText(
            text: formatDate(transaction['tran_date']?.toString() ?? ''),
            style: AppTextStyle.body1(context),
            maxFontSize: 10,
            minFontSize: 8,
            color: cs.onSurfaceVariant.withOpacity(0.75),
          ),
        ],
      ),

      trailing: DefaultText(
        text: toCurrencyString(amountString),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
        ),
      ),

      background: tileBg,
      leadingBackground: tileBg,
    );
  }
}
