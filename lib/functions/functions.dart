import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice2/places.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/variables.dart';
import 'package:luvpay/functions/eta_calculator.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/notification_controller.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/routes/routes.dart';
import '../sqlite/pa_message_table.dart';
import '../sqlite/reserve_notification_table.dart';
import '../sqlite/share_location_table.dart';
import 'package:uuid/uuid.dart';

class Functions {
  static GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;
  static Future<Uint8List> getSearchMarker(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  static Future<List> getUserBalance() async {
    final respo = await Authentication().getUserData2().then((userData) async {
      String subApi = "${ApiKeys.getUserBalance}${userData["user_id"]}";

      final response = await HttpRequestApi(api: subApi).get();
      if (response == "No Internet") {
        return [
          {"has_net": false, "success": false, "items": []},
        ];
      }
      if (response == null) {
        return [
          {"has_net": true, "success": false, "items": []},
        ];
      }
      return ([
        {"has_net": true, "success": true, "items": response["items"]},
      ]);
    });

    return respo;
  }

  static Future<void> getUserBalance2(context, Function cb) async {
    void logoutAccount() async {
      CustomDialogStack.showError(
        context,
        "Error",
        "There are some changes made in your account. please contact support.",
        () async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          Navigator.pop(context);

          await NotificationDatabase.instance.readAllNotifications().then((
            notifData,
          ) async {
            if (notifData.isNotEmpty) {
              for (var nData in notifData) {
                NotificationController.cancelNotificationsById(
                  nData["reserved_id"],
                );
              }
            }
            var logData = pref.getString('loginData');
            var mappedLogData = [jsonDecode(logData!)];
            mappedLogData[0]["is_active"] = "N";
            pref.setString("loginData", jsonEncode(mappedLogData[0]!));

            NotificationDatabase.instance.deleteAll();
            PaMessageDatabase.instance.deleteAll();
            ShareLocationDatabase.instance.deleteAll();
            NotificationController.cancelNotifications();
            Get.offAndToNamed(Routes.login);
          });
        },
      );
    }

    Authentication().getUserData().then((userData) {
      if (userData == null) {
        cb([
          {"has_net": true, "success": false, "items": []},
        ]);
        logoutAccount();
      } else {
        var user = jsonDecode(userData);

        String subApi = "${ApiKeys.getUserBalance}${user["user_id"]}";

        HttpRequestApi(api: subApi).get().then((returnBalance) async {
          if (returnBalance == "No Internet") {
            cb([
              {"has_net": false, "success": false, "items": []},
            ]);

            return;
          }
          if (returnBalance == null) {
            cb([
              {"has_net": true, "success": false, "items": []},
            ]);

            return;
          }
          if (returnBalance["items"].isEmpty) {
            logoutAccount();
          } else {
            cb([
              {
                "has_net": true,
                "success": true,
                "items": returnBalance["items"],
              },
            ]);
          }
        });
      }
    });
  }

  static Future<void> getLocation(BuildContext context, Function cb) async {
    try {
      List ltlng = await Functions.getCurrentPosition();

      if (ltlng.isNotEmpty) {
        Map<String, dynamic> firstItem = ltlng[0];
        if (firstItem.containsKey('lat') && firstItem.containsKey('long')) {
          double lat = double.parse(firstItem['lat'].toString());
          double long = double.parse(firstItem['long'].toString());
          cb(LatLng(lat, long));
        } else {
          cb(null);
        }
      } else {
        cb(null);
      }
    } catch (e) {
      cb(null);
    }
  }

  static Future<List> getCurrentPosition() async {
    final position = await geolocatorPlatform.getCurrentPosition();

    return [
      {"lat": position.latitude, "long": position.longitude},
    ];
  }

  static Future<LatLng> searchPlaces(BuildContext context, String query) async {
    try {
      final places = GoogleMapsPlaces(apiKey: Variables.mapApiKey);
      PlacesSearchResponse response = await places.searchByText(query);

      if (response.isOkay) {
        if (response.results.isNotEmpty) {
          var location = response.results[0].geometry?.location;

          if (location == null) {
            throw Exception("Invalid location data received");
          }

          return LatLng(location.lat, location.lng);
        }
        return LatLng(0, 0);
      } else {
        return LatLng(0, 0);
      }
    } catch (e) {
      return LatLng(0, 0);
    }
  }

