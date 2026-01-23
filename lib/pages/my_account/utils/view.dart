import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';

import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/custom_textfield.dart';
import '../../../custom_widgets/loading.dart';
import '../../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../../custom_widgets/luvpay/luv_neumorphic.dart';
import '../../../custom_widgets/spacing.dart';
import '../../../custom_widgets/variables.dart';

class UpdateProfile extends GetView<UpdateProfileController> {
  const UpdateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    void close() {
      CustomDialogStack.showConfirmation(
        context,
        "Close Page",
        "Are you sure you want to close this page?",
        leftText: "No",
        rightText: "Yes",
        () {
          Get.back();
        },
        () {
          Get.back();
          Get.back();
        },
      );
    }

    return Obx(
      () =>
          controller.isLoading.value
              ? const Scaffold(body: LoadingCard())
              : CustomScaffoldV2(
                appBarTitle: "Personal Information",

                onPopInvokedWithResult: (bool didPop, dynamic result) {
                  FocusScope.of(context).requestFocus(FocusNode());
                  if (!didPop) {
                    close();
                  }
                },
                onPressedLeading: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  close();
                },
                canPop: false,
                enableToolBar: true,
                scaffoldBody: SizedBox(
                  width: double.infinity,
                  child: ScrollConfiguration(
                    behavior: ScrollBehavior().copyWith(overscroll: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: Builder(
                            builder: (context) {
                              if (controller.currentIndex.value == 0) {
                                return DefaultText(
                                  maxLines: 1,
                                  style: AppTextStyle.body1,
                                  text:
                                      "Enter accurate details to personalize your experience.",
                                );
                              } else if (controller.currentIndex.value == 1) {
                                return DefaultText(
                                  style: AppTextStyle.body1,
                                  text:
                                      "Add your full residential address for verification.",
                                );
                              } else {
                                return DefaultText(
                                  style: AppTextStyle.body1,
                                  text:
                                      "Select an answer you can easily recall but that others cannot easily guess.",
                                );
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 100),
                            transitionBuilder: (
                              Widget child,
                              Animation<double> animation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child:
                                controller.pages[controller.currentIndex.value],
                          ),
                        ),
                        if (MediaQuery.of(context).viewInsets.bottom == 0)
                          Row(
                            children: [
                              if (controller.currentIndex.value > 0)
                                Expanded(
                                  child: LuvNeuPress.rect(
                                    radius: BorderRadius.circular(16),
                                    onTap: controller.previousPage,
                                    borderColor: AppColorV2.lpBlueBrand
                                        .withOpacity(0.18),
                                    child: SizedBox(
                                      height: 52,
                                      child: Center(
                                        child: DefaultText(
                                          text: "Previous",
                                          style: AppTextStyle.body1.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                          color: AppColorV2.lpBlueBrand,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (controller.currentIndex.value > 0)
                                spacing(width: 10),
                              Expanded(
                                child: LuvNeuPress.rect(
                                  radius: BorderRadius.circular(16),
                                  onTap: controller.nextPage,
                                  background: AppColorV2.lpBlueBrand,
                                  borderColor: AppColorV2.lpBlueBrand
                                      .withOpacity(0.12),
                                  child: SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: DefaultText(
                                        text:
                                            controller.currentIndex.value == 2
                                                ? "Submit"
                                                : "Next",
                                        style: AppTextStyle.body1.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                        color: AppColorV2.background,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        spacing(height: 20),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(90),
                  child: index(),
                ),
              ),
    );
  }

  Widget index() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (index != 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  controller.currentIndex.value >= index
                                      ? AppColorV2.background
                                      : AppColorV2.background.withAlpha(50),
                            ),
                          ),
                        Container(
                          alignment: Alignment.center,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                controller.currentIndex.value > index
                                    ? AppColorV2.background
                                    : controller.currentIndex.value == index
                                    ? AppColorV2.background
                                    : AppColorV2.background.withAlpha(50),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppColorV2.lpBlueBrand,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (index != 2)
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  controller.currentIndex.value > index
                                      ? AppColorV2.background
                                      : AppColorV2.background.withAlpha(50),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return DefaultText(
                style: AppTextStyle.body1,
                text:
                    index == 0
                        ? "Profile"
                        : index == 1
                        ? "  Address"
                        : "Security",
                color:
                    controller.currentIndex.value >= index
                        ? AppColorV2.background
                        : AppColorV2.background.withAlpha(180),
              );
            }),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class NumericInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (RegExp(r'^\d*$').hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class SimpleNameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final regex = RegExp(r'^(|[a-zA-Z][a-zA-Z.-]*( [a-zA-Z.-]*)* ?)$');

    int periodCount = newValue.text.split('.').length - 1;
    int hyphenCount = newValue.text.split('-').length - 1;

    bool hasDisallowedCombination =
        newValue.text.contains('. -') ||
        newValue.text.contains('- .') ||
        newValue.text.contains(' .') ||
        newValue.text.contains('-.') ||
        newValue.text.contains('.-') ||
        newValue.text.contains('- ') ||
        newValue.text.contains(' -') ||
        newValue.text.contains('. ');

    if (newValue.text.length <= 30 &&
        regex.hasMatch(newValue.text) &&
        periodCount <= 1 &&
        hyphenCount <= 1 &&
        !hasDisallowedCombination) {
      return newValue;
    }
    return oldValue;
  }
}

class Stepp1 extends StatelessWidget {
  const Stepp1({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: SingleChildScrollView(
            child: Form(
              key: controller.formKeyStep1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20),
                  DefaultText(
                    text: "First Name",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  CustomTextField(
                    textInputAction: TextInputAction.next,

                    hintText: "e.g Juan",
                    controller: controller.firstName,
                    onChange: (value) {
                      if (value.isNotEmpty) {
                        controller.firstName.value = TextEditingValue(
                          text: Variables.capitalizeAllWord(value),
                          selection: controller.firstName.selection,
                        );
                      } else {
                        controller.firstName.value = TextEditingValue(
                          text: Variables.capitalizeAllWord(
                            value.substring(0, 30),
                          ),
                          selection: TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      SimpleNameFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "First name is required";
                      }
                      if ((value.endsWith(' ') ||
                          value.endsWith('-') ||
                          value.endsWith('.'))) {
                        return "First name cannot end with a space, hyphen, or period";
                      }
                      return null;
                    },
                  ),
                  Container(height: 15),
                  DefaultText(
                    text: "Middle Name",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  CustomTextField(
                    textInputAction: TextInputAction.next,

                    hintText: "e.g Santos (optional)",
                    controller: controller.middleName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      SimpleNameFormatter(),
                    ],
                    textCapitalization: TextCapitalization.words,
                    onChange: (inputText) {},
                    validator: (value) {
                      if (value != null &&
                          (value.endsWith(' ') ||
                              value.endsWith('-') ||
                              value.endsWith('.'))) {
                        return "Middle name cannot end with a space, hyphen, or period";
                      }
                      return null;
                    },
                  ),
                  Container(height: 15),
                  DefaultText(
                    text: "Last Name",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  CustomTextField(
                    textInputAction: TextInputAction.next,

                    hintText: "e.g dela Cruz",
                    controller: controller.lastName,
                    textCapitalization: TextCapitalization.words,
                    onChange: (value) {
                      if (value.isNotEmpty) {
                        controller.lastName.value = TextEditingValue(
                          text: Variables.capitalizeAllWord(value),
                          selection: controller.lastName.selection,
                        );
                      } else {
                        controller.lastName.value = TextEditingValue(
                          text: Variables.capitalizeAllWord(
                            value.substring(0, 30),
                          ),
                          selection: TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      SimpleNameFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Last name is required";
                      }
                      if ((value.endsWith(' ') ||
                          value.endsWith('-') ||
                          value.endsWith('.'))) {
                        return "Last name cannot end with a space, hyphen, or period";
                      }
                      return null;
                    },
                  ),
                  Container(height: 15),
                  DefaultText(
                    text: "Email",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),

                  CustomTextField(
                    textInputAction: TextInputAction.next,

                    hintText: "youremail@gmail.com",
                    controller: controller.email,
                    keyboardType: TextInputType.emailAddress,
                    onChange: (value) {
                      String trimmedValue = value.replaceFirst(
                        RegExp(r'^\s+'),
                        '',
                      );
                      if (trimmedValue.isNotEmpty) {
                      } else {
                        controller.email.value = TextEditingValue(
                          text: Variables.capitalizeAllWord(
                            trimmedValue.substring(0, 30),
                          ),
                          selection: TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email address is required';
                      }
                      if (!EmailValidator.validate(value) ||
                          !Variables.emailRegex.hasMatch(value)) {
                        controller.focusNode.requestFocus();
                        return "Invalid email format";
                      }
                      return null;
                    },
                  ),
                  Container(height: 15),
                  DefaultText(
                    text: "Birthday",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  CustomTextField(
                    onIconTap: () {
                      controller.selectDate(Get.context!);
                    },
                    inputFormatters: [DateTextInputFormatter()],
                    keyboardType: TextInputType.number,
                    suffixIcon: LucideIcons.calendarRange,
                    hintText: "Year-Month-Day",
                    isReadOnly: false,
                    controller: controller.bday,
                    onTap: () {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Birthday is required";
                      }

                      try {
                        final parsedDate = DateFormat(
                          'yyyy-MM-dd',
                        ).parseStrict(value);

                        final today = DateTime.now();
                        int age = today.year - parsedDate.year;
                        if (today.month < parsedDate.month ||
                            (today.month == parsedDate.month &&
                                today.day < parsedDate.day)) {
                          age--;
                        }

                        if (age < 12) {
                          return "You must be at least 12 years old.";
                        }
                      } catch (e) {
                        return "Please enter a valid date (YYYY-MM-DD)";
                      }

                      return null;
                    },
                  ),

                  Container(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultText(
                              text: "Gender",
                              style: AppTextStyle.h3,
                              color: AppColorV2.primaryTextColor,
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: AppColorV2.boxStroke,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value:
                                    controller.gender.value.isEmpty
                                        ? null
                                        : controller.gender.value,

                                items: [
                                  DropdownMenuItem(
                                    value: "M",
                                    child: DefaultText(
                                      text: "Male",
                                      color: AppColorV2.primaryTextColor,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "F",
                                    child: DefaultText(
                                      text: "Female",
                                      color: AppColorV2.primaryTextColor,
                                    ),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    controller.gender.value = newValue;
                                  }
                                },
                                dropdownColor: Colors.white,
                                underline: SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultText(
                              text: "Civil status",
                              style: AppTextStyle.h3,
                              color: AppColorV2.primaryTextColor,
                            ),
                            SizedBox(height: 5),
                            customDropdown(
                              labelText: "Select status",
                              isDisabled: false,
                              items: controller.civilData,
                              selectedValue: controller.selectedCivil.value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Civil status is required";
                                }
                                return null;
                              },
                              onChanged: (data) {
                                controller.selectedCivil.value = data!;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  spacing(height: 10),
                  spacing(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Stepp2 extends StatelessWidget {
  const Stepp2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Form(
              key: controller.formKeyStep2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  spacing(height: 20),
                  DefaultText(
                    text: "Region",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose Region",
                      isDisabled: false,
                      items: controller.regionData,
                      selectedValue: controller.selectedRegion.value,
                      onChanged: (String? newValue) {
                        controller.selectedRegion.value = newValue.toString();
                        controller.getProvinceData(newValue);
                        controller.zipCode.clear();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Region is required";
                        }
                        return null;
                      },
                    ),
                  ),
                  DefaultText(
                    text: "Province",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose Province",
                      isDisabled: false,
                      items: controller.provinceData,
                      selectedValue: controller.selectedProvince.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Province is required';
                        }
                        return null;
                      },
                      onChanged: (data) {
                        controller.selectedProvince.value = data.toString();
                        controller.getCityData(data);
                      },
                    ),
                  ),
                  DefaultText(
                    text: "City",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose City",
                      isDisabled: false,
                      items: controller.cityData,
                      selectedValue: controller.selectedCity.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                      onChanged: (data) {
                        controller.selectedCity.value = data.toString();
                        controller.getBrgyData(data);
                      },
                    ),
                  ),
                  DefaultText(
                    text: "Barangay",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose Barangay",
                      isDisabled: false,
                      items: controller.brgyData,
                      selectedValue: controller.selectedBrgy.value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Barangay is required';
                        }
                        return null;
                      },
                      onChanged: (data) {
                        controller.selectedBrgy.value = data.toString();
                      },
                    ),
                  ),
                  DefaultText(
                    text: "Zip Code",
                    style: AppTextStyle.h3,
                    color: AppColorV2.primaryTextColor,
                  ),
                  CustomTextField(
                    filledColor: AppColorV2.inactiveButton,
                    isReadOnly:
                        controller.selectedBrgy.value == null ||
                        controller.selectedRegion.value == null ||
                        controller.selectedProvince.value == null ||
                        controller.selectedCity.value == null,
                    isFilled:
                        controller.selectedBrgy.value == null ||
                        controller.selectedRegion.value == null ||
                        controller.selectedProvince.value == null ||
                        controller.selectedCity.value == null,
                    hintText: 'Enter Zip Code',
                    controller: controller.zipCode,
                    inputFormatters: [
                      NumericInputFormatter(),
                      LengthLimitingTextInputFormatter(4),
                    ],
                    keyboardType:
                        Platform.isAndroid
                            ? TextInputType.number
                            : const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: false,
                            ),
                    onChange: (value) {
                      controller.zipCode.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.zipCode.text.length),
                      );
                      controller.formKeyStep2.currentState?.validate();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ZIP code is required';
                      } else if (value.length != 4) {
                        return 'ZIP code must be 4 digits';
                      } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                        return 'ZIP code must be numeric';
                      }
                      return null;
                    },
                  ),
                  spacing(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Stepp3 extends StatelessWidget {
  const Stepp3({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    return Obx(
      () => SingleChildScrollView(
        child: Form(
          key: controller.formKeyStep3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              spacing(height: 20),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      controller.showBottomSheet(
                        bottomSheetQuestion(controller.getDropdownData(), (
                          objData,
                        ) {
                          Get.back();
                          controller.question1.value = objData["question"];
                          controller.seq1.value = objData["secq_id"];
                        }),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultText(
                            text: controller.question1.value,
                            style: AppTextStyle.h3,
                            color:
                                controller.seq1.value == 0
                                    ? AppColorV2.lpBlueBrand
                                    : AppColorV2.primaryTextColor,
                          ),
                        ),
                        spacing(width: 10),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color:
                              controller.seq1.value == 0
                                  ? AppColorV2.lpBlueBrand
                                  : AppColorV2.primaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  spacing(height: 10),
                  CustomTextField(
                    hintText: "Enter your answer",
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    keyboardType: TextInputType.name,
                    controller: controller.answer1,
                    isReadOnly: controller.seq1.value == 0,
                    isObscure: controller.obscureTextAnswer1.value,
                    suffixIcon:
                        controller.obscureTextAnswer1.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onIconTap: () {
                      controller.onToggleShowAnswer1(
                        !controller.obscureTextAnswer1.value,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Field is required.';
                      }
                      if (value.length < 3) {
                        return 'Minimum length is 3 characters.';
                      }
                      if (value.length > 30) {
                        return 'Maximum length is 30 characters.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
              spacing(height: 20),
              Column(
                children: [
                  Column(
                    children: [
                      InkWell(
                        onTap: () {
                          controller.showBottomSheet(
                            bottomSheetQuestion(controller.getDropdownData(), (
                              objData,
                            ) {
                              Get.back();
                              controller.question2.value = objData["question"];
                              controller.seq2.value = objData["secq_id"];
                            }),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: DefaultText(
                                text: controller.question2.value,
                                style: AppTextStyle.h3,
                                color:
                                    controller.seq2.value == 0
                                        ? AppColorV2.lpBlueBrand
                                        : AppColorV2.primaryTextColor,
                              ),
                            ),
                            spacing(width: 10),
                            Icon(
                              CupertinoIcons.chevron_down,
                              color:
                                  controller.seq2.value == 0
                                      ? AppColorV2.lpBlueBrand
                                      : AppColorV2.primaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      spacing(height: 10),
                      CustomTextField(
                        hintText: "Enter your answer",
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(30),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.characters,
                        isReadOnly: controller.seq2.value == 0,
                        controller: controller.answer2,
                        isObscure: controller.obscureTextAnswer2.value,
                        suffixIcon:
                            controller.obscureTextAnswer2.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onIconTap: () {
                          controller.onToggleShowAnswer2(
                            !controller.obscureTextAnswer2.value,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field is required.';
                          }
                          if (value.length < 3) {
                            return 'Minimum length is 3 characters.';
                          }
                          if (value.length > 30) {
                            return 'Maximum length is 30 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
              spacing(height: 30),
              Column(
                children: [
                  Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          await Future.delayed(Duration(milliseconds: 200));
                          controller.showBottomSheet(
                            bottomSheetQuestion(controller.getDropdownData(), (
                              objData,
                            ) {
                              Get.back();
                              controller.question3.value = objData["question"];
                              controller.seq3.value = objData["secq_id"];
                            }),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: DefaultText(
                                text: controller.question3.value,
                                style: AppTextStyle.h3,
                                color:
                                    controller.seq3.value == 0
                                        ? AppColorV2.lpBlueBrand
                                        : AppColorV2.primaryTextColor,
                              ),
                            ),
                            spacing(width: 10),
                            Icon(
                              CupertinoIcons.chevron_down,
                              color:
                                  controller.seq3.value == 0
                                      ? AppColorV2.lpBlueBrand
                                      : AppColorV2.primaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      spacing(height: 10),
                      CustomTextField(
                        hintText: "Enter your answer",
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(30),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.characters,
                        controller: controller.answer3,
                        isReadOnly: controller.seq3.value == 0,
                        isObscure: controller.obscureTextAnswer3.value,
                        suffixIcon:
                            controller.obscureTextAnswer3.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onIconTap: () {
                          controller.onToggleShowAnswer3(
                            !controller.obscureTextAnswer3.value,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field is required.';
                          }
                          if (value.length < 3) {
                            return 'Minimum length is 3 characters.';
                          }
                          if (value.length > 30) {
                            return 'Maximum length is 30 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
              spacing(height: MediaQuery.of(context).size.height / 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomSheetQuestion(dynamic data, Function cb) {
    return Container(
      height: MediaQuery.of(Get.context!).size.height * .60,
      width: MediaQuery.of(Get.context!).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
        child: Column(
          children: [
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
            spacing(height: 10),
            const DefaultText(text: "Choose a question"),
            Divider(),
            spacing(height: 20),
            Expanded(
              child: StretchingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                child: ListView.separated(
                  physics: BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(5),
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        cb(data[index]);
                      },

                      title: DefaultText(
                        style: AppTextStyle.paragraph2,
                        text: data[index]["question"],
                        color: Colors.black,
                      ),
                    );
                  },
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 5),
                  itemCount: data.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
