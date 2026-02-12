import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:luvpay/core/network/http/http_request.dart';

import '../../core/security/agent_x.dart';
import '../../auth/authentication.dart';
import '../../auth/ub_auth.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/scanner.dart';
import '../../shared/widgets/variables.dart';
import '../../core/network/http/api_keys.dart';
import '../../shared/components/web_view/webview.dart';
import '../payment_integration/instapay.dart';
import '../payment_integration/success.dart';

class WalletRechargeLoadController extends GetxController
    with GetSingleTickerProviderStateMixin {
  WalletRechargeLoadController();

  final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
  final arguments = Get.arguments;
  RxString aesKeys = "".obs;
  TextEditingController amountController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  var currentPayment = 'wt_unionbank'.obs;
  Rx<Contact?> contact = Rx<Contact?>(null);
  RxString userImage = "".obs;
  List dataList =
      [
        {"value": 500, "is_active": false},
        {"value": 1000, "is_active": false},
        {"value": 2000, "is_active": false},
      ].obs;
  RxList padData = [].obs;
  RxString email = "".obs;
  RxString fullName = "".obs;
  RxString hash = "".obs;
  RxBool isActiveBtn = false.obs;
  RxBool isLoadingPage = true.obs;
  RxBool isValidNumber = false.obs;
  RxInt minTopUp = 0.obs;
  final TextEditingController mobNum = TextEditingController();
  final GlobalKey<FormState> topUpKey = GlobalKey<FormState>();
  RxString pageUrl = "".obs;
  TextEditingController rname = TextEditingController();

  // Nullable integer uniform code
  Rxn<int> selectedBankTracker = Rxn<int>(null);
  Rxn<int> selectedBankType = Rxn<int>(null);
  var denoInd = (-1).obs;
  var userDataInfo;
  final TextEditingController userName = TextEditingController();

  Timer? _debounce;
  Timer? _pollPrompt;
  //UB auth;
  final authService = UnionBankAuthService();
  @override
  void onClose() {
    _debounce?.cancel();
    topUpKey.currentState?.reset();
    super.onClose();
  }

  @override
  void onInit() {
    padData.value = dataList;
    rname = TextEditingController();
    amountController = TextEditingController(text: "500");
    fullName.value = "";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onTextChange();
      getData();
    });
    super.onInit();
  }

  Future<void> getData() async {
    final String bank = arguments["bank_code"].toString().toLowerCase();
    final String payment =
        bank.contains('ub online')
            ? 'wt_unionbank'
            : bank.contains('instapay')
            ? 'wt_instapay'
            : bank.contains('pesonet')
            ? 'wt_pesonet'
            : 'default_image';

    currentPayment.value = payment;
    var userData = await Authentication().getUserData();

    var item = jsonDecode(userData!);
    email.value = item["email"].toString();
    emailController.text = item["email"] == null ? "" : email.value;
    mobNum.text = item['mobile_no'].toString().substring(2);

    await onSearchChanged(mobNum.text, true);
  }

  Future<void> testUBUriPage(plainText, secretKeyHex) async {
    final secretKey = Variables.hexStringToArrayBuffer(secretKeyHex);
    final nonce = Variables.generateRandomNonce();

    // Encrypt
    final encrypted = await Variables.encryptData(secretKey, nonce, plainText);
    final concatenatedArray = Variables.concatBuffers(nonce, encrypted);
    final output = Variables.arrayBufferToBase64(concatenatedArray);

    hash.value = Uri.encodeComponent(output);

    Get.to(
      () => WebviewPage(
        urlDirect: "${pageUrl.value}${hash.value}",
        label: "Bank Payment",
      ),
      transition: Transition.zoom,
      duration: const Duration(milliseconds: 200),
    );
  }

  bool isBase64(String s) {
    try {
      String normalized = Base64Codec().normalize(s);
      base64Decode(normalized);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool isObjData(dynamic s) {
    return s is Map<String, dynamic>;
  }

  Future<void> requestCameraPermission() async {
    Get.to(
      ScannerScreen(
        onchanged: (args) {
          defPopup({msg}) {
            CustomDialogStack.showError(
              Get.context!,
              "Invalid QR Code",
              msg ?? "The scanned QR code is invalid. Please try again.",
              () {
                Get.back();
              },
            );
          }

          if (!isBase64(args)) {
            defPopup();
            return;
          }

          dynamic jsonData = jsonDecode(AgentX_().decryptAES256CBC(args));

          if (jsonData["amount"].toString().isEmpty) {
            amountController.text = "500";
          } else {
            amountController.text = jsonData["amount"].toString();
          }
          onTextChange();
          if (jsonData is Map) {
            if (jsonData.containsKey('mobile_no')) {
              String mobileNo = jsonData["mobile_no"].toString();
              if (mobileNo.toString().length == 12) {
                mobNum.text = mobileNo.replaceAll(" ", "").substring(2);

                onSearchChanged(mobNum.text, false, from: "scan_qr");
                CustomDialogStack.showLoading(Get.context!);
                return;
              }
              defPopup(msg: "Invalid mobile number");
              return;
            } else {
              defPopup();
              return;
            }
          } else {
            defPopup();
            return;
          }
        },
      ),
    );
  }

  //function for my pads
  Future<void> pads(int value) async {
    amountController.text = value.toString();
    padData.value =
        dataList.map((obj) {
          obj["is_active"] = (obj["value"] == value);
          return obj;
        }).toList();

    isActiveBtn.value = true;
  }

  Future<void> onSearchChanged(mobile, isFirst, {String? from}) async {
    isActiveBtn.value = false;
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (mobile.toString().length < 10) {
      return;
    }
    Duration duration = const Duration(milliseconds: 200);
    if (isFirst) {
      duration = const Duration(milliseconds: 200);
    } else {
      duration = const Duration(seconds: 2);
    }

    _debounce = Timer(duration, () {
      CustomDialogStack.showLoading(Get.context!);

      String api =
          "${ApiKeys.verifyUserAccount}?mobile_no=63${mobile.toString().replaceAll(" ", '')}";
      HttpRequestApi(api: api).get().then((objData) {
        FocusScope.of(Get.context!).unfocus();
        if (objData == "No Internet") {
          isValidNumber.value = false;
          rname.text = "";
          fullName.value = "";
          userName.text = "";

          Get.back();
          CustomDialogStack.showConnectionLost(Get.context!, () {
            Get.back();
          });
          return;
        }
        if (objData == null) {
          Get.back();

          isValidNumber.value = false;
          rname.text = "";
          fullName.value = "";
          userName.text = "";

          CustomDialogStack.showServerError(Get.context!, () {
            Get.back();
          });
          return;
        }
        if (objData["user_id"] == 0) {
          Get.back();

          userDataInfo = null;
          rname.text = "Unknown user";
          userName.text = "";
          fullName.value = "";
          email.value = "No email provided yet";
          isValidNumber.value = false;

          CustomDialogStack.showError(
            Get.context!,
            "Error",
            "Sorry, we're unable to find your account.",
            () {
              Get.back();
              Get.back();
              Get.back();
            },
          );

          return;
        } else {
          minTopUp.value = int.parse(objData["min_topup"].toString());
          userImage.value = objData["image_base64"] ?? "";
          Get.back();
          isActiveBtn.value = true;
          userDataInfo = [objData];
          isValidNumber.value = true;
          String originalFullName = userDataInfo[0]["first_name"].toString();
          String transformedFullName = Variables.transformFullName(
            originalFullName.replaceAll(RegExp(r'\..*'), ''),
          );
          String transformedLname = Variables.transformFullName(
            userDataInfo[0]["last_name"].toString().replaceAll(
              RegExp(r'\..*'),
              '',
            ),
          );

          String middelName = "";
          email.value = userDataInfo[0]["email"].toString();
          if (userDataInfo[0]["middle_name"] != null) {
            middelName = userDataInfo[0]["middle_name"].toString()[0];
          } else {
            middelName = "";
          }
          userName.text =
              "$originalFullName $middelName ${userDataInfo[0]["last_name"].toString()}";
          fullName.value =
              '$transformedFullName $middelName${middelName.isNotEmpty ? "." : ""} $transformedLname';
          if (originalFullName == 'null') {
            rname.text = "Unverified user";
          } else {
            rname.text = fullName.value;
          }
          if (from == "contacts" || from == "scan_qr" || from == "proceed") {
            Get.back();
            Get.back();
          }
        }
      });
    });
  }

  Future<void> onTextChange() async {
    denoInd.value = -1;

    final double? value = double.tryParse(amountController.text);

    bool isValueInDataList = dataList.any((e) => e["value"] == value);

    padData.value =
        padData.map((e) {
          if (isValueInDataList &&
              double.parse(e["value"].toString()) == value) {
            e["is_active"] = true;
          } else {
            e["is_active"] = false;
          }
          return e;
        }).toList();
    isActiveBtn.value =
        isValueInDataList || (value != null && value >= minTopUp.value);
  }

  Future<void> onPay() async {
    if (topUpKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus!.unfocus();
      if (!isActiveBtn.value) {
        return;
      }
      if (arguments["bank_type"].toString().toLowerCase().contains(
        "unionbank",
      )) {
        uBankPay();
      }
      if (arguments["bank_type"].toString().toLowerCase().contains("maya")) {
        mayaPay();
      }
      if (arguments["bank_type"].toString().toLowerCase().contains(
        "landbank",
      )) {
        landbankPay();
      }
    }
  }

  Future<dynamic> getUserTnx2() async {
    String bankApi =
        arguments["bank_type"].toString().toLowerCase().contains("maya")
            ? ApiKeys.postGetMayaRef
            : ApiKeys.postThirdPartyPayment;
    final userId = await Authentication().getUserId();
    var dataParam = {
      "amount": amountController.text.toString().split(".")[0],
      "user_id": userId,
      "to_mobile_no": "63${mobNum.text.replaceAll(" ", "")}",
    };
    CustomDialogStack.showLoading(Get.context!);
    final returnPost =
        await HttpRequestApi(api: bankApi, parameters: dataParam).postBody();

    if (returnPost == "No Internet") {
      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Please check your internet connection and try again.",
        () {
          Get.back();
        },
      );
      return "";
    }
    if (returnPost == null) {
      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Error while connecting to server, Please try again.",
        () {
          Get.back();
        },
      );
      return "";
    } else {
      if (returnPost["success"] == 'Y') {
        Get.back();

        return returnPost["tnx_hk"];
      } else {
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          returnPost['msg'],
          () {
            Get.back();
          },
        );
        return "";
      }
    }
  }

  ////select paymentType
  void paymentType(Function cb) async {
    final response = await getUserTnx2();
    final bankType = arguments;
    if (response is String) {
      cb({"type": bankType["bank_code"].toString().trim(), "key": response});
    }

    //
  }

  Future<void> uBankPay() async {
    paymentType((payMethod) async {
      CustomDialogStack.showLoading(Get.context!);
      Map<String, dynamic> param = {
        "emailAddress": email.value,
        "mobileNumber": mobNum.text.trim(),
        "amount": amountController.text,
        "paymentMethod": payMethod["type"],
        "references": [
          {
            "index": 1,
            "name": "RECIPIENT_MOBILE_NO",
            "value": "63${mobNum.text.trim()}",
          },
          {"index": 2, "name": "RECIPIENT_FULL_NAME", "value": userName.text},
          {"index": 3, "name": "TNX_HK", "value": payMethod["key"].toString()},
        ],
      };

      final response =
          await HttpRequestApi(
            api: ApiKeys.postUBTrans,
            parameters: param,
          ).postBody();

      Get.back();
      if (response == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return;
      }
      if (response == null) {
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Error while connecting to server, Please try again.",
          () {
            Get.back();
          },
        );
        return;
      } else {
        if (response is Map) {
          if (response["success"] == "N") {
            CustomDialogStack.showInfo(
              Get.context!,
              "Oops!",
              response["msg"],
              () {
                Get.back();
              },
            );
            return;
          }

          if (payMethod['type'].toString().toLowerCase().contains("instapay")) {
            Navigator.of(Get.context!).push(
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) => InstapayPage(
                      qr: response["qrCode"].toString(),
                      amount: double.parse(amountController.text),
                    ),
                transitionDuration: Duration(milliseconds: 200),
                reverseTransitionDuration: Duration.zero,
              ),
            );

            return;
          } else {
            final result = await Get.to(
              () => WebviewPage(
                urlDirect: response["message"],
                label: "Bank Payment",
              ),
              transition: Transition.zoom,
              duration: const Duration(milliseconds: 200),
            );

            if (result != null) {
              if (result['status'].toString().toLowerCase() == 'success' ||
                  result['status'].toString().toLowerCase() == 'processed') {
                Get.to(
                  () => SuccessPage(),
                  transition: Transition.zoom,
                  duration: const Duration(milliseconds: 200),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: LuvpayText(
                      text:
                          '${result['status'].toString().replaceAll("_", " ")}',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }
            }
          }
        }
      }
    });
  }

  // Start of maya pay
  Future<void> mayaPay() async {
    CustomDialogStack.showLoading(Get.context!);

    final userId = await Authentication().getUserId();

    double amtPay = double.parse(
      amountController.text.toString().split(".")[0],
    );

    Map<String, dynamic> postParam = {
      "amount": amtPay.toString().split(".")[0],
      "user_id": userId,
      "to_mobile_no": "63${mobNum.text.replaceAll(" ", "")}",
    };

    final response =
        await HttpRequestApi(
          api: ApiKeys.postMayaIntegration,
          parameters: postParam,
        ).postBody();
    Get.back();
    if (response == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Error while connecting to server, Please try again.",
        () {
          Get.back();
        },
      );
      return;
    }

    if (response.isNotEmpty) {
      final result = await Get.to(
        () => WebviewPage(
          urlDirect: response["redirectUrl"],
          label: "Bank Payment",
        ),
        transition: Transition.zoom,
        duration: const Duration(milliseconds: 200),
      );
      // Map<String, dynamic> updateParam = {
      //   "bankType": payMethod['type'],
      //   "param": {"maya_tnx_hk": payMethod["key"]},
      // };

      if (result != null) {
        if (result['status'].toString().toLowerCase() == 'success' ||
            result['status'].toString().toLowerCase() == 'processed') {
          Get.to(
            () => SuccessPage(),
            // arguments: updateParam,
            transition: Transition.zoom,
            duration: const Duration(milliseconds: 200),
          );
          return;
        } else {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: LuvpayText(
                text: '${result['status'].toString().replaceAll("_", " ")}',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        }
      }
    } else {
      CustomDialogStack.showInfo(
        Get.context!,
        "No data found",
        "Unable to get data. please try again.",
        () {
          Get.back();
        },
      );
      return;
    }
    // paymentType((payMethod) async {
    //   if (payMethod["key"] != null) {

    //   } else {
    //     CustomDialogStack.showInfo(
    //       Get.context!,
    //       "No data available",
    //       "We couldn't find any data. Please try again.",
    //       () {
    //         Get.back();
    //       },
    //     );
    //   }
    // });
  }

  Future<void> landbankPay() async {
    CustomDialogStack.showLoading(Get.context!);

    final userId = await Authentication().getUserId();

    double amtPay = double.parse(
      amountController.text.toString().split(".")[0],
    );

    Map<String, dynamic> postParam = {
      "amount": amtPay.toString().split(".")[0],
      "user_id": userId,
      "to_mobile_no": "63${mobNum.text.replaceAll(" ", "")}",
    };
    final String api = ApiKeys.postLandBankTrans;
    final response =
        await HttpRequestApi(api: api, parameters: postParam).postBody();
    Get.back();
    if (response == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Error while connecting to server, Please try again.",
        () {
          Get.back();
        },
      );
      return;
    }
    final Map<String, dynamic> userData = {
      "name": rname.text.toString(),
      "user_id": userId,
      "to_mobile_no": "63${mobNum.text.replaceAll(" ", "")}",
    };
    if (response.isNotEmpty) {
      await Get.to(
        () => WebviewPage(
          urlDirect: response["redirect_url"],
          label: "Bank Payment",
          callback: (isSuccess) {
            getPollLPayStatus(response["reference_no"]);
          },
          userData: userData,
          lbReturn: response,
        ),
        transition: Transition.zoom,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      CustomDialogStack.showInfo(
        Get.context!,
        "No data found",
        "Unable to get data. please try again.",
        () {
          Get.back();
        },
      );
      return;
    }
  }

  Future<void> getPollLPayStatus(String refNo) async {
    bool isPaid = false;
    int retryCount = 0;
    const int maxRetries = 30;

    while (!isPaid && retryCount < maxRetries) {
      try {
        final response =
            await HttpRequestApi(
              api: "${ApiKeys.postLandBankTrans}?reference_no=$refNo",
            ).get();
        if (response["items"] is List && response["items"].isNotEmpty) {
          final firstItem = response["items"][0];

          if (firstItem["success"] == "Y") {
            CustomDialogStack.showLoading(Get.context!);
            await Future.delayed(Duration(seconds: 5));
            Get.back();
            await Future.delayed(Duration(milliseconds: 500));
            Get.back();
            Get.to(
              () => SuccessPage(),
              transition: Transition.zoom,
              duration: const Duration(milliseconds: 200),
            );
            return;
          }
          isPaid = true;
          return;
        }
        isPaid = true;
      } catch (e) {
        print("Error polling Landbank status: $e");
        isPaid = true;
      }

      await Future.delayed(Duration(seconds: 5));
      retryCount++;
    }

    if (!isPaid) {
      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Payment Failed"),
            content: const Text(
              "Due to unconfirmed payment or exceeded time limit,\n"
              "this transaction will now be closed.\n\n"
              "Please check your Landbank app or try again later.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Get.back(); // close payment/QR page
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }
}
