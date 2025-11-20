// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:luvpay/custom_widgets/app_color_v2.dart';
// import 'package:luvpay/custom_widgets/custom_scaffold.dart';
// import 'package:luvpay/custom_widgets/custom_text_v2.dart';
// import 'package:luvpay/custom_widgets/spacing.dart';

// import '../routes/routes.dart';
// import 'controller.dart';

// class MyOnboardingPage extends StatelessWidget {
//   const MyOnboardingPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final OnboardingController controller = Get.put(OnboardingController());
//     return CustomScaffoldV2(
//       enableToolBar: false,
//       padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
//       scaffoldBody: GetBuilder<OnboardingController>(
//         builder: (ctxt) {
//           final currentIndex = controller.currentPage.value;
//           final currentData = controller.sliderData[currentIndex];

//           return Column(
//             children: [
//               SizedBox(height: 35),

//               SizedBox(
//                 height: MediaQuery.of(context).size.height * .40,
//                 child: StretchingOverscrollIndicator(
//                   axisDirection: AxisDirection.right,
//                   child: ScrollConfiguration(
//                     behavior: ScrollBehavior().copyWith(overscroll: false),
//                     child: PageView(
//                       controller: controller.pageController,
//                       onPageChanged: (value) {
//                         controller.onPageChanged(value);
//                       },
//                       children: List.generate(
//                         controller.sliderData.length,
//                         (index) => Center(
//                           child: Image(
//                             image: AssetImage(
//                               "assets/images/${controller.sliderData[index]['icon']}.png",
//                             ),
//                             width: MediaQuery.of(context).size.width * .95,
//                             fit: BoxFit.contain,
//                             filterQuality: FilterQuality.high,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               spacing(height: 30),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   controller.sliderData.length,
//                   (index) => Container(
//                     width: currentIndex == index ? 10 : 5,
//                     height: currentIndex == index ? 10 : 5,
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color:
//                           currentIndex == index
//                               ? AppColorV2.lpBlueBrand
//                               : AppColorV2.pastelBlueAccent,
//                     ),
//                   ),
//                 ),
//               ),

//               spacing(height: 38),

//               Center(
//                 child: DefaultText(
//                   text: currentData["title"],
//                   textAlign: TextAlign.center,
//                   style: AppTextStyle.h1,
//                   height: 32 / 28,
//                 ),
//               ),
//               spacing(height: 10),
//               Center(
//                 child: DefaultText(
//                   text: currentData["subTitle"],
//                   textAlign: TextAlign.center,
//                   style: AppTextStyle.paragraph1,
//                   height: 20 / 16,
//                 ),
//               ),
//               spacing(height: 25),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         TextButton(
//                           onPressed: () {
//                             Get.offAndToNamed(Routes.login);
//                           },
//                           child: DefaultText(
//                             style: AppTextStyle.textButton,
//                             color: AppColorV2.lpBlueBrand,
//                             height: 20 / 16,
//                             text: "Skip",
//                           ),
//                         ),
//                         SizedBox(width: 35),
//                         GestureDetector(
//                           onTap: controller.btnTap,

//                           child: Padding(
//                             padding: const EdgeInsets.only(right: 14),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 15,
//                                 vertical: 10,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: AppColorV2.lpBlueBrand,

//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   DefaultText(
//                                     text:
//                                         currentIndex ==
//                                                 controller.sliderData.length - 1
//                                             ? "Get started"
//                                             : "Next",
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                   SizedBox(width: 5),
//                                   Icon(
//                                     Icons.arrow_right_alt_outlined,
//                                     color: Colors.white,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 50),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:luvpay/pages/login/index.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MyOnboardingPage extends StatefulWidget {
//   const MyOnboardingPage({super.key});

//   @override
//   State<MyOnboardingPage> createState() => _MyOnboardingPageState();
// }

