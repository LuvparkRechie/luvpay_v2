// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../subwallet/utils/transaction_modal.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/longprint.dart';
import 'package:luvpay/shared/widgets/luvpay_loading.dart';
import 'package:luvpay/shared/widgets/no_data_found.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/colors.dart';

import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';

class SubWalletTransactions extends StatefulWidget {
  final String subWalletId;
  final String walletName;

  const SubWalletTransactions({
    super.key,
    required this.subWalletId,
    required this.walletName,
  });

  @override
  State<SubWalletTransactions> createState() => _SubWalletTransactionsState();
}

class _SubWalletTransactionsState extends State<SubWalletTransactions> {
  bool isLoading = true;
  List<dynamic> transactions = [];
  Map<String, dynamic> mapToTransferData(Map<String, dynamic> tx) {
    return {
      "transfer_desc": tx["tran_desc"],
      "transfer_date": tx["tran_date"],
      "amount": tx["amount"],
      "amount_bal_bfore": tx["bal_before"],
      "amount_bal_after": tx["bal_after"],
      "ref_no": tx["ref_no"],
    };
  }

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() => isLoading = true);

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(toDate);

    final subApi =
        "${ApiKeys.subTransactions}?user_sub_wallet_id=${widget.subWalletId}"
        "&tran_date_from=$fromStr"
        "&tran_date_to=$toStr";

    final response = await HttpRequestApi(api: subApi).get();
    if (!mounted) return;

    if (response == "No Internet" || response == null) {
      setState(() {
        isLoading = false;
        transactions = [];
      });
      return;
    }

    final items = (response["items"] ?? []) as List<dynamic>;

    items.sort(
      (a, b) => DateTime.parse(b['tran_date'])
          .compareTo(DateTime.parse(a['tran_date'])),
    );

    setState(() {
      transactions = items;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScaffoldV2(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      appBarTitle: "Transaction Logs",
      backgroundColor: cs.surface,
      scaffoldBody: isLoading
          ? LoadingCard()
          : transactions.isEmpty
              ? const Center(child: NoDataFound())
              : RefreshIndicator(
                  onRefresh: fetchTransactions,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, i) {
                      final tx = transactions[i];

                      final amount =
                          double.tryParse(tx["amount"].toString()) ?? 0;

                      final isDebit = amount < 0;

                      final color = isDebit
                          ? AppColorV2.incorrectState
                          : AppColorV2.success;

                      return Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: LuvNeuPress.rectangle(
                            background: cs.surfaceContainerHighest,
                            depth:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.55
                                    : 1.4,
                            pressedDepth:
                                Theme.of(context).brightness == Brightness.dark
                                    ? -0.25
                                    : -0.75,
                            overlayOpacity:
                                Theme.of(context).brightness == Brightness.dark
                                    ? 0.0
                                    : 0.02,
                            borderColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.transparent
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withOpacity(0.02),
                            radius: BorderRadius.circular(16),
                            pressedScale: 0.985,
                            pressedTranslateY: 1.0,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => TransferDetailsModal(
                                  data: mapToTransferData(tx),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: color
                                          .withOpacity(isDark ? 0.20 : 0.12),
                                    ),
                                    child: Icon(
                                      isDebit
                                          ? Iconsax.arrow_up_1
                                          : Iconsax.arrow_down_1,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LuvpayText(
                                          text: tx["tran_desc"] ?? "",
                                          maxLines: 1,
                                          style: AppTextStyle.body1(context)
                                              .copyWith(
                                                  fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        LuvpayText(
                                          text: Functions.formatSmartPHDateTime(
                                              tx["tran_date"]),
                                          fontSize: 11,
                                          color: cs.onSurface.withOpacity(
                                              isDark ? 0.60 : 0.55),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      LuvpayText(
                                          text:
                                              "${isDebit ? '-' : '+'}₱ ${amount.abs().toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurface,
                                          )),
                                      const SizedBox(height: 6),
                                      Icon(
                                        Iconsax.arrow_right_3,
                                        size: 16,
                                        color: cs.onSurface
                                            .withOpacity(isDark ? 0.40 : 0.45),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                      );
                    },
                  ),
                ),
    );
  }
}
