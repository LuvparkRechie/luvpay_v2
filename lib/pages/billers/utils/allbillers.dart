// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/custom_textfield.dart';
import '../../../custom_widgets/loading.dart';
import '../../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../../custom_widgets/no_data_found.dart';
import '../../../custom_widgets/spacing.dart';
import '../../../http/thirdparty.dart';
import '../../routes/routes.dart';
import '../controller.dart';
import 'templ.dart';

class Allbillers extends GetView<BillersController> {
  Allbillers({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return CustomScaffoldV2(
      onPressedLeading: () {
        Get.back();
        controller.filterBillers('');
        searchController.clear();
      },
      appBarTitle: "Billers",
      enableToolBar: true,

      scaffoldBody: Obx(
        () => Column(
          children: [
            SizedBox(
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: Offset(0, 0),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(54),
                ),
                child: TextField(
                  autofocus: false,
                  style: AppTextStyle.paragraph2,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    hintText: "Search billers",
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(54),
                      borderSide: BorderSide(color: AppColorV2.lpBlueBrand),
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(54),
                      borderSide: BorderSide(
                        width: 1,
                        color: Color(0xFFCECECE),
                      ),
                    ),
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 15),
                        Icon(LucideIcons.search),
                        Container(width: 10),
                      ],
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Visibility(
                          visible: searchController.text.isNotEmpty,
                          child: InkWell(
                            onTap: () {
                              searchController.clear();
                              controller.filterBillers('');
                            },
                            child: Container(
                              padding: EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade300,
                              ),
                              child: Icon(
                                LucideIcons.x,
                                color: AppColorV2.primaryTextColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    hintStyle: AppTextStyle.paragraph2,
                    labelStyle: AppTextStyle.paragraph2,
                  ),
                  onChanged: (value) {
                    controller.filterBillers(value);
                  },
                ),
              ),
            ),
            Expanded(
              child:
                  controller.filteredBillers.isEmpty
                      ? NoDataFound(text: "No Billers found")
                      : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.filteredBillers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 3,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () async {
                                  // controller.filterBillers('');
                                  // searchController.clear();
                                  Map<String, dynamic> billerData = {
                                    'biller_name':
                                        controller
                                            .filteredBillers[index]["biller_name"] ??
                                        "",
                                    'biller_id':
                                        controller
                                            .filteredBillers[index]["biller_id"] ??
                                        "",
                                    'biller_code':
                                        controller
                                            .filteredBillers[index]["bi)ller_code"] ??
                                        "",
                                    'biller_address':
                                        controller
                                            .filteredBillers[index]["biller_address"] ??
                                        "",
                                    'service_fee':
                                        controller
                                            .filteredBillers[index]["service_fee"] ??
                                        "",
                                    'posting_period_desc':
                                        controller
                                            .filteredBillers[index]["posting_period_desc"] ??
                                        "",
                                    'source': Get.arguments["source"] ?? "",
                                    'full_url':
                                        controller
                                            .filteredBillers[index]["full_url"] ??
                                        "",
                                    "account_name": "",
                                    'accountno': "",
                                  };

                                  final res = await Get.toNamed(
                                    Routes.billsPayment,
                                    arguments: billerData,
                                  );

                                  if (res != null) {
                                    Get.back(result: true);
                                  }
                                },
                                title: DefaultText(
                                  style: AppTextStyle.h3,
                                  text:
                                      controller
                                          .filteredBillers[index]['biller_name'] ??
                                      'Unknown',
                                ),
                                subtitle: DefaultText(
                                  maxLines: 1,
                                  text:
                                      controller
                                          .filteredBillers[index]["biller_address"] ??
                                      'Address not specified',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class ValidateAccount extends StatefulWidget {
  final dynamic billerData;
  const ValidateAccount({super.key, this.billerData});

  @override
  State<ValidateAccount> createState() => _ValidateAccountState();
}

class _ValidateAccountState extends State<ValidateAccount> {
  Map<String, TextEditingController> controllers2 = {};
  final _formKey = GlobalKey<FormState>();
  List tempData = [];
  final Map<String, RegExp> _filter = {
    'A': RegExp(r'[A-Za-z0-9]'),
    '0': RegExp(r'[0-9]'),
    'N': RegExp(r'[0-9]'),
  };

  @override
  void initState() {
    super.initState();
    initializedData();
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

  void initializedData() async {
    List fieldData = widget.billerData["field"];
    setState(() {
      controllers2.clear();
      tempData =
          fieldData
              .where((element) => element["is_validation"] == "Y")
              .toList();
    });

    for (var field in tempData) {
      String key = field['key'];
      String value = widget.billerData["details"][key]?.toString() ?? '';
      controllers2[key] = TextEditingController(text: value);
    }

    setState(() {});
  }

  void _verifyAccount() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> formData = {};
      for (var field in tempData) {
        formData[field['key']] = controllers2[field['key']]!.text;
      }

      String paramUrl = widget.billerData["details"]["full_url"];

      Map<String, dynamic> validateParam = {};
      for (var field in tempData) {
        String key = field["key"];
        if (formData.containsKey(key)) {
          field["value"] = formData[key];
        }
      }

      for (var field in tempData) {
        String key = field["key"];
        String value = field["value"];
        validateParam[key] = value;
      }

      Uri fullUri = Uri.parse(paramUrl).replace(queryParameters: validateParam);
      String fullUrl = fullUri.toString();

      CustomDialogStack.showLoading(Get.context!);
      final inatay = await Http3rdPartyRequest(url: fullUrl).getBiller();
      Get.back();

      if (inatay == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
      } else if (inatay["result"] == "true") {
        Get.back();
        Get.to(
          arguments: {
            "details": widget.billerData["details"],
            "field": widget.billerData["field"],
            "user_details": inatay["data"],
          },
          const Templ(),
        );
      } else if (inatay == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      } else {
        CustomDialogStack.showInfo(
          Get.context!,
          "Invalid request",
          "Please provide the required information or ensure the data entered is valid.",
          () {
            Get.back();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
        color: Colors.white,
      ),
      child:
          tempData.isEmpty
              ? LoadingCard()
              : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    spacing(height: 20),
                    Center(
                      child: Container(
                        width: 71,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(56),
                          color: const Color(0xffd9d9d9),
                        ),
                      ),
                    ),
                    spacing(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultText(
                            text: "Account Verification",
                            fontSize: 20,
                          ),
                          spacing(height: 5),
                          DefaultText(
                            text:
                                "Ensure your account information is accurate.",
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(15, 30, 15, 10),
                        itemCount: tempData.length,
                        itemBuilder: (context, i) {
                          final field = tempData[i];

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultText(fontSize: 14, text: field['label']),
                                CustomTextField(
                                  controller: controllers2[field['key']]!,
                                  isReadOnly: true,
                                  isFilled: false,
                                  suffixIcon: Icons.calendar_today,
                                  onTap:
                                      () => _selectDate(context, field['key']),
                                  validator: (value) {
                                    if (field['required'] &&
                                        (value == null || value.isEmpty)) {
                                      return '${field['label']} is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          } else if (field['type'] == 'number') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultText(fontSize: 14, text: field['label']),
                                CustomTextField(
                                  controller: controllers2[field['key']]!,
                                  maxLength: field['maxLength'],
                                  keyboardType: TextInputType.number,
                                  hintText: "Enter ${field['label']}",
                                  inputFormatters: inputFormatters,
                                  validator: (value) {
                                    if (field['required'] &&
                                        (value == null || value.isEmpty)) {
                                      return '${field['label']} is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultText(fontSize: 14, text: field['label']),
                                CustomTextField(
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  controller: controllers2[field['key']]!,
                                  maxLength: field['maxLength'],
                                  keyboardType: TextInputType.text,
                                  validator: (value) {
                                    if (field['required'] &&
                                        (value == null || value.isEmpty)) {
                                      return '${field['label']} is required';
                                    }
                                    return null;
                                  },
                                  inputFormatters: inputFormatters,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Visibility(
                        visible: MediaQuery.of(context).viewInsets.bottom == 0,
                        child: CustomButton(
                          text: "Proceed",
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _verifyAccount();
                            }
                          },
                        ),
                      ),
                    ),
                    spacing(height: 30),
                  ],
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

    // Remove non-numeric characters
    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as decimal (e.g., "123" -> "1.23")
    final value = double.tryParse(numericValue) ?? 0.0;
    final formattedValue = (value / 100).toStringAsFixed(2);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
