import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/http/http_request.dart';

import '../../../auth/authentication.dart';
import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/loading.dart';
import '../../../http/api_keys.dart';

class VouchersBody extends StatefulWidget {
  const VouchersBody({
    super.key,
    required this.queryParam,
    this.selectedIds,
    required this.callBack,
  });

  final Function? callBack;
  final Map<String, String>? queryParam;
  final Map<String, dynamic>? selectedIds;

  @override
  State<VouchersBody> createState() => VouchersBodyState();
}

class VouchersBodyState extends State<VouchersBody>
    with SingleTickerProviderStateMixin {
  List availableList = [];
  List claimedList = [];
  List expiredList = [];
  List vouchersList = [];

  final TextEditingController controller = TextEditingController();

  bool isLoading = true;
  bool isNetConn = true;
  bool isSelected = false;
  int? selectedVoucherId;

  bool _isDialogVisible = false;

  late TabController _tabController;
  int _savedTabIndex = 0;

  bool get _isFromBooking => widget.queryParam?["isFromBooking"] == "true";

  int get _tabLength => _isFromBooking ? 1 : 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _savedTabIndex = _tabController.index;
      }
    });
    _getVouchers();
  }

  @override
  void didUpdateWidget(covariant VouchersBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tabLength != _tabController.length) {
      final newIndex = _savedTabIndex.clamp(0, _tabLength - 1);

      _tabController.dispose();
      _tabController = TabController(length: _tabLength, vsync: this);
      _tabController.index = newIndex;

      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _savedTabIndex = _tabController.index;
        }
      });
    } else {
      final fixedIndex = _savedTabIndex.clamp(0, _tabLength - 1);
      if (_tabController.index != fixedIndex) _tabController.index = fixedIndex;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    await _getVouchers();
    final fixedIndex = _savedTabIndex.clamp(0, _tabLength - 1);
    if (_tabController.index != fixedIndex) _tabController.index = fixedIndex;
  }

  Future<void> _getVouchers() async {
    if (!mounted) return;

    _savedTabIndex = _tabController.index;

    setState(() {
      isLoading = true;
      isNetConn = true;
    });

    try {
      final item = await Authentication().getUserData();
      String userId = jsonDecode(item!)['user_id'].toString();

      final availableApi = "${ApiKeys.vouchers}?user_id=$userId";
      final usedApi = "${ApiKeys.vouchersUsed}?user_id=$userId";
      final expiredApi = "${ApiKeys.vouchersExpired}?user_id=$userId";

      final results = await Future.wait([
        HttpRequestApi(api: availableApi).get(),
        HttpRequestApi(api: usedApi).get(),
        HttpRequestApi(api: expiredApi).get(),
      ]);

      if (!mounted) return;

      if (results.contains("No Internet")) {
        setState(() {
          isLoading = false;
          isNetConn = false;
        });

        if (!_isDialogVisible) {
          _isDialogVisible = true;
          CustomDialogStack.showConnectionLost(Get.context!, () {
            _isDialogVisible = false;
            Get.back();
            _getVouchers();
          });
        }
        return;
      }

      final availableData = results[0];
      final usedData = results[1];
      final expiredData = results[2];

      setState(() {
        availableList =
            availableData is Map ? (availableData["items"] ?? []) : [];
        claimedList = usedData is Map ? (usedData["items"] ?? []) : [];
        expiredList = expiredData is Map ? (expiredData["items"] ?? []) : [];

        vouchersList = [...availableList, ...claimedList, ...expiredList];

        isLoading = false;
        isNetConn = true;
      });

      if (widget.selectedIds != null && widget.selectedIds!.isNotEmpty) {
        final selectedVoucher = vouchersList.firstWhere(
          (voucher) =>
              voucher["promo_voucher_id"] ==
              widget.selectedIds!["promo_voucher_id"],
          orElse: () => {},
        );
        selectedVoucherId = selectedVoucher["promo_voucher_id"];
        isSelected = true;
      }

      final fixedIndex = _savedTabIndex.clamp(0, _tabLength - 1);
      if (_tabController.index != fixedIndex) _tabController.index = fixedIndex;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isNetConn = true;
      });
    }
  }

  Widget _noVoucherWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/novouchersyet.svg"),
          const SizedBox(height: 16),
          DefaultText(
            text: "No Vouchers Yet",
            style: AppTextStyle.h3,
            color: AppColorV2.inactiveState,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _voucherListView(List list, bool isFromBooking, {bool isCE = false}) {
    if (list.isEmpty) {
      return _noVoucherWidget();
    }

    return RefreshIndicator(
      onRefresh: _getVouchers,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final voucher = list[index];
          isSelected = voucher["promo_voucher_id"] == selectedVoucherId;

          DateTime? expDt =
              voucher["expiry_date"] != null &&
                      voucher["expiry_date"].toString().isNotEmpty
                  ? DateTime.tryParse(voucher["expiry_date"].toString())
                  : null;

          String voucherDt =
              expDt != null ? DateFormat('MMM d, yyyy').format(expDt) : "N/A";

          return Stack(
            alignment: Alignment.centerRight,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  InkWell(
                    onTap:
                        !isFromBooking
                            ? null
                            : () {
                              if (selectedVoucherId ==
                                  voucher["promo_voucher_id"]) {
                                selectedVoucherId = null;
                              } else {
                                selectedVoucherId = voucher["promo_voucher_id"];
                              }
                              setState(() {});
                              widget.callBack!(selectedVoucherId);
                            },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 6,
                                offset: const Offset(5, 2),
                              ),
                            ],
                          ),
                          child:
                              isCE
                                  ? ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withAlpha(100),
                                      BlendMode.srcATop,
                                    ),
                                    child: Image.asset(
                                      "assets/images/voucher_ticket.png",
                                      height: 70,
                                    ),
                                  )
                                  : Image.asset(
                                    "assets/images/voucher_ticket.png",
                                    height: 70,
                                  ),
                        ),
                        Expanded(
                          child: Tooltip(
                            onTriggered: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: '${voucher["voucher_code"]}',
                                ),
                              );
                            },
                            message: '${voucher["voucher_code"]}',
                            waitDuration: const Duration(milliseconds: 500),
                            showDuration: const Duration(seconds: 2),
                            child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                                color: AppColorV2.background,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DefaultText(
                                    text: voucher["merchant_name"] ?? "N/A",
                                    style: AppTextStyle.h3,
                                    color:
                                        isCE
                                            ? AppColorV2.primaryTextColor
                                                .withAlpha(50)
                                            : AppColorV2.primaryTextColor,
                                  ),
                                  DefaultText(
                                    text:
                                        "Get ${voucher["voucher_amt"]} tokens off your parking",
                                    color:
                                        isCE
                                            ? AppColorV2.lpBlueBrand.withAlpha(
                                              150,
                                            )
                                            : AppColorV2.lpBlueBrand,
                                  ),
                                  SizedBox(height: 2),
                                  Expanded(
                                    child: DefaultText(
                                      text: "Expiry date: $voucherDt",
                                      color:
                                          isCE
                                              ? AppColorV2.primaryTextColor
                                                  .withAlpha(50)
                                              : AppColorV2.bodyTextColor,
                                      maxFontSize: 14,
                                      maxLines: 1,
                                      minFontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SizedBox(
                        width: 50,
                        child: DefaultText(
                          textAlign: TextAlign.center,
                          minFontSize: 12,
                          maxFontSize: 14,
                          color: AppColorV2.background,
                          style: AppTextStyle.h3,
                          text: "-${voucher["voucher_amt"]}",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isFromBooking)
                InkWell(
                  onTap: () {
                    if (selectedVoucherId == voucher["promo_voucher_id"]) {
                      selectedVoucherId = null;
                    } else {
                      selectedVoucherId = voucher["promo_voucher_id"];
                    }

                    setState(() {});
                    widget.callBack!(selectedVoucherId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorV2.lpBlueBrand,
                            width: 2,
                          ),
                          color:
                              isSelected
                                  ? AppColorV2.lpBlueBrand
                                  : Colors.transparent,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 15,
                                  color: Colors.white,
                                )
                                : const SizedBox(width: 15, height: 15),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = [
      Tab(text: _isFromBooking ? "Available Vouchers" : "Available"),
      if (!_isFromBooking) const Tab(text: "Claimed"),
      if (!_isFromBooking) const Tab(text: "Expired"),
    ];

    final List<Widget> tabViews = [
      _voucherListView(availableList, _isFromBooking),
      if (!_isFromBooking) _voucherListView(claimedList, false, isCE: true),
      if (!_isFromBooking) _voucherListView(expiredList, false, isCE: true),
    ];

    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppColorV2.background,
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  physics: BouncingScrollPhysics(),
                  controller: _tabController,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
                  labelPadding: EdgeInsets.zero,
                  labelColor: AppColorV2.lpBlueBrand,
                  unselectedLabelColor: AppColorV2.inactiveState,
                  indicatorColor:
                      _isFromBooking ? Colors.transparent : Colors.blue,
                  indicatorWeight: 3,
                  labelStyle: AppTextStyle.h3,
                  unselectedLabelStyle: AppTextStyle.h3_semibold,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: tabs.map((tab) => Center(child: tab)).toList(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      isLoading
                          ? LoadingCard()
                          : vouchersList.isEmpty
                          ? _noVoucherWidget()
                          : TabBarView(
                            physics: BouncingScrollPhysics(),
                            controller: _tabController,
                            children: tabViews,
                          ),
                ),
              ],
            ),
          ),
        ),
        // if (_isFromBooking)
        // SafeArea(
        //   child: Container(
        //     decoration: BoxDecoration(color: AppColorV2.background),
        //     padding: const EdgeInsets.all(16.0),
        //     child: CustomButton(
        //       isInactive: selectedVoucherId == null,
        //       onPressed: () {
        //         if (selectedVoucherId == null) return;

        //         final selectedVoucher = vouchersList.firstWhere(
        //           (voucher) =>
        //               voucher["promo_voucher_id"] == selectedVoucherId,
        //           orElse: () => {},
        //         );

        //         Get.back(result: selectedVoucher);
        //       },
        //       text: "Apply voucher",
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
