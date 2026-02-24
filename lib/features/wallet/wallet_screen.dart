// ignore_for_file: deprecated_member_use, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/shared/widgets/no_data_found.dart';
import 'package:luvpay/features/billers/index.dart';
import 'package:luvpay/features/billers/utils/allbillers.dart';
import 'package:luvpay/features/routes/routes.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import '../../core/network/http/http_request.dart';
import 'refresh_wallet.dart';
import 'transaction/transaction_details.dart';
import 'transaction/transaction_screen.dart';

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
  String firstName = "";
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
    {
      'icon': "assets/images/navigation.png",
      'label': 'Send',
      'color': Colors.orange,
      'onTap': () {
        Get.toNamed(Routes.send);
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
    _showFirstName();
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

    setState(() => isLoading = true);

    Functions.getUserBalance2(context, (List data) {
      if (!mounted) return;

      try {
        final root = (data.isNotEmpty && data[0] is Map) ? data[0] as Map : {};
        final net = root["has_net"] == true;
        final success = root["success"] == true;

        setState(() {
          hasNet = net;
          userData = data;
          isLoading = false;
        });

        if (!success && net) {}
      } catch (e) {
        debugPrint("Error parsing balance: $e");
        if (mounted) setState(() => isLoading = false);
      }
    });
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

  Future<void> _showFirstName() async {
    try {
      final data = await Authentication().getUserData2();
      final name = (data["first_name"] ?? "").toString().trim();
      if (!mounted) return;
      setState(() {
        firstName = name;
      });
    } catch (_) {}
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
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.60 : 0.35,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

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
              LuvpayText(
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
              const SizedBox(height: 14),
              _buildMerchantBillsGrid(),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LuvpayText(
                      text: 'Recent Transactions',
                      style: AppTextStyle.h3(context),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => TransactionHistory());
                      },
                      child: LuvpayText(
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
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisExtent: 80,
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
            SizedBox(height: 6),
            LuvpayText(
              text: item['label'],
              style: AppTextStyle.paragraph1(context),
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              maxFontSize: 12,
              minFontSize: 8,
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
                LuvpayText(
                  text: "$greeting${firstName.isEmpty ? "" : ", $firstName"}!",
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final balanceText =
        userData.isEmpty || userData[0]["items"].isEmpty || !isOpen
            ? "PHP • • • • • • •"
            : "PHP ${toCurrencyString(userData[0]["items"][0]["amount_bal"])}";

    final mobileText =
        isOpen
            ? (userInfo["mobile_no"]?.toString() ?? "• • • • • • • • • • •")
            : "• • • • • • • • • • •";
    final brandA = AppColorV2.lpBlueBrand;
    final brandB = AppColorV2.lpTealBrand;

    return Container(
      height: 198,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(brandA, Colors.black, isDark ? 0.14 : 0.00)!,
            Color.lerp(brandB, Colors.black, isDark ? 0.18 : 0.02)!,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.10 : 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.08 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withOpacity(isDark ? 0.05 : 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.14 : 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            LuvpayText(
                              text: "luvpay Wallet",
                              style: AppTextStyle.body1(context),
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              maxFontSize: 12,
                              minFontSize: 10,
                            ),
                          ],
                        ),
                      ),

                      _PremiumEyeIcon(
                        isOpen: isOpen,
                        onTap: () => openEye(isOpen),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LuvpayText(
                        text: 'Available Balance',
                        style: AppTextStyle.paragraph1(context),
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      LuvpayText(
                        key: ValueKey(isOpen),
                        text: balanceText,
                        fontSize: 32,
                        style: AppTextStyle.body1(context),
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.14 : 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: LuvpayText(
                          key: ValueKey(isOpen),
                          minFontSize: 8,
                          text: mobileText,
                          style: AppTextStyle.body1(context),
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  LuvpayText(
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

    return CustomRowTile(
      trailingUseNeumorphic: false,
      onTap: () {
        Get.to(
          TransactionDetails(index: 0, data: [transaction], isHistory: true),
        );
      },

      leading: Icon(
        !isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: accent,
        size: 20,
      ),

      title: LuvpayText(
        text: transaction['tran_desc']?.toString() ?? 'No description',
        style: AppTextStyle.body1(context),
        maxFontSize: 16,
        maxLines: 1,
        minFontSize: 14,
        color: cs.onSurface,
      ),
      subtitle: LuvpayText(
        text: formatDate(transaction['tran_date']?.toString() ?? ''),
        style: AppTextStyle.body1(context),
        maxFontSize: 10,
        minFontSize: 8,
        color: cs.onSurfaceVariant.withOpacity(0.75),
      ),

      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          LuvpayText(
            text: toCurrencyString(amountString),
            color: accent,
            style: AppTextStyle.body1(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          LuvpayText(
            text: transaction['category']?.toString() ?? 'Transaction',
            style: AppTextStyle.body1(context),
            maxFontSize: 10,
            minFontSize: 8,
            color: cs.onSurfaceVariant.withOpacity(0.75),
          ),
        ],
      ),

      background: tileBg,
      leadingBackground: tileBg,
    );
  }
}

class _PremiumEyeIcon extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _PremiumEyeIcon({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.14 : 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isOpen ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
