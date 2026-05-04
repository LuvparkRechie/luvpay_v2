import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/shared/widgets/variables.dart';

import '../../security/security/app_security.dart';

class HttpRequestApi {
  static const String noInternetMessage = "No Internet";
  static const String defaultErrorMessage = "Failed to fetch data";
  static const Map<String, String> _defaultHeaders = {
    "Content-Type": "application/json; charset=utf-8",
  };
  static const Set<String> _supportedMethods = {
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  };

  final String api;
  final Object? parameters;

  const HttpRequestApi({required this.api, this.parameters});

  Future<dynamic> request({
    String method = "GET",
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
    bool returnHeaders = false,
    bool runSecurityCheck = true,
    bool includeDefaultHeaders = true,
  }) async {
    final normalizedMethod = method.toUpperCase();
    if (!_supportedMethods.contains(normalizedMethod)) {
      throw UnsupportedError("Unsupported HTTP method: $method");
    }

    final isAppSecured = await _ensureSecurity(
      runSecurityCheck: runSecurityCheck,
    );

    if (!isAppSecured) {
      return null;
    }

    final resolvedBody = body ?? parameters;
    final resolvedQueryParameters = _resolveQueryParameters(
      normalizedMethod,
      queryParameters,
    );
    final uri = _buildUri(
      apiKey: apiKey,
      queryParameters: resolvedQueryParameters,
    );
    final requestHeaders = _buildHeaders(
      headers,
      includeDefaultHeaders: includeDefaultHeaders,
    );

    try {
      final response = await _sendRequest(
        method: normalizedMethod,
        uri: uri,
        headers: requestHeaders,
        body: resolvedBody,
        timeout: timeout ?? _defaultTimeout(normalizedMethod),
      );

      _logRequest(
        method: normalizedMethod,
        uri: uri,
        body: resolvedBody,
        response: response,
      );

      if (!_isSuccessful(response.statusCode, successStatusCodes)) {
        return null;
      }

      if (returnHeaders) {
        return response.headers;
      }

      if (!decodeResponse) {
        return response.body;
      }

      return _decodeResponse(response);
    } catch (error) {
      _logRequest(
        method: normalizedMethod,
        uri: uri,
        body: resolvedBody,
        error: error,
      );
      return noInternetMessage;
    }
  }

  Future<dynamic> requestHandler({
    String? apiKey,
    int? ctr,
    String method = "GET",
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
    bool returnHeaders = false,
    bool runSecurityCheck = true,
    bool includeDefaultHeaders = true,
    String nullDataMessage = defaultErrorMessage,
    FutureOr<void> Function(int counter)? onInit,
    FutureOr<void> Function(String message)? onError,
    FutureOr<void> Function(dynamic result)? onSuccess,
  }) async {
    final counter = ctr == null ? 0 : ctr + 1;
    await onInit?.call(counter);

    try {
      final result = await request(
        method: method,
        apiKey: apiKey,
        queryParameters: queryParameters,
        body: body,
        headers: headers,
        timeout: timeout,
        successStatusCodes: successStatusCodes,
        decodeResponse: decodeResponse,
        returnHeaders: returnHeaders,
        runSecurityCheck: runSecurityCheck,
        includeDefaultHeaders: includeDefaultHeaders,
      );

      if (result == noInternetMessage) {
        await onError?.call("No internet connection");
        return result;
      }

      if (result == null) {
        await onError?.call(nullDataMessage);
        return null;
      }

      await onSuccess?.call(result);
      return result;
    } catch (error) {
      await onError?.call("An error occurred: $error");
      return null;
    }
  }

  Future<dynamic> get({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
  }) async {
    return request(
      method: "GET",
      apiKey: apiKey,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
    );
  }

  Future<dynamic> post({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
    bool returnHeaders = false,
  }) async {
    return request(
      method: "POST",
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
      returnHeaders: returnHeaders,
    );
  }

  Future<dynamic> postBody({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
  }) async {
    return post(
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
    );
  }

  Future<dynamic> put({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
    bool returnHeaders = false,
  }) async {
    return request(
      method: "PUT",
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
      returnHeaders: returnHeaders,
    );
  }

  Future<dynamic> putBody({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
  }) async {
    return put(
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
    );
  }

  Future<dynamic> put2({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
  }) async {
    return request(
      method: "PUT",
      apiKey: apiKey,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
      includeDefaultHeaders: false,
    );
  }

  Future<dynamic> patch({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
    bool returnHeaders = false,
  }) async {
    return request(
      method: "PATCH",
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
      returnHeaders: returnHeaders,
    );
  }

