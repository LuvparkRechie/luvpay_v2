import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzz;

import '../../auth/authentication.dart';
import '../database/sqlite/pa_message_model.dart';
import '../database/sqlite/pa_message_table.dart';
import '../network/http/api_keys.dart';
import '../network/http/http_request.dart';
import '../utils/functions/functions.dart';
import '../../shared/widgets/variables.dart';
import '../../features/routes/routes.dart';

class NotificationController {
  static ReceivedAction? initialAction;

  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
      null, //'resource://drawable/res_app_icon',//
      [
        NotificationChannel(
          channelKey: 'alerts',
          channelName: 'Alerts',
          channelDescription: 'Notification tests as alerts',
          playSound: true,
          onlyAlertOnce: true,
          groupAlertBehavior: GroupAlertBehavior.Children,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultColor: Colors.deepPurple,
          ledColor: Colors.deepPurple,
        ),
      ],
      debug: true,
    );

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: false,
    );
  }

  static ReceivePort? receivePort;
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort(
      'Notification action port in main isolate',
    )..listen((silentData) => onActionReceivedImplementationMethod(silentData));

    // This initialization only happens on the main isolate
    IsolateNameServer.registerPortWithName(
      receivePort!.sendPort,
      'notification_action_port',
    );
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      await executeLongTaskInBackground();
    } else {
      if (receivePort == null) {
        SendPort? sendPort = IsolateNameServer.lookupPortByName(
          'notification_action_port',
        );

        if (sendPort != null) {
          sendPort.send(receivedAction);
          return;
        }
      }

      return onActionReceivedImplementationMethod(receivedAction);
    }
  }

  static Future<void> executeLongTaskInBackground() async {
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    await http.get(url);
  }

  //Parking notification
  static Future<void> parkingNotif(
    int id,
    int geoShareId,
    String? title,
    String? body,
    String? payload,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alerts',
        title: title!,
        body: body!,
        wakeUpScreen: true,
        autoDismissible: true,
        notificationLayout: NotificationLayout.BigText,
        payload: {'notificationId': payload!, "geo_share_id": "$geoShareId"},
      ),
    );
  }
  //Share token notif

  static Future<void> shareTokenNotification(
    int id,
    int geoShareId,
    String? title,
    String? body,
    String? payload,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alerts',
        title: title!,
        body: body!,
        wakeUpScreen: true,
        autoDismissible: true,
        notificationLayout: NotificationLayout.BigText,
        payload: {'notificationId': payload!, "geo_share_id": "$geoShareId"},
      ),
    );
  }

  //to notify users about  reported damage
  static Future<void> createInformationMessage(
    int id,
    int geoShareId,
    String? title,
    String? body,
    String? payload,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alerts',
        title: title!,
        body: body!,
        wakeUpScreen: true,
        autoDismissible: false,
        notificationLayout: NotificationLayout.BigText,
        payload: {'notificationId': payload!},
      ),
      actionButtons: [
        NotificationActionButton(key: 'MESSAGE', label: 'View Message'),
      ],
    );
  }

  // MAKE A FOREGROUND NOTIFICATION
  static Future<void> createForegroundNotif(
    int id,
    int geoShareId,
    String? title,
    String? body,
    String? payload,
  ) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'alerts',
        title: title!,
        body: body!,
        wakeUpScreen: true,
        autoDismissible: false,
        notificationLayout: NotificationLayout.BigText,
        payload: {'notificationId': payload!, "geo_share_id": "$geoShareId"},
      ),
    );
  }

  static Future<void> scheduleNewNotification(
    int id,
    String title,
    String body,
    String? dateSched,
    String payLoad,
  ) async {
    try {
      tz.initializeTimeZones();
      // Check if timezone database is initialized, if not initialize it

      final tzz.TZDateTime scheduledTime = tzz.TZDateTime.from(
        DateTime.parse(dateSched!),
        tzz.getLocation('Asia/Manila'),
      ).subtract(const Duration(minutes: 10));

      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        return;
      }

      await myNotifyScheduleInHours(
        id: id,
        title: title,
        msg: body,
        hoursFromNow: scheduledTime,
        repeatNotif: false,
        payLoad: payLoad,
      );
    } catch (e) {}
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  static Future<void> cancelNotificationsById(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> onActionReceivedImplementationMethod(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.payload!["notificationId"] == "parking") {
      if (Get.currentRoute == Routes.bookingReceipt) {
        Get.back();
      } else {
        Get.toNamed(Routes.parking, arguments: "N");
      }
    }

    if ((Platform.isAndroid
            ? receivedAction.buttonKeyPressed.toString().toLowerCase().trim()
            : receivedAction.payload!["notificationId"]
                .toString()
                .toLowerCase()
                .trim()) ==
        "message") {
      Get.toNamed(Routes.message);
    }
  }

  static Future<void> myNotifyScheduleInHours({
    required tzz.TZDateTime hoursFromNow,
    required String title,
    required String msg,
    required String payLoad,
    required int id,
    bool repeatNotif = false,
  }) async {
    await AwesomeNotifications().createNotification(
      schedule: NotificationCalendar(
        weekday: null,
        hour: hoursFromNow.hour,
        minute: hoursFromNow.minute,
        second: 0,
        repeats: repeatNotif,
        allowWhileIdle: true,
      ),
      content: NotificationContent(
        id: id,
        channelKey: 'alerts',
        title: title,
        body: msg,
        payload: {'notificationId': payLoad},
      ),
    );
  }
}

