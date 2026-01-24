// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/luvpay/dashboard_tab_icons.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/custom_scrollbar.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../custom_widgets/luvpay/luv_neumorphic.dart';
import '../../custom_widgets/luvpay/luvpay_loading.dart';
import '../../custom_widgets/no_internet.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';

class WalletNotifications extends StatefulWidget {
  final bool? fromTab;
  const WalletNotifications({super.key, required this.fromTab});

  @override
  State<WalletNotifications> createState() => _WalletNotificationsState();
}

class _WalletNotificationsState extends State<WalletNotifications> {
  List<Map<String, dynamic>> notifications = [];
  bool allMarked = false;
  bool isLoading = true;
  bool isNetConn = true;
  bool isSelectionMode = false;
  List<int> selectedIndex = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    getNotification(showLoading: true);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      getNotification(showLoading: false);
    });
  }

  Future<void> getNotification({required bool showLoading}) async {
    try {
      if (showLoading && mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final item = await Authentication().getUserData();
      String userId = jsonDecode(item!)['user_id'].toString();

      String subApi = "${ApiKeys.notificationApi}$userId";
      final response = await HttpRequestApi(api: subApi).get();

      if (!mounted) return;

      if (response == "No Internet") {
        setState(() {
          isLoading = false;
          isNetConn = false;
        });
        return;
      }

      if (response == null) {
        setState(() {
          isLoading = false;
          isNetConn = true;
        });
        return;
      }

      if (response["items"] != null && response["items"].isNotEmpty) {
        setState(() {
          notifications =
              response["items"].map<Map<String, dynamic>>((notification) {
                return {
                  "notification_id": notification["sms_id"],
                  "notification": notification["sms_msg"],
                  "created_on": notification["created_on"],
                };
              }).toList();
          isLoading = false;
          isNetConn = true;
        });
      } else {
        setState(() {
          notifications = [];
          isLoading = false;
          isNetConn = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteNotification(String smsId) async {
    setState(() => isLoading = true);
    try {
      await deleteSingleNotification(smsId);
      await getNotification(showLoading: false);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteSelectedNotifications() async {
    if (selectedIndex.isEmpty) return;

    CustomDialogStack.showConfirmation(
      context,
      "Confirm Deletion",
      "Delete selected notification${selectedIndex.length > 1 ? "s" : ""}?",
      leftText: "No",
      rightText: "Yes",
      () => Get.back(),
      () async {
        Get.back();
        if (!mounted) return;

        setState(() => isLoading = true);

        try {
          final deleteFutures =
              selectedIndex
                  .map((id) => deleteSingleNotification(id.toString()))
                  .toList();

          await Future.wait(deleteFutures);

          if (!mounted) return;

          setState(() {
            notifications.removeWhere(
              (notification) => selectedIndex.contains(
                int.parse(notification['notification_id'].toString()),
              ),
            );
            selectedIndex.clear();
            isSelectionMode = false;
            allMarked = false;
          });

          CustomDialogStack.showSuccess(
            context,
            "Success",
            "Notifications deleted successfully",
            () {
              Get.back();
              getNotification(showLoading: false);
            },
          );
        } catch (_) {
          if (!mounted) return;
          CustomDialogStack.showError(
            context,
            "Error",
            "Failed to delete some notifications",
            () => Get.back(),
          );
        } finally {
          if (!mounted) return;
          setState(() => isLoading = false);
        }
      },
    );
  }

  Future<void> deleteSingleNotification(String smsId) async {
    final item = await Authentication().getUserData();
    String userId = jsonDecode(item!)['user_id'].toString();
    String subApi = "${ApiKeys.notificationApi}$userId";
    var params = {"sms_id": smsId};

    final response =
        await HttpRequestApi(api: subApi, parameters: params).deleteData();

    if (response == "No Internet") {
      throw Exception("No internet connection");
    } else if (response == null || response["success"] != "Y") {
      throw Exception("Failed to delete notification");
    }
  }

  void enterSelectionMode(int index) {
    int id = int.parse(notifications[index]["notification_id"].toString());
    setState(() {
      selectedIndex.add(id);
      isSelectionMode = true;
      allMarked = false;
    });
  }

  void toggleMark(int index) {
    int id = int.parse(notifications[index]["notification_id"].toString());
    setState(() {
      if (!selectedIndex.contains(id)) {
        selectedIndex.add(id);
      } else {
        selectedIndex.remove(id);
      }
      isSelectionMode = true;
      allMarked = selectedIndex.length == notifications.length;
    });
  }

  void toggleMarkAll() {
    setState(() {
      if (allMarked) {
        selectedIndex.clear();
        allMarked = false;
        isSelectionMode = true;
      } else {
        selectedIndex =
            notifications
                .map((e) => int.parse(e["notification_id"].toString()))
                .toList();
        allMarked = true;
        isSelectionMode = true;
      }
    });
  }

  void cancelSelectionMode() {
    setState(() {
      selectedIndex.clear();
      isSelectionMode = false;
      allMarked = false;
    });
  }

  String _formatTime(DateTime date) {
    int hour = date.hour % 12;
    hour = hour == 0 ? 12 : hour;
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute$period";
  }

  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    }

    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final bool hideBackBecauseFromTab = widget.fromTab == true;

    final body =
        !isNetConn
            ? NoInternetConnected(
              onTap: () => getNotification(showLoading: true),
            )
            : notifications.isEmpty
            ? Center(child: noDataFound())
            : CustomScrollbarSingleChild(child: allNotifications());

    return CustomScaffoldV2(
      backgroundColor: AppColorV2.background,
      drawer: Container(),
      appBarLeadingWidth: isSelectionMode ? 50 : null,
      leading:
          isSelectionMode
              ? IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.close,
                  color: AppColorV2.background,
                  size: 30,
                  semanticLabel: 'Cancel selection',
                ),
                onPressed: cancelSelectionMode,
              )
              : (hideBackBecauseFromTab
                  ? const SizedBox.shrink()
                  : IconButton(
                    onPressed: () => Get.back(),
                    icon: Row(
                      children: [
                        Icon(CupertinoIcons.back, color: AppColorV2.background),
                        DefaultText(
                          color: AppColorV2.background,
                          text: "Back",
                          style: AppTextStyle.h3_semibold,
                          height: 20 / 16,
                        ),
                      ],
                    ),
                  )),
      enableToolBar: true,
      appBarTitle:
          isSelectionMode
              ? "${selectedIndex.length} selected"
              : "Notifications",
      appBarAction:
          isSelectionMode
              ? [
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: NeoNavIcon.icon(
                    flatten: true,
                    padding: const EdgeInsets.all(8.0),
                    iconSize: 20,
                    iconData: Icons.delete,
                    iconColor: AppColorV2.incorrectState,
                    onTap: deleteSelectedNotifications,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    allMarked ? Icons.check_box : Icons.check_box_outline_blank,
                    color: AppColorV2.background,
                    size: 30,
                    semanticLabel: allMarked ? 'Unmark all' : 'Mark all',
                  ),
                  onPressed: toggleMarkAll,
                ),
              ]
              : [],
      padding: const EdgeInsets.fromLTRB(19, 20, 19, 0),
      scaffoldBody: PremiumLoaderOverlay(
        loading: isLoading,
        accentColor: AppColorV2.lpBlueBrand,
        glowColor: AppColorV2.lpTealBrand,
        child: body,
      ),
    );
  }

  Column noDataFound() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset("assets/images/wallet_message-question.svg"),
        const SizedBox(height: 8),
        DefaultText(
          text: "No notifications yet",
          style: AppTextStyle.h3_semibold,
          color: AppColorV2.bodyTextColor,
        ),
      ],
    );
  }

  Widget allNotifications() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        String img = "";
        String notificationMessage = notifications[index]["notification"];
        DateTime createdOn = DateTime.parse(
          notifications[index]["created_on"],
        ).toUtc().add(const Duration(hours: 8));

        if (notificationMessage.toLowerCase().contains("share")) {
          img = "wallet_sharetoken";
        } else if (notificationMessage.toLowerCase().contains("received") ||
            notificationMessage.toLowerCase().contains("credit")) {
          img = "wallet_receivetoken";
        } else {
          img = "wallet_payparking";
        }

        return InkWell(
          onLongPress: () {
            if (!isSelectionMode) {
              enterSelectionMode(index);
            }
          },
          onTap: () {
            if (isSelectionMode) {
              toggleMark(index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 10),
            child: LuvNeuPress.rect(
              radius: BorderRadius.circular(16),
              onTap: null,
              borderWidth: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset("assets/images/$img.svg"),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNotificationText(notificationMessage),
                                const SizedBox(height: 8),
                                DefaultText(
                                  text:
                                      _formatDate(createdOn) +
                                      " " +
                                      _formatTime(createdOn),
                                ),
                              ],
                            ),
                          ),
                          if (isSelectionMode)
                            Checkbox.adaptive(
                              value: selectedIndex.contains(
                                int.parse(
                                  notifications[index]["notification_id"]
                                      .toString(),
                                ),
                              ),
                              onChanged: (_) => toggleMark(index),
                              activeColor: AppColorV2.lpBlueBrand,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationText(String text) {
    final currencyRegExp = RegExp(r'(₱)?\d{1,3}(,\d{3})*\.\d{2}');
    final List<TextSpan> textSpans = [];
    int lastEnd = 0;

    for (final match in currencyRegExp.allMatches(text)) {
      if (match.start > lastEnd) {
        textSpans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: AppTextStyle.body1.copyWith(
              color: AppColorV2.primaryTextColor,
            ),
          ),
        );
      }

      textSpans.add(
        TextSpan(
          text: match.group(0),
          style: AppTextStyle.body1.copyWith(color: AppColorV2.lpBlueBrand),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      textSpans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: AppTextStyle.body1.copyWith(
            color: AppColorV2.primaryTextColor,
          ),
        ),
      );
    }

    if (textSpans.isNotEmpty) {
      return RichText(
        maxLines: isSelectionMode ? 6 : 5,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: textSpans),
      );
    }

    return DefaultText(
      minFontSize: 8,
      maxLines: isSelectionMode ? 6 : 5,
      text: text,
    );
  }
}
