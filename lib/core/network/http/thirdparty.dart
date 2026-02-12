import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/widgets/variables.dart';
import '../../security/security/app_security.dart';

class Http3rdPartyRequest {
  final String? api;
  final Map<String, dynamic>? parameters;
  final String? url;

  const Http3rdPartyRequest({this.api, this.url, this.parameters});
  Future<dynamic> post() async {
    List appSecurity = await AppSecurity.checkDeviceSecurity();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .post(
              Uri.parse(Uri.decodeFull(Uri.https(url!, api!).toString())),
              headers: {"Content-Type": 'application/json; charset=utf-8'},
              body: json.encode(parameters),
            )
            .timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          return response.headers;
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> getBiller() async {
    List appSecurity = await AppSecurity.checkDeviceSecurity();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        final Map<String, String> headers = {
          "Content-Type": "application/json;charset=UTF-8",
        };

        // Use Uri.parse directly for HTTP URL
        final uri = Uri.parse(url!);

        var response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(
            utf8.decode(response.bodyBytes, allowMalformed: true),
          );
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> postBiller() async {
    List appSecurity = await AppSecurity.checkDeviceSecurity();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        final Map<String, String> headers = {
          "Content-Type": "application/json;charset=UTF-8",
        };

        final uri = Uri.parse(url!);

        var response = await http
            .post(uri, headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(
            utf8.decode(response.bodyBytes, allowMalformed: true),
          );
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> fetchParkingSpots(mapApi) async {
    final urlapi = Uri.parse('$url&key=$mapApi');
    try {
      final response = await http.get(urlapi);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['results'];
      } else {
        throw Exception('Failed to load parking spots');
      }
    } catch (e) {
      return "No Internet";
    }
  }
}