Future<void> getLogSession(context) async {
  final userData = await Authentication().getUserData2();
  final getUserLogin = await Authentication().getUserLogin();

  if (userData == null ||
      getUserLogin == null ||
      getUserLogin["is_login"] == "N") {
    return;
  }

  String sessionId = userData["session_id"].toString();

  final response =
      await HttpRequestApi(
        api: "${ApiKeys.getSession}?session_id=$sessionId",
      ).get();

  if (response is Map) {
    if (response["items"].isNotEmpty &&
        response["items"][0]["dt_out"] != null) {
      Functions.logoutUser(
        userData == null ? "" : userData["session_id"].toString(),
        (isSuccess) async {
          if (isSuccess["is_true"]) {
            CustomDialogStack.showSnackBar(
              context,
              "Your account has been logged in on another device.",
              AppColorV2.lpBlueBrand,
              () {
                Get.back();
              },
            );
            final userLogin = await Authentication().getUserLogin();
            List userData = [userLogin];
            userData =
                userData.map((e) {
                  e["is_login"] = "N";
                  return e;
                }).toList();
            await Authentication().setLogin(jsonEncode(userData[0]));
            final prefs = await SharedPreferences.getInstance();
            prefs.remove("last_booking");
            Authentication().setLogoutStatus(true);

            if (Variables.inactiveTmr != null) {
              Variables.inactiveTmr!.cancel();
            }

            Get.offAllNamed(Routes.login);
          }
        },
      );
    }
  }
}

//GET MEssage from PA
Future<void> getMessNotif() async {
  var akongId = await Authentication().getUserId();

  HttpRequestApi(api: "${ApiKeys.getPaMessage}?user_id=$akongId").get().then((
    messageData,
  ) async {
    if (messageData == "No Internet" || messageData == null) {
      return;
    }
    if (messageData["items"].isNotEmpty) {
      for (dynamic dataRow in messageData["items"]) {
        PaMessageDatabase.instance
            .readNotificationById(dataRow["push_msg_id"])
            .then((objData) async {
              if (objData == null) {
                DateTime pdt = DateTime.parse(dataRow["created_on"].toString());
                DateTime targetDate = DateTime(
                  pdt.year,
                  pdt.month,
                  pdt.day,
                  pdt.hour,
                  pdt.minute,
                );
                bool dugaga = await Variables.withinDayRange(targetDate);
                if (!dugaga) return;
                Object json = {
                  PaMessageDataFields.pushMsgId: dataRow["push_msg_id"],
                  PaMessageDataFields.userId: dataRow["user_id"],
                  PaMessageDataFields.message: dataRow["message"],
                  PaMessageDataFields.createdDate: dataRow["created_on"],
                  PaMessageDataFields.status: dataRow["push_status"],
                  PaMessageDataFields.runOn: dataRow["run_on"],
                  PaMessageDataFields.isRead: "N",
                };

                PaMessageDatabase.instance.insertUpdate(json);
                NotificationController.createInformationMessage(
                  dataRow["push_msg_id"],
                  0,
                  'Attention',
                  "You have a new message in the app. Please check it.",
                  "message",
                );
              }
            });
      }
    }
  });
}

List<dynamic> getLastColumn(List<Map<String, dynamic>> list) {
  List<dynamic> lastColumn = [];

  for (var map in list) {
    // Get all keys of the map
    List<String> keys = map.keys.toList();

    // Get the last key (last column)
    String lastKey = keys.last;

    // Get the value corresponding to the last key
    dynamic lastValue = map[lastKey];

    lastColumn.add(lastValue);
  }

  return lastColumn;
}
