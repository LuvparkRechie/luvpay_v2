import 'package:get/get.dart';
import 'package:luvpay/otp_field/index.dart';

import '../dashboard/index.dart';
import '../landing/index.dart';
import '../loading/index.dart';
import '../lock_screen/index.dart';
import '../login/index.dart';
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
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.landing,
      page: () => const LandingScreen(),
      binding: LandingBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.loading,
      page: () => const LoadingScreen(),
      binding: LoadingBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
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
    // GetPage(
    //     name: Routes.dashboard,
    //     page: () => const DashboardScreen(),
    //     binding: DashboardBinding()),
    GetPage(
      name: Routes.registration,
      page: () => const RegistrationPage(),
      binding: RegistrationBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.lockScreen,
      page: () => const LockScreen(),
      binding: LockScreenBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.otpField,
      page: () => const OtpFieldScreen(),
      binding: OtpFieldScreenBinding(),
      transition: Transition.rightToLeftWithFade, // Smooth slide transition
      transitionDuration: Duration(milliseconds: 300),
      preventDuplicates: true,
    ),
  ];
}