// class _MyOnboardingPageState extends State<MyOnboardingPage> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final List<OnboardingPage> _pages = [
//     OnboardingPage(
//       title: "Secure Digital Wallet",
//       description:
//           "Keep your money safe with bank-level security and instant transaction protection",
//       imagePath: "assets/wallet_secure.svg",
//       color: Color(0xFF6366F1),
//     ),
//     OnboardingPage(
//       title: "Instant Payments",
//       description:
//           "Send and receive money instantly with zero fees to friends and family",
//       imagePath: "assets/instant_pay.svg",
//       color: Color(0xFF10B981),
//     ),
//     OnboardingPage(
//       title: "Smart Budgeting",
//       description:
//           "Track your spending and set budgets with intelligent insights",
//       imagePath: "assets/budget.svg",
//       color: Color(0xFFF59E0B),
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0F172A),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Skip button
//             Align(
//               alignment: Alignment.topRight,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: TextButton(
//                   onPressed: () {
//                     if (_currentPage < _pages.length - 1) {
//                       _pageController.animateToPage(
//                         _pages.length - 1,
//                         duration: Duration(milliseconds: 500),
//                         curve: Curves.easeInOut,
//                       );
//                     } else {
//                       _completeOnboarding();
//                     }
//                   },
//                   child: Text(
//                     _currentPage == _pages.length - 1 ? "Get Started" : "Skip",
//                     style: GoogleFonts.inter(
//                       color: Colors.white54,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // Page View
//             Expanded(
//               flex: 4,
//               child: PageView.builder(
//                 controller: _pageController,
//                 itemCount: _pages.length,
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentPage = index;
//                   });
//                 },
//                 itemBuilder: (context, index) {
//                   return OnboardingPageWidget(page: _pages[index]);
//                 },
//               ),
//             ),

//             // Indicator and Next button
//             Expanded(
//               flex: 1,
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     // Page indicator
//                     SmoothPageIndicator(
//                       controller: _pageController,
//                       count: _pages.length,
//                       effect: ExpandingDotsEffect(
//                         activeDotColor: _pages[_currentPage].color,
//                         dotColor: Colors.white24,
//                         dotHeight: 8,
//                         dotWidth: 8,
//                         spacing: 12,
//                         expansionFactor: 3,
//                       ),
//                     ),

//                     const SizedBox(height: 40),

//                     // Next/Get Started button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (_currentPage < _pages.length - 1) {
//                             _pageController.nextPage(
//                               duration: Duration(milliseconds: 500),
//                               curve: Curves.easeInOut,
//                             );
//                           } else {
//                             _completeOnboarding();
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _pages[_currentPage].color,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           elevation: 0,
//                           shadowColor: Colors.transparent,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               _currentPage == _pages.length - 1
//                                   ? "Get Started"
//                                   : "Next",
//                               style: GoogleFonts.inter(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Icon(
//                               Icons.arrow_forward_rounded,
//                               size: 20,
//                               color: Colors.white,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _completeOnboarding() {
//     // Navigate to main app or next screen
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginScreen()),
//     );
//   }
// }

// class OnboardingPage {
//   final String title;
//   final String description;
//   final String imagePath;
//   final Color color;

//   OnboardingPage({
//     required this.title,
//     required this.description,
//     required this.imagePath,
//     required this.color,
//   });
// }

// class OnboardingPageWidget extends StatelessWidget {
//   final OnboardingPage page;

//   const OnboardingPageWidget({super.key, required this.page});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Animated illustration container
//           Container(
//             width: 280,
//             height: 280,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   page.color.withOpacity(0.2),
//                   page.color.withOpacity(0.1),
//                 ],
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       page.color.withOpacity(0.4),
//                       page.color.withOpacity(0.2),
//                     ],
//                   ),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: SvgPicture.asset(
//                     page.imagePath,
//                     width: 120,
//                     height: 120,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 60),

//           // Title
//           Text(
//             page.title,
//             style: GoogleFonts.inter(
//               fontSize: 32,
//               fontWeight: FontWeight.w700,
//               color: Colors.white,
//               height: 1.2,
//             ),
//             textAlign: TextAlign.center,
//           ),

//           const SizedBox(height: 16),

//           // Description
//           Text(
//             page.description,
//             style: GoogleFonts.inter(
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//               color: Colors.white70,
//               height: 1.5,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/smooth_route.dart';
import 'package:luvpay/pages/dashboard/view.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../wallet/wallet_screen.dart';

class MyOnboardingPage extends StatefulWidget {
  const MyOnboardingPage({super.key});

  @override
  State<MyOnboardingPage> createState() => _MyOnboardingPageState();
}

