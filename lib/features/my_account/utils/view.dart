// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/features/my_account/utils/index.dart';

import '../../../shared/widgets/upper_case_formatter.dart';
import '../../../shared/dialogs/dialogs.dart';
import '../../../shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/custom_scaffold.dart';
import '../../../shared/widgets/luvpay_loading.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../../shared/widgets/spacing.dart';
import '../../../shared/widgets/variables.dart';
import 'success/update_success.dart';

class UpdateProfile extends GetView<UpdateProfileController> {
  const UpdateProfile({super.key});

  Color _stroke(ColorScheme cs, bool isDark) =>
      cs.onSurface.withOpacity(isDark ? 0.05 : 0.01);

  @override
  Widget build(BuildContext context) {
    void close() {
      CustomDialogStack.showConfirmation(
        context,
        "Close Page",
        "Are you sure you want to close this page?",
        leftText: "No",
        rightText: "Yes",
        () => Get.back(),
        () {
          Get.back();
          Get.back();
        },
      );
    }

    return Obx(() {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: cs.surface,
          body: const LoadingCard(text: "Loading…"),
        );
      }

      return CustomScaffoldV2(
        appBarTitle: "Personal Information",
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          FocusScope.of(context).requestFocus(FocusNode());
          if (!didPop) close();
        },
        onPressedLeading: () {
          FocusScope.of(context).requestFocus(FocusNode());
          close();
        },
        canPop: false,
        enableToolBar: true,
        padding: EdgeInsets.zero,
        scaffoldBody: SizedBox(
          width: double.infinity,
          child: ScrollConfiguration(
            behavior: ScrollBehavior().copyWith(overscroll: false),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(19, 19, 19, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Builder(
                      builder: (context) {
                        final idx = controller.currentIndex.value;
                        if (idx == 0) {
                          return LuvpayText(
                            maxLines: 1,
                            style: AppTextStyle.body1(context),
                            color: cs.onSurface.withOpacity(0.72),
                            text:
                                "Enter accurate details to personalize your experience.",
                          );
                        } else if (idx == 1) {
                          return LuvpayText(
                            style: AppTextStyle.body1(context),
                            color: cs.onSurface.withOpacity(0.72),
                            text:
                                "Add your full residential address for verification.",
                          );
                        } else {
                          return LuvpayText(
                            style: AppTextStyle.body1(context),
                            color: cs.onSurface.withOpacity(0.72),
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
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: controller.pages[controller.currentIndex.value],
                    ),
                  ),
                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                    Row(
                      children: [
                        if (controller.currentIndex.value > 0)
                          Expanded(
                            child: LuvNeuPress.rectangle(
                              radius: BorderRadius.circular(16),
                              onTap: controller.previousPage,
                              background: cs.surface,
                              borderColor: _stroke(cs, isDark),
                              child: SizedBox(
                                height: 52,
                                child: Center(
                                  child: LuvpayText(
                                    text: "Previous",
                                    style: AppTextStyle.body1(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (controller.currentIndex.value > 0)
                          spacing(width: 10),
                        Expanded(
                          child: LuvNeuPress.rectangle(
                            radius: BorderRadius.circular(16),
                            onTap: controller.nextPage,
                            background: cs.primary,
                            borderColor: Colors.transparent,
                            child: SizedBox(
                              height: 52,
                              child: Center(
                                child: LuvpayText(
                                  text:
                                      controller.currentIndex.value == 2
                                          ? "Submit"
                                          : "Next",
                                  style: AppTextStyle.body1(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w900),
                                  color: cs.onPrimary,
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
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: index(context),
        ),
      );
    });
  }

  Widget index(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final inactiveDot = cs.onPrimary.withOpacity(isDark ? 0.22 : 0.40);
    final activeDot = cs.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final cur = controller.currentIndex.value;
              final passed = cur > i;
              final isNow = cur == i;
              final enabled = cur >= i;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (i != 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: enabled ? activeDot : inactiveDot,
                            ),
                          ),
                        Container(
                          alignment: Alignment.center,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: passed || isNow ? activeDot : inactiveDot,
                            border: Border.all(
                              color: cs.onPrimary.withOpacity(
                                isDark ? 0.05 : 0.01,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        if (i != 2)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: passed ? activeDot : inactiveDot,
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
            children: List.generate(3, (i) {
              final enabled = controller.currentIndex.value >= i;
              return LuvpayText(
                style: AppTextStyle.body1(context),
                text:
                    i == 0
                        ? "Profile"
                        : i == 1
                        ? "  Address"
                        : "Security",
                color: enabled ? cs.onPrimary : cs.onPrimary.withOpacity(0.70),
              );
            }),
          ),
          const SizedBox(height: 20),
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
    if (RegExp(r'^\d*$').hasMatch(newValue.text)) return newValue;
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

    final periodCount = newValue.text.split('.').length - 1;
    final hyphenCount = newValue.text.split('-').length - 1;

    final hasDisallowedCombination =
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  const SizedBox(height: 20),

                  LuvpayText(
                    text: "First Name",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
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
                          text: Variables.capitalizeAllWord(value),
                          selection: const TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      SimpleNameFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "First name is required";
                      if (value.endsWith(' ') ||
                          value.endsWith('-') ||
                          value.endsWith('.')) {
                        return "First name cannot end with a space, hyphen, or period";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  LuvpayText(
                    text: "Middle Name",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
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
                    onChange: (_) {},
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

                  const SizedBox(height: 15),

                  LuvpayText(
                    text: "Last Name",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
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
                          text: Variables.capitalizeAllWord(value),
                          selection: const TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      SimpleNameFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Last name is required";
                      if (value.endsWith(' ') ||
                          value.endsWith('-') ||
                          value.endsWith('.')) {
                        return "Last name cannot end with a space, hyphen, or period";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  LuvpayText(
                    text: "Email",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  CustomTextField(
                    textInputAction: TextInputAction.next,
                    hintText: "youremail@gmail.com",
                    controller: controller.email,
                    keyboardType: TextInputType.emailAddress,
                    onChange: (value) {
                      final trimmedValue = value.replaceFirst(
                        RegExp(r'^\s+'),
                        '',
                      );
                      if (trimmedValue.isEmpty) {
                        controller.email.value = TextEditingValue(
                          text: trimmedValue,
                          selection: const TextSelection.collapsed(offset: 0),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Email address is required';
                      if (!EmailValidator.validate(value) ||
                          !Variables.emailRegex.hasMatch(value)) {
                        controller.focusNode.requestFocus();
                        return "Invalid email format";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  LuvpayText(
                    text: "Birthday",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  CustomTextField(
                    onIconTap: () => controller.selectDate(Get.context!),
                    inputFormatters: [DateTextInputFormatter()],
                    keyboardType: TextInputType.number,
                    suffixIcon: LucideIcons.calendarRange,
                    hintText: "Year-Month-Day",
                    isReadOnly: false,
                    controller: controller.bday,
                    onTap: () {},
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Birthday is required";
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
                        if (age < 12)
                          return "You must be at least 12 years old.";
                      } catch (_) {
                        return "Please enter a valid date (YYYY-MM-DD)";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LuvpayText(
                              text: "Gender",
                              style: AppTextStyle.h3(context),
                              color: cs.onSurface,
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1,
                                  color: cs.onSurface.withOpacity(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.05
                                        : 0.01,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: cs.surface,
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value:
                                    controller.gender.value.isEmpty
                                        ? null
                                        : controller.gender.value,
                                items: const [
                                  DropdownMenuItem(
                                    value: "M",
                                    child: Text("Male"),
                                  ),
                                  DropdownMenuItem(
                                    value: "F",
                                    child: Text("Female"),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.gender.value = v;
                                },
                                dropdownColor: cs.surface,
                                underline: const SizedBox(),
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                                iconEnabledColor: cs.onSurface.withOpacity(
                                  0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LuvpayText(
                              text: "Civil status",
                              style: AppTextStyle.h3(context),
                              color: cs.onSurface,
                            ),
                            const SizedBox(height: 5),
                            customDropdown(
                              labelText: "Select status",
                              isDisabled: false,
                              items: controller.civilData,
                              selectedValue: controller.selectedCivil.value,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "Civil status is required";
                                return null;
                              },
                              onChanged:
                                  (data) =>
                                      controller.selectedCivil.value = data!,
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
    final cs = Theme.of(context).colorScheme;

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

                  LuvpayText(
                    text: "Region",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
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
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? "Region is required"
                                  : null,
                    ),
                  ),

                  LuvpayText(
                    text: "Province",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose Province",
                      isDisabled: false,
                      items: controller.provinceData,
                      selectedValue: controller.selectedProvince.value,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Province is required'
                                  : null,
                      onChanged: (data) {
                        controller.selectedProvince.value = data.toString();
                        controller.getCityData(data);
                      },
                    ),
                  ),

                  LuvpayText(
                    text: "City",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose City",
                      isDisabled: false,
                      items: controller.cityData,
                      selectedValue: controller.selectedCity.value,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'City is required'
                                  : null,
                      onChanged: (data) {
                        controller.selectedCity.value = data.toString();
                        controller.getBrgyData(data);
                      },
                    ),
                  ),

                  LuvpayText(
                    text: "Barangay",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: customDropdown(
                      labelText: "Choose Barangay",
                      isDisabled: false,
                      items: controller.brgyData,
                      selectedValue: controller.selectedBrgy.value,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Barangay is required'
                                  : null,
                      onChanged:
                          (data) =>
                              controller.selectedBrgy.value = data.toString(),
                    ),
                  ),

                  LuvpayText(
                    text: "Zip Code",
                    style: AppTextStyle.h3(context),
                    color: cs.onSurface,
                  ),
                  CustomTextField(
                    filledColor: cs.surfaceContainerHighest,
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
                    onChange: (_) {
                      controller.zipCode.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.zipCode.text.length),
                      );
                      controller.formKeyStep2.currentState?.validate();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'ZIP code is required';
                      if (value.length != 4) return 'ZIP code must be 4 digits';
                      if (!RegExp(r'^\d{4}$').hasMatch(value))
                        return 'ZIP code must be numeric';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(
      () => SingleChildScrollView(
        child: Form(
          key: controller.formKeyStep3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              spacing(height: 20),

              _QnaBlock(
                titleText: controller.question1.value,
                isDisabled: controller.seq1.value == 0,
                titleColor:
                    controller.seq1.value == 0 ? cs.primary : cs.onSurface,
                onPickQuestion: () {
                  controller.showBottomSheet(
                    bottomSheetQuestion(controller.getDropdownData(), (
                      objData,
                    ) {
                      Get.back();
                      controller.question1.value = objData["question"];
                      controller.seq1.value = objData["secq_id"];
                    }, context),
                  );
                },
                controller: controller.answer1,
                obscure: controller.obscureTextAnswer1.value,
                toggle:
                    () => controller.onToggleShowAnswer1(
                      !controller.obscureTextAnswer1.value,
                    ),
              ),

              spacing(height: 20),

              _QnaBlock(
                titleText: controller.question2.value,
                isDisabled: controller.seq2.value == 0,
                titleColor:
                    controller.seq2.value == 0 ? cs.primary : cs.onSurface,
                onPickQuestion: () {
                  controller.showBottomSheet(
                    bottomSheetQuestion(controller.getDropdownData(), (
                      objData,
                    ) {
                      Get.back();
                      controller.question2.value = objData["question"];
                      controller.seq2.value = objData["secq_id"];
                    }, context),
                  );
                },
                controller: controller.answer2,
                obscure: controller.obscureTextAnswer2.value,
                toggle:
                    () => controller.onToggleShowAnswer2(
                      !controller.obscureTextAnswer2.value,
                    ),
              ),

              spacing(height: 30),

              _QnaBlock(
                titleText: controller.question3.value,
                isDisabled: controller.seq3.value == 0,
                titleColor:
                    controller.seq3.value == 0 ? cs.primary : cs.onSurface,
                onPickQuestion: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  await Future.delayed(const Duration(milliseconds: 200));
                  controller.showBottomSheet(
                    bottomSheetQuestion(controller.getDropdownData(), (
                      objData,
                    ) {
                      Get.back();
                      controller.question3.value = objData["question"];
                      controller.seq3.value = objData["secq_id"];
                    }, context),
                  );
                },
                controller: controller.answer3,
                obscure: controller.obscureTextAnswer3.value,
                toggle:
                    () => controller.onToggleShowAnswer3(
                      !controller.obscureTextAnswer3.value,
                    ),
              ),

              spacing(height: MediaQuery.of(context).size.height / 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomSheetQuestion(dynamic data, Function cb, BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * .60,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(
          color: cs.onSurface.withOpacity(isDark ? 0.05 : 0.01),
          width: 1,
        ),
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
                  color: cs.onSurface.withOpacity(isDark ? 0.20 : 0.12),
                ),
              ),
            ),
            spacing(height: 10),
            LuvpayText(
              text: "Choose a question",
              style: AppTextStyle.h3(context),
              color: cs.onSurface,
            ),
            Divider(color: cs.onSurface.withOpacity(isDark ? 0.08 : 0.05)),
            spacing(height: 10),
            Expanded(
              child: StretchingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(5),
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () => cb(data[index]),
                      title: LuvpayText(
                        style: AppTextStyle.paragraph2(context),
                        text: data[index]["question"],
                        color: cs.onSurface.withOpacity(0.88),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
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

class _QnaBlock extends StatelessWidget {
  final String titleText;
  final bool isDisabled;
  final Color titleColor;
  final VoidCallback onPickQuestion;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback toggle;

  const _QnaBlock({
    required this.titleText,
    required this.isDisabled,
    required this.titleColor,
    required this.onPickQuestion,
    required this.controller,
    required this.obscure,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPickQuestion,
          child: Row(
            children: [
              Expanded(
                child: LuvpayText(
                  text: titleText,
                  style: AppTextStyle.h3(context),
                  color: titleColor,
                ),
              ),
              spacing(width: 10),
              Icon(CupertinoIcons.chevron_down, color: titleColor),
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
          controller: controller,
          isReadOnly: isDisabled,
          isObscure: obscure,
          suffixIcon: obscure ? Icons.visibility_off : Icons.visibility,
          onIconTap: toggle,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Field is required.';
            if (value.length < 3) return 'Minimum length is 3 characters.';
            if (value.length > 30) return 'Maximum length is 30 characters.';
            return null;
          },
        ),
      ],
    );
  }
}
