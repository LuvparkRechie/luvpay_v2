// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, deprecated_member_use

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/no_data_found.dart';
import 'package:luvpay/shared/widgets/no_internet.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../auth/authentication.dart';
import '../../shared/widgets/luvpay_loading.dart';
import '../../core/utils/functions/functions.dart';
import 'transaction_details.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});
  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  final filterFromDate = TextEditingController();
  final filterToDate = TextEditingController();

  bool isLoadingPage = true;
  bool isNetConn = true;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 15));
  DateTime toDate = DateTime.now();

  String randomNumber = Random().nextInt(100000).toString();

  List<dynamic> filterLogs = [];
  Map<String, List<dynamic>> groupedLogs = {};

  bool isDownloading = false;

  TextEditingController password = TextEditingController();
  bool isShowPass = false;

  @override
  void initState() {
    super.initState();
    filterToDate.text = DateFormat('yyyy-MM-dd').format(toDate);
    filterFromDate.text = DateFormat('yyyy-MM-dd').format(fromDate);
    fetchLogs(isInitial: true);
  }

  @override
  void dispose() {
    filterFromDate.dispose();
    filterToDate.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _showLoaderNextFrame() async {
    if (!mounted) return;
    setState(() => isLoadingPage = true);
    await Future.delayed(Duration.zero);
  }

  Future<void> _showDownloadingNextFrame() async {
    if (!mounted) return;
    setState(() => isDownloading = true);
    await Future.delayed(Duration.zero);
  }

  Future<void> fetchLogs({bool isInitial = false}) async {
    await _showLoaderNextFrame();

    final userId = await Authentication().getUserId();
    final subApi =
        "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=${filterFromDate.text}&tran_date_to=${filterToDate.text}";
    final response = await HttpRequestApi(api: subApi).get();

    if (!mounted) return;

    if (response == "No Internet") {
      setState(() {
        isLoadingPage = false;
        isNetConn = false;
        filterLogs = [];
        groupedLogs = {};
      });
      CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
      return;
    }

    if (response == null) {
      setState(() {
        isLoadingPage = false;
        isNetConn = true;
        filterLogs = [];
        groupedLogs = {};
      });
      CustomDialogStack.showError(
        context,
        "luvpay",
        "Error while connecting to server, Please contact support.",
        () => Get.back(),
      );
      return;
    }

    final items = (response["items"] ?? []) as List<dynamic>;
    items.sort(
      (a, b) => DateTime.parse(
        b['tran_date'],
      ).compareTo(DateTime.parse(a['tran_date'])),
    );

    final nextLogs = isInitial ? items.take(15).toList() : items;

    final nextGrouped = <String, List<dynamic>>{};
    for (var tx in nextLogs) {
      final dt = DateTime.parse(tx["tran_date"]);
      final key = _getGroupKey(dt);
      nextGrouped.putIfAbsent(key, () => []).add(tx);
    }

    setState(() {
      filterLogs = nextLogs;
      groupedLogs = nextGrouped;
      isNetConn = true;
      isLoadingPage = false;
    });
  }

  DateTime _startOfWeekSunday(DateTime date) {
    final daysToSubtract = date.weekday % 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  String _getGroupKey(DateTime dt) {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final yesterday = dayStart.subtract(const Duration(days: 1));
    final thisWeekStart = _startOfWeekSunday(dayStart);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(seconds: 1));
    final previousMonth = DateTime(today.year, today.month - 1);

    if (_isSameDay(dt, dayStart)) return 'Today';
    if (_isSameDay(dt, yesterday)) return 'Yesterday';

    if (dt.isAfter(thisWeekStart) || _isSameDay(dt, thisWeekStart)) {
      return 'This Week';
    }

    if (dt.isAfter(lastWeekStart) && dt.isBefore(lastWeekEnd)) {
      return 'Last Week';
    }

    if (dt.month == today.month && dt.year == today.year) {
      return DateFormat('MMMM').format(dt);
    }

    if (dt.month == previousMonth.month && dt.year == previousMonth.year) {
      return 'Last Month';
    }

    return DateFormat('MMM dd, yyyy').format(dt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _safeName(String str) =>
      str.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      return true;
    }
    return true;
  }

  Future<String?> _getDownloadDirectoryPath() async {
    if (Platform.isAndroid) {
      try {
        final dir = await getExternalStorageDirectory();
        if (dir != null && !await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir?.path;
      } catch (e) {
        debugPrint("Error accessing external storage: $e");
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    return null;
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
      saveText: "Download",
      helpText: "Select Date Range",
      builder: (context, child) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return Theme(
          data: theme.copyWith(
            colorScheme: cs.copyWith(primary: AppColorV2.lpBlueBrand),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    await _showDownloadingNextFrame();

    final exportFrom = picked.start;
    final exportTo = picked.end;

    final fromStr = DateFormat('yyyy-MM-dd').format(exportFrom);
    final toStr = DateFormat('yyyy-MM-dd').format(exportTo);

    final userId = await Authentication().getUserId();
    final subApi =
        "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=$fromStr&tran_date_to=$toStr";
    final response = await HttpRequestApi(api: subApi).get();

    if (!mounted) return;

    if (response == "No Internet" || response == null) {
      setState(() => isDownloading = false);
      CustomDialogStack.showConnectionLost(context, () => Get.back());
      return;
    }

    final items = (response["items"] ?? []) as List<dynamic>;
    if (items.isEmpty) {
      setState(() => isDownloading = false);
      CustomDialogStack.showInfo(
        Get.context!,
        "No Data",
        "No transactions found in the selected range.",
        () => Get.back(),
      );
      return;
    }

    items.sort(
      (a, b) => DateTime.parse(
        b['tran_date'],
      ).compareTo(DateTime.parse(a['tran_date'])),
    );

    final rows = <List<String>>[
      [
        "Date",
        "Reference #",
        "Category",
        "Description",
        "Balance Before",
        "Debit",
        "Credit",
        "Balance After",
      ],
      ...items.map((tx) {
        final amount = double.tryParse(tx["amount"].toString()) ?? 0.0;
        final isCredit = amount > 0;
        return [
          DateFormat(
            'EEE, MMM d, yyyy h:mm a',
          ).format(DateTime.parse(tx["tran_date"].toString())),
          (tx["ref_no"] ?? '').toString(),
          (tx["category"] ?? '').toString(),
          (tx["tran_desc"] ?? '').toString(),
          (tx["bal_before"] ?? '').toString(),
          isCredit ? '' : amount.toStringAsFixed(2),
          isCredit ? amount.toStringAsFixed(2) : '',
          (tx["bal_after"] ?? '').toString(),
        ].map((e) => e.toString()).toList();
      }),
    ];

    double totalCredit = 0;
    double totalDebit = 0;

    for (var tx in items) {
      final amount = double.tryParse(tx["amount"].toString()) ?? 0.0;
      if (amount > 0) {
        totalCredit += amount;
      } else {
        totalDebit += amount.abs();
      }
    }

    final totalSpent = totalDebit;

    rows.add([
      '',
      '',
      '',
      'TOTAL',
      '',
      totalDebit.toStringAsFixed(2),
      totalCredit.toStringAsFixed(2),
      '',
    ]);
    rows.add([
      '',
      '',
      '',
      'TOTAL SPENT',
      '',
      totalSpent.toStringAsFixed(2),
      '',
      '',
    ]);

    final baseName =
        "transaction_history_${_safeName(fromStr)}_to_${_safeName(toStr)}_$randomNumber";

    await downloadTransactionsAsPdf(rows, baseName);

    if (!mounted) return;
    setState(() => isDownloading = false);
  }

  Future<void> downloadTransactionsAsPdf(
    List<List<String>> rows,
    String baseFileName,
  ) async {
    final hasPermission = await _checkAndRequestStoragePermission();
    if (!hasPermission) {
      if (!mounted) return;
      CustomDialogStack.showError(
        context,
        "Permission Denied",
        "Storage permission is required to save the PDF file.",
        () => Get.back(),
      );
      return;
    }

    final directoryPath = await _getDownloadDirectoryPath();
    if (directoryPath == null) {
      if (!mounted) return;
      CustomDialogStack.showError(
        context,
        "Error",
        "Could not access download directory",
        () => Get.back(),
      );
      return;
    }

    final PdfDocument document = PdfDocument();

    if (password.text.isNotEmpty) {
      document.security.userPassword = password.text;
      document.security.ownerPassword = password.text;
      document.security.permissions.addAll([
        PdfPermissionsFlags.print,
        PdfPermissionsFlags.copyContent,
        PdfPermissionsFlags.accessibilityCopyContent,
        PdfPermissionsFlags.fillFields,
      ]);
    }

    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      16,
      style: PdfFontStyle.bold,
    );
    final PdfFont subtitleFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final PdfFont cellFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    graphics.drawString(
      'Transaction History',
      titleFont,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    graphics.drawString(
      'Exported on: ${DateTime.now().toLocal().toString().split('.')[0]}',
      subtitleFont,
      bounds: Rect.fromLTWH(0, 35, page.getClientSize().width, 15),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: rows.first.length);

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    for (int i = 0; i < rows.first.length; i++) {
      headerRow.cells[i].value = rows.first[i];
      headerRow.cells[i].style.font = headerFont;
      headerRow.cells[i].style.backgroundBrush = PdfSolidBrush(
        PdfColor(211, 211, 211),
      );
    }

    for (int i = 1; i < rows.length; i++) {
      final PdfGridRow row = grid.rows.add();
      for (int j = 0; j < rows[i].length; j++) {
        row.cells[j].value = rows[i][j];
        row.cells[j].style.font = cellFont;
      }
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0,
        60,
        page.getClientSize().width,
        page.getClientSize().height - 60,
      ),
    );

    try {
      final filePath = '$directoryPath/$baseFileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await document.save());

      document.dispose();

      if (!mounted) return;

      CustomDialogStack.showLoading(Get.context!);
      await Future.delayed(const Duration(seconds: 3));
      Get.back();
      CustomDialogStack.showConfirmation(
        context,
        "Download Complete",
        "PDF saved to:\n${_simplifyPathForDisplay(filePath)}\n\nDo you want to open the file now?",
        leftText: "Back",
        rightText: "Open File",
        rightTextColor: Theme.of(context).colorScheme.onPrimary,
        rightBtnColor: AppColorV2.lpBlueBrand,
        () => Get.back(),
        () {
          Get.back();
          OpenFile.open(filePath);
        },
      );
    } catch (e) {
      document.dispose();
      if (!mounted) return;
      CustomDialogStack.showError(
        context,
        "Error",
        "Failed to save PDF: ${e.toString()}",
        () => Get.back(),
      );
    }
  }

  String _simplifyPathForDisplay(String path) {
    if (Platform.isAndroid) {
      return path
          .replaceFirst('/storage/emulated/0/', 'Internal storage/')
          .replaceFirst('/Download/', '/Downloads/');
    }
    return path;
  }

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final body =
        !isNetConn
            ? NoInternetConnected(onTap: () => fetchLogs(isInitial: true))
            : isLoadingPage || isDownloading
            ? LoadingCard()
            : groupedLogs.isEmpty
            ? Center(child: NoDataFound())
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DateTime>(
                  future: Functions.getTimeNow(),
                  builder:
                      (context, s) => LuvpayText(
                        color: AppColorV2.lpBlueBrand,
                        style: AppTextStyle.h3(ctx),
                        text:
                            "As of ${s.hasData ? DateFormat('MMM d, yyyy').format(s.data!) : '...'}",
                      ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                    itemCount: groupedLogs.length + 1,
                    itemBuilder: (c, idx) {
                      if (idx == groupedLogs.length) {
                        return Column(
                          children: [
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: CustomButton(
                                text: "Download Transactions",
                                onPressed: () async {
                                  final result = await showDialog(
                                    context: ctx,
                                    builder: (BuildContext context) {
                                      bool dialogIsShowPass = isShowPass;

                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return PopScope(
                                            canPop: false,
                                            child: Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      19,
                                                      30,
                                                      19,
                                                      19,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: cs.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(20),

                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(
                                                            isDark
                                                                ? 0.35
                                                                : 0.08,
                                                          ),
                                                      blurRadius: 18,
                                                      offset: const Offset(
                                                        0,
                                                        8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    LuvpayText(
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: cs.onSurface,
                                                      ),
                                                      textAlign:
                                                          TextAlign.start,
                                                      text:
                                                          "Create File Password",
                                                    ),
                                                    const SizedBox(height: 10),
                                                    CustomTextField(
                                                      hintText:
                                                          "Enter PDF password",
                                                      controller: password,
                                                      isObscure:
                                                          !dialogIsShowPass,
                                                      suffixIcon:
                                                          !dialogIsShowPass
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons
                                                                  .visibility,
                                                      onIconTap: () {
                                                        setDialogState(() {
                                                          dialogIsShowPass =
                                                              !dialogIsShowPass;
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(height: 10),
                                                    LuvpayText(
                                                      text:
                                                          "Note: Password must be 8-15 characters long",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            cs.onSurfaceVariant,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: CustomButton(
                                                            textColor:
                                                                AppColorV2
                                                                    .lpBlueBrand,
                                                            bordercolor:
                                                                AppColorV2
                                                                    .lpBlueBrand,
                                                            btnColor:
                                                                cs.surface,
                                                            text: "Cancel",
                                                            onPressed:
                                                                () =>
                                                                    Get.back(),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: CustomButton(
                                                            text: "Confirm",
                                                            onPressed: () {
                                                              final enteredPassword =
                                                                  password.text;

                                                              if (enteredPassword
                                                                  .isEmpty) {
                                                                CustomDialogStack.showSnackBar(
                                                                  ctx,
                                                                  "Please enter a password",
                                                                  AppColorV2
                                                                      .error,
                                                                  () {},
                                                                );
                                                                return;
                                                              }

                                                              if (enteredPassword
                                                                      .length <
                                                                  8) {
                                                                CustomDialogStack.showSnackBar(
                                                                  ctx,
                                                                  "Password must be at least 8 characters long",
                                                                  AppColorV2
                                                                      .error,
                                                                  () {},
                                                                );
                                                                return;
                                                              }

                                                              if (enteredPassword
                                                                      .length >
                                                                  15) {
                                                                CustomDialogStack.showSnackBar(
                                                                  ctx,
                                                                  "Password cannot exceed 15 characters",
                                                                  AppColorV2
                                                                      .error,
                                                                  () {},
                                                                );
                                                                return;
                                                              }

                                                              setState(
                                                                () =>
                                                                    isShowPass =
                                                                        dialogIsShowPass,
                                                              );
                                                              Navigator.pop(
                                                                ctx,
                                                                true,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );

                                  setState(() => isShowPass = false);

                                  if (result == true) {
                                    await selectDateRange(ctx);
                                    password.clear();
                                  } else {
                                    password.clear();
                                  }
                                },
                              ),
                            ),
                            spacing(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: LuvpayText(
                                maxLines: 3,
                                textAlign: TextAlign.center,
                                text: 'Select transactions by date range',
                                style: AppTextStyle.paragraph2(
                                  ctx,
                                ).copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }

                      final key = groupedLogs.keys.elementAt(idx);
                      final list = groupedLogs[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                            decoration: BoxDecoration(
                              color: AppColorV2.lpBlueBrand.withOpacity(
                                isDark ? 0.18 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(
                                  isDark ? 0.05 : 0.01,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: LuvpayText(
                              text: key,
                              color: AppColorV2.lpBlueBrand,
                              style: AppTextStyle.body1(ctx),
                            ),
                          ),
                          ...list.map((tx) {
                            final desc = tx['tran_desc'].toString();
                            final category = tx['category'].toString();

                            final amount =
                                double.tryParse(tx['amount'].toString()) ?? 0.0;
                            final isDebit = amount < 0;

                            final accent =
                                isDebit
                                    ? AppColorV2.incorrectState
                                    : AppColorV2.success;

                            String formatDate(String dateString) {
                              try {
                                final date =
                                    DateTime.parse(dateString).toLocal();
                                return DateFormat(
                                  'MMM dd, yyyy • HH:mm',
                                ).format(date);
                              } catch (_) {
                                return dateString;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: CustomRowTile(
                                trailingUseNeumorphic: false,
                                onTap: () {
                                  Get.to(
                                    TransactionDetails(
                                      index: 0,
                                      data: [tx],
                                      isHistory: true,
                                    ),
                                  );
                                },
                                background: cs.surface,
                                leadingBackground: cs.surface,
                                leadingSize: 46,
                                leadingRadius: const BorderRadius.all(
                                  Radius.circular(14),
                                ),
                                radius: const BorderRadius.all(
                                  Radius.circular(18),
                                ),
                                padding: const EdgeInsets.all(12),

                                leading: Icon(
                                  isDebit
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: accent,
                                  size: 20,
                                ),

                                title: LuvpayText(
                                  text: category,
                                  style: AppTextStyle.body1(ctx),
                                  color: cs.onSurface,
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LuvpayText(
                                    //   text: desc,
                                    //   maxLines: 1,
                                    //   maxFontSize: 12,
                                    //   style: AppTextStyle.paragraph2(ctx),
                                    //   color: cs.onSurfaceVariant.withOpacity(
                                    //     isDark ? 0.78 : 0.75,
                                    //   ),
                                    // ),
                                    // const SizedBox(height: 4),
                                    LuvpayText(
                                      text: formatDate(
                                        tx['tran_date'].toString(),
                                      ),
                                      style: AppTextStyle.body1(ctx),
                                      maxFontSize: 10,
                                      minFontSize: 8,
                                      color: cs.onSurfaceVariant.withOpacity(
                                        isDark ? 0.72 : 0.70,
                                      ),
                                    ),
                                  ],
                                ),

                                trailing: LuvpayText(
                                  text: toCurrencyString(tx['amount']),
                                  style: TextStyle(color: accent),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );

    return CustomScaffoldV2(
      backgroundColor: cs.surface,
      padding: EdgeInsets.zero,
      enableToolBar: true,
      appBarTitle: "Transaction History",
      scaffoldBody: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 19),
        child: body,
      ),
    );
  }
}
