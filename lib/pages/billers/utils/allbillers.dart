// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/custom_textfield.dart';
import '../../../custom_widgets/loading.dart';
import '../../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../../custom_widgets/no_data_found.dart';
import '../../../custom_widgets/spacing.dart';
import '../../../custom_widgets/luvpay/luv_neumorphic.dart';
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
      padding: EdgeInsets.zero,
      appBarTitle: "Billers",
      enableToolBar: true,
      scaffoldBody: Obx(
        () => Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 5),
          child: Column(
            children: [
              _NeumorphicSearchBar(
                controller: searchController,
                onChanged: controller.filterBillers,
                onClear: () {
                  searchController.clear();
                  controller.filterBillers('');
                },
              ),
              Expanded(
                child:
                    controller.filteredBillers.isEmpty
                        ? NoDataFound(text: "No Billers found")
                        : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: controller.filteredBillers.length,
                          itemBuilder: (context, index) {
                            final biller = controller.filteredBillers[index];

                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                margin: EdgeInsets.only(left: 10, right: 10),
                                child: LuvNeuPress.rect(
                                  radius: BorderRadius.circular(16),
                                  borderColor: AppColorV2.lpBlueBrand
                                      .withOpacity(0.06),
                                  onTap: () async {
                                    Map<String, dynamic> billerData = {
                                      'biller_name':
                                          biller["biller_name"] ?? "",
                                      'biller_id': biller["biller_id"] ?? "",
                                      'biller_code':
                                          biller["bi)ller_code"] ?? "",
                                      'biller_address':
                                          biller["biller_address"] ?? "",
                                      'service_fee':
                                          biller["service_fee"] ?? "",
                                      'posting_period_desc':
                                          biller["posting_period_desc"] ?? "",
                                      'source': Get.arguments["source"] ?? "",
                                      'full_url': biller["full_url"] ?? "",
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Neumorphic(
                                          style: NeumorphicStyle(
                                            color: AppColorV2.background,
                                            depth: -1.2,
                                            intensity: LuvNeu.intensity,
                                            surfaceIntensity:
                                                LuvNeu.surfaceIntensity,
                                            boxShape:
                                                NeumorphicBoxShape.roundRect(
                                                  BorderRadius.circular(12),
                                                ),
                                            border: NeumorphicBorder(
                                              color: AppColorV2.lpBlueBrand
                                                  .withOpacity(0.06),
                                              width: 0.7,
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Icon(
                                              LucideIcons.receipt,
                                              size: 20,
                                              color: AppColorV2.lpBlueBrand,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DefaultText(
                                                style: AppTextStyle.h3,
                                                text:
                                                    biller['biller_name'] ??
                                                    'Unknown',
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              DefaultText(
                                                maxLines: 1,
                                                text:
                                                    biller["biller_address"] ??
                                                    'Address not specified',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 18,
                                          color: AppColorV2.bodyTextColor
                                              .withOpacity(0.7),
                                        ),
                                      ],
                                    ),
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
      ),
    );
  }
}

class _NeumorphicSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _NeumorphicSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8),
      child: SizedBox(
        height: 54,
        child: Neumorphic(
          style: NeumorphicStyle(
            color: AppColorV2.background,
            depth: -2.0,
            intensity: LuvNeu.intensity,
            surfaceIntensity: LuvNeu.surfaceIntensity,
            boxShape: NeumorphicBoxShape.stadium(),
            border: NeumorphicBorder(
              color: AppColorV2.lpBlueBrand.withOpacity(0.07),
              width: 0.8,
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              return Center(
                child: TextField(
                  controller: controller,
                  autofocus: false,
                  style: AppTextStyle.paragraph2,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: "Search billers",
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),

                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColorV2.bodyTextColor.withOpacity(0.8),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),

                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child:
                          controller.text.isNotEmpty
                              ? Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: LuvNeuPress.circle(
                                  key: const ValueKey('clear'),
                                  onTap: () {
                                    onClear();
                                    setLocal(() {});
                                  },
                                  borderColor: AppColorV2.lpBlueBrand
                                      .withOpacity(0.06),
                                  child: const SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: Icon(LucideIcons.x, size: 18),
                                  ),
                                ),
                              )
                              : const SizedBox(width: 12),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),

                    hintStyle: AppTextStyle.paragraph2.copyWith(
                      color: AppColorV2.bodyTextColor.withOpacity(0.7),
                    ),
                  ),
                  onChanged: (value) {
                    onChanged(value);
                    setLocal(() {});
                  },
                ),
              );
            },
          ),
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
        CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
      } else if (inatay == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
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
      } else {
        CustomDialogStack.showInfo(
          Get.context!,
          "Invalid request",
          "Please provide the required information or ensure the data entered is valid.",
          () => Get.back(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: LuvNeu.card(
        radius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: AppColorV2.background,
        borderColor: AppColorV2.lpBlueBrand.withOpacity(0.08),
        borderWidth: 0.9,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child:
              tempData.isEmpty
                  ? const LoadingCard()
                  : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        spacing(height: 14),
                        Center(
                          child: Neumorphic(
                            style: NeumorphicStyle(
                              color: AppColorV2.background,
                              depth: -1.0,
                              intensity: LuvNeu.intensity,
                              surfaceIntensity: LuvNeu.surfaceIntensity,
                              boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(56),
                              ),
                              border: NeumorphicBorder(
                                color: AppColorV2.lpBlueBrand.withOpacity(0.06),
                                width: 0.8,
                              ),
                            ),
                            child: const SizedBox(width: 71, height: 6),
                          ),
                        ),
                        spacing(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              DefaultText(
                                text: "Account Verification",
                                fontSize: 20,
                              ),
                              SizedBox(height: 5),
                              DefaultText(
                                text:
                                    "Ensure your account information is accurate.",
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(15, 22, 15, 10),
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

                              Widget fieldWidget;

                              if (field['type'] == 'date') {
                                fieldWidget = _FieldBlock(
                                  label: field['label'],
                                  child: CustomTextField(
                                    controller: controllers2[field['key']]!,
                                    isReadOnly: true,
                                    isFilled: false,
                                    suffixIcon: Icons.calendar_today,
                                    onTap:
                                        () =>
                                            _selectDate(context, field['key']),
                                    validator: (value) {
                                      if (field['required'] &&
                                          (value == null || value.isEmpty)) {
                                        return '${field['label']} is required';
                                      }
                                      return null;
                                    },
                                  ),
                                );
                              } else if (field['type'] == 'number') {
                                fieldWidget = _FieldBlock(
                                  label: field['label'],
                                  child: CustomTextField(
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
                                );
                              } else {
                                fieldWidget = _FieldBlock(
                                  label: field['label'],
                                  child: CustomTextField(
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    controller: controllers2[field['key']]!,
                                    maxLength: field['maxLength'],
                                    keyboardType: TextInputType.text,
                                    inputFormatters: inputFormatters,
                                    validator: (value) {
                                      if (field['required'] &&
                                          (value == null || value.isEmpty)) {
                                        return '${field['label']} is required';
                                      }
                                      return null;
                                    },
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Neumorphic(
                                  style: LuvNeu.card(
                                    radius: BorderRadius.circular(16),
                                    borderColor: AppColorV2.lpBlueBrand
                                        .withOpacity(0.06),
                                    borderWidth: 0.8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: fieldWidget,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Visibility(
                            visible:
                                MediaQuery.of(context).viewInsets.bottom == 0,
                            child: LuvNeuPress.rect(
                              radius: BorderRadius.circular(16),
                              background: AppColorV2.lpBlueBrand,
                              borderColor: AppColorV2.lpBlueBrand.withOpacity(
                                0.12,
                              ),
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  _verifyAccount();
                                }
                              },
                              child: SizedBox(
                                height: 54,
                                child: Center(
                                  child: DefaultText(
                                    text: "Proceed",
                                    color: Colors.white,
                                    style: AppTextStyle.h3_semibold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        spacing(height: 20),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(
          fontSize: 14,
          text: label,
          color: AppColorV2.primaryTextColor,
        ),
        const SizedBox(height: 8),
        child,
      ],
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
