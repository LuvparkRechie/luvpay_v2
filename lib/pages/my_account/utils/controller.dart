import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';

import '../../../auth/authentication.dart';
import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/variables.dart';
import '../../../functions/functions.dart';
import '../../../http/api_keys.dart';
import 'success/update_success.dart';

class UpdateProfileController extends GetxController {
  UpdateProfileController();

  final parameters = Get.arguments;
  final GlobalKey<FormState> formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyStep2 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyStep3 = GlobalKey<FormState>();
  final FocusNode focusNode = FocusNode();
  PageController pageController = PageController();
  RxBool isLoading = true.obs;
  RxInt currentPage = 0.obs;
  late DateTime dateTime;
  DateTime? selectedDate;
  DateTime? minimumDate;
  String parsedDate(String date) {
    final DateFormat displayFormater = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final DateFormat serverFormater = DateFormat('yyyy-MM-dd');
    final DateTime displayDate = displayFormater.parse(date);
    final String formatted = serverFormater.format(displayDate);
    return formatted;
  }

  //Step 1 variable
  RxList suffixes = [].obs;
  RxList civilData = [].obs;
  RxString gender = "M".obs;

  var selectedSuffix = Rx<String?>(null);
  var selectedCivil = Rx<String?>(null);

  TextEditingController firstName = TextEditingController();
  TextEditingController middleName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController bday = TextEditingController();

  //step 2 variable
  RxList regionData = [].obs;
  RxList provinceData = [].obs;
  RxList cityData = [].obs;
  RxList brgyData = [].obs;
  var selectedRegion = Rx<String?>(null);
  var selectedProvince = Rx<String?>(null);
  var selectedCity = Rx<String?>(null);
  var selectedBrgy = Rx<String?>(null);

  TextEditingController address1 = TextEditingController();
  TextEditingController address2 = TextEditingController();
  TextEditingController zipCode = TextEditingController();

  //Step 3
  RxList questionData = [].obs;

  RxString question1 = "Tap to choose a security question".obs;
  RxString question2 = "Tap to choose a security question".obs;
  RxString question3 = "Tap to choose a security question".obs;

  RxInt seq1 = 0.obs;
  RxInt seq2 = 0.obs;
  RxInt seq3 = 0.obs;

  TextEditingController answer1 = TextEditingController();
  TextEditingController answer2 = TextEditingController();
  TextEditingController answer3 = TextEditingController();

  var obscureTextAnswer1 = true.obs;
  var obscureTextAnswer2 = true.obs;
  var obscureTextAnswer3 = true.obs;

  RxInt currentIndex = 0.obs;

  final List<Widget> pages = [
    Container(key: ValueKey(1), child: Stepp1()),
    Container(key: ValueKey(2), child: Stepp2()),
    Container(key: ValueKey(3), child: Stepp3()),
  ];