  Future<dynamic> deleteData({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
    List<int>? successStatusCodes,
    bool decodeResponse = true,
  }) async {
    return request(
      method: "DELETE",
      apiKey: apiKey,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
      timeout: timeout,
      successStatusCodes: successStatusCodes,
      decodeResponse: decodeResponse,
    );
  }

  Future<dynamic> linkToPage() async {
    final appSecurity = await AppSecurity.checkDeviceSecurity();
    final isAppSecured = appSecurity[0]["is_secured"];

    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    } else {
      try {
        final response = await http
            .get(
              Uri.https("luvpark.ph", "/terms-of-use"),
              headers: _defaultHeaders,
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return "Success";
        } else {
          return null;
        }
      } catch (_) {
        return noInternetMessage;
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
    } catch (_) {
      return noInternetMessage;
    }
  }

  Future<bool> _ensureSecurity({required bool runSecurityCheck}) async {
    if (!runSecurityCheck) {
      return true;
    }

    final appSecurity = await AppSecurity.checkDeviceSecurity();
    final isAppSecured = appSecurity[0]["is_secured"] == true;

    if (!isAppSecured) {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    }

    return isAppSecured;
  }

  Map<String, dynamic>? _resolveQueryParameters(
    String method,
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters != null) {
      return queryParameters;
    }

    if (method == "GET" && parameters is Map<String, dynamic>) {
      return Map<String, dynamic>.from(parameters as Map<String, dynamic>);
    }

    return null;
  }

  Uri _buildUri({
    String? apiKey,
    Map<String, dynamic>? queryParameters,
  }) {
    final targetApi = (apiKey ?? api).trim();
    final normalizedApi = targetApi.startsWith("/") ? targetApi : "/$targetApi";

    final baseUri =
        targetApi.startsWith("http://") || targetApi.startsWith("https://")
            ? Uri.parse(targetApi)
            : Uri.parse("https://${ApiKeys.gApiURL}$normalizedApi");

    final mergedQueryParameters = <String, String>{
      ...baseUri.queryParameters,
    };

    queryParameters?.forEach((key, value) {
      if (value != null) {
        mergedQueryParameters[key] = value.toString();
      }
    });

    return baseUri.replace(
      queryParameters:
          mergedQueryParameters.isEmpty ? null : mergedQueryParameters,
    );
  }

  Map<String, String> _buildHeaders(
    Map<String, String>? headers, {
    required bool includeDefaultHeaders,
  }) {
    final requestHeaders = <String, String>{};

    if (includeDefaultHeaders) {
      requestHeaders.addAll(_defaultHeaders);
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return requestHeaders;
  }

  Future<http.Response> _sendRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
    Object? body,
  }) {
    switch (method) {
      case "GET":
        return http.get(uri, headers: headers).timeout(timeout);
      case "POST":
        return http
            .post(
              uri,
              headers: headers,
              body: _encodeBody(body),
            )
            .timeout(timeout);
      case "PUT":
        return http
            .put(
              uri,
              headers: headers,
              body: _encodeBody(body),
            )
            .timeout(timeout);
      case "PATCH":
        return http
            .patch(
              uri,
              headers: headers,
              body: _encodeBody(body),
            )
            .timeout(timeout);
      case "DELETE":
        return http
            .delete(
              uri,
              headers: headers,
              body: _encodeBody(body),
            )
            .timeout(timeout);
      default:
        throw UnsupportedError("Unsupported HTTP method: $method");
    }
  }

  Object? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String) {
      return body;
    }

    return json.encode(body);
  }

  dynamic _decodeResponse(http.Response response) {
    final responseBody = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );

    if (responseBody.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(responseBody);
    } catch (_) {
      return responseBody;
    }
  }

  Duration _defaultTimeout(String method) {
    return method == "GET"
        ? const Duration(seconds: 20)
        : const Duration(seconds: 10);
  }

  bool _isSuccessful(int statusCode, List<int>? successStatusCodes) {
    if (successStatusCodes != null && successStatusCodes.isNotEmpty) {
      return successStatusCodes.contains(statusCode);
    }

    return statusCode >= 200 && statusCode < 300;
  }

  void _logRequest({
    required String method,
    required Uri uri,
    Object? body,
    http.Response? response,
    Object? error,
  }) {
    if (!kDebugMode) {
      return;
    }

    //   debugPrint("api: $uri");
    //   debugPrint("method: $method");

    //   if (body != null) {
    //     debugPrint("body: $body");
    //   }

    //   if (response != null) {
    //     debugPrint("statusCode: ${response.statusCode}");
    //     debugPrint("result: ${response.body}");
    //   }

    //   if (error != null) {
    //     debugPrint("error: $error");
    //   }
  }
}
