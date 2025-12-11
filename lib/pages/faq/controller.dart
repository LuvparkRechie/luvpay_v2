import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/http/http_request.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../http/api_keys.dart';

class FaqPageController extends GetxController {
  RxList<Map<String, dynamic>> faqsData = <Map<String, dynamic>>[].obs;
  RxBool isLoadingPage = true.obs;
  RxBool isNetConn = true.obs;
  RxSet<int> expandedIndexes = <int>{}.obs;
  final RxString searchText = ''.obs;
  final TextEditingController searchController = TextEditingController();

  /// Each item: {'index': originalIndex, 'faq': Map<String, dynamic>}
  RxList<Map<String, dynamic>> filteredFaqs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
    getFaq();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> refresher() async {
    isNetConn.value = true;
    getFaq();
  }

  Future<void> getFaq() async {
    isLoadingPage.value = true;
    var returnData = await HttpRequestApi(api: ApiKeys.getFAQ).get();

    if (returnData == "No Internet") {
      isNetConn.value = false;
      isLoadingPage.value = false;
      return;
    }
    if (returnData == null) {
      isNetConn.value = true;
      isLoadingPage.value = false;
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }

    faqsData.value = List<Map<String, dynamic>>.from(returnData["items"]);

    // Fill filtered list with original indexes
    filteredFaqs.assignAll(
      faqsData.asMap().entries.map((e) {
        return {'index': e.key, 'faq': e.value};
      }).toList(),
    );

    isLoadingPage.value = false;
  }

  Future<void> getFaqAnswers(String id, int originalIndex) async {
    CustomDialogStack.showLoading(Get.context!);
    var returnData =
        await HttpRequestApi(api: '${ApiKeys.getFAQsAnswer}?faq_id=$id').get();
    Get.back();
    if (returnData == "No Internet") {
      isNetConn.value = false;
      isLoadingPage.value = false;
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData == null) {
      isNetConn.value = true;
      isLoadingPage.value = false;
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }

    if (returnData["items"].isNotEmpty) {
      faqsData[originalIndex]['answers'] = returnData["items"];
      expandedIndexes.clear();
      expandedIndexes.add(originalIndex);
    } else {
      CustomDialogStack.showError(Get.context!, "luvpark", "No data found", () {
        Get.back();
      });
    }
  }

  void onExpand(
    bool isExpanded,
    int originalIndex,
    Map<String, dynamic> item,
  ) async {
    if (isExpanded) {
      if (!expandedIndexes.contains(originalIndex)) {
        await getFaqAnswers(item['faq_id'].toString(), originalIndex);
      }
    } else {
      expandedIndexes.clear();
    }
    update();
  }

  void filteredFaq(String query) {
    if (query.isEmpty) {
      filteredFaqs.assignAll(
        faqsData.asMap().entries.map((e) {
          return {'index': e.key, 'faq': e.value};
        }).toList(),
      );
    } else {
      filteredFaqs.assignAll(
        faqsData
            .asMap()
            .entries
            .where(
              (entry) =>
                  entry.value['faq_text'] != null &&
                  entry.value['faq_text'].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .map((entry) => {'index': entry.key, 'faq': entry.value})
            .toList(),
      );
    }
  }
}
