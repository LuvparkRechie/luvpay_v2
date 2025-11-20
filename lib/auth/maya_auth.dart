import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../custom_widgets/alert_dialog.dart';

class MayaAuth {
  static final String? _baseUrl = dotenv.env['MAYA_BASE_URL'];
  static final String? _mayaEndpoint = dotenv.env["MAYA_END_POINT"];
  static final String? _mayaAuth = dotenv.env["MAYA_AUTH"];
  final Map<String, dynamic> postParam;

  const MayaAuth({required this.postParam});

  Future<dynamic> postData() async {
    try {
      final uri = Uri.parse(_baseUrl! + _mayaEndpoint!);
      final header = {
        'Authorization': 'Basic $_mayaAuth',
        'content-type': 'application/json',
      };

      final response = await http
          .post(uri, headers: header, body: json.encode(postParam))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return null;
      }
    } catch (e) {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return "No Internet";
    }
  }
}
