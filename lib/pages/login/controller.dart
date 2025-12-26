import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/sqlite/pa_message_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../device_registration/device_reg.dart';
import '../../functions/functions.dart';
import '../../otp_field/view.dart';
import '../../sqlite/reserve_notification_table.dart';
import '../routes/routes.dart';
import 'change_pass_new_proc/change_pass_new.dart';

class LoginScreenController extends GetxController {
  LoginScreenController();
  // final GlobalKey<FormState> formKeyLogin = GlobalKey<FormState>();
  RxBool isAgree = false.obs;
  RxBool isShowPass = false.obs;
  RxBool isLoading = false.obs;
  RxInt counter = 0.obs;
  final storage = FlutterSecureStorage();
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLogin = false;
  RxBool isInternetConnected = true.obs;
  String mobnum = "";
  RxBool canProceed = false.obs;
  bool isTappedReg = false;
  var usersLogin = [];

  void toggleLoading(bool value) {
    isLoading.value = value;
  }

  void onPageChanged(bool agree) {
    isAgree.value = agree;
    update();
  }

  void visibilityChanged(bool visible) {
    isShowPass.value = visible;
    update();
  }

  Future<void> getMobile() async {
    final data = await Authentication().getUserData2();

    mobnum = data["mobile_no"].toString();
  }

