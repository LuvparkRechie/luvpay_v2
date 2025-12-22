import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_profile_image.dart';
import 'package:luvpay/pages/billers/index.dart';
import 'package:luvpay/pages/billers/utils/allbillers.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:luvpay/pages/scanner_screen.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';
import '../dashboard/refresh_wallet.dart';
import '../transaction/transaction_details.dart';
import '../transaction/transaction_screen.dart';
import 'notifications.dart';

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
  int unreadMsg = 0;
  int notifCount = 0;
  final PageController _pageController = PageController();
  bool isOpen = false;
  String myprofile = "";
  bool _isDialogVisible = false;

  List<Map<String, dynamic>> get _merchantGridItems => [
    {
      'icon': "assets/images/luvpay_merchant.png",
      'label': 'Merchant',
      'color': Colors.blue,
      'onTap': () {
        scanMerchant();
      },
    },
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
      'icon': "assets/images/luvpay_subwallet.png",
      'label': 'Subwallets',
      'color': Colors.red,
      'onTap': () {
        Get.toNamed(Routes.subwallet);
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
    getNotificationCount();

    ever(WalletRefreshBus.refresh, (_) {
      _startAutoRefresh();
    });
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

  Future<void> scanMerchant() async {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return ScannerScreenV2(
          onchanged: (args) async {
            if (args.isNotEmpty) {
              getService(args);
            }
          },
        );
      },
    );
  }

  Future<dynamic> getScannedQr(String apiKey) async {
    print("Calling API: $apiKey");
    final response = await HttpRequestApi(api: apiKey).get();
    return response;
  }

  void getService(String args) async {
    CustomDialogStack.showLoading(Get.context!);

    String apiMerchant = "${ApiKeys.getMerchantScan}?merchant_key=$args";

    final merchantResponse = await getScannedQr(apiMerchant);

    if (merchantResponse == "No Internet") {
      _showInternetError();
      return;
    }

    if (_isValidResponse(merchantResponse)) {
      String serviceName = merchantResponse["items"][0]["merchant_name"] ?? "";
      String serviceAddress =
          merchantResponse["items"][0]["merchant_address"] ?? "";
      _handleSuccess(
        args,
        "merchant",
        merchantResponse,
        serviceName,
        serviceAddress,
      );
      return;
    }

    Get.back();
    CustomDialogStack.showError(
      Get.context!,
      "Invalid QR Code",
      "This QR code is not registered in the system.",
      () {
        Get.back();
      },
    );
  }

  bool _isValidResponse(dynamic res) {
    if (res == null) return false;
    if (res == "Error" || res == "Failed") return false;
    if (res == "" || res == "{}" || res == "[]") return false;

    if (res is Map && res.isNotEmpty) return true;
    if (res is List && res.isNotEmpty) return true;

    return false;
  }

  void _handleSuccess(
    String args,
    String type,
    dynamic response,
    serviceName,
    serviceAddress,
  ) async {
    final paymentHk = await getpaymentHK();
    Get.back();

    List itemData = [
      {
        "data": response["items"],
        'merchant_key': args,
        "merchant_name": serviceName,
        'merchant_address': serviceAddress,
        "payment_key": paymentHk,
      },
    ];
    Get.to(
      Scaffold(
        backgroundColor: AppColorV2.background,
        appBar: AppBar(
          elevation: 1,
          backgroundColor: AppColorV2.lpBlueBrand,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColorV2.lpBlueBrand,
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
          ),
          title: Text("Pay Merchant"),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(Iconsax.arrow_left, color: Colors.white),
          ),
        ),
        body: PayMerchant(data: itemData),
      ),
    );
  }

  void _showInternetError() {
    Get.back();
    CustomDialogStack.showError(
      Get.context!,
      "Error",
      "Please check your internet connection and try again.",
      () {
        Get.back();
      },
    );
  }

  Future<dynamic> getpaymentHK() async {
    final userID = await Authentication().getUserId();

    final paymentKey =
        await HttpRequestApi(api: "${ApiKeys.getPaymentKey}$userID").get();
    if (paymentKey == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return null;
    }
    if (paymentKey == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });

      return null;
    }
    if (paymentKey["items"].isNotEmpty) {
      print("diri ${paymentKey["items"][0]["payment_hk"]}");
      return paymentKey["items"][0]["payment_hk"].toString();
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });

      return null;
    }
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
        'color': AppColorV2.secondary,
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
        'color': AppColorV2.warning,
        'onTap': () {
          Get.toNamed(
            Routes.walletrechargeload,
            arguments: {
              "bank_type": "InstaPay",
              "image": "assets/images/wt_instapay.png",
              "bank_code": " InstaPay",
            },
          );
        },
      },

      {
        'name': 'UnionBank',
        'image': 'assets/images/w_pesonet.png',
        'color': AppColorV2.secondary,
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
        'color': AppColorV2.success,
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
        'color': AppColorV2.success,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SizedBox(height: 16),

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
                text: 'Select Top-Up Method',
                style: TextStyle(
                  color: AppColorV2.primaryTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildBalanceCard(),
              _buildMerchantBillsGrid(),
              SizedBox(height: 25),
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
                  GestureDetector(
                    onTap: () {
                      Get.to(() => TransactionHistory());
                    },
                    child: DefaultText(
                      text: 'See all',
                      style: AppTextStyle.textButton,
                      color: AppColorV2.lpBlueBrand,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
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
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
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
            Image.asset(item['icon'], width: 55, height: 60),
            SizedBox(height: 5),
            DefaultText(
              text: item['label'],
              textAlign: TextAlign.center,
              style: AppTextStyle.body1,
              color: AppColorV2.primaryTextColor,
              minFontSize: 5,
              maxLines: 1,
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
        LpProfileAvatar(imageProvider: profileImage, size: 50, borderWidth: 3),
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
                text: Functions().getFirstSurnameLetter(userInfo),
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
    return Container(
      height: 198,
      width: 350,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/luvpay_card.png"),
          fit: BoxFit.fill,
        ),
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
                color: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
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
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DefaultText(
                          text: 'Available Balance',
                          style: AppTextStyle.paragraph1,
                          color: AppColorV2.background,
                          fontWeight: FontWeight.w600,
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
                      style: AppTextStyle.body1,
                      color: AppColorV2.background,
                    ),
                    SizedBox(height: 8),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DefaultText(
                      text: Functions().getFirstSurnameLetter(userInfo),
                      style: AppTextStyle.h3_semibold,
                      color: AppColorV2.background,
                      maxLines: 1,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: TransactionSectionListView(
        transactions: logs.cast<Map<String, dynamic>>(),
      ),
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
            color: Colors.black.withValues(alpha: 0.03),
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
                            color: bank['color'].withValues(alpha: 0.1),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 50,
                color: AppColorV2.lpBlueBrand.withValues(alpha: 0.5),
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
  final List<Map<String, dynamic>> transactions;

  const TransactionSectionListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return NoTransactionsWidget();
    }

    return Container(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: BouncingScrollPhysics(),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: transactionData['color'].withValues(alpha: 0.1),
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
