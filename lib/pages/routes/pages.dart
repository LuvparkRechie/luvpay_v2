import 'package:get/get.dart';
import 'package:luvpay/otp_field/index.dart';
import 'package:luvpay/pages/billers/index.dart';
import 'package:luvpay/pages/bills_payment/index.dart';
import 'package:luvpay/pages/faq/index.dart';
import 'package:luvpay/pages/forgot_password/index.dart';
import 'package:luvpay/pages/forgot_password/utils/create_new/index.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';
import 'package:luvpay/pages/qr/index.dart';
import 'package:luvpay/pages/security_settings/index.dart';
import 'package:luvpay/pages/subwallet/index.dart';
import 'package:luvpay/pages/wallet_recharge_load/index.dart';

import '../dashboard/index.dart';
import '../landing/index.dart';
import '../loading/index.dart';
import '../lock_screen/index.dart';
import '../login/index.dart';
import '../merchant/merchantreceipt/index.dart';
import '../onboarding/index.dart';
import '../registration/index.dart';
import '../splash_screen/index.dart';
import 'routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: Routes.onboarding,
      page: () => const MyOnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.landing,
      page: () => const LandingScreen(),
      binding: LandingBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.billers,
      page: () => Billers(),
      binding: BillersBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.billsPayment,
      page: () => const BillsPayment(),
      binding: BillsPaymentBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.loading,
      page: () => const LoadingScreen(),
      binding: LoadingBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginScreenBinding(),
      preventDuplicates: true,
      transition: Transition.noTransition, // Custom transition
      transitionDuration: Duration(
        milliseconds: 300,
      ), // Speed of animation  preventDuplicates: true,
    ),

    GetPage(
      name: Routes.registration,
      page: () => const RegistrationPage(),
      binding: RegistrationBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.lockScreen,
      page: () => const LockScreen(),
      binding: LockScreenBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.otpField,
      page: () => const OtpFieldScreen(),
      binding: OtpFieldScreenBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.qr,
      page: () => const QR(),
      binding: QRBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.forgotPass,
      page: () => const ForgotPassword(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.createNewPass,
      page: () => const CreateNewPassword(),
      binding: CreateNewPasswordBinding(),

      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.faqpage,
      page: () => const FaqPage(),
      binding: FaqPageBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.updProfile,
      page: () => const UpdateProfile(),
      binding: UpdateProfileBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.securitySettings,
      page: () => const Security(),
      binding: SecuritySettingsBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.merchantReceipt,
      page: () => MerchantQRReceipt(),
      binding: merchantQRRBindings(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.subwallet,
      page: () => SubWalletScreen(),
      binding: SubWalletBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.walletrechargeload,
      page: () => const WalletRechargeLoadScreen(),
      binding: WalletRechargeLoadBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
  ];
}