  //POST LOGIN
  postLogin(context, Map<String, dynamic> param, Function cb) async {
    HttpRequestApi(api: ApiKeys.postLogin, parameters: param).postBody().then((
      returnPost,
    ) async {
      if (returnPost == "No Internet") {
        CustomDialogStack.showConnectionLost(context, () {
          Get.back();
          cb([
            {"has_net": false, "items": []},
          ]);
        });
        return;
      }
      if (returnPost == null) {
        CustomDialogStack.showError(
          context,
          "Error",
          "Error while connecting to server, Please try again.",
          () {
            Get.back();
            cb([
              {"has_net": true, "items": []},
            ]);
          },
        );
        return;
      }
      if (returnPost["success"] == "N") {
        cb([
          {"has_net": true, "items": []},
        ]);
        //activate account
        if (returnPost["is_active"] == "N") {
          CustomDialogStack.showConfirmation(
            context,
            "Activate account",
            "Your account is currently inactive. Would you like to activate it now?",
            leftText: "No",
            rightText: "Yes",
            () {
              Get.back();
            },
            () async {
              Get.back();
              CustomDialogStack.showLoading(context);
              DateTime timeNow = await Functions.getTimeNow();
              Get.back();
              String mobileNo = param["mobile_no"].toString();
              Map<String, String> reqParam = {
                "mobile_no": mobileNo,
                "new_pwd": password.text,
              };
              Functions().requestOtp(reqParam, (obj) async {
                DateTime timeExp = DateFormat(
                  "yyyy-MM-dd hh:mm:ss a",
                ).parse(obj["otp_exp_dt"].toString());
                DateTime otpExpiry = DateTime(
                  timeExp.year,
                  timeExp.month,
                  timeExp.day,
                  timeExp.hour,
                  timeExp.minute,
                  timeExp.millisecond,
                );

                // Calculate difference
                Duration difference = otpExpiry.difference(timeNow);

                if (obj["success"] == "Y" || obj["status"] == "PENDING") {
                  Map<String, String> putParam = {
                    "mobile_no": mobileNo.toString(),
                    "req_type": "NA",
                    "otp": obj["otp"].toString(),
                  };

                  Object args = {
                    "time_duration": difference,
                    "mobile_no": mobileNo.toString(),
                    "req_otp_param": reqParam,
                    "verify_param": putParam,
                    "callback": (otp) {
                      if (otp != null) {
                        Map<String, dynamic> data = {
                          "mobile_no": mobileNo,
                          "pwd": password.text,
                        };
                        final plainText = jsonEncode(data);

                        Authentication().encryptData(plainText);
                        CustomDialogStack.showSuccess(
                          context,
                          "Activate Account",
                          "Your account has been successfully activated! 🎉 You can now enjoy full access to all features.",
                          leftText: "Okay",
                          () {
                            Get.back();
                            Get.back();
                          },
                        );
                      }
                    },
                  };

                  Get.to(
                    OtpFieldScreen(arguments: args),
                    transition: Transition.rightToLeftWithFade,
                    duration: Duration(milliseconds: 400),
                  );
                }
              });
            },
          );
          return;
        }

        if (returnPost["login_attempt"] != null &&
            returnPost["login_attempt"] >= 5) {
          List mapData = [returnPost];

          mapData =
              mapData.map((e) {
                e["mobile_no"] = param["mobile_no"];
                return e;
              }).toList();

          Future.delayed(Duration(milliseconds: 200), () {
            mobileNumber.text = "";
            password.text = "";
            Get.offAndToNamed(Routes.lockScreen, arguments: mapData);
          });
          return;
        } else {
          if (returnPost["device_valid"] != null) {
            if (returnPost["user_id"] == 0 &&
                returnPost["session_id"] != null &&
                returnPost["device_valid"] == 'N') {
              final uData = await Authentication().getUserLogin();

              if (uData == null) {
                Get.back();
                Functions().verifyAccount(param["mobile_no"], (data) {
                  if (data["success"]) {
                    Get.to(
                      DeviceRegScreen(
                        mobileNo: param["mobile_no"].toString(),
                        userId: data["data"]["user_id"].toString(),
                        sessionId: returnPost["session_id"].toString(),
                        pwd: param["pwd"],
                      ),
                      arguments: {"data": returnPost},
                      transition: Transition.rightToLeftWithFade,
                      duration: Duration(milliseconds: 400),
                    );
                    return;
                  }
                });

                return;
              } else {
                CustomDialogStack.showInfo(
                  context,
                  "Secure Account",
                  returnPost["msg"].toString(),
                  () {
                    Get.back();
                  },
                );
              }
              return;
            } else {
              Get.back();
              Get.to(
                DeviceRegScreen(
                  mobileNo: param["mobile_no"].toString(),
                  pwd: param["pwd"],
                ),
                arguments: {"data": returnPost},
                transition: Transition.rightToLeftWithFade,
                duration: Duration(milliseconds: 400),
              );
            }
            return;
          }
          CustomDialogStack.showInfo(
            context,
            "Security Warning",
            returnPost["msg"],
            () {
              Get.back();
              Get.back();
            },
          );
        }

        return;
      }
      if (returnPost["success"] == "R") {
        Get.back();

        CustomDialogStack.showInfo(
          context,
          "Secure Account",
          returnPost["msg"],
          () {
            Get.back();
            Get.to(
              ChangePassNewProtocol(
                userId: returnPost["user_id"].toString(),
                mobileNo:
                    "63${mobileNumber.text.toString().replaceAll(" ", "")}",
              ),
            );
          },
        );
        return;
      } else {
        Get.back();
        if (returnPost["device_valid"] == "N") {
          CustomDialogStack.showConfirmation(
            context,
            "Secure Account",
            returnPost["msg"],
            leftText: "Cancel",
            rightText: "Register device",
            () {
              Get.back();
            },
            () {
              Get.back();
              Get.to(
                DeviceRegScreen(
                  mobileNo: param["mobile_no"].toString(),
                  pwd: param["pwd"],
                ),
                arguments: {
                  "data": returnPost,
                  "cb": (d) {
                    CustomDialogStack.showSuccess(
                      context,
                      "Success",
                      "Device successfully registered.",
                      leftText: "Okay",
                      () {
                        getUserData(param, returnPost, (data) {
                          Get.back();

                          if (data[0]["items"].isNotEmpty) {
                            Get.back();
                            cb(data);
                          }
                        });
                      },
                    );
                  },
                },
                transition: Transition.rightToLeftWithFade,
                duration: Duration(milliseconds: 400),
              );
            },
          );
          return;
        }

        if (returnPost["pwd_days_left"] < 1) {
          CustomDialogStack.showConfirmation(
            image: "reset_password",
            context,
            "Account Safety",
            "New security update — please update your password.",
            leftText: "Waive",
            rightText: "Update",
            () {
              Get.back();
              extendPassword(param["mobile_no"], (isTrue) {
                if (isTrue) {
                  getUserData(param, returnPost, (data) {
                    cb(data);
                  });
                }
              });
            },
            () {
              Get.back();
              String mobileNo = param["mobile_no"].toString();
              Get.toNamed(Routes.createNewPass, arguments: mobileNo);
            },
          );
          return;
        }
        getUserData(param, returnPost, (data) {
          cb(data);
        });
      }
    });
  }

  void extendPassword(String mobileNo, Function cb) async {
    final putParam = {"extend": "Y", "mobile_no": mobileNo};
    CustomDialogStack.showLoading(Get.context!);
    final response =
        await HttpRequestApi(
          api: ApiKeys.putLogin,
          parameters: putParam,
        ).putBody();
    Get.back();
    if (response == "No Internet") {
      cb(false);
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      cb(false);
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response["success"] == "Y") {
      CustomDialogStack.showSuccess(
        Get.context!,
        "Success",
        response["msg"],
        leftText: "Okay",
        () {
          Get.back();
          cb(true);
        },
      );
      return;
    } else {
      cb(false);
      CustomDialogStack.showInfo(
        Get.context!,
        "Unsuccessful",
        response["msg"],
        () {
          Get.back();
        },
      );
      return;
    }
  }

