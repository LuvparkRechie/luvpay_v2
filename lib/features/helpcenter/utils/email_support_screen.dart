import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';
import 'package:luvpay/shared/widgets/tap_guard.dart';

import '../../../shared/dialogs/dialogs.dart';
import '../../../shared/widgets/luvpay_text.dart';

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() => _EmailSupportScreenState();
}

class _EmailSupportScreenState extends State<EmailSupportScreen> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  String category = "Account Concern";

  final List<String> categories = [
    "Account Concern",
    "Payment Issue",
    "Refund",
    "Parking Issue",
    "App Bug",
    "Verification",
    "Others",
  ];

  File? selectedFile;
  String? fileName;

  static const String submitKey = "submit_email_support";

  bool validate() {
    if (nameController.text.trim().isEmpty) {
      showError("Please enter your name");
      return false;
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(mobileController.text.trim())) {
      showError("Enter valid mobile number (09XXXXXXXXX)");
      return false;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      showError("Enter valid email address");
      return false;
    }

    if (messageController.text.trim().isEmpty) {
      showError("Please describe your concern");
      return false;
    }

    if (messageController.text.length < 10) {
      showError("Message must be at least 10 characters");
      return false;
    }

    return true;
  }

  void showError(String message) {
    CustomDialogStack.showSnackBar(
      context,
      message,
      null,
      null,
    );
  }

  Future<void> pickAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(child: LuvpayText(text: "1")),
                title: const LuvpayText(text: "Take Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    final file = File(image.path);
                    if (await validateFile(file)) {
                      setState(() {
                        selectedFile = file;
                        fileName = file.path.split('/').last;
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: LuvpayText(text: "2")),
                title: const LuvpayText(text: "Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final file = File(image.path);
                    if (await validateFile(file)) {
                      setState(() {
                        selectedFile = file;
                        fileName = file.path.split('/').last;
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: LuvpayText(text: "3")),
                title: const LuvpayText(text: "Choose File"),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                  );
                  if (result != null) {
                    final file = File(result.files.single.path!);
                    if (await validateFile(file)) {
                      setState(() {
                        selectedFile = file;
                        fileName = result.files.single.name;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> validateFile(File file) async {
    final fileSize = await file.length();
    final fileSizeInMB = fileSize / (1024 * 1024);

    if (fileSizeInMB > 5) {
      showError("File size must be less than 5MB");
      return false;
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf'].contains(ext)) {
      showError("Only JPG, PNG, and PDF files are allowed");
      return false;
    }

    return true;
  }

  Future<void> submit() async {
    if (!validate()) return;

    TapGuard.run(
      key: submitKey,
      action: () async {
        setState(() {});

        await Future.delayed(const Duration(seconds: 2));

        final ticketNumber =
            "LP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

        if (mounted) {
          setState(() {});
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const LuvpayText(text: "Ticket Submitted"),
              content:
                  LuvpayText(text: "Your ticket number is:\n\n$ticketNumber"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const LuvpayText(text: "OK"),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = TapGuard.isLocked(submitKey);

    return CustomScaffoldV2(
      appBarTitle: "Email Support",
      scaffoldBody: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRowTile(
              icon: Iconsax.user,
              title: "Name",
              subtitleWidget: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Enter your name",
                  border: InputBorder.none,
                ),
              ),
              onTap: () {},
            ),
            InfoRowTile(
              icon: Iconsax.call,
              title: "Mobile",
              subtitleWidget: TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "09XXXXXXXXX",
                  border: InputBorder.none,
                ),
              ),
              onTap: () {},
            ),
            InfoRowTile(
              icon: Iconsax.sms,
              title: "Email",
              subtitleWidget: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "example@email.com",
                  border: InputBorder.none,
                ),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 10),
            InfoRowTile(
              icon: Iconsax.category,
              title: "Category",
              subtitle: category,
              trailing: const Icon(Iconsax.arrow_down_1),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: categories
                            .map(
                              (e) => ListTile(
                                title: LuvpayText(
                                  text: e,
                                ),
                                onTap: () {
                                  setState(() => category = e);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            DefaultContainer(
              child: Column(
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: "Describe your concern...",
                      border: InputBorder.none,
                      counterText: "",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: LuvpayText(
                      text: "${messageController.text.length}/500",
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            InfoRowTile(
              icon: Iconsax.paperclip,
              title: "Attachment",
              subtitle: fileName ?? "Attach screenshot / receipt (optional)",
              onTap: pickAttachment,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: locked ? "Submitting Ticket..." : "Submit Ticket",
              leading: const Icon(Iconsax.send_1),
              isInactive: locked,
              onPressed: submit,
            ),
          ],
        ),
      ),
    );
  }
}
