// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';
import 'package:luvpay/features/routes/routes.dart';

import '../../shared/components/web_view/webview.dart';

class MyOnboardingPage extends StatefulWidget {
  const MyOnboardingPage({super.key});

  @override
  State<MyOnboardingPage> createState() => _MyOnboardingPageState();
}

class _MyOnboardingPageState extends State<MyOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _backgroundOffset = 0.0;
  double _titleOffset = 0.0;

  List<OnboardingPage> _buildPages(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      OnboardingPage(
        title: "Secure & Smart",
        description:
            "Bank-level security meets intelligent finance management. Your money stays safe while growing smarter.",
        imagePath: "assets/svg/wallet_secure.svg",
        primaryColor: AppColorV2.lpBlueBrand,
        accentColor: AppColorV2.lpTealBrand,
        iconData: Icons.shield_outlined,
      ),
      OnboardingPage(
        title: "Lightning Fast",
        description:
            "Transactions that happen in a blink. Send, receive, and pay instantly across the globe.",
        imagePath: "assets/svg/instant_pay.svg",
        primaryColor: cs.primary,
        accentColor: cs.secondary,
        iconData: Icons.bolt_outlined,
      ),
      OnboardingPage(
        title: "Your Financial AI",
        description:
            "Get personalized insights, smart budgets, and investment suggestions tailored just for you.",
        imagePath: "assets/svg/budget.svg",
        primaryColor: cs.onSurface,
        accentColor: AppColorV2.lpTealBrand,
        iconData: Icons.psychology_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (_pageController.page != null) {
      setState(() {
        _backgroundOffset = _pageController.page! * -150;
        _titleOffset = _pageController.page! * -50;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = theme.scaffoldBackgroundColor;
    final surface = cs.surface;

    final isDark = theme.brightness == Brightness.dark;
    final stroke =
        isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke.withOpacity(0.06);

    final pages = _buildPages(context);
    final currentPageColor = pages[_currentPage].primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    final isLast = _currentPage == pages.length - 1;

    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      enableToolBar: false,
      backgroundColor: bg,
      scaffoldBody: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubic,
            left: _backgroundOffset,
            child: Container(
              width: screenWidth * 3,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    pages[0].primaryColor.withOpacity(isDark ? 0.06 : 0.03),
                    pages[1].primaryColor.withOpacity(isDark ? 0.06 : 0.03),
                    pages[2].primaryColor.withOpacity(isDark ? 0.06 : 0.03),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: screenWidth / 3,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentPageColor.withOpacity(isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 50,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    pages[_currentPage].accentColor.withOpacity(
                      isDark ? 0.10 : 0.05,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              currentPageColor,
                              pages[_currentPage].accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: currentPageColor.withOpacity(
                                isDark ? 0.18 : 0.30,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: cs.onPrimary,
                            size: 26,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage == 0 ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: _currentPage != 0,
                          child: InkWell(
                            onTap: () {
                              _pageController.animateToPage(
                                pages.length - 1,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: surface.withOpacity(
                                  isDark ? 0.65 : 0.90,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: stroke, width: 1.5),
                              ),
                              child: LuvpayText(
                                text: "Skip",
                                style: AppTextStyle.paragraph1(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return ModernOnboardingPageWidget(
                        page: pages[index],
                        isActive: index == _currentPage,
                        titleOffset: _titleOffset,
                        index: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(pages.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == _currentPage ? 40 : 12,
                              height: 6,
                              decoration: BoxDecoration(
                                color:
                                    index == _currentPage
                                        ? currentPageColor
                                        : stroke,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow:
                                    index == _currentPage
                                        ? [
                                          BoxShadow(
                                            color: currentPageColor.withOpacity(
                                              isDark ? 0.18 : 0.30,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                        : [],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 48),
                      CustomButton(
                        text: isLast ? "Get Started" : "Continue",
                        leading:
                            isLast
                                ? Icon(
                                  Icons.check_rounded,
                                  color:
                                      isLast
                                          ? AppColorV2.lpBlueBrand
                                          : cs.onPrimary,
                                )
                                : Icon(
                                  Icons.arrow_forward_rounded,
                                  color:
                                      isLast
                                          ? AppColorV2.lpBlueBrand
                                          : cs.onPrimary,
                                ),
                        onPressed: () {
                          if (!isLast) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        textColor:
                            isLast ? AppColorV2.lpBlueBrand : cs.onPrimary,
                        btnColor:
                            isLast ? AppColorV2.background : currentPageColor,
                      ),

                      if (isLast) ...[
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () => Get.toNamed(Routes.login),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface.withOpacity(isDark ? 0.65 : 0.80),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: stroke, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LuvpayText(
                                  text: "Already have an account? ",
                                  style: AppTextStyle.paragraph1(
                                    context,
                                  ).copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 15,
                                  ),
                                ),
                                LuvpayText(
                                  text: "Sign In",
                                  style: AppTextStyle.paragraph1(
                                    context,
                                  ).copyWith(
                                    color: currentPageColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LuvpayText(
                              text: "By continuing, you accept the ",
                              style: AppTextStyle.paragraph2(
                                context,
                              ).copyWith(color: cs.onSurfaceVariant),
                            ),
                            InkWell(
                              onTap: () {
                                Get.to(
                                  const WebviewPage(
                                    bodyPadding: EdgeInsets.all(0),
                                    urlDirect:
                                        "https://luvpark.ph/terms-of-use/",
                                    label: "Terms of Use",
                                    isBuyToken: false,
                                  ),
                                );
                              },
                              child: LuvpayText(
                                style: AppTextStyle.paragraph2(context),
                                color: AppColorV2.lpBlueBrand,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                                text: "Terms of Use",
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() {
    Get.offAllNamed(Routes.registration);
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color accentColor;
  final IconData iconData;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.accentColor,
    required this.iconData,
  });
}

class ModernOnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final bool isActive;
  final double titleOffset;
  final int index;

  const ModernOnboardingPageWidget({
    super.key,
    required this.page,
    required this.isActive,
    required this.titleOffset,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, isActive ? 0 : 60, 0)
                ..scale(isActive ? 1.0 : 0.9),
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.primaryColor.withOpacity(isDark ? 0.22 : 0.15),
                      page.accentColor.withOpacity(isDark ? 0.14 : 0.08),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.primaryColor.withOpacity(
                        isDark ? 0.12 : 0.15,
                      ),
                      blurRadius: 40,
                      offset: const Offset(0, 25),
                      spreadRadius: -15,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: isActive ? 64 : 48,
                        height: isActive ? 64 : 48,
                        decoration: BoxDecoration(
                          color: page.accentColor.withOpacity(
                            isDark ? 0.18 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withOpacity(
                                isDark ? 0.18 : 0.20,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          page.iconData,
                          size: 24,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        width: isActive ? 100 : 80,
                        height: isActive ? 100 : 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              page.primaryColor.withOpacity(
                                isDark ? 0.16 : 0.10,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        transform:
                            Matrix4.identity()..scale(isActive ? 1.0 : 0.9),
                        child: SvgPicture.asset(
                          page.imagePath,
                          width: 140,
                          height: 140,
                          color: page.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: isActive ? 1 : 0.3,
              child: Transform.translate(
                offset: Offset(titleOffset + (index * 50), 0),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [page.primaryColor, page.accentColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds);
                          },
                          child: LuvpayText(
                            text: page.title,
                            style: AppTextStyle.h4(context),
                            color: Colors.white,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Positioned(
                          bottom: -12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              width: isActive ? 80 : 0,
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [page.accentColor, page.primaryColor],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: page.accentColor.withOpacity(
                                      isDark ? 0.30 : 0.50,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LuvpayText(
                      text: page.description,
                      style: AppTextStyle.body1(
                        context,
                      ).copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