  @override
  // ignore: unnecessary_overrides
  void onInit() {
    pageController = PageController();
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (dynamic datas in parameters) {
        regionData.add({
          "text": datas["region_name"],
          "value": datas["region_id"],
        });
      }
      for (dynamic item in Variables.civilStatusData) {
        civilData.add({
          "text": toProperCase(item["text"]),
          "value": item["value"],
        });
      }
      getSuffixes();
    });
  }

  @override
  void onClose() {
    super.onClose();
    pageController.dispose();
    focusNode.dispose();
  }

  String toProperCase(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  Future<void> getUserDataFields() async {
    final userData = await Authentication().getUserData2();

    String getQuestion(id) {
      String quest =
          questionData.where((obj) {
            return obj["secq_id"] == id;
          }).toList()[0]["question"];
      return quest;
    }

    firstName.text =
        userData["first_name"] != null &&
                userData["first_name"].toString().isNotEmpty
            ? userData["first_name"].toString()
            : "";

    middleName.text =
        userData["middle_name"] != null &&
                userData["middle_name"].toString().isNotEmpty
            ? userData["middle_name"].toString().trim()
            : "";
    lastName.text =
        userData["last_name"] != null &&
                userData["last_name"].toString().isNotEmpty
            ? userData["last_name"].toString().trim()
            : "";
    email.text =
        userData["email"] != null && userData["email"].toString().isNotEmpty
            ? userData["email"].toString().trim()
            : "";
    bday.text =
        userData["birthday"] != null &&
                userData["birthday"].toString().isNotEmpty
            ? userData["birthday"].toString().split("T")[0].trim()
            : "";
    if (userData["civil_status"] != null) {
      selectedCivil.value =
          civilData.where((objData) {
            return objData["value"].toString().toLowerCase() ==
                userData["civil_status"].toString().toLowerCase();
          }).toList()[0]["value"];
    }
    if (userData["region_id"] != 0) {
      selectedRegion.value = userData["region_id"].toString();
      selectedProvince.value = userData["province_id"].toString();
      selectedCity.value = userData["city_id"].toString();
      selectedBrgy.value = userData["brgy_id"].toString();
      zipCode.text =
          userData["zip_code"] == null ? "" : userData["zip_code"].toString();
      seq1.value = userData["secq_id1"];
      seq2.value = userData["secq_id2"];
      seq3.value = userData["secq_id3"];
      answer1.text = userData["seca1"];
      answer2.text = userData["seca2"];
      answer3.text = userData["seca3"];
      question1.value = getQuestion(seq1.value);
      question2.value = getQuestion(seq2.value);
      question3.value = getQuestion(seq3.value);

      CustomDialogStack.showLoading(Get.context!);
      executeCodeAddress(
        "${ApiKeys.getProvince}?p_region_id=${userData['region_id']}",
        1,
        (data) {
          if (data.isNotEmpty) {
            provinceData.value = data;
          }
          executeCodeAddress(
            "${ApiKeys.getCity}?p_province_id=${userData['province_id']}",
            2,
            (data) {
              if (data.isNotEmpty) {
                cityData.value = data;
              }
              executeCodeAddress(
                "${ApiKeys.getBrgy}?p_city_id=${userData['city_id']}",
                3,
                (data) {
                  if (data.isNotEmpty) {
                    brgyData.value = data;
                  }
                },
              );
            },
          );
        },
      );
    }
  }

  void onToggleShowAnswer1(bool isShow) {
    obscureTextAnswer1.value = isShow;
    update();
  }

  void onToggleShowAnswer2(bool isShow) {
    obscureTextAnswer2.value = isShow;
    update();
  }

  void onToggleShowAnswer3(bool isShow) {
    obscureTextAnswer3.value = isShow;
    update();
  }

  Future<void> executeCodeAddress(String api, int index, Function cb) async {
    final response = await HttpRequestApi(api: api).get();

    if (response == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response["items"].isNotEmpty) {
      cb(response["items"]);
      if (index == 3) {
        Get.back();
      }
      return;
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime timeNow = await Functions.getTimeNow();
    DateTime? datePicker = await showDatePicker(
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      context: context,
      initialDate: timeNow,
      firstDate: DateTime(timeNow.year - 80),
      lastDate: timeNow,
      initialDatePickerMode: DatePickerMode.day,
    );

    if (datePicker != null) {
      selectedDate = datePicker;

      final today = timeNow;
      final age =
          today.year -
          datePicker.year -
          (today.month > datePicker.month ||
                  (today.month == datePicker.month &&
                      today.day >= datePicker.day)
              ? 0
              : 1);

      if (age < 12) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Age Restriction'),
              content: const Text(
                'You must be at least 12 years old to proceed.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        dateTime = datePicker;
        bday.text = DateFormat('yyyy-MM-dd').format(datePicker);
      }
    }
  }

  void getSuffixes() {
    suffixes.value = [
      {"text": "Jr.", "value": "jr"},
      {"text": "Sr.", "value": "sr"},
      {"text": "II", "value": "II"},
      {"text": "III", "value": "III"},
    ];
    getQuestionData();
  }

  void getQuestionData() {
    HttpRequestApi(api: ApiKeys.getSecDropdown).get().then((returnData) async {
      isLoading.value = false;
      questionData.value = [];
      if (returnData == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
      }
      if (returnData == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        questionData.value = returnData["items"];
        getUserDataFields();
      }
    });
  }

  void getProvinceData(id) async {
    selectedProvince.value = null;
    selectedCity.value = null;
    selectedBrgy.value = null;
    provinceData.value = [];
    cityData.value = [];
    brgyData.value = [];
    CustomDialogStack.showLoading(Get.context!);
    var returnData =
        await HttpRequestApi(
          api: "${ApiKeys.getProvince}?p_region_id=$id",
        ).get();
    Get.back();
    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData["items"].isNotEmpty) {
      provinceData.value = returnData["items"];
      update();
      return;
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  void getCityData(id) async {
    selectedCity.value = null;
    selectedBrgy.value = null;
    cityData.value = [];
    brgyData.value = [];
    CustomDialogStack.showLoading(Get.context!);
    var returnData =
        await HttpRequestApi(api: "${ApiKeys.getCity}?p_province_id=$id").get();
    Get.back();
    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData["items"].isNotEmpty) {
      cityData.value = returnData["items"];
      update();
      return;
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  void getBrgyData(id) async {
    selectedBrgy.value = null;
    brgyData.value = [];
    CustomDialogStack.showLoading(Get.context!);
    var returnData =
        await HttpRequestApi(api: "${ApiKeys.getBrgy}?p_city_id=$id").get();
    Get.back();
    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (returnData["items"].isNotEmpty) {
      brgyData.value = returnData["items"];
      update();
      return;
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
    }
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    update();
  }

  void nextPage() {
    if (currentIndex.value == 0 && formKeyStep1.currentState!.validate()) {
      currentIndex.value++;
    } else if (currentIndex.value == 1 &&
        formKeyStep2.currentState!.validate()) {
      currentIndex.value++;
    } else if (currentIndex.value == 2 &&
        formKeyStep3.currentState!.validate()) {
      onSubmit();
    }
  }

  void previousPage() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
  }

  void onUserInteract() {
    switch (currentPage.value) {
      case 0:
        if (formKeyStep1.currentState!.validate()) {}
        break;
      case 1:
        if (formKeyStep2.currentState!.validate()) {}
        break;
      case 2:
        if (formKeyStep3.currentState!.validate()) {}
        break;
    }
  }

  void onSubmit() async {
    final data = await Authentication().getUserData2();
    CustomDialogStack.showLoading(Get.context!);
    Map<String, dynamic> submitParam = {
      "mobile_no": data["mobile_no"].toString(),
      "last_name": lastName.text,
      "first_name": firstName.text,
      "middle_name": middleName.text,
      "birthday": bday.text.toString().split("T")[0],
      "gender": gender.value,
      "civil_status": selectedCivil.value,
      "address1": address1.text,
      "address2": address2.text,
      "brgy_id": selectedBrgy.value.toString(),
      "city_id": selectedCity.value.toString(),
      "province_id": selectedProvince.value.toString(),
      "region_id": selectedRegion.value.toString(),
      "zip_code": zipCode.text,
      "email": email.text,
      "secq_id1": seq1.toString(),
      "secq_id2": seq2.toString(),
      "secq_id3": seq3.toString(),
      "seca1": answer1.text,
      "seca2": answer2.text,
      "seca3": answer3.text,
      "image_base64": "",
    };

    HttpRequestApi(
      api: ApiKeys.putUpdateUserProf,
      parameters: submitParam,
    ).putBody().then((res) async {
      Get.back();
      if (res == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
      }
      if (res == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      } else {
        if (res["success"] == "Y") {
          Get.to(const UpdateInfoSuccess());
        } else {
          CustomDialogStack.showError(Get.context!, "luvpark", res["msg"], () {
            Get.back();
          });

          return;
        }
      }
    });
  }

  void showBottomSheet(Widget child) {
    Get.bottomSheet(child, isScrollControlled: true);
  }

  List<dynamic> getDropdownData() {
    var data = questionData;
    int id1 = seq1.value;
    int id2 = seq2.value;
    int id3 = seq3.value;
    List<int> selectedIds = [id1, id2, id3];
    List filteredObjects =
        data
            .where((object) => !selectedIds.contains(object["secq_id"]))
            .toList();
    return filteredObjects;
  }

  bool isAgeValid(String input) {
    try {
      final date = DateFormat('yyyy-MM-dd').parseStrict(input);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age >= 12;
    } catch (_) {
      return false;
    }
  }

  void closePage() async {
    CustomDialogStack.showLoading(Get.context!);
    await Future.delayed(Duration(seconds: 2), () {
      Get.back();
    });
    Get.back();
  }
}

class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 4 || i == 6) {
        buffer.write('-');
        if (i < selectionIndex) selectionIndex++;
      }
      buffer.write(digitsOnly[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