  void getUserData(param, returnPost, Function cb) async {
    CustomDialogStack.showLoading(Get.context!);
    var getApi =
        "${ApiKeys.getLogin}?mobile_no=${param["mobile_no"]}&auth_key=${returnPost["auth_key"].toString()}";

    HttpRequestApi(api: getApi).get().then((objData) async {
      if (objData == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
          cb([
            {"has_net": false, "items": []},
          ]);
        });
        return;
      }
      if (objData == null) {
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          "Error while connecting to server, Please try again.",
          () {
            Get.back();
            cb([
              {"has_net": true, "items": []},
            ]);
          },
        );
        return;
      } else {
        if (objData["items"].isEmpty) {
          CustomDialogStack.showError(
            Get.context!,
            "Error",
            objData["items"]["msg"],
            () {
              Get.back();
              cb([
                {"has_net": true, "items": []},
              ]);
            },
          );
          return;
        } else {
          List itemData = objData["items"];

          itemData =
              itemData.map((e) {
                e["session_id"] = returnPost["session_id"];
                return e;
              }).toList();

          var items = itemData[0];

          await initializeStoredData(items);
          //sms keys
          Map<String, dynamic> data = {
            "mobile_no": param["mobile_no"],
            "pwd": param["pwd"],
          };
          final plainText = jsonEncode(data);

          Map<String, dynamic> parameters = {
            "user_id": items['user_id'].toString(),
            "mobile_no": param["mobile_no"],
            "is_active": "Y",
            "is_login": "Y",
          };

          Authentication().setLogin(jsonEncode(parameters));
          Authentication().setUserData(jsonEncode(items));
          Authentication().setLogoutStatus(false);
          Authentication().encryptData(plainText);

          if (items["image_base64"] != null) {
            Authentication().setProfilePic(jsonEncode(items["image_base64"]));
          } else {
            Authentication().setProfilePic("");
          }

          List dataCb = objData["items"];

          if (Platform.isIOS) {
            final service = FlutterBackgroundService();
            service.invoke('updateUserLogin', {
              'userId': int.parse(items['user_id'].toString()),
            });
          }
          cb([
            {"has_net": true, "items": dataCb},
          ]);
        }
      }
    });
  }

  Future<void> initializeStoredData(itemData) async {
    final stMob = await Authentication().getUserData2();

    if (stMob == null ||
        int.parse(itemData['user_id'].toString()) != stMob["user_id"]) {
      await Authentication().remove("last_booking");
      await Authentication().remove("userData");
      await PaMessageDatabase.instance.deleteAll();
      await NotificationDatabase.instance.deleteAll();
      await AwesomeNotifications().cancelAllSchedules();
      await AwesomeNotifications().dismissAllNotifications();
      await AwesomeNotifications().cancelAll();
    }
  }

  void switchAccount() {
    CustomDialogStack.showConfirmation(
      Get.context!,
      "Switch accounts?",
      "You’ll be signed out first.",
      leftText: "No",
      rightText: "Yes",
      () {
        Get.back();
      },
      () async {
        Get.back();
        final uData = await Authentication().getUserData2();
        Functions.logoutUser(
          uData == null ? "" : uData["session_id"].toString(),
          (isSuccess) async {
            if (isSuccess["is_true"]) {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove("auth_login");
              await Authentication().enableTimer(false);
              await Authentication().setLogoutStatus(true);
              await Authentication().setBiometricStatus(false);

              if (Platform.isIOS) {
                final service = FlutterBackgroundService();
                service.invoke('updateUserLogin', {'userId': 0});
              }
              Get.offAllNamed(Routes.login);
            }
          },
        );
      },
    );
  }

  Future<bool> userAuth(String mobile) async {
    final data = await Authentication().getEncryptedKeys();
    int mobaNo =
        data == null
            ? 0
            : int.parse(
              data["mobile_no"].toString().trim().replaceAll(" ", ""),
            );
    int usrMo = int.parse("63${mobile.toString().trim().replaceAll(" ", "")}");

    return mobaNo == usrMo ? false : true;
  }

  @override
  void onInit() {
    mobileNumber = TextEditingController();
    password = TextEditingController();
    getMobile();
    super.onInit();
  }
}