  static Future<bool> checkAvailability(
    String startTimeStr,
    String endTimeStr, {
    time,
  }) async {
    DateTime currentTime = time ?? await Functions.getTimeNow();

    List<String> startParts = startTimeStr.split(':');
    List<String> endParts = endTimeStr.split(':');

    int startHour = int.parse(startParts[0]);
    int startMinute = int.parse(startParts[1]);
    int endHour = int.parse(endParts[0]);
    int endMinute = int.parse(endParts[1]);

    DateTime startTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      startHour,
      startMinute,
    );

    DateTime endTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      endHour,
      endMinute,
    );

    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  static Future<List<Map<String, dynamic>>> fetchETA(
    LatLng origin,
    LatLng destination,
  ) async {
    final calculator = EtaCalculators(origin, destination, vehicleType: 'car');

    final result = calculator.calculateEta();
    return [
      {"distance": result["distanceFormatted"], "time": result["etaFormatted"]},
    ];
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latDouble = lat / 1e5;
      double lngDouble = lng / 1e5;
      poly.add(LatLng(latDouble, lngDouble));
    }

    return poly;
  }

  static Future<String?> getAddress(double lat, double long) async {
    try {
      DateTime startTime = await Functions.getTimeNow();

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark placemark = placemarks[0];
      String locality = placemark.locality.toString();
      String subLocality = placemark.subLocality.toString();
      String street = placemark.street.toString();
      String subAdministrativeArea = placemark.subAdministrativeArea.toString();
      String myAddress =
          "$street,$subLocality,$locality,$subAdministrativeArea.";

      final duration = startTime.difference(startTime);

      await Future.delayed(duration);

      return "$myAddress-${locality.isEmpty ? subLocality : locality}";
    } catch (e) {
      return null;
    }
  }

  static List<dynamic> sortJsonList(
    List<dynamic> jsonList,
    String key, {
    bool ascending = true,
  }) {
    jsonList.sort((a, b) {
      final comparison = a[key].compareTo(b[key]);
      return ascending ? comparison : -comparison;
    });
    return jsonList.reversed.toList();
  }

  static Future<DateTime> getTimeNow() async {
    try {
      DateTime timeNow = await NTP.now().timeout(Duration(seconds: 2));
      return timeNow;
    } catch (e) {
      return DateTime.now();
    }
  }

  static Future<dynamic> generateQr() async {
    int userId = await Authentication().getUserId();
    String apiParam = ApiKeys.generatePayKey;
    dynamic param = {"luvpay_id": userId};

    final response =
        await HttpRequestApi(api: apiParam, parameters: param).put();

    Get.back();
    if (response == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return {"response": response, "data": []};
    }
    if (response == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return {"response": response, "data": []};
    }
    if (response["success"] == 'N') {
      CustomDialogStack.showInfo(
        Get.context!,
        "lvupark",
        "No data found for app version. Please contact support.",
        () {
          Get.back();
        },
      );
      return {"response": "No data", "data": response["items"][0]};
    } else {
      return {"response": "Success", "data": response["payment_hk"]};
    }
  }

  static void popPage([int times = 1]) {
    for (int i = 0; i < times; i++) {
      Get.back();
    }
  }

  static bool isValidInput(double inputAmount, serviceFee, balance) {
    double totalAmount = inputAmount + serviceFee;
    return totalAmount <= balance;
  }

  static Uint8List generateKey(String key, int length) {
    var keyBytes = utf8.encode(key);
    if (keyBytes.length < length) {
      keyBytes = Uint8List.fromList([
        ...keyBytes,
        ...List.filled(length - keyBytes.length, 0),
      ]);
    } else if (keyBytes.length > length) {
      keyBytes = keyBytes.sublist(0, length);
    }
    return Uint8List.fromList(keyBytes);
  }

  static Future<void> logoutUser(String sessionId, Function cb) async {
    CustomDialogStack.showLoading(Get.context!);

    if (sessionId.isEmpty) {
      cb({"is_true": true, "data": 0});
      Get.back();
      return;
    }

    DateTime timeNow = await Functions.getTimeNow();
    String formattedDt = DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow);

    Map<String, dynamic> putLogoutParam = {
      "dt_out": formattedDt,
      "session_id": sessionId,
    };

    final response =
        await HttpRequestApi(
          api: ApiKeys.putLogout,
          parameters: putLogoutParam,
        ).putBody();
    Get.back();
    if (response == "No Internet") {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response["success"] == "Y") {
      cb({"is_true": true, "data": response["user_id"]});
      final userLogin = await Authentication().getUserLogin();
      if (userLogin != null) {
        List userData = [userLogin];
        userData =
            userData.map((e) {
              e["is_login"] = "N";
              return e;
            }).toList();
        await Authentication().setLogin(jsonEncode(userData[0]));
      }

      Authentication().enableTimer(false);
      return;
    } else {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showError(Get.context!, "Error", response["msg"], () {
        Get.back();
      });
      return;
    }
  }

  static Future<void> logoutUserSession(String sessionId, Function cb) async {
    DateTime timeNow = await Functions.getTimeNow();
    String formattedDt = DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow);

    Map<String, dynamic> putLogoutParam = {
      "dt_out": formattedDt,
      "session_id": sessionId,
    };

    final response =
        await HttpRequestApi(
          api: ApiKeys.putLogout,
          parameters: putLogoutParam,
        ).putBody();

    if (response == "No Internet") {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response["success"] == "Y") {
      cb({"is_true": true, "data": response["user_id"]});

      Authentication().enableTimer(false);
      return;
    } else {
      cb({"is_true": false, "data": 0});
      CustomDialogStack.showError(Get.context!, "Error", response["msg"], () {
        Get.back();
      });
      return;
    }
  }

  Future<String> getUniqueDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString('device_id');

    if (storedDeviceId == null) {
      var uuid = Uuid();
      storedDeviceId = uuid.v4();
      await prefs.setString('device_id', storedDeviceId);
    }

    return storedDeviceId;
  }

  Future<void> requestOtp(Map<String, String> param, Function cb) async {
    CustomDialogStack.showLoading(Get.context!);

    HttpRequestApi(
      api: ApiKeys.postGenerateOtp,
      parameters: param,
    ).postBody().then((returnData) async {
      Get.back();

      if (returnData == "No Internet") {
        cb(returnData);
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Please check your internet connection and try again.",
          () {
            Get.back();
          },
        );

        return;
      }
      if (returnData == null) {
        cb(returnData);
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Error while connecting to server, Please try again.",
          () {
            Get.back();
          },
        );

        return;
      }

      if (returnData["success"] == 'Y') {
        cb(returnData);
        return;
      } else {
        CustomDialogStack.showError(
          Get.context!,
          "Security Warning",
          returnData["msg"],
          () {
            Get.back();
            if (returnData["status"] == "PENDING") {
              cb(returnData);
              return;
            }
            if (returnData["status"] == "LOCKED") {
              List mapData = [returnData];

              mapData =
                  mapData.map((e) {
                    e["mobile_no"] = param["mobile_no"];
                    return e;
                  }).toList();

              Future.delayed(Duration(milliseconds: 200), () {
                Get.offAllNamed(Routes.lockScreen, arguments: mapData);
              });
            }
          },
        );
        return;
      }
    });
  }

  Future<void> verifyMobile(String mobileNo, Function cb) async {
    CustomDialogStack.showLoading(Get.context!);
    HttpRequestApi(api: "${ApiKeys.getAcctStatus}$mobileNo/vlevel").get().then((
      objData,
    ) {
      Get.back();
      if (objData == "No Internet") {
        cb({"success": false, "data": {}});
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });

        return;
      }
      if (objData == null) {
        cb({"success": false, "data": {}});
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        if (objData["success"] == "Y") {
          cb({"success": true, "data": objData});
        } else {
          cb({"success": false, "data": {}});
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            objData["msg"],
            () {
              Get.back();
            },
          );
          return;
        }
      }
    });
  }

  void getSecQdata(mobile, Function cb) {
    CustomDialogStack.showLoading(Get.context!);
    Random random = Random();
    int myRan = random.nextInt(3) + 1;

    String subApi = "${ApiKeys.getSecQue}?mobile_no=$mobile&secq_no=$myRan";

    HttpRequestApi(api: subApi).get().then((returnData) {
      Get.back();
      if (returnData == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });

        return;
      }
      if (returnData == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        if (returnData["items"].isNotEmpty) {
          List seqData = returnData["items"];
          seqData =
              seqData.map((e) {
                e["secq_no"] = myRan;
                return e;
              }).toList();

          cb(seqData);
        } else {
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            "Make sure that you've entered the correct phone number.",
            () {
              Get.back();
            },
          );
          return;
        }
      }
    });
  }

  void verifyAccount(String mobileNo, Function cb) async {
    CustomDialogStack.showLoading(Get.context!);
    var params = "${ApiKeys.verifyUserAccount}?mobile_no=$mobileNo";

    HttpRequestApi(api: params).get().then((objData) async {
      Get.back();
      if (objData == "No Internet") {
        cb({"success": false, "data": {}});
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });

        return;
      }
      if (objData == null) {
        cb({"success": false, "data": {}});
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        if (objData["msg"] == "Success") {
          cb({"success": true, "data": objData});
        } else {
          cb({"success": false, "data": {}});
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            objData["msg"],
            () {
              Get.back();
            },
          );
          return;
        }
      }
    });
  }

  static String getIconAssetForPwdDetails(
    String parkingTypeCode,
    String vehicleTypes,
  ) {
    switch (parkingTypeCode) {
      case "S":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/blue/blue_cmp.png';
        } else if (vehicleTypes.toString().toLowerCase().contains(
          "Motorcycle",
        )) {
          return 'assets/details_logo/blue/blue_mp.png';
        } else {
          return 'assets/details_logo/blue/blue_cp.png';
        }
      case "P":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/orange/orange_cmp.png';
        } else if (vehicleTypes.toString().toLowerCase().contains(
          "motorcycle",
        )) {
          return 'assets/details_logo/orange/orange_mp.png';
        } else {
          return 'assets/details_logo/orange/orange_cp.png';
        }
      case "C":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/green/green_cmp.png';
        } else if (vehicleTypes.toString().toLowerCase().contains(
          "motorcycle",
        )) {
          return 'assets/details_logo/green/green_mp.png';
        } else {
          return 'assets/details_logo/green/green_cp.png';
        }
      default:
        return 'assets/details_logo/violet/v.png';
    }
  }

  static String getIconAssetForNonPwdDetails(
    String parkingTypeCode,
    String vehicleTypes,
  ) {
    switch (parkingTypeCode) {
      case "S":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/blue/blue_cm.png';
        } else if (vehicleTypes.contains("Motorcycle")) {
          return 'assets/details_logo/blue/blue_motor.png';
        } else {
          return 'assets/details_logo/blue/blue_car.png';
        }
      case "P":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/orange/orange_cm.png';
        } else if (vehicleTypes.contains("Motorcycle")) {
          return 'assets/details_logo/orange/orange_motor.png';
        } else {
          return 'assets/details_logo/orange/orange_car.png';
        }
      case "C":
        if (vehicleTypes.toString().toLowerCase().contains("motorcycle") &&
            vehicleTypes.toString().toLowerCase().contains("light")) {
          return 'assets/details_logo/green/green_cm.png';
        } else if (vehicleTypes.toString().toLowerCase().contains(
          "motorcycle",
        )) {
          return 'assets/details_logo/green/green_motor.png';
        } else {
          return 'assets/details_logo/green/green_car.png';
        }
      case "V":
        return 'assets/details_logo/violet/v.png';
      default:
        return 'assets/images/no_image.png';
    }
  }

  Future<void> getIpOfDomain() async {
    try {
      final result = await InternetAddress.lookup('app.luvpay.ph');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {}
    } catch (e) {
      print('Failed to get IP: $e');
    }
  }

  static Future<bool> isOpenArea(mData, DateTime timeNow) async {
    Map<String, dynamic> jsonData = mData;
    Map<String, String> jsonDatas = {};
    Iterable<String> keys = jsonData.keys;
    String today = DateFormat('EEEE').format(timeNow).toLowerCase();

    for (var key in keys) {
      if (key.toLowerCase() == today.toLowerCase()) {
        jsonDatas[key] = jsonData[key];
      }
    }
    String value = jsonData[today].toString();
    return value.toLowerCase() == "y" ? true : false;
  }

  static Future<String> parkingStatus(List data, DateTime timeNow) async {
    bool isOperatingTime = await isOpenArea(data[0], timeNow);
    DateTime parseTime(String time) {
      DateTime parsed = DateFormat("HH:mm").parse(time);
      return DateTime(
        timeNow.year,
        timeNow.month,
        timeNow.day,
        parsed.hour,
        parsed.minute,
      );
    }

    DateTime openTime = parseTime(data[0]["opened_time"].toString().trim());
    DateTime closeTime = parseTime(data[0]["closed_time"].toString().trim());

    DateTime earlyBookingTime = openTime.subtract(Duration(minutes: 30));
    DateTime earlyBookingOTParking = closeTime.subtract(Duration(minutes: 30));

    if (!isOperatingTime) {
      return "Closed";
    }
    if (timeNow.isAfter(earlyBookingTime) && timeNow.isBefore(openTime)) {
      if (data[0]["is_allow_overnight"] == "Y") {
        return "Open";
      }
      return "Closed";
    }

    if (timeNow.isBefore(openTime) || timeNow.isAfter(closeTime)) {
      if (data[0]["is_allow_overnight"] == "Y") {
        return "Open";
      }
      return "Closed";
    } else {
      if (data[0]["is_allow_overnight"] == "Y" &&
          timeNow.isAfter(earlyBookingOTParking)) {
        return "Open";
      }
      return "Open";
    }
  }

  static Future<dynamic> getDropdownVehicles({parkAreaId}) async {
    String api = "${ApiKeys.getDropdownVhTypesArea}$parkAreaId";

    final returnData = await HttpRequestApi(api: api).get();

    if (returnData == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return [];
    }

    if (returnData == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return [];
    }

    if (returnData["items"] is List) {
      return returnData["items"];
    }

    return [];
  }

  Image getIconImage(String category) {
    String icon = "assets/images/";
    if (category.toLowerCase().contains("large")) {
      icon = "${icon}large";
    } else if (category.toLowerCase().contains("motor")) {
      icon = "${icon}motorcycle";
    } else {
      icon = "${icon}car";
    }

    return Image(image: AssetImage("$icon.png"), height: 40);
  }

  Widget getIconDetails(String category) {
    String icon = "assets/area_details/";
    if (category.toLowerCase().contains("large")) {
      icon = "${icon}truck_details";
    } else if (category.toLowerCase().contains("motor")) {
      icon = "${icon}motor_details";
    } else {
      icon = "${icon}car_details";
    }

    return SvgPicture.asset(fit: BoxFit.cover, "$icon.svg");
  }

  static String formatDistance(num distanceInKm) {
    if (distanceInKm < 1) {
      num distanceInMeters = distanceInKm * 1000;
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${distanceInKm.toStringAsFixed(2)} km';
    }
  }

  String getDisplayName(Map<String, dynamic> user) {
    final first = user['first_name'] ?? '';
    final middle = user['middle_name'] ?? '';
    final last = user['last_name'] ?? '';
    final mobile = user['mobile_no'] ?? '';

    final fullName =
        [
          first,
          middle.toString().isNotEmpty ? "${middle[0]}." : middle,
          last,
        ].where((e) => e.toString().trim().isNotEmpty).join(' ').trim();

    if (fullName.isNotEmpty) return fullName;

    if (mobile.toString().isNotEmpty && mobile.toString().length >= 4) {
      return "User ${mobile.toString().substring(mobile.toString().length - 4)}";
    }

    return "Wallet User";
  }
}
