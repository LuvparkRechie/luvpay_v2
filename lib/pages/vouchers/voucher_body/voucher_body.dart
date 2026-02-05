// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/luvpay/luvpay_loading.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:ticketcher/ticketcher.dart';

import '../../../auth/authentication.dart';
import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/custom_text_v2.dart';
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
  int? selectedVoucherId;

  bool _isDialogVisible = false;

  late TabController _tabController;
  int _savedTabIndex = 0;

  bool get _isFromBooking => widget.queryParam?["isFromBooking"] == "true";
  int get _tabLength => _isFromBooking ? 1 : 3;

  Color _border(ColorScheme cs, bool isDark, [double? o]) =>
      cs.outlineVariant.withOpacity(o ?? (isDark ? 0.05 : 0.01));

  List<BoxShadow> _softShadow(ColorScheme cs, bool isDark) {
    return [
      BoxShadow(
        color: (isDark ? Colors.black : cs.shadow).withOpacity(
          isDark ? 0.22 : 0.08,
        ),
        blurRadius: isDark ? 18 : 12,
        offset: const Offset(0, 10),
      ),
    ];
  }

  BoxDecoration _neo(
    BuildContext context, {
    double radius = 18,
    Color? color,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: color ?? cs.surface,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: shadows ?? _softShadow(cs, isDark),
    );
  }

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
      final userId = jsonDecode(item!)['user_id'].toString();

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
      }

      final fixedIndex = _savedTabIndex.clamp(0, _tabLength - 1);
      if (_tabController.index != fixedIndex) _tabController.index = fixedIndex;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isNetConn = true;
      });
    }
  }

  Widget _noVoucherWidget() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/novouchersyet.svg"),
          const SizedBox(height: 16),
          DefaultText(
            text: "No Vouchers Yet",
            style: AppTextStyle.h3(context),
            color: cs.onSurface.withOpacity(0.55),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tabBar(List<Tab> tabs) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stroke = _border(cs, isDark);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _neo(
        context,
        radius: 18,
        border: Border.all(color: stroke, width: 1),
      ),
      child: TabBar(
        physics: const BouncingScrollPhysics(),
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurface.withOpacity(0.55),
        labelStyle: AppTextStyle.h3(context),
        unselectedLabelStyle: AppTextStyle.h3_semibold(context),
        indicator: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: stroke, width: 1),
          boxShadow: _softShadow(cs, isDark),
        ),
        tabs: tabs,
      ),
    );
  }

  Widget _voucherCard({
    required Map voucher,
    required bool isFromBooking,
    required bool isCE,
    required String voucherDt,
    required bool isSelectedNow,
    required VoidCallback? onSelect,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final String amt = (voucher["voucher_amt"] ?? "0").toString();
    final String merchant = (voucher["merchant_name"] ?? "N/A").toString();
    final String code = (voucher["voucher_code"] ?? "—").toString();

    final Color accent =
        isCE ? cs.onSurface.withOpacity(0.35) : cs.primary.withOpacity(0.95);

    final Color fadedText = cs.onSurface.withOpacity(isCE ? 0.40 : 0.90);
    final Color fadedSub = cs.onSurface.withOpacity(isCE ? 0.35 : 0.65);

    final stroke = _border(cs, isDark);
    final base = cs.surface;

    return GestureDetector(
      onTap: onSelect,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Ticketcher.horizontal(
            height: 108,
            decoration: TicketcherDecoration(
              backgroundColor: base,
              border: Border.all(color: stroke, width: 1),
              borderRadius: const TicketRadius(radius: 18),
              divider: TicketDivider.dashed(
                color: cs.onSurface.withOpacity(isDark ? 0.18 : 0.10),
                thickness: 1,
                dashWidth: 10,
                dashSpace: 7,
                padding: 10,
              ),
              shadow: BoxShadow(
                color: (isDark ? Colors.black : cs.shadow).withOpacity(
                  isDark ? 0.18 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 10),
              ),
            ),
            sections: [
              Section(
                widthFactor: 1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DefaultText(
                      text: "-$amt",
                      style: AppTextStyle.h2(context),
                      color: cs.primary.withOpacity(isCE ? 0.45 : 0.95),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Section(
                widthFactor: 3,
                child: Tooltip(
                  onTriggered: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  message: code,
                  waitDuration: const Duration(milliseconds: 500),
                  showDuration: const Duration(seconds: 2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 44, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DefaultText(
                          text: merchant,
                          style: AppTextStyle.h3(context),
                          color: fadedText,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        DefaultText(
                          text: "Get $amt tokens off your parking",
                          color: accent,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        DefaultText(
                          text: "Expiry date: $voucherDt",
                          color: fadedSub,
                          maxFontSize: 10,
                          minFontSize: 8,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isFromBooking)
            Positioned(
              right: 12,
              child: GestureDetector(
                onTap: onSelect,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelectedNow ? cs.primary : base,
                    boxShadow: _softShadow(cs, isDark),
                    border: Border.all(color: stroke, width: 1),
                  ),
                  child:
                      isSelectedNow
                          ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                          : const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _voucherListView(List list, bool isFromBooking, {bool isCE = false}) {
    if (list.isEmpty) return _noVoucherWidget();

    return RefreshIndicator(
      onRefresh: _getVouchers,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final voucher = list[index];
          final bool isSelectedNow =
              voucher["promo_voucher_id"] == selectedVoucherId;

          DateTime? expDt =
              voucher["expiry_date"] != null &&
                      voucher["expiry_date"].toString().isNotEmpty
                  ? DateTime.tryParse(voucher["expiry_date"].toString())
                  : null;

          final voucherDt =
              expDt != null ? DateFormat('MMM d, yyyy').format(expDt) : "N/A";

          VoidCallback? onSelect =
              !isFromBooking
                  ? null
                  : () {
                    if (selectedVoucherId == voucher["promo_voucher_id"]) {
                      selectedVoucherId = null;
                    } else {
                      selectedVoucherId = voucher["promo_voucher_id"];
                    }
                    setState(() {});
                    widget.callBack?.call(selectedVoucherId);
                  };

          return Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: _voucherCard(
              voucher: voucher,
              isFromBooking: isFromBooking,
              isCE: isCE,
              voucherDt: voucherDt,
              isSelectedNow: isSelectedNow,
              onSelect: onSelect,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _tabBar(tabs),
          const SizedBox(height: 14),
          Expanded(
            child:
                isLoading
                    ? const LoadingCard(text: "Loading…")
                    : vouchersList.isEmpty
                    ? _noVoucherWidget()
                    : TabBarView(
                      physics: const BouncingScrollPhysics(),
                      controller: _tabController,
                      children: tabViews,
                    ),
          ),
        ],
      ),
    );
  }
}
