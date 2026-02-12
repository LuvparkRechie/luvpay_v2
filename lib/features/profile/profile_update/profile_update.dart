// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import '../../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../../shared/widgets/colors.dart';
import '../../../shared/widgets/variables.dart';
import '../../../core/network/http/api_keys.dart';

enum AppState { free, picked, cropped }

class ProfileUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  List regionData, provinceData, cityData, brgyData;

  ProfileUpdateScreen({
    super.key,
    required this.userData,
    required this.regionData,
    required this.provinceData,
    required this.cityData,
    required this.brgyData,
  });

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? imageBase64;
  AppState? state;
  File? imageFile;
  // Profile Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _birthdayController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _zipCodeController;

  String? _selectedGender;
  String? _selectedCivilStatus;
  String? _regionId;
  String? _provinceId;
  String? _cityId;
  String? _brgyId;
  DateTime? _selectedBirthday;

  // Security Questions
  final List<Map<String, dynamic>> _securityQuestions = [
    {'value': 1, 'text': "What was the name of your first pet?"},
    {'value': 2, 'text': "What city were you born in?"},
    {'value': 3, 'text': "What is your mother's maiden name?"},
    {'value': 4, 'text': "What was your favorite school teacher's name?"},
    {'value': 5, 'text': "What is the name of your childhood best friend?"},
    {'value': 6, 'text': "What was your first car's model?"},
  ];

  late List<TextEditingController> _answerControllers;
  late List<String?> _selectedQuestions;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Profile Controllers
    _firstNameController = TextEditingController(
      text: widget.userData['first_name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['last_name'] ?? '',
    );
    _middleNameController = TextEditingController(
      text: widget.userData['middle_name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.userData['mobile_no'] ?? '',
    );
    _birthdayController = TextEditingController(
      text: widget.userData['birthday'] ?? '',
    );
    _address1Controller = TextEditingController(
      text: widget.userData['address1'] ?? '',
    );
    _address2Controller = TextEditingController(
      text: widget.userData['address2'] ?? '',
    );
    _zipCodeController = TextEditingController(
      text: widget.userData['zip_code'] ?? '',
    );

    //address dropdown
    _regionId =
        widget.userData['region_id'] == 0 ? null : widget.userData['region_id'];
    _provinceId =
        widget.userData['province_id'] == 0
            ? null
            : widget.userData['province_id'];
    _cityId =
        widget.userData['city_id'] == 0 ? null : widget.userData['city_id'];
    _brgyId =
        widget.userData['brgy_id'] == 0 ? null : widget.userData['brgy_id'];
    _selectedGender = widget.userData['gender'];
    _selectedCivilStatus = widget.userData['civil_status'];

    _answerControllers = List.generate(3, (index) => TextEditingController());
    _selectedQuestions = List.generate(3, (index) => null);

    if (widget.userData['secq_id1'] != null) {
      _selectedQuestions[0] = _getQuestionById(widget.userData['secq_id1']);
      _answerControllers[0].text = widget.userData['seca1'] ?? '';
    }
    if (widget.userData['secq_id2'] != null) {
      _selectedQuestions[1] = _getQuestionById(widget.userData['secq_id2']);
      _answerControllers[1].text = widget.userData['seca2'] ?? '';
    }
    if (widget.userData['secq_id3'] != null) {
      _selectedQuestions[2] = _getQuestionById(widget.userData['secq_id3']);
      _answerControllers[2].text = widget.userData['seca3'] ?? '';
    }
  }

  String? _getQuestionById(dynamic id) {
    if (id == null) return null;
    int questionId = int.tryParse(id.toString()) ?? 0;
    return _securityQuestions.firstWhere(
      (q) => q['value'] == questionId,
      orElse: () => {'text': ''},
    )['text'];
  }

  Future<dynamic> getAddressData(String param) async {
    CustomDialogStack.showLoading(Get.context!);

    final response = await HttpRequestApi(api: param).get();
    Get.back();

    if (response is Map) {
      return response["items"];
    } else {
      if (response == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return [];
      }
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return [];
    }
  }

  void onchangeEvent(int id, Function cb) {
    FocusManager.instance.primaryFocus!.unfocus();
    switch (id) {
      case 1:
        //on region change
        _provinceId = null;
        _cityId = null;
        _brgyId = null;
        widget.provinceData = [];
        widget.cityData = [];
        widget.brgyData = [];
        setState(() {});
        cb();
        break;
      case 2:
        //on province change
        _cityId = null;
        _brgyId = null;
        widget.cityData = [];
        widget.brgyData = [];
        setState(() {});
        cb();
        break;
      case 3:
        widget.brgyData = [];
        setState(() {
          _brgyId = null;
        });

        cb();
        break;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _birthdayController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _zipCodeController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void submitProfilePic() async {
    CustomDialogStack.showLoading(Get.context!);
    final myData = await Authentication().getUserData2();

    Map<String, dynamic> parameters = {
      "mobile_no": myData["mobile_no"],
      "last_name": myData["last_name"],
      "first_name": myData["first_name"],
      "middle_name": myData["middle_name"],
      "birthday":
          myData["birthday"].toString() == 'null'
              ? ''
              : myData["birthday"].toString().split("T")[0],
      "gender": myData["gender"],
      "civil_status": myData["civil_status"],
      "address1": myData["address1"],
      "address2": myData["address2"],
      "brgy_id": myData["brgy_id"] ?? "",
      "city_id": myData["city_id"] ?? "",
      "province_id": myData["province_id"] ?? "",
      "region_id": myData["region_id"] ?? "",
      "zip_code": myData["zip_code"] ?? "",
      "email": myData["email"],
      "secq_id1": myData["secq_id1"] ?? "",
      "secq_id2": myData["secq_id2"] ?? "",
      "secq_id3": myData["secq_id3"] ?? "",
      "seca1": myData["seca1"],
      "seca2": myData["seca2"],
      "seca3": myData["seca3"],
      "image_base64": imageBase64.toString(),
    };

    HttpRequestApi(
      api: ApiKeys.putUpdateUserProf,
      parameters: parameters,
    ).putBody().then((res) async {
      Get.back();
      if (res == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return;
      }
      if (res == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        if (res["success"] == "Y") {
          Authentication().setProfilePic(jsonEncode(imageBase64));
          Get.back();
        } else {
          CustomDialogStack.showError(Get.context!, "luvpay", res["msg"], () {
            Get.back();
          });
          return;
        }
      }
    });
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthday ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _nextPage() {
    FocusManager.instance.primaryFocus!.unfocus();
    if (_currentPage == 0 && !_validateProfilePage()) return;
    if (_currentPage == 1 && !_validateSecurityQuestions()) return;

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _takeSelfie();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateProfilePage() {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.error,
          content: const Text('Please fill in required fields'),
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateSecurityQuestions() {
    Set<String?> selectedSet = _selectedQuestions.toSet();
    if (selectedSet.length < 3 || selectedSet.contains(null)) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.error,
          content: const Text('Please select 3 unique security questions'),
        ),
      );
      return false;
    }
    for (int i = 0; i < 3; i++) {
      if (_answerControllers[i].text.isEmpty ||
          _answerControllers[i].text.length < 2) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cs.error,
            content: const Text(
              'Please provide valid answers for all questions',
            ),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _takeSelfie() async {
    final pickedFile = await _picker.pickImage(
      preferredCameraDevice: CameraDevice.front,
      source: ImageSource.camera,
      imageQuality: Platform.isIOS ? 14 : 20,
      maxWidth: Platform.isIOS ? 200 : 400,
      requestFullMetadata: true,
    );

    imageFile = pickedFile != null ? File(pickedFile.path) : null;

    if (imageFile != null) {
      state = AppState.picked;
      imageFile!.readAsBytes().then((data) {
        imageBase64 = base64.encode(data);
      });
    } else {
      imageBase64 = null;
    }

    setState(() {});
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
    final inactiveText =
        isDark ? AppColorV2.darkBodyText : AppColorV2.bodyTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Column(
        children: [
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: stroke,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width:
                    MediaQuery.of(context).size.width * (_currentPage + 1) / 3,
                decoration: BoxDecoration(
                  gradient: AppColorV2.primaryGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Progress Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _currentPage == 0 ? FontWeight.w600 : FontWeight.w400,
                  color: _currentPage == 0 ? cs.primary : inactiveText,
                ),
              ),
              Text(
                'Security',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _currentPage == 1 ? FontWeight.w600 : FontWeight.w400,
                  color: _currentPage == 1 ? cs.primary : inactiveText,
                ),
              ),
              Text(
                'Selfie',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _currentPage == 2 ? FontWeight.w600 : FontWeight.w400,
                  color: _currentPage == 2 ? cs.primary : inactiveText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
    final cardBg = cs.surface;
    final fieldBg = isDark ? AppColorV2.darkSurface2 : AppColorV2.background;
    final hintText =
        isDark ? AppColorV2.darkBodyText : AppColorV2.bodyTextColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(
              alpha: isDark ? 0.35 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: LuvpayText(
              text: 'Question ${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          customDropdown(
            isDisabled: false,
            labelText: "Select a question",
            items: _securityQuestions,
            selectedValue: _selectedQuestions[index],
            onChanged: (value) {
              FocusManager.instance.primaryFocus!.unfocus();
              setState(() {
                _selectedQuestions[index] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a question';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Answer Input
          Container(
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stroke),
            ),
            child: TextFormField(
              controller: _answerControllers[index],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: cs.primary),
                hintText: 'Enter your answer',
                hintStyle: GoogleFonts.inter(color: hintText),
                suffixIcon:
                    _answerControllers[index].text.isNotEmpty
                        ? Icon(
                          Icons.check_circle_rounded,
                          color: AppColorV2.correctState,
                        )
                        : null,
              ),
              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an answer';
                }
                if (value.length < 2) {
                  return 'Answer must be at least 2 characters';
                }
                return null;
              },
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildEnhancedSectionHeader(
            'Personal Information',
            Icons.person_outline_rounded,
          ),
          CustomTextField(
            title: 'First Name',
            controller: _firstNameController,
            hintText: "First Name",
            prefixIcon: const Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'First Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            title: 'Last Name',
            controller: _lastNameController,
            hintText: "Last Name",
            prefixIcon: const Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Last Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            title: 'Middle Name',
            controller: _middleNameController,
            hintText: "Middle Name",
            prefixIcon: const Icon(Icons.person),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            title: 'Email',
            controller: _emailController,
            hintText: "Email",
            prefixIcon: const Icon(Icons.email),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email Name is required';
              }
              return null;
            },
          ),

          // Additional Information Section
          _buildEnhancedSectionHeader(
            'Additional Information',
            Icons.info_outline_rounded,
          ),
          CustomTextField(
            title: 'Birthday',
            controller: _birthdayController,
            hintText: "Birthday",
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: Icons.calendar_month,
            onIconTap: _selectBirthday,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Birthday is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          customDropdown(
            prefixIcon: const Icon(Icons.transgender),
            isDisabled: false,
            labelText: "Select gender",
            items: const [
              {"text": "Female", "value": "F"},
              {"text": "Male", "value": "M"},
            ],
            selectedValue: _selectedGender,
            onChanged: (value) {
              FocusManager.instance.primaryFocus!.unfocus();

              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a gender';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          customDropdown(
            prefixIcon: const Icon(Icons.transgender),
            isDisabled: false,
            labelText: "Civil Status",
            items: Variables.civilStatusData,
            selectedValue: _selectedCivilStatus,
            onChanged: (value) {
              FocusManager.instance.primaryFocus!.unfocus();
              setState(() {
                _selectedCivilStatus = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a gender';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          _buildEnhancedSectionHeader('Address', Icons.home_outlined),
          customDropdown(
            prefixIcon: const Icon(Icons.location_on),
            isDisabled: false,
            labelText: "Region",
            items:
                widget.regionData.map((e) {
                  e["text"] = e["region_name"];
                  e["value"] = e["region_id"];
                  return e;
                }).toList(),
            selectedValue: _regionId,
            onChanged: (value) async {
              List respo = await getAddressData(
                "${ApiKeys.getProvince}?p_region_id=${value!}",
              );

              if (respo.isEmpty) return;
              onchangeEvent(1, () {
                widget.provinceData = respo;
              });
              setState(() {
                _regionId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a region';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
          customDropdown(
            prefixIcon: const Icon(Icons.location_on),
            isDisabled: false,
            labelText: "Province",
            items: widget.provinceData,
            selectedValue: _provinceId,
            onChanged: (value) async {
              List respo = await getAddressData(
                "${ApiKeys.getCity}?p_province_id=${value!}",
              );

              if (respo.isEmpty) return;
              onchangeEvent(2, () {
                widget.cityData = respo;
              });
              setState(() {
                _provinceId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a province';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
          customDropdown(
            prefixIcon: const Icon(Icons.location_on),
            isDisabled: false,
            labelText: "City",
            items: widget.cityData,
            selectedValue: _cityId,
            onChanged: (value) async {
              List respo = await getAddressData(
                "${ApiKeys.getBrgy}?p_city_id=$value",
              );

              if (respo.isEmpty) return;
              onchangeEvent(3, () {
                widget.brgyData = respo;
              });
              setState(() {
                _cityId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a city';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          customDropdown(
            prefixIcon: const Icon(Icons.location_on),
            isDisabled: false,
            labelText: "Brgy",
            items: widget.brgyData,
            selectedValue: _brgyId,
            onChanged: (value) async {
              setState(() {
                _brgyId = value;
              });
              FocusManager.instance.primaryFocus!.unfocus();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a brgy';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
          CustomTextField(
            title: 'Address Line 1',
            controller: _address1Controller,
            hintText: "Address Line 1",
            prefixIcon: const Icon(Icons.location_on),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            title: 'Address Line 2',
            controller: _address2Controller,
            hintText: "Address Line 2",
            prefixIcon: const Icon(Icons.location_on),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            title: 'ZIP Code',
            controller: _zipCodeController,
            hintText: "ZIP Code",
            prefixIcon: const Icon(Icons.numbers),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSecurityQuestionsPage() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
    final tipBg = cs.primary.withValues(alpha: isDark ? 0.12 : 0.08);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // Security Tips
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tipBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Setup',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose 3 unique security questions and provide answers that are memorable but hard to guess.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColorV2.darkBodyText
                                  : AppColorV2.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Question Cards
          _buildQuestionCard(0),
          _buildQuestionCard(1),
          _buildQuestionCard(2),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: isDark ? 0.25 : 0.30),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final surface = cs.surface;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: bg,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildProfilePage(),
                  _buildSecurityQuestionsPage(),
                  // _buildSelfiePage(),
                ],
              ),
            ),
            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: cs.primary),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColorV2.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(
                              alpha: isDark ? 0.22 : 0.30,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == 0
                              ? 'Continue to Security'
                              : _currentPage == 1
                              ? 'Continue to Selfie'
                              : 'Submit',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
