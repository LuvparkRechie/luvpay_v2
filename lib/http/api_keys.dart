import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static final bool isProduction = dotenv.env['IS_PRODUCTION'] == 'true';
  static final String luvApi =
      isProduction ? dotenv.env['LUV_API_PROD']! : dotenv.env['LUV_API_TEST']!;
  static final String parkSpaceApi =
      isProduction
          ? dotenv.env['PARK_SPACE_API_PROD']!
          : dotenv.env['PARK_SPACE_API_TEST']!;
  static final String gApiURL =
      isProduction
          ? dotenv.env['G_API_URL_PROD']!
          : dotenv.env['G_API_URL_TEST']!;

  static final String getPaymentKey = dotenv.env['GET_PAYMENT_KEY']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String generatePayKey = dotenv.env['GENERATE_PAY_KEY']!
      .replaceAll('{LUV_API}', luvApi); //

  static final String getSecQue = dotenv.env['GET_SEC_QUE']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getSecDropdown = dotenv.env['GET_SEC_DROPDOWN']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getUserBalance = dotenv.env['GET_USER_BALANCE']!
      .replaceAll('{LUV_API}', luvApi);
  static final String verifyUserAccount = dotenv.env['VERIFY_USER_ACCOUNT']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getIdle = dotenv.env['GET_IDLE']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getTransLogs = dotenv.env['GET_TRANS_LOGS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getParkingRes = dotenv.env['GET_PARKING_RES']!.replaceAll(
    '{PARK_SPACE_API}',
    parkSpaceApi,
  );
  static final String getResQr = dotenv.env['GET_RES_QR']!.replaceAll(
    '{PARK_SPACE_API}',
    parkSpaceApi,
  );
  static final String getActiveParking = dotenv.env['GET_ACTIVE_PARKING']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getNearbyParkingLoc = dotenv
      .env['GET_NEARBY_PARKING_LOC']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getSuggestedParking = dotenv.env['GET_SUGGESTED_PARKING']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);

  static final String getDropdownRadius = dotenv.env['GET_DD_RADIUS']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getParkingTypes = dotenv.env['GET_PARKING_TYPES']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);

  static final String getRegion = dotenv.env['GET_REGION']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getProvince = dotenv.env['GET_PROVINCE']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getCity = dotenv.env['GET_CITY']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getBrgy = dotenv.env['GET_BRGY']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getRecipient = dotenv.env['GET_RECIPIENT']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postThirdPartyPayment = dotenv
      .env['POST_THIRD_PARTY_PAYMENT']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getUserAccStatus = dotenv.env['GET_USER_ACC_STATUS']!
      .replaceAll('{LUV_API}', luvApi);

  static final String getBankDetails = dotenv.env['GET_BANK_DETAILS']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getBankParam = dotenv.env['GET_BANK_PARAM']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postShareToken = dotenv.env['POST_SHARE_TOKEN']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getParkingRates = dotenv.env['GET_PARKING_RATES']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postUserReg = dotenv.env['POST_USER_REG']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );

  static final String putUpdateUserProf = dotenv.env['PUT_UPDATE_USER_PROF']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getRegisteredVehicle = dotenv
      .env['GET_REGISTERED_VEHICLE']!
      .replaceAll('{LUV_API}', luvApi);
  static final String postRegisterVehicle = dotenv.env['POST_REGISTER_VEHICLE']!
      .replaceAll('{LUV_API}', luvApi);
  static final String deleteRegVh = dotenv.env['DELETE_REG_VH']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getVehicleBrands = dotenv.env['GET_VEHICLE_BRANDS']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postLogin = dotenv.env['POST_LOGIN']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getLogin = dotenv.env['GET_LOGIN']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String putLogin = dotenv.env['PUT_LOGIN']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String putLogout = dotenv.env['PUT_LOGOUT']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getParkingNotice = dotenv.env['GET_PARKING_NOTICE']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getComputeDistance = dotenv.env['GET_COMPUTE_DISTANCE']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getAcctStatus = dotenv.env['GET_ACCT_STATUS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getDdVehicleTypes = dotenv.env['GET_DD_VEHICLE_TYPES']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getDropdownVhTypesArea = dotenv
      .env['GET_DROPDOWN_VH_TYPES_AREA']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);

  static final String postQueueBooking = dotenv.env['POST_QUEUE_BOOKING']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getPaMessage = dotenv.env['GET_PA_MESSAGE']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String putReadPaMessages = dotenv.env['PUT_READ_PA_MESSAGES']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getFAQ = dotenv.env['GET_FAQ']!.replaceAll(
    '{PARK_SPACE_API}',
    parkSpaceApi,
  );
  static final String getFAQsAnswer = dotenv.env['GET_FAQS_ANSWER']!.replaceAll(
    '{PARK_SPACE_API}',
    parkSpaceApi,
  );
  static final String postDeleteUserAcct = dotenv.env['POST_DELETE_USER_ACCT']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getParkingAmenities = dotenv.env['GET_PARKING_AMENITIES']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getAllAmenities = dotenv.env['GET_ALL_AMENITIES']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String bookParking = dotenv.env['BOOK_PARKING']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postSelfChkIn = dotenv.env['POST_SELF_CHK_IN']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String putCancelBooking = dotenv.env['PUT_CANCEL_BOOKING']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postExtendParking = dotenv.env['POST_EXTEND_PARKING']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postCancelAutoExtend = dotenv
      .env['POST_CANCEL_AUTO_EXTEND']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postVhParkingSubs = dotenv.env['POST_VH_PARKING_SUBS']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getSubscribedVehicle = dotenv
      .env['GET_SUBSCRIBED_VEHICLE']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String getVhSubscription = dotenv.env['GET_VH_SUBSCRIPTION']!
      .replaceAll('{PARK_SPACE_API}', parkSpaceApi);
  static final String postAddFavBiller = dotenv.env['POST_ADD_FAV_BILLER']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getFavBiller = dotenv.env['GET_FAV_BILLER']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String deleteFavBiller = dotenv.env['DELETE_FAV_BILLER']!
      .replaceAll('{LUV_API}', luvApi);
  static final String postPayBills = dotenv.env['POST_PAY_BILLS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postMerchant = dotenv.env['POST_MERCHANT']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getMerchantScan = dotenv.env['GET_MERCHANT_SCAN']!
      .replaceAll('{LUV_API}', luvApi);
  static final String getMerchants = dotenv.env['GET_MERCHANTS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getBillerTemp = dotenv.env['GET_BILLER_TEMP']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getBillers = dotenv.env['GET_BILLERS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postGenerateOtp = dotenv.env['POST_GENERATE_OTP']!
      .replaceAll('{LUV_API}', luvApi);
  static final String putVerifyOtp = dotenv.env['PUT_VERIFY_OTP']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String postRegDevice = dotenv.env['POST_REG_DEVICE']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String getSession = dotenv.env['GET_SESSION']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );

  static final String notificationApi = dotenv.env['WALLET_NOTIFICATIONS']!
      .replaceAll('{LUV_API}', luvApi);
  static final String postMayaIntegration = dotenv.env['POST_MAYA_END_POINT']!
      .replaceAll('{LUV_API}', luvApi);
  static final String postGetMayaRef = dotenv.env['POST_MAYA_REF']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
  static final String updateMayaBalance = dotenv.env['POST_UPDATE_MAYA_BAL']!
      .replaceAll('{LUV_API}', luvApi);

  static final String vouchers = dotenv.env['VOUCHERS']!.replaceAll(
    '{LUV_API}',
    luvApi,
  );
}