class LuvPayColors {
  // Brand Colors
  static Color lpBlueBrand = const Color(0xFF0078FF);
  static Color lpTealBrand = const Color(0xFF00DEEB);
  static Color lpWhite = const Color(0xFFFFFFFF);

  // Derived colors
  static Color get background => lpWhite;
  static Color get textPrimary => const Color(0xFF1E293B);
  static Color get textSecondary => const Color(0xFF64748B);
  static Color get buttonText => lpWhite;
}

class _MyOnboardingPageState extends State<MyOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Secure Digital Wallet",
      description:
          "Keep your money safe with bank-level security and instant transaction protection",
      imagePath: "assets/svg/wallet_secure.svg",
      primaryColor: LuvPayColors.lpBlueBrand,
      secondaryColor: LuvPayColors.lpTealBrand,
    ),
    OnboardingPage(
      title: "Instant Payments",
      description:
          "Send and receive money instantly with zero fees to friends and family",
      imagePath: "assets/svg/instant_pay.svg",
      primaryColor: LuvPayColors.lpTealBrand,
      secondaryColor: LuvPayColors.lpBlueBrand,
    ),
    OnboardingPage(
      title: "Smart Budgeting",
      description:
          "Track your spending and set budgets with intelligent insights",
      imagePath: "assets/svg/budget.svg",
      primaryColor: LuvPayColors.lpBlueBrand,
      secondaryColor: LuvPayColors.lpTealBrand,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvPayColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.animateToPage(
                        _pages.length - 1,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? "Get Started" : "Skip",
                    style: GoogleFonts.inter(
                      color: LuvPayColors.lpBlueBrand,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Indicator and Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: _pages[_currentPage].primaryColor,
                      dotColor: LuvPayColors.lpBlueBrand.withOpacity(0.2),
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 12,
                      expansionFactor: 3,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: _pages[_currentPage].primaryColor
                            .withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? "Get Started"
                                : "Next",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: LuvPayColors.buttonText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: LuvPayColors.buttonText,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Secondary option for last page
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // Handle sign in action
                      },
                      child: Text(
                        "Already have an account? Sign In",
                        style: GoogleFonts.inter(
                          color: LuvPayColors.lpBlueBrand,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeOnboarding() {
    // Navigate to main app or next screen
    Get.offAllNamed(Routes.login);
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration container with gradient
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.primaryColor.withOpacity(0.1),
                  page.secondaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.primaryColor.withOpacity(0.15),
                      page.secondaryColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: page.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    page.imagePath,
                    width: 120,
                    height: 120,
                    color: page.primaryColor,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Title
          Text(
            page.title,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: LuvPayColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: LuvPayColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// class MainAppScreen extends StatefulWidget {
//   const MainAppScreen({super.key});

//   @override
//   State<MainAppScreen> createState() => _MainAppScreenState();
// }

// class _MainAppScreenState extends State<MainAppScreen> {
//   bool isLoading = false;
//   @override
//   void initState() {
//     super.initState();

//     initialize();
//   }

//   void initialize() async {
//     await Future.delayed(Duration(seconds: 3));
//     setState(() {
//       isLoading = true;
//     });
//     await Future.delayed(Duration(seconds: 1));
//     setState(() {
//       isLoading = false;
//     });
//     // ignore: use_build_context_synchronously
//     await SmoothRoute(context: context, child: LandingScreen()).route();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: LuvPayColors.background,
//       body: Stack(
//         children: [
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         LuvPayColors.lpBlueBrand,
//                         LuvPayColors.lpTealBrand,
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Icon(
//                     Icons.account_balance_wallet,
//                     color: LuvPayColors.lpWhite,
//                     size: 40,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   "Welcome to LuvPay!",
//                   style: GoogleFonts.inter(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w700,
//                     color: LuvPayColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   "Your digital wallet is ready to use",
//                   style: GoogleFonts.inter(
//                     fontSize: 16,
//                     color: LuvPayColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isLoading)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black.withValues(alpha: 0.2),
//                 child: Center(
//                   child: SizedBox(
//                     height: 40,
//                     width: 40,
//                     child: CircularProgressIndicator(color: Colors.grey),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
