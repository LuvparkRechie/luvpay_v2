// ignore_for_file: deprecated_member_use, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart'
    hide toCurrencyString;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_loading.dart';
import 'package:luvpay/shared/widgets/no_data_found.dart';
import 'package:luvpay/features/billers/index.dart';
import 'package:luvpay/features/biller_screen/allbillers.dart';
import 'package:luvpay/features/routes/routes.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import '../../shared/widgets/luvpay_conn.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import '../../core/network/http/http_request.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../subwallet/controller.dart';
import '../subwallet/utils/wallet_details.dart';
import '../subwallet/view.dart';
import 'refresh_wallet.dart';
import 'transaction/subwallets_carousel.dart';
import 'transaction/transaction_details.dart';
import 'transaction/transaction_screen.dart';

class WalletScreen extends StatefulWidget {
  final bool? fromTab;
  const WalletScreen({super.key, this.fromTab});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final BillersController billController = Get.put(BillersController());
  List favBillers = [];
  final subWalletController = Get.put(SubWalletController());
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
  List<Map<String, dynamic>> userDetails = [];
  String firstName = "";
  String _internetMsg = "Connection lost";
  int _loadCtr = 0;
  bool _isActiveTmr = true;
  String serviceFee = "0.00";
  String maxFee = "0.00";
  List<Map<String, dynamic>> get _merchantGridItems => [
        {
          'icon': Icons.add_circle,
          'label': 'Top-up',
          'color': AppColorV2.lpBlueBrand,
          'onTap': userDetails[0]["email"] == null ||
                  userDetails[0]["first_name"] == null
              ? () {
                  CustomDialogStack.showConfirmation(
                      Get.context!,
                      "Update Profile",
                      "Please update your profile to continue using this feature. Would you like to update now?",
                      leftText: "Cancel",
                      rightText: "Update", () {
                    Get.back();
                  }, () async {
                    Get.back();

                    final regions = await Functions().fetchRegions(context);

                    if (regions.isEmpty) return;

                    Get.toNamed(
                      Routes.updProfile,
                      arguments: regions,
                    );
                  });
                }
              : () {
                  showTopUpMethod();
                },
        },
        {
          'icon': Icons.people_alt,
          'label': 'Send',
          'color': AppColorV2.lpBlueBrand,
          'onTap': () {
            Get.toNamed(Routes.send);
          },
        },
        {
          'icon': Icons.wallet,
          'label': 'Bills',
          'color': AppColorV2.lpBlueBrand,
          'onTap': () async {
            final billController = Get.put(BillersController());
            billController.getBillers((billers) async {
              final result = await Get.to(
                () => Allbillers(),
                arguments: {'source': 'pay'},
              );
              if (result != null) {
                _refreshWallet();
              }
            });
          },
        },
      ];

  @override
  void initState() {
    super.initState();

    _loadUserInfo().then((_) {
      getLogs();
      getFavorites();
    });

    getUserData();
    _loadProfile();
    _startAutoRefresh();
    _showFirstName();
    ever(WalletRefreshBus.refresh, (_) {
      getUserData();
      getLogs();
      getFavorites();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pageController.dispose();
    super.dispose();
  }

  void disposeUyy() {
    _timer?.cancel();
    _timer = null;
    _pageController.dispose();
  }

  Future<void> getFavorites() async {
    final item = await Authentication().getUserData();
    final decodedItem = jsonDecode(item!);
    String userId = decodedItem['user_id'].toString();
    userDetails = [decodedItem];
    await billController.fetchFavorites(userId);
  }

  List<Wallet> _mapWallets(List<Map<String, dynamic>> data) {
    return data.map((w) {
      return Wallet(
        id: w['id']?.toString() ?? '',
        userId: w['user_id']?.toString() ?? '',
        categoryId: w['category_id']?.toString() ?? '',
        name: w['name']?.toString() ?? 'Unnamed Wallet',
        balance: (w['amount'] as num?)?.toDouble() ?? 0.0,
        category: w['category']?.toString() ?? 'Unknown',
        iconBase64: w['image_base64']?.toString(),
        color: AppColorV2.lpBlueBrand,
        createdOn: w['created_on']?.toString() ?? '',
        updatedOn: w['updated_on']?.toString() ?? '',
        isActive: w['is_active']?.toString() ?? 'N',
        categoryTitle: w['category_title']?.toString() ?? 'Unknown',
        imageBase64: w['image_base64']?.toString(),
        targetAmount: null,
      );
    }).toList();
  }

  Future<void> _refreshWallet() async {
    if (mounted) {
      setState(() {
        _loadCtr = 0;
        isLoading = true;
        _isActiveTmr = true;
      });
    }

    await Future.delayed(Duration(seconds: 1));
    getUserData();
    getLogs();
    await getFavorites();
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
    });
  }

