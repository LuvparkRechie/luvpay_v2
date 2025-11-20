import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:luvpay/custom_widgets/variables.dart';
import 'package:luvpay/http/api_keys.dart';

import '../security/app_security.dart';

class HttpRequestApi {
  final String api;
  final Map<String, dynamic>? parameters;

  const HttpRequestApi({required this.api, this.parameters});

  Future<dynamic> get() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .get(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              headers: {"Content-Type": 'application/json; charset=utf-8'},
            )
            .timeout(Duration(seconds: 20));
        if (response.statusCode == 200) {
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

  Future<dynamic> post() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .post(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
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

  Future<dynamic> postBody() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .post(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              headers: {"Content-Type": 'application/json; charset=utf-8'},
              body: json.encode(parameters),
            )
            .timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> putBody() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .put(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              headers: {"Content-Type": "application/json"},
              body: json.encode(parameters),
            )
            .timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> put() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .put(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              headers: {"Content-Type": "application/json"},
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

  Future<dynamic> put2() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .put(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              // headers: {"Content-Type": "application/json"},
            )
            .timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> deleteData() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .delete(
              Uri.parse(
                Uri.decodeFull(Uri.https(ApiKeys.gApiURL, api).toString()),
              ),
              headers: {"Content-Type": 'application/json; charset=utf-8'},
              body: json.encode(parameters),
            )
            .timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> linkToPage() async {
    List appSecurity = await AppSecurity.checkDevMode();
    bool isAppSecured = appSecurity[0]["is_secured"];
    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        var response = await http
            .get(
              Uri.https("luvpay.ph", "/terms-of-use"),
              headers: {"Content-Type": 'application/json; charset=utf-8'},
            )
            .timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          return "Success";
        } else {
          return null;
        }
      } catch (e) {
        return "No Internet";
      }
    }
  }

  Future<dynamic> pingInternet() async {
    try {
      final response = await http
          .get(Uri.https("www.google.com", "/"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return "Success";
      } else {
        return null;
      }
    } catch (e) {
      return "No Internet";
    }
  }
}
