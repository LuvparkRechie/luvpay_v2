import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UnionBankAuthService {
  static final String? _getCookie = dotenv.env['UB_COOKIE'];
  static final String? _payCookie = dotenv.env['UB_PAY_COOKIE'];
  static final String? _baseUrl = dotenv.env['UB_BASE_URL'];
  static final String? _tokenEndpoint = dotenv.env["TOKEN_END_POINT"];
  static final String? _payEndpoint = dotenv.env["PAY_END_POINT"];
  static final String? _grantType = dotenv.env["GRANT_TYPE"];
  static final String? _scope = dotenv.env["SCOPE"];
  static final String? _userName = dotenv.env["USERNAME"];
  static final String? _password = dotenv.env["PASSWORD"];
  static final String? _clientId = dotenv.env["CLIENT_ID"];

  static final String? _xIBMCID = dotenv.env["X_IBM_CLIENT_ID"];
  static final String? _xIBMSECRET = dotenv.env["X_IBM_SECRET"];
  static final String? _xPartner = dotenv.env["X_PARTNER_ID"];

  Future<dynamic> getTokenWithPasswordGrant() async {
    try {
      final uri = Uri.parse(_baseUrl! + _tokenEndpoint!);

      // Prepare the request body as x-www-form-urlencoded
      final body = {
        'grant_type': _grantType,
        'scope': _scope,
        'username': _userName,
        'password': _password,
        'client_id': _clientId,
      };

      // Encode the body
      final encodedBody =
          Uri(
            queryParameters: body.map(
              (key, value) => MapEntry(key, value.toString()),
            ),
          ).query;

      // Make the POST request with headers and cookies
      Map<String, String> headers = {
        'accept': 'application/json',
        'content-type': 'application/x-www-form-urlencoded',
      };
      final response = await http.post(
        uri,
        headers: headers,
        body: encodedBody,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return "No Internet";
    }
  }

  Future makePayment({
    required String accessToken,
    required String senderRefId,
    required String tranRequestDate,
    required String emailAddress,
    required String mobileNumber,
    required double amount,
    required String billerUuid,
    required String paymentMethod,
    required String callbackUrl,
    required List<Map<String, dynamic>> references,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl! + _payEndpoint!);

      // Prepare the request body
      final body = {
        'senderRefId': senderRefId,
        'tranRequestDate': tranRequestDate,
        'emailAddress': emailAddress,
        'mobileNumber': mobileNumber,
        'amount': amount,
        'billerUuid': billerUuid,
        'paymentMethod': paymentMethod,
        'callbackUrl': callbackUrl,
        'references': references,
      };

      final response = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
          'x-ibm-client-id': _xIBMCID!,
          'x-ibm-client-secret': _xIBMSECRET!,
          'x-partner-id': _xPartner!,
          'Cookie': _payCookie!,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final mapData = jsonDecode(response.body);

        Map<String, dynamic> data = mapData["errors"][0];

        Map failedRes = {
          'title': data["description"],
          'body': "${data["details"]["message"]}",
        };
        return jsonEncode(failedRes);
      }
    } catch (e) {
      Map failedRes = {'title': "Error making payment", 'body': e};
      return jsonEncode(failedRes);
    }
  }
}