  openEye(bool value) {
    setState(() {
      isOpen = !isOpen;
    });
  }

  Future<void> getUserData() async {
    if (!mounted) return;
    if (_loadCtr == 0) {
      setState(() => isLoading = true);
      if (mounted) {
        _loadCtr++;
      }
    }

    Functions.getUserBalance2(context, (List data) {
      if (Get.currentRoute != "/dashboard") return;
      if (!mounted) return;
      if (!_isActiveTmr) return;
      try {
        final root = (data.isNotEmpty && data[0] is Map) ? data[0] as Map : {};
        final net = root["has_net"];
        final success = root["success"];

        if (!success && !net) {
          setState(() {
            _internetMsg = "Connection lost";
            hasNet = net;
            userData = data;
            isLoading = false;
            _isActiveTmr = false;
          });
          _startAutoRefresh();
          return;
        }
        setState(() {
          hasNet = net;
          userData = data;
          isLoading = false;
          _isActiveTmr = true;
        });
        getLogs();
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
        if (mounted) {
          setState(() {
            hasNet = false;
            isLoading = false;
            _internetMsg = "Connection lost";
          });
        }
        _startAutoRefresh();
        return;
      }
      List itemData = response["items"];

      itemData.sort((a, b) {
        final dateA = DateTime.tryParse(a["tran_date"] ?? "") ?? DateTime(0);
        final dateB = DateTime.tryParse(b["tran_date"] ?? "") ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _internetMsg = "";
        logs = itemData.take(5).toList();
      });
    } catch (e) {
      _internetMsg = "Error";
      CustomDialogStack.showSnackBar(
          context, "Error fetching logs: $e", Colors.red, () => Get.back());
      debugPrint("Error fetching logs: $e");
    }
  }

  Future<bool> getServiceFee() async {
    CustomDialogStack.showLoading(Get.context!);

    final response = await HttpRequestApi(api: ApiKeys.getServiceFee).get();
    Get.back();

    if (response == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return false;
    }

    if (response == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return false;
    }

    setState(() {
      final fee = response["service_fee"];
      maxFee = response["max_topup_free"].toString();
      if (fee == null) return;
      serviceFee = fee == null
          ? "0.00"
          : double.tryParse(fee.toString())?.toStringAsFixed(2) ?? "0.00";
    });
    return true;
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
        'api': ApiKeys.getServiceFee,
        'name': 'Landbank',
        'image': 'assets/images/w_landbank.png',
        'color': AppColorV2.correctState,
        'onTap': () async {
          final success = await getServiceFee();

          if (!success) return;
          final arguments = {
            "bank_type": "Landbank",
            "image": "assets/images/wt_landbank.png",
            "bank_code": " LandBank",
            "service_fee": serviceFee.toString(),
            "max_fee": maxFee.toString(),
          };
          Get.toNamed(Routes.walletrechargeload, arguments: arguments);
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomScaffoldV2(
      appBarBackgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: LuvNeuPress.circle(
          onTap: () {
            Get.to(ProfileSettingsScreen(fromBuildHeader: true));
          },
          background: cs.surface,
          borderColor: cs.primary.withOpacity(0.10),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: LuvpayText(
                  text: Functions().getInitials(userInfo),
                  style: AppTextStyle.body1(context),
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
      appBarAction: [
        LuvNeuIconButton(
            icon: LucideIcons.history,
            onTap: () {
              Get.to(Get.to(() => TransactionHistory()));
            }),
      ],
      scaffoldBody: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 19, 10, 0),
          child: isLoading
              ? const Center(child: LoadingCard())
              : !isLoading && !hasNet
                  ? ConnectionInterruption(
                      onPressed: () {
                        _refreshWallet();
                      },
                    )
                  : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceCard(),
                          _carousel(context),
                          Obx(() {
                            final favs = billController.favBillers;

                            if (favs.isEmpty) return const SizedBox();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                LuvpayText(
                                  text:
                                      'Favorite Biller${favs.length > 1 ? 's' : ''}',
                                  style: AppTextStyle.h3(context),
                                ),
                                _favBillers(cs),
                                const SizedBox(height: 25),
                              ],
                            );
                          }),
                          _buildMerchantBillsGrid(),
                          const SizedBox(height: 25),
                          LuvpayText(
                            text: 'Transactions',
                            style: AppTextStyle.h3(context),
                          ),
                          const SizedBox(height: 15),
                          _buildTransactionsTab(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _favBillers(ColorScheme cs) {
    return Obx(() {
      final favs = billController.favBillers;

      if (favs.isEmpty) return const SizedBox();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: favs.map((fav) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  LuvNeuPress.rectangle(
                    radius: const BorderRadius.all(Radius.circular(50)),
                    background: cs.surface,
                    onTap: () {
                      CustomDialogStack.showConfirmation(
                        textAlign: TextAlign.left,
                        context,
                        fav['biller_name'] ?? 'Biller',
                        _buildFavSubtitle(fav),
                        () => Get.back(),
                        () async {
                          Get.back();

                          final mappedData = {
                            "bill_acct_no": fav["account_no"],
                            "bill_no": fav["bill_no"],
                            "account_name": fav["account_name"],
                            "amount": fav["amount"] ?? "0",
                            "biller_id": fav["biller_id"],
                            "biller_name": fav["biller_name"],
                            "service_fee": fav["service_fee"],
                          };
                          final paymentHk = await Functions.getpaymentHK();
                          if (paymentHk == null) {
                            CustomDialogStack.showServerError(Get.context!, () {
                              Get.back();
                            });
                            return;
                          }
                          final result = await Get.to(
                            () => BillerScreen(
                              paymentHk: paymentHk,
                              data: [mappedData],
                            ),
                            transition: Transition.rightToLeftWithFade,
                            duration: const Duration(milliseconds: 300),
                          );

                          if (result != null) {
                            _refreshWallet();
                          }
                        },
                        leftText: "Close",
                        rightText: "Bill Now",
                        isAllBlueColor: true,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: LuvpayText(
                        text: fav['biller_name'] ?? 'Unnamed',
                        style: AppTextStyle.body2(Get.context!),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  String _buildFavSubtitle(Map fav) {
    final buffer = StringBuffer();

    if (fav['account_name'] != null) {
      buffer.writeln("Account: ${fav['account_name']}");
    }
    if (fav['account_no'] != null) {
      buffer.writeln("Acct No: ${fav['account_no']}");
    }
    if (fav['biller_address'] != null) {
      buffer.writeln("Address: ${fav['biller_address']}");
    }
    if (fav['service_fee'] != null) {
      buffer.writeln("Fee: ₱${fav['service_fee']}");
    }

    return buffer.toString().trim();
  }

  Widget _carousel(BuildContext context) {
    return Obx(() {
      final wallets = _mapWallets(subWalletController.userSubWallets);

      if (wallets.isEmpty) {
        return const SizedBox();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14),
          SubWallerCarousel(
            wallets: wallets,
            onTap: (wallet) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                builder: (_) => WalletDetailsModal(
                  wallet: wallet,
                  allWallets: wallets,
                  onAddMoney: (_) async => _reloadSubWallets(),
                  onReturnMoney: (_) async => _reloadSubWallets(),
                  onUpdate: (_) async => _reloadSubWallets(),
                  onDelete: () async => _reloadSubWallets(),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Future<void> _reloadSubWallets() async {
    await subWalletController.getUserSubWallets();
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
              iconData: item['icon'],
              onTap: item['onTap'],
              borderRadius: BorderRadius.circular(14),
              iconColor: item['color'].withAlpha(200),
            ),
            SizedBox(height: 6),
            LuvpayText(
              text: item['label'],
              style: AppTextStyle.paragraph1(context),
              color: Theme.of(context).colorScheme.onSurface,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LuvNeuPress.circle(
            onTap: () {
              Get.to(ProfileSettingsScreen(fromBuildHeader: true));
            },
            background: cs.surface,
            borderColor: cs.primary.withOpacity(0.10),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: LuvpayText(
                    text: Functions().getInitials(userInfo),
                    style: AppTextStyle.body1(context),
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
          LuvNeuIconButton(
              icon: LucideIcons.history,
              onTap: () {
                Get.to(Get.to(() => TransactionHistory()));
              }),
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
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final balanceText =
        userData.isEmpty || userData[0]["items"].isEmpty || !isOpen
            ? "PHP • • • • • • •"
            : "PHP ${toCurrencyString(userData[0]["items"][0]["amount_bal"])}";

    final mobileText = isOpen
        ? (userInfo["mobile_no"]?.toString() ?? "• • • • • • • • • • •")
        : "• • • • • • • • • • •";

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuvpayText(
                text: 'Total Balance',
                style: AppTextStyle.h3_semibold(context),
                color: cs.onSurface.withOpacity(0.60),
              ),
              Row(
                children: [
                  LuvpayText(
                    key: ValueKey(isOpen),
                    text: balanceText,
                    style: AppTextStyle.h4(context),
                    color: cs.outline,
                  ),
                  _PremiumEyeIcon(
                    isOpen: isOpen,
                    onTap: () => openEye(isOpen),
                  ),
                ],
              ),
            ],
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
      return Center(child: NoDataFound());
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
        final cleaned = dateString.replaceAll('Z', '');
        final date = DateTime.parse(cleaned);

        return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isOpen ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 22,
          ),
        ),
      ),
    );
  }
}
