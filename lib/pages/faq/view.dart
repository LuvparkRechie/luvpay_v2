import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/pages/faq/index.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/no_data_found.dart';
import '../../custom_widgets/no_internet.dart';

class FaqPage extends GetView<FaqPageController> {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomScaffoldV2(
        enableToolBar: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.height / 3.4,
          ),
          child: Container(
            alignment: Alignment.topLeft,
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 3.4,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fitWidth,
                image: AssetImage("assets/images/faq_bg.png"),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.back,
                              color: AppColorV2.background,
                            ),
                            DefaultText(
                              color: AppColorV2.background,
                              text: "Back",
                              style: AppTextStyle.h3_semibold,
                              height: 20 / 16,
                            ),
                          ],
                        ),
                      ),
                      DefaultText(
                        text: "FAQs",
                        style: AppTextStyle.h3,
                        color: AppColorV2.background,
                        maxLines: 1,
                      ),
                      SizedBox(width: 80),
                    ],
                  ),
                  SizedBox(height: 47),
                  Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: DefaultText(
                      text: "How can we help you?",
                      style: AppTextStyle.h3_f22,
                      color: AppColorV2.background,
                    ),
                  ),
                  SizedBox(height: 14),
                  faqs(controller.searchController),
                ],
              ),
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        scaffoldBody:
            controller.isLoadingPage.value
                ? const LoadingCard()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child:
                            !controller.isNetConn.value
                                ? NoInternetConnected(
                                  onTap: controller.refresher,
                                )
                                : controller.faqsData.isEmpty ||
                                    controller.filteredFaqs.isEmpty
                                ? NoDataFound()
                                : ScrollConfiguration(
                                  behavior: ScrollBehavior().copyWith(
                                    overscroll: false,
                                  ),
                                  child: StretchingOverscrollIndicator(
                                    axisDirection: AxisDirection.down,
                                    child: ListView.separated(
                                      itemCount: controller.filteredFaqs.length,

                                      separatorBuilder:
                                          (context, index) => Divider(
                                            color: Colors.grey[800],
                                            height: 1,
                                          ),
                                      itemBuilder: (context, index) {
                                        var faqWrapper =
                                            controller.filteredFaqs[index];
                                        int originalIndex = faqWrapper['index'];
                                        var faq = faqWrapper['faq'];

                                        return ExpansionTile(
                                          title: DefaultText(
                                            maxLines: 4,
                                            text:
                                                faq['faq_text'] ??
                                                'No text available',
                                            color: Colors.black,
                                            style: AppTextStyle.h3,
                                          ),
                                          trailing: Icon(
                                            controller.expandedIndexes.contains(
                                                  originalIndex,
                                                )
                                                ? Iconsax.minus
                                                : Iconsax.add,
                                            color: AppColorV2.lpBlueBrand,
                                          ),
                                          onExpansionChanged: (onExpand) async {
                                            controller.onExpand(
                                              onExpand,
                                              originalIndex,
                                              faq,
                                            );
                                          },
                                          children: [
                                            if (controller.expandedIndexes
                                                .contains(originalIndex))
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      15,
                                                      0,
                                                      15,
                                                      15,
                                                    ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (faq['answers'] ==
                                                            null ||
                                                        (faq['answers'] as List)
                                                            .isEmpty)
                                                      const DefaultText(
                                                        maxLines: 8,
                                                        text:
                                                            'No answers available',
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      )
                                                    else
                                                      ...((faq['answers']
                                                              as List)
                                                          .asMap()
                                                          .entries
                                                          .map((entry) {
                                                            int answerIndex =
                                                                entry.key;
                                                            var answer =
                                                                entry.value;
                                                            return DefaultText(
                                                              maxLines: 8,
                                                              text:
                                                                  '${answerIndex + 1}. ${answer['faq_ans_text'] ?? 'No answer available'}',
                                                            );
                                                          })
                                                          .toList()),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      'Updated on: ${faq['updated_on'] != null ? DateFormat('MMMM d, y').format(DateTime.parse(faq['updated_on'])) : 'N/A'}',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  TextField faqs(TextEditingController searchFaqController) {
    return TextField(
      controller: controller.searchController,
      cursorColor: AppColorV2.background,
      autofocus: false,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
        color: AppColorV2.background,
      ),
      maxLines: 1,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 10),
        hintText: "Ask a question...",
        filled: true,
        fillColor: const Color.fromRGBO(0, 0, 0, 0),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(54),
          borderSide: BorderSide(color: AppColorV2.background),
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(54),
          borderSide: BorderSide(width: 1, color: AppColorV2.background),
        ),
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 15),
            Icon(LucideIcons.search, color: AppColorV2.background),
            Container(width: 10),
          ],
        ),
        suffixIcon: Obx(() {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: controller.searchText.value.isNotEmpty,
                child: InkWell(
                  onTap: () {
                    controller.searchController.clear();
                    controller.searchText.value = '';
                    controller.filteredFaq('');
                  },

                  child: Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorV2.background,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      color: AppColorV2.lpBlueBrand,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
          color: AppColorV2.background,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
          color: AppColorV2.background,
        ),
      ),
      onChanged: (value) {
        controller.searchText.value = value;
        controller.filteredFaq(value);
      },
    );
  }
}
