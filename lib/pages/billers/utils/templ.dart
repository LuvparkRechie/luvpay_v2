// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../auth/authentication.dart';
import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/custom_textfield.dart';
import '../../../custom_widgets/spacing.dart';
import '../../../functions/functions.dart';
import '../../../http/api_keys.dart';
import '../../../http/http_request.dart';
import '../../../http/thirdparty.dart';
import '../../../notification_controller.dart';
import '../controller.dart';
import 'receipt_billing.dart';

class Templ extends StatefulWidget {
  const Templ({super.key});

  @override
  State<Templ> createState() => _TemplState();
}

class _TemplState extends State<Templ> {
  Map<String, TextEditingController> controllers2 = {};
  final TextEditingController nickName = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(BillersController());
  final args = Get.arguments;
  final userDetails = Get.arguments["user_details"];
  final billerDetails = Get.arguments["details"];
  final Map<String, RegExp> _filter = {
    'A': RegExp(r'[A-Za-z0-9]'),
    '0': RegExp(r'[0-9]'),
    'N': RegExp(r'[0-9]'),
  };
  List dataBiller = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    setState(() {
      dataBiller = args["field"];

      controllers2.clear();
    });

    for (var field in dataBiller) {
      controllers2[field['key']] = TextEditingController(text: field['value']);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      initializeFormData();
    }
  }

  void initializeFormData() {
    Map<String, dynamic> formData = {};
    List postData =
        dataBiller.where((e) => e["is_for_posting"] == "Y").toList();

    for (var field in postData) {
      formData[field['key']] = controllers2[field['key']]!.text;
    }

    Map<String, dynamic> validateParam = {};
    for (var field in postData) {
      String key = field["key"];
      if (formData.containsKey(key)) {
        field["value"] = formData[key];
      }
    }

    for (var field in postData) {
      String key = field["key"];
      String value = field["value"];
      validateParam[key] = value;
    }
    luvparkPayment(validateParam);
  }

  Future<void> luvparkPayment(vParam) async {
    FocusManager.instance.primaryFocus?.unfocus();
    CustomDialogStack.showLoading(Get.context!);
    final response = await Functions.generateQr();
    if (response["response"] == "Success") {
      double serviceFee =
          double.tryParse(args['service_fee'].toString()) ?? 0.0;
      double userAmount = double.tryParse(vParam["received_amount"]) ?? 0.0;
      double addedAmount = serviceFee + userAmount;
      String totalAmount = addedAmount.toStringAsFixed(2);
      int userId = await Authentication().getUserId();
      CustomDialogStack.showConfirmation(
        Get.context!,
        "Pay Bills",
        "Are you sure you want to continue?",
        leftText: "No",
        rightText: "Okay",
        () {
          Get.back();
        },
        () async {
          Get.back();
          var parameters = {
            "luvpay_id": userId.toString(),
            "biller_id": args["details"]["biller_id"],
            "bill_acct_no": vParam["accountno"],
            "amount": totalAmount,
            "payment_hk": response["data"],
            "bill_no": vParam["bill_ref_no"],
            "account_name": userDetails["fullname"],
            'original_amount': userAmount,
          };

          CustomDialogStack.showLoading(Get.context!);

          HttpRequestApi(
            api: ApiKeys.postPayBills,
            parameters: parameters,
          ).postBody().then((returnPost) async {
            if (returnPost == "No Internet") {
              Get.back();
              CustomDialogStack.showConnectionLost(Get.context!, () {
                Get.back();
              });
            } else if (returnPost == null) {
              Get.back();
              CustomDialogStack.showServerError(Get.context!, () {
                Get.back();
              });
            } else {
              if (returnPost["success"] == 'Y') {
                vParam["luvpark_trans_ref"] = returnPost["lp_ref_no"];
                postData(
                  vParam,
                  returnPost["msg"],
                  userAmount,
                  vParam["accountno"],
                );
              } else {
                Get.back();
                CustomDialogStack.showError(
                  Get.context!,
                  "Error",
                  returnPost["msg"],
                  () {
                    Get.back();
                  },
                );
              }
            }
          });
        },
      );
    }
  }

  Future<void> postData(vParam, msg, amount, accountNo) async {
    String paramUrl = "http://192.168.7.78/web/eforms/hydracore/add_payment";
    Uri fullUri = Uri.parse(paramUrl).replace(queryParameters: vParam);
    String fullUrl = fullUri.toString();
    DateTime dateNow = await Functions.getTimeNow();
    final inatay = await Http3rdPartyRequest(url: fullUrl).postBiller();
    Get.back();

    if (inatay == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (inatay["result"]) {
      NotificationController.parkingNotif(
        dateNow.microsecond,
        0,
        "Payment Successfull",
        msg,
        "",
      );
      String payDate = DateFormat("MMM dd, yyyy hh:mm a").format(dateNow);

      Map<String, String> receiptData = {
        "Biller Name": "${billerDetails["biller_name"]}",
        "Biller Address": "${billerDetails["biller_address"]}",
        "Account Name": "${userDetails["fullname"]}",
        "Date Paid": "$payDate",
        "Amount Paid": "$amount",
      };
      Get.to(
        TicketUI(),
        arguments: {
          "nick_name": nickName.text,
          "receipt_data": receiptData,
          "biller_id": "${args["details"]["biller_id"]}",
          "account_no": "$accountNo",
        },
      );
      return;
    }
    if (inatay == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    } else {
      CustomDialogStack.showInfo(
        Get.context!,
        "Invalid request",
        "Please provide the required information or ensure the data entered is valid.",
        () {
          Get.back();
        },
      );
      return;
    }
  }

  Future<void> _selectDate(BuildContext context, String key) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controllers2[key]!.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColorV2.lpBlueBrand,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.lpBlueBrand,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text("Pay Biller"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
      ),
      body: Container(
        child:
            dataBiller.isEmpty
                ? Container()
                : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: DefaultText(
                          text: args["details"]["biller_name"],
                          color: AppColorV2.lpBlueBrand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: DefaultText(
                          text: args["details"]["biller_address"],
                          fontSize: 10,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Divider(color: AppColorV2.bodyTextColor),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(15, 20, 15, 10),
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DefaultText(
                                      fontSize: 14,
                                      text: "Nickname(optional)",
                                    ),
                                    CustomTextField(
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      controller: nickName,
                                      maxLength: 15,
                                      keyboardType: TextInputType.text,
                                      isFilled: false,
                                      isReadOnly: false,
                                    ),
                                  ],
                                ),
                                ...dataBiller.map((d) {
                                  final field = d;

                                  List<TextInputFormatter> inputFormatters = [];
                                  if (field['input_formatter'] != null &&
                                      field['input_formatter'].isNotEmpty) {
                                    String mask = field['input_formatter'];
                                    inputFormatters = [
                                      MaskTextInputFormatter(
                                        mask: mask,
                                        filter: _filter,
                                      ),
                                    ];
                                  }
                                  if (field['type'] == 'date') {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DefaultText(
                                          fontSize: 14,
                                          text: field['label'],
                                        ),
                                        CustomTextField(
                                          controller:
                                              controllers2[field['key']]!,
                                          isReadOnly: true,
                                          isFilled: false,
                                          suffixIcon: Icons.calendar_today,
                                          onTap:
                                              () => _selectDate(
                                                context,
                                                field['key'],
                                              ),
                                          validator: (value) {
                                            if (field['required'] &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return '${field['label']} is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    );
                                  } else if (field['type'] == 'number') {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DefaultText(
                                          fontSize: 14,
                                          text: field['label'],
                                        ),
                                        CustomTextField(
                                          controller:
                                              controllers2[field['key']]!,
                                          maxLength: field['maxLength'],
                                          isReadOnly:
                                              field['is_validation'] == "Y",
                                          keyboardType: TextInputType.phone,
                                          inputFormatters:
                                              field['is_amount'] == "N"
                                                  ? inputFormatters
                                                  : [
                                                    AutoDecimalInputFormatter(),
                                                  ],
                                          isFilled:
                                              field['is_validation'] == "Y",
                                          validator: (value) {
                                            if (field['label'] ==
                                                "Received Amount") {
                                              if (value?.startsWith('0') ??
                                                  false) {
                                                return "Invalid amount";
                                              }
                                            }
                                            if (field['required'] &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return '${field['label']} is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DefaultText(
                                          fontSize: 14,
                                          text: field['label'],
                                        ),
                                        CustomTextField(
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          controller:
                                              controllers2[field['key']]!,
                                          maxLength: field['maxLength'],
                                          keyboardType: TextInputType.text,
                                          isFilled:
                                              field['is_validation'] == "Y",
                                          isReadOnly:
                                              field['is_validation'] == "Y",
                                          validator: (value) {
                                            if (field['required'] &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return '${field['label']} is required';
                                            }
                                            return null;
                                          },
                                          inputFormatters: inputFormatters,
                                        ),
                                      ],
                                    );
                                  }
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (MediaQuery.of(context).viewInsets.bottom == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: CustomButton(
                            text: "Submit",
                            onPressed: _submitForm,
                          ),
                        ),
                      spacing(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }
}

class AutoDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final value = double.tryParse(numericValue) ?? 0.0;
    final formattedValue = (value / 100).toStringAsFixed(2);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
