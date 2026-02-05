// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/luvpay/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/luvpay_loading.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/no_data_found.dart';
import '../../custom_widgets/no_internet.dart';
import '../../functions/functions.dart';
import '../routes/routes.dart';
import 'controller.dart';
import 'utils/allbillers.dart';

class Billers extends StatelessWidget {
  const Billers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BillersController controller = Get.put(BillersController());
    return CustomScaffoldV2(
      appBarTitle: "Billers",
      enableToolBar: true,

      scaffoldBody: Obx(
        () =>
            !controller.isNetConn.value
                ? NoInternetConnected(onTap: controller.loadFavoritesAndBillers)
                : RefreshIndicator(
                  onRefresh: () async {
                    await controller.loadFavoritesAndBillers();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultText(
                        style: AppTextStyle.h3(context),
                        text: "Pay Bills",
                      ),
                      SizedBox(height: 14),
                      InkWell(
                        onTap: () {
                          controller.getBillers((isSuccess) async {
                            if (isSuccess) {
                              final result = await Get.to(
                                () => Allbillers(),
                                arguments: {'source': 'pay'},
                              );
                              if (result != null) {
                                Get.back(result: true);
                              }
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              width: 2,
                              color: AppColorV2.lpBlueBrand,
                            ),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.payment_outlined,
                                    color: AppColorV2.lpBlueBrand,
                                  ),
                                  SizedBox(width: 10),
                                  DefaultText(
                                    text: "Select Biller",
                                    color: AppColorV2.lpBlueBrand,
                                  ),
                                ],
                              ),
                              Icon(
                                CupertinoIcons.forward,
                                color: AppColorV2.lpBlueBrand,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DefaultText(
                            style: AppTextStyle.h3(context),
                            text: "Favorites",
                          ),
                          controller.favBillers.isEmpty
                              ? SizedBox.shrink()
                              : Container(
                                width: 150,
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColorV2.pastelBlueAccent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(30),
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Get.bottomSheet(
                                      isDismissible: true,
                                      CustomSort(
                                        onSortSelected: (String sortOption) {
                                          controller.selectedSortOption.value =
                                              sortOption;
                                          controller.sortFavorites();
                                          Get.back();
                                        },
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      DefaultText(
                                        color: AppColorV2.lpBlueBrand,
                                        fontSize: 10,
                                        text: "Sort",
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.sort,
                                        color: AppColorV2.lpBlueBrand,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                      Expanded(
                        child:
                            controller.isLoading.value
                                ? const LoadingCard()
                                : controller.favBillers.isEmpty
                                ? NoDataFound()
                                : Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColorV2.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: BouncingScrollPhysics(),
                                      itemCount: controller.favBillers.length,
                                      itemBuilder: (context, index) {
                                        String accountNo =
                                            "${controller.favBillers[index]["account_no"]}";

                                        String maskedAccountNo =
                                            accountNo.length <= 3
                                                ? accountNo
                                                : accountNo.replaceAll(
                                                  RegExp(r'.(?=.{3})'),
                                                  '*',
                                                );

                                        return GestureDetector(
                                          onTap: () async {
                                            Map<String, String> billerData = {
                                              'biller_name':
                                                  controller
                                                      .favBillers[index]["biller_name"]
                                                      .toString(),
                                              'biller_id':
                                                  controller
                                                      .favBillers[index]["biller_id"]
                                                      .toString(),
                                              'biller_code':
                                                  controller
                                                      .favBillers[index]["biller_code"]
                                                      .toString(),
                                              'biller_address':
                                                  controller
                                                      .favBillers[index]["biller_address"]
                                                      .toString(),
                                              'service_fee':
                                                  controller
                                                      .favBillers[index]["service_fee"]
                                                      .toString(),
                                              'accountno':
                                                  controller
                                                      .favBillers[index]["account_no"]
                                                      .toString(),
                                              'full_url':
                                                  controller
                                                      .favBillers[index]["full_url"]
                                                      .toString(),
                                              "account_name":
                                                  controller
                                                      .favBillers[index]["account_name"],
                                              "type": "use_fav",
                                            };

                                            final res = await Get.toNamed(
                                              Routes.billsPayment,
                                              arguments: billerData,
                                            );

                                            if (res != null) {
                                              Get.back(result: true);
                                            }
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(bottom: 10),
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade100,
                                              ),
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(30),
                                                bottomLeft: Radius.circular(30),
                                                bottomRight: Radius.circular(
                                                  10,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SingleChildScrollView(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      DefaultText(
                                                        fontSize: 14,
                                                        color:
                                                            AppColorV2
                                                                .primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        minFontSize: 10,
                                                        text:
                                                            "${controller.favBillers[index]["biller_name"]}",
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      LucideIcons.mapPin,
                                                      size: 15,
                                                      color:
                                                          AppColorV2
                                                              .bodyTextColor,
                                                    ),
                                                    Expanded(
                                                      child: DefaultText(
                                                        fontSize: 10,
                                                        text:
                                                            controller.favBillers[index]["biller_address"] !=
                                                                    null
                                                                ? "${controller.favBillers[index]["biller_address"]}"
                                                                : "Address not specified",
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 5),
                                                Visibility(
                                                  visible:
                                                      controller
                                                          .favBillers[index]['account_name'] !=
                                                      null,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      DefaultText(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        text:
                                                            controller
                                                                .favBillers[index]['account_name'] ??
                                                            '',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      SizedBox(height: 5),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    DefaultText(
                                                      color:
                                                          AppColorV2
                                                              .bodyTextColor,
                                                      fontSize: 14,
                                                      text: maskedAccountNo,
                                                      textAlign: TextAlign.end,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        controller
                                                            .deleteFavoriteBiller(
                                                              int.parse(
                                                                controller
                                                                    .favBillers[index]['user_biller_id']
                                                                    .toString(),
                                                              ),
                                                            );
                                                      },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 5,
                                                              horizontal: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color:
                                                                AppColorV2
                                                                    .incorrectState,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              size: 16,
                                                              Iconsax
                                                                  .close_circle,
                                                              color:
                                                                  AppColorV2
                                                                      .incorrectState,
                                                            ),
                                                            SizedBox(width: 5),
                                                            DefaultText(
                                                              color:
                                                                  AppColorV2
                                                                      .incorrectState,
                                                              fontSize: 12,
                                                              text: "delete",
                                                              textAlign:
                                                                  TextAlign.end,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder:
                                          (context, index) =>
                                              SizedBox(height: 5),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class CustomSort extends StatefulWidget {
  final Function(String) onSortSelected;

  const CustomSort({Key? key, required this.onSortSelected}) : super(key: key);

  @override
  State<CustomSort> createState() => _CustomSortState();
}

class _CustomSortState extends State<CustomSort> {
  @override
  Widget build(BuildContext context) {
    final ct = Get.put(BillersController());

    final List<Map<String, dynamic>> sortOptions = [
      {'text': 'Nickname', 'icon': Icons.account_circle_rounded},
      {'text': 'Biller Name', 'icon': Icons.credit_card},
      {'text': 'Biller Address', 'icon': Icons.location_on},
    ];

    return Wrap(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DefaultText(text: "Sort by ", fontWeight: FontWeight.w600),
                  DefaultText(
                    text: "${ct.selectedSortOption}",
                    color: AppColorV2.lpBlueBrand,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(width: 5),
                  DefaultText(
                    color: AppColorV2.lpBlueBrand,
                    fontWeight: FontWeight.w600,
                    text: ct.isAscending.value ? "(A-Z)" : "(Z-A)",
                  ),
                ],
              ),
              Divider(color: AppColorV2.bodyTextColor),
              for (var option in sortOptions)
                InkWell(
                  onTap: () {
                    widget.onSortSelected(option['text']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option['icon'],
                            size: 25,
                            color: AppColorV2.lpBlueBrand,
                          ),
                          SizedBox(width: 10),
                          Expanded(child: DefaultText(text: option['text'])),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Close',
                onPressed: () {
                  Functions.popPage(1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
