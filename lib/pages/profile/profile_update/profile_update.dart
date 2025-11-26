import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/http/http_request.dart';
import '../../../auth/authentication.dart';
import '../../../custom_widgets/alert_dialog.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/variables.dart';
import '../../../http/api_keys.dart';

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

    // Security Questions Controllers
    _answerControllers = List.generate(3, (index) => TextEditingController());
    _selectedQuestions = List.generate(3, (index) => null);

    // Pre-fill existing security data
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
          DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
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
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _takeSelfie();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateProfilePage() {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColorV2.error,
          content: Text('Please fill in required fields'),
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateSecurityQuestions() {
    Set<String?> selectedSet = _selectedQuestions.toSet();
    if (selectedSet.length < 3 || selectedSet.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColorV2.error,
          content: Text('Please select 3 unique security questions'),
        ),
      );
      return false;
    }
    for (int i = 0; i < 3; i++) {
      if (_answerControllers[i].text.isEmpty ||
          _answerControllers[i].text.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColorV2.error,
            content: Text('Please provide valid answers for all questions'),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Column(
        children: [
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColorV2.boxStroke,
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width * (_currentPage + 1) / 3,
              decoration: BoxDecoration(
                gradient: AppColorV2.primaryGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          SizedBox(height: 12),
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
                  color:
                      _currentPage == 0
                          ? AppColorV2.lpBlueBrand
                          : AppColorV2.onSurfaceVariant,
                ),
              ),
              Text(
                'Security',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _currentPage == 1 ? FontWeight.w600 : FontWeight.w400,
                  color:
                      _currentPage == 1
                          ? AppColorV2.lpBlueBrand
                          : AppColorV2.onSurfaceVariant,
                ),
              ),
              Text(
                'Selfie',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _currentPage == 2 ? FontWeight.w600 : FontWeight.w400,
                  color:
                      _currentPage == 2
                          ? AppColorV2.lpBlueBrand
                          : AppColorV2.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorV2.boxStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DefaultText(
              text: 'Question ${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColorV2.lpBlueBrand,
              ),
            ),
          ),
          SizedBox(height: 12),

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
          SizedBox(height: 12),

          // Answer Input
          Container(
            decoration: BoxDecoration(
              color: AppColorV2.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColorV2.boxStroke),
            ),
            child: TextFormField(
              controller: _answerControllers[index],
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColorV2.lpBlueBrand,
                ),
                hintText: 'Enter your answer',
                hintStyle: GoogleFonts.inter(
                  color: AppColorV2.onSurfaceVariant,
                ),
                suffixIcon:
                    _answerControllers[index].text.isNotEmpty
                        ? Icon(
                          Icons.check_circle_rounded,
                          color: AppColorV2.success,
                        )
                        : null,
              ),
              style: GoogleFonts.inter(fontSize: 14),
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
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          // Personal Information Section
          _buildEnhancedSectionHeader(
            'Personal Information',
            Icons.person_outline_rounded,
          ),
          CustomTextField(
            title: 'First Name',
            controller: _firstNameController,
            hintText: "First Name",
            prefixIcon: Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'First Name is required';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          CustomTextField(
            title: 'Last Name',
            controller: _lastNameController,
            hintText: "Last Name",
            prefixIcon: Icon(Icons.person),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Last Name is required';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          CustomTextField(
            title: 'Middle Name',
            controller: _middleNameController,
            hintText: "Middle Name",
            prefixIcon: Icon(Icons.person),
          ),
          SizedBox(height: 16),
          CustomTextField(
            title: 'Email',
            controller: _emailController,
            hintText: "Email",
            prefixIcon: Icon(Icons.email),

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
            prefixIcon: Icon(Icons.calendar_today),
            suffixIcon: Icons.calendar_month,
            onIconTap: _selectBirthday,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Birthday is required';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          customDropdown(
            prefixIcon: Icon(Icons.transgender),
            isDisabled: false,
            labelText: "Select gender",
            items: [
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
          SizedBox(height: 16),
          customDropdown(
            prefixIcon: Icon(Icons.transgender),
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

          SizedBox(height: 16),

          // Address Section
          _buildEnhancedSectionHeader('Address', Icons.home_outlined),
          customDropdown(
            prefixIcon: Icon(Icons.location_on),
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

          SizedBox(height: 16),
          customDropdown(
            prefixIcon: Icon(Icons.location_on),
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

          SizedBox(height: 16),
          customDropdown(
            prefixIcon: Icon(Icons.location_on),
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
          SizedBox(height: 16),
          customDropdown(
            prefixIcon: Icon(Icons.location_on),
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

          SizedBox(height: 16),
          CustomTextField(
            title: 'Address Line 1',
            controller: _address1Controller,
            hintText: "Address Line 1",
            prefixIcon: Icon(Icons.location_on),
          ),
          SizedBox(height: 16),
          CustomTextField(
            title: 'Address Line 2',
            controller: _address2Controller,
            hintText: "Address Line 2",
            prefixIcon: Icon(Icons.location_on),
          ),
          SizedBox(height: 16),
          CustomTextField(
            title: 'ZIP Code',
            controller: _zipCodeController,
            hintText: "ZIP Code",
            prefixIcon: Icon(Icons.numbers),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSecurityQuestionsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          // Security Tips
          Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorV2.pastelBlueAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColorV2.lpBlueBrand.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: AppColorV2.lpBlueBrand,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Setup',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColorV2.primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose 3 unique security questions and provide answers that are memorable but hard to guess.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColorV2.onSurfaceVariant,
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

          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSelfiePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          // Modern Card Header
          Container(
            margin: EdgeInsets.only(bottom: 30),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColorV2.pastelBlueAccent.withValues(alpha: 0.9),
                  AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColorV2.lpBlueBrand.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Animated verification badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorV2.lpBlueBrand.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColorV2.lpBlueBrand,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Profile Verification',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColorV2.lpBlueBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Capture your best selfie for profile verification. Ensure good lighting and a clear view of your face.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColorV2.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Modern Selfie Capture Area
          Stack(
            alignment: Alignment.center,
            children: [
              // Animated background rings
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColorV2.lpBlueBrand.withValues(alpha: 0.05),
                      AppColorV2.lpBlueBrand.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),

              // Main circular container with modern border
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColorV2.lpBlueBrand.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  color: AppColorV2.background,
                ),
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorV2.background,
                          AppColorV2.background.withValues(alpha: 0.8),
                        ],
                      ),
                      image: DecorationImage(
                        image:
                            Image.memory(
                                  base64Decode(imageBase64.toString()),
                                  fit: BoxFit.cover,
                                )
                                as ImageProvider,
                      ),
                    ),
                    child:
                        imageBase64 == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.face_retouching_natural_rounded,
                                  size: 64,
                                  color: AppColorV2.lpBlueBrand.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Selfie',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColorV2.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                            : null,
                  ),
                ),
              ),

              // Floating camera button with modern design
              Positioned(
                bottom: 8,
                child: GestureDetector(
                  onTap: () {
                    _takeSelfie();
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColorV2.lpBlueBrand,
                          AppColorV2.lpBlueBrand.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColorV2.lpBlueBrand.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Instruction text with modern typography
          Text(
            'Tap the camera to capture your selfie',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColorV2.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),

          SizedBox(height: 8),

          // Additional guidance
          Text(
            '• Good lighting recommended\n• Face the camera directly\n• No filters or accessories',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColorV2.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),

          SizedBox(height: 30),

          // Modern button with smooth animation
          if (imageBase64 != null)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: submitProfilePic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorV2.success,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColorV2.success.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Complete Profile Update',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Add some bottom spacing
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16, top: 8),
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColorV2.lpBlueBrand.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColorV2.lpBlueBrand, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColorV2.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorV2.background,

      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColorV2.lpBlueBrand),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColorV2.primaryTextColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColorV2.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
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
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColorV2.lpBlueBrand),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColorV2.lpBlueBrand,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColorV2.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorV2.lpBlueBrand.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
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
                            color: Colors.white,
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
