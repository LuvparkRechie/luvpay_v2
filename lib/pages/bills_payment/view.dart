import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/otp_field/index.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/spacing.dart';
import '../../functions/functions.dart';
import '../biller_screen/biller_screen.dart';
import '../billers/utils/ticketclipper.dart';
import 'controller.dart';

class BillsPayment extends GetView<BillsPaymentController> {
  const BillsPayment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      appBarTitle: "Pay Bill",
      enableToolBar: true,
      scaffoldBody: SafeArea(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 20),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBillerCard(),

                  Visibility(
                    visible: controller.arguments["biller_address"] != "",
                    child: DefaultText(
                      text: controller.arguments["biller_address"],
                      fontSize: 14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 20),
                  buildWalletBalance(),
                  spacing(height: 30),
                  DefaultText(
                    text: "Bill Account Number",
                    style: AppTextStyle.h3,
                  ),
                  CustomTextField(
                    controller: controller.accNo,
                    hintText: 'Enter bill account number',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      UpperCaseTextFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Account number is required";
                      } else if (value.length < 5) {
                        return "Account number must be at least 5 digits";
                      } else if (value.length > 15) {
                        return "Account number must not exceed 15 digits";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14),

                  DefaultText(text: "Account Name", style: AppTextStyle.h3),
                  CustomTextField(
                    controller: controller.accName,
                    hintText: "Enter account name",
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final filtered = newValue.text
                            .toUpperCase()
                            .replaceAll(RegExp(r'[^A-Z\s]'), '')
                            .replaceAll(RegExp(r'\s+'), ' ');

                        return TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                            offset: filtered.length,
                          ),
                        );
                      }),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "account name is required";
                      }
                      if (value.startsWith(' ') || value.endsWith(' ')) {
                        return "account name cannot start or end with a space";
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14),
                  DefaultText(text: "Bill Number", style: AppTextStyle.h3),
                  CustomTextField(
                    controller: controller.billNo,
                    hintText: "Enter bill number",
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final filtered = newValue.text.toUpperCase().replaceAll(
                          RegExp(r'[^A-Z0-9]'),
                          '',
                        );

                        return TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                            offset: filtered.length,
                          ),
                        );
                      }),
                    ],
                  ),

                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DefaultText(text: "Amount", style: AppTextStyle.h3),
                      Visibility(
                        visible:
                            controller.arguments["service_fee"].toString() !=
                                "0" &&
                            controller.arguments["service_fee"].toString() !=
                                "",
                        child: DefaultText(
                          text:
                              "+${controller.arguments["service_fee"].toString()} Service Fee",
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  CustomTextField(
                    controller: controller.billAmount,
                    hintText: "Enter amount",
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      AutoDecimalInputFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Amount is required";
                      }
                      if ((value.startsWith(' ') ||
                          value.endsWith(' ') ||
                          value.endsWith('-') ||
                          value.endsWith('.'))) {
                        return "Amount cannot start or end with a space";
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: 30),
                  CustomButton(
                    text: "Proceed",
                    onPressed: () async {
                      if (controller.formKey.currentState?.validate() ??
                          false) {
                        Map<String, dynamic> data =
                            await Authentication().getEncryptedKeys();

                        final uData = await Authentication().getUserData2();
                        Map<String, String> requestParam = {
                          "mobile_no": uData["mobile_no".toString()].toString(),
                          "pwd": data["pwd"],
                        };
                        CustomDialogStack.showLoading(Get.context!);
                        DateTime timeNow = await Functions.getTimeNow();
                        Get.back();

                        Functions().requestOtp(requestParam, (objData) async {
                          DateTime timeExp = DateFormat(
                            "yyyy-MM-dd hh:mm:ss a",
                          ).parse(objData["otp_exp_dt"].toString());
                          DateTime otpExpiry = DateTime(
                            timeExp.year,
                            timeExp.month,
                            timeExp.day,
                            timeExp.hour,
                            timeExp.minute,
                            timeExp.millisecond,
                          );

                          Duration difference = otpExpiry.difference(timeNow);

                          if (objData["success"] == "Y" ||
                              objData["status"] == "PENDING") {
                            Map<String, String> putParam = {
                              "mobile_no": uData["mobile_no"].toString(),
                              "otp": objData["otp"].toString(),
                            };

                            Object args = {
                              "time_duration": difference,
                              "mobile_no":
                                  uData["mobile_no".toString()].toString(),
                              "req_otp_param": requestParam,
                              "verify_param": putParam,
                              "callback": (otp) async {
                                if (otp != null) {
                                  controller.getBillerKey();
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
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillerCard() {
    return Row(
      children: [
        Icon(Iconsax.receipt_text, color: AppColorV2.lpBlueBrand, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            _capitalize(controller.arguments["biller_name"]),
            style: TextStyle(
              color: AppColorV2.lpBlueBrand,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget buildWalletBalance() {
    return GetBuilder<BillsPaymentController>(
      builder: (c) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultText(text: "luvpay Balance", style: AppTextStyle.h3),
            spacing(height: 14),
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColorV2.lpBlueBrand.withAlpha(50)),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/booking_wallet_bg.png"),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Symbols.wallet, color: AppColorV2.background),
                  Container(width: 10),
                  Expanded(
                    child: DefaultText(
                      color: AppColorV2.background,
                      text: toCurrencyString(c.walletBalance.toString()),
                      style: AppTextStyle.body1,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

class PaymentTicket extends GetView<BillsPaymentController> {
  final Map<String, String> ticketParam;
  final dynamic args;
  const PaymentTicket(this.args, {super.key, required this.ticketParam});

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: false,
      canPop: false,
      enableCustom: false,

      scaffoldBody: SafeArea(
        child: Container(
          color: AppColorV2.lpBlueBrand,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  DownloadTicket(isDownload: false, ticketParam: ticketParam),
                  Positioned(
                    right: 15,
                    top: 20,
                    child: IconButton(
                      onPressed: () {
                        controller.saveTicket(
                          DownloadTicket(
                            isDownload: false,
                            ticketParam: ticketParam,
                          ),
                        );
                      },
                      icon: Icon(
                        LucideIcons.download,
                        color: AppColorV2.lpBlueBrand.withValues(alpha: .8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    CustomButton(
                      btnColor: Colors.white,
                      text: "Close",
                      textColor: AppColorV2.lpBlueBrand,
                      onPressed: () {
                        int backCount = (args["type"] == "use_pass") ? 5 : 4;

                        if (args["fav"] == "use_fav") {
                          backCount = 4;
                        }

                        for (int i = 0; i < backCount; i++) {
                          Get.back();
                        }
                      },
                    ),
                    spacing(height: 10),
                    TextButton(
                      onPressed: controller.addFavorites,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          DefaultText(
                            text: "Add to favorite",
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadTicket extends GetView<BillsPaymentController> {
  final bool isDownload;
  final Map<String, String> ticketParam;
  const DownloadTicket({
    super.key,
    required this.isDownload,
    required this.ticketParam,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          child: TicketClipper(
            clipper: RoundedEdgeClipper(edge: Edge.vertical, depth: 15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 50),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 50,
                        color: AppColorV2.lpBlueBrand,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultText(
                              text: "Congrats",
                              fontSize: 20,
                              style: AppTextStyle.h2,
                              color: AppColorV2.lpBlueBrand,
                            ),
                            SizedBox(height: 5),
                            DefaultText(
                              text: "Successful transaction",
                              color: AppColorV2.bodyTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          ticketParam.entries.map((e) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    DefaultText(
                                      text: "${e.key} :",
                                      style: AppTextStyle.paragraph1,
                                      maxLines: 1,
                                    ),
                                    DefaultText(
                                      minFontSize: 14,
                                      text: e.value.toString(),
                                      maxLines: 1,
                                      style: AppTextStyle.h3,
                                      color: AppColorV2.bodyTextColor,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: PrettyQrView(
                            decoration: const PrettyQrDecoration(
                              background: Colors.white,
                              image: PrettyQrDecorationImage(
                                image: AssetImage("assets/images/logo.png"),
                              ),
                            ),
                            qrImage: QrImage(
                              QrCode.fromData(
                                data: ticketParam["ref_no"].toString(),
                                errorCorrectLevel: QrErrorCorrectLevel.H,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [_buildRefNoSection()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefNoSection() {
    final refEntry = ticketParam.entries.firstWhere(
      (e) => e.key.toLowerCase().contains("ref no"),
      orElse: () => MapEntry('', ''),
    );

    return Column(
      children: [
        DefaultText(
          style: AppTextStyle.h3,
          text: refEntry.value,
          fontWeight: FontWeight.w700,
        ),
        DefaultText(
          style: AppTextStyle.paragraph2,
          text: refEntry.key.replaceAll('.', ''),
        ),
      ],
    );
  }
}
