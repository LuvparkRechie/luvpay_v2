// // ignore_for_file: deprecated_member_use

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:luvpay/auth/authentication.dart';
// import 'package:luvpay/custom_widgets/app_color_v2.dart';
// import 'package:luvpay/custom_widgets/custom_text_v2.dart';
// import 'package:luvpay/functions/functions.dart';
// import 'package:luvpay/http/http_request.dart';
// import 'package:luvpay/pages/dashboard/index.dart';
// import 'package:luvpay/pages/routes/routes.dart';
// import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

// import '../../custom_widgets/no_data_found.dart';
// import '../../http/api_keys.dart';
// import 'notifications.dart';

// class WalletScreen extends StatefulWidget {
//   const WalletScreen({super.key});

//   @override
//   State<WalletScreen> createState() => WalletScreenState();
// }

// class WalletScreenState extends State<WalletScreen> {
//   bool isLoading = false;
//   List userData = [];
//   bool hasNet = true;
//   List logs = [];
//   Timer? _timer;
//   Map<String, dynamic> userInfo = {};
//   int unreadMsg = 0;
//   int notifCount = 0;
//   @override
//   void initState() {
//     super.initState();
//     getUserInfo();
//     getUserData();
//     getNotificationCount();
//     getLogs();
//     _startAutoRefresh();
//   }

//   // void getNotif() async {
//   //   List<dynamic> msgdata =
//   //       await PaMessageDatabase.instance.getUnreadMessages();
//   //   unreadMsg = msgdata.length;
//   // }

//   void getUserInfo() async {
//     userInfo = await Authentication().getUserData2();
//   }

//   void _startAutoRefresh() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 5), (_) {
//       getUserData();
//       getLogs();
//     });
//   }

//   Future<void> getUserData() async {
//     if (isLoading) return;
//     setState(() => isLoading = true);

//     try {
//       final data = await Functions.getUserBalance();

//       if (mounted) {
//         setState(() {
//           userData = data;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error fetching user data: $e");
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }
//   }

//   Future<void> getLogs() async {
//     DateTime timeNow = await Functions.getTimeNow();
//     String toDate = timeNow.toString().split(" ")[0];
//     String fromDate =
//         timeNow.subtract(const Duration(days: 1)).toString().split(" ")[0];
//     String userId = userInfo["user_id"].toString();

//     String subApi =
//         "${ApiKeys.getTransLogs}?user_id=$userId&tran_date_from=$fromDate&tran_date_to=$toDate";
//     HttpRequestApi(api: subApi).get().then((response) async {
//       if (response is Map && response["items"].isNotEmpty) {
//         DateTime timeNow = await Functions.getTimeNow();
//         DateTime today = timeNow.toUtc();

//         String todayString = today.toIso8601String().substring(0, 10);

//         if (mounted) {
//           List items = response["items"];
//           setState(() {
//             logs =
//                 items
//                     .where((transaction) {
//                       String transactionDate =
//                           transaction['tran_date'].toString().split("T")[0];
//                       return transactionDate == todayString;
//                     })
//                     .toList()
//                     .take(5)
//                     .toList();
//           });
//         }
//       }
//     });
//   }

//   Future<void> getNotificationCount() async {
//     try {
//       final item = await Authentication().getUserData();
//       String userId = jsonDecode(item!)['user_id'].toString();

//       String subApi = "${ApiKeys.notificationApi}$userId";
//       HttpRequestApi(api: subApi).get().then((response) async {
//         if (response["items"].isNotEmpty) {
//           notifCount = response["items"].length;
//         } else {
//           notifCount = 0;
//         }
//       });
//     } catch (e) {
//       notifCount = 0;
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColorV2.background,
//       appBar: AppBar(
//         elevation: 0,
//         toolbarHeight: 0,
//         backgroundColor: Colors.transparent,
//         systemOverlayStyle: SystemUiOverlayStyle(
//           statusBarColor: AppColorV2.background,
//           statusBarIconBrightness: Brightness.dark,
//           statusBarBrightness: Brightness.light,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(19, 19, 19, 0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _WalletHeaderSection(
//               userInfo: userInfo,
//               unreadMsg: unreadMsg,
//               notifCount: notifCount,
//             ),
//             SizedBox(height: 10),
//             _ModernBalanceCardWithBgImage(
//               userInfo: userInfo,
//               userData: userData,
//             ),
//             Expanded(
//               child: RefreshIndicator.adaptive(
//                 onRefresh: getUserData,
//                 child: CustomScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   slivers: [
//                     SliverToBoxAdapter(child: SizedBox(height: 20)),
//                     SliverToBoxAdapter(child: _BillsPaymentSection()),
//                     SliverToBoxAdapter(child: SizedBox(height: 30)),
//                     SliverToBoxAdapter(
//                       child: _ModernTransactionHistorySection(logs: logs),
//                     ),
//                     SliverToBoxAdapter(child: SizedBox(height: 30)),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _WalletHeaderSection extends StatelessWidget {
//   final int unreadMsg;
//   final int notifCount;
//   final Map<String, dynamic> userInfo;
//   const _WalletHeaderSection({
//     required this.userInfo,
//     required this.unreadMsg,
//     required this.notifCount,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10.0),
//       child: SafeArea(
//         child: Row(
//           children: [
//             _buildProfileImage(),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   DefaultText(
//                     text: 'Welcome back,',
//                     style: AppTextStyle.body1,
//                     color: AppColorV2.primaryTextColor,
//                   ),
//                   DefaultText(
//                     text: Functions().getDisplayName(userInfo),
//                     style: AppTextStyle.h4,
//                     maxLines: 1,
//                   ),
//                 ],
//               ),
//             ),
//             Row(
//               children: [
//                 Stack(
//                   clipBehavior: Clip.none,
//                   alignment: Alignment.topRight,
//                   children: [
//                     InkWell(
//                       onTap: () {
//                         Get.to(WalletNotifications());
//                       },
//                       child: SvgPicture.asset(
//                         "assets/images/${notifCount != 0 ? "wallet_active_notification" : "wallet_inactive_notification"}.svg",
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileImage() {
//     final String? base64Image = userInfo["image_base64"];

//     if (base64Image != null && base64Image.isNotEmpty) {
//       try {
//         String imageString = base64Image;
//         if (base64Image.contains(',')) {
//           imageString = base64Image.split(',').last;
//         }

//         // Check if we have a cached image provider
//         ImageProvider? cachedImage = ImageCacheHelper.getCachedImage(
//           base64Image,
//         );

//         if (cachedImage == null) {
//           // Create and cache new image provider
//           final bytes = base64Decode(imageString);
//           cachedImage = MemoryImage(bytes);
//           ImageCacheHelper.cacheImage(base64Image, cachedImage);
//         }

//         return Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 2),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColorV2.primaryVariant.withOpacity(0.3),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ClipOval(
//             child: Image(
//               image: cachedImage,
//               width: 50,
//               height: 50,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return _buildDefaultProfileIcon();
//               },
//             ),
//           ),
//         );
//       } catch (e) {
//         return _buildDefaultProfileIcon();
//       }
//     } else {
//       return _buildDefaultProfileIcon();
//     }
//   }

//   Widget _buildDefaultProfileIcon() {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: LinearGradient(
//           colors: [
//             AppColorV2.primaryVariant,
//             AppColorV2.primaryVariant.withOpacity(0.7),
//           ],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppColorV2.primaryVariant.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
//     );
//   }
// }

// class ImageCacheHelper {
//   static final Map<String, ImageProvider> _cache = {};

//   static ImageProvider? getCachedImage(String base64String) {
//     if (_cache.containsKey(base64String)) {
//       return _cache[base64String];
//     }
//     return null;
//   }

//   static void cacheImage(String base64String, ImageProvider imageProvider) {
//     _cache[base64String] = imageProvider;
//   }
// }

// class _ModernBalanceCardWithBgImage extends StatelessWidget {
//   final Map<String, dynamic> userInfo;
//   final List userData;
//   const _ModernBalanceCardWithBgImage({
//     required this.userData,
//     required this.userInfo,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 180,
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//       decoration: BoxDecoration(
//         image: const DecorationImage(
//           fit: BoxFit.fill,
//           image: AssetImage("assets/images/wallet_card_bg.png"),
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColorV2.primaryVariant.withOpacity(0.3),
//             blurRadius: 50,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               DefaultText(
//                 text: 'Total Balance',
//                 style: AppTextStyle.h3_semibold,
//                 color: AppColorV2.surface,
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: DefaultText(
//                   text:
//                       userInfo["mobile_no"] != null
//                           ? "•••••••${userInfo["mobile_no"].toString().substring(userInfo["mobile_no"].toString().length - 4)}"
//                           : "•••••••••••",

//                   style: AppTextStyle.body1,
//                   color: AppColorV2.background,
//                 ),
//               ),
//             ],
//           ),

//           DefaultText(
//             text:
//                 userData.isEmpty || userData[0]["items"].isEmpty
//                     ? "•••••"
//                     : toCurrencyString(userData[0]["items"][0]["amount_bal"]),
//             style: GoogleFonts.poppins(
//               color: Colors.white,
//               fontSize: 32,
//               fontWeight: FontWeight.w700,
//               height: 1.1,
//             ),
//           ),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               SizedBox(),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: AppColorV2.success,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     DefaultText(
//                       text: 'Active',
//                       style: AppTextStyle.body1,
//                       color: AppColorV2.background,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _BillsPaymentSection extends StatefulWidget {
//   const _BillsPaymentSection();

//   @override
//   State<_BillsPaymentSection> createState() => _BillsPaymentSectionState();
// }

// class _BillsPaymentSectionState extends State<_BillsPaymentSection> {
//   final Map<String, List<Map<String, dynamic>>> billersByCategory = {
//     'Utilities': [
//       {
//         'name': 'Electricity',
//         'icon': Icons.lightbulb_outline_rounded,
//         'color': Colors.amber,
//         'biller': 'Meralco',
//       },
//       {
//         'name': 'Water',
//         'icon': Icons.water_drop_outlined,
//         'color': Colors.blue,
//         'biller': 'Maynilad',
//       },
//       {
//         'name': 'Internet',
//         'icon': Icons.wifi_rounded,
//         'color': Colors.green,
//         'biller': 'PLDT',
//       },
//       {
//         'name': 'Mobile',
//         'icon': Icons.phone_iphone_rounded,
//         'color': Colors.purple,
//         'biller': 'Globe',
//       },
//       {
//         'name': 'Cable TV',
//         'icon': Icons.live_tv_rounded,
//         'color': Colors.purple,
//         'biller': 'Sky Cable',
//       },
//     ],
//     'Loans': [
//       {
//         'name': 'Bank Loan',
//         'icon': Icons.account_balance_rounded,
//         'color': Colors.orange,
//         'biller': 'BPI',
//       },
//       {
//         'name': 'Credit Card',
//         'icon': Icons.credit_card_rounded,
//         'color': Colors.indigo,
//         'biller': 'BDO',
//       },
//       {
//         'name': 'Personal Loan',
//         'icon': Icons.money_rounded,
//         'color': Colors.teal,
//         'biller': 'Security Bank',
//       },
//       {
//         'name': 'Car Loan',
//         'icon': Icons.directions_car_rounded,
//         'color': Colors.red,
//         'biller': 'Metrobank',
//       },
//       {
//         'name': 'Home Loan',
//         'icon': Icons.house_rounded,
//         'color': Colors.brown,
//         'biller': 'PNB',
//       },
//     ],
//     'Government': [
//       {
//         'name': 'SSS',
//         'icon': Icons.assignment_rounded,
//         'color': Colors.blueGrey,
//         'biller': 'Social Security',
//       },
//       {
//         'name': 'Pag-IBIG',
//         'icon': Icons.home_work_rounded,
//         'color': Colors.brown,
//         'biller': 'Pag-IBIG Fund',
//       },
//       {
//         'name': 'PhilHealth',
//         'icon': Icons.local_hospital_rounded,
//         'color': Colors.green,
//         'biller': 'PhilHealth',
//       },
//       {
//         'name': 'BIR',
//         'icon': Icons.receipt_long_rounded,
//         'color': Colors.red,
//         'biller': 'Bureau of Internal Revenue',
//       },
//       {
//         'name': 'LGU',
//         'icon': Icons.account_balance_rounded,
//         'color': Colors.blue,
//         'biller': 'Local Government',
//       },
//     ],
//     'Insurance': [
//       {
//         'name': 'Life Insurance',
//         'icon': Icons.family_restroom_rounded,
//         'color': Colors.pink,
//         'biller': 'Sun Life',
//       },
//       {
//         'name': 'Car Insurance',
//         'icon': Icons.car_crash_rounded,
//         'color': Colors.orange,
//         'biller': 'Malayan Insurance',
//       },
//       {
//         'name': 'Health Insurance',
//         'icon': Icons.health_and_safety_rounded,
//         'color': Colors.green,
//         'biller': 'Maxicare',
//       },
//       {
//         'name': 'Home Insurance',
//         'icon': Icons.house_rounded,
//         'color': Colors.blue,
//         'biller': 'Prudential',
//       },
//     ],
//   };

//   @override
//   Widget build(BuildContext context) {
//     final categories = billersByCategory.keys.toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 DefaultText(
//                   text: 'Bills Payment',
//                   color: AppColorV2.onSurface,
//                   style: AppTextStyle.h3,
//                 ),
//                 const SizedBox(height: 2),
//                 DefaultText(
//                   text: 'Select a category to pay bills',
//                   color: AppColorV2.bodyTextColor,
//                 ),
//               ],
//             ),
//             SizedBox(width: 10),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColorV2.primaryVariant.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: DefaultText(
//                   textAlign: TextAlign.center,
//                   text: '${categories.length} Categories',
//                   maxLines: 1,
//                   color: AppColorV2.primaryVariant,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),

//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             childAspectRatio: 1.4,
//           ),
//           itemCount: categories.length,
//           itemBuilder: (context, index) {
//             final category = categories[index];
//             final billers = billersByCategory[category]!;
//             return _buildCategoryCard(category, billers);
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryCard(
//     String category,
//     List<Map<String, dynamic>> billers,
//   ) {
//     final categoryData = _getCategoryData(category);

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () {
//           _showBillersBottomSheet(category, billers);
//         },
//         child: Container(
//           decoration: BoxDecoration(
//             color: categoryData['color'].withOpacity(0.1),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: categoryData['color'].withOpacity(0.2)),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Wrap(
//               children: [
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: categoryData['color'].withOpacity(0.2),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         categoryData['icon'],
//                         color: categoryData['color'],
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     DefaultText(
//                       text: category,
//                       color: AppColorV2.onSurface,
//                       style: AppTextStyle.body1,
//                     ),
//                     const SizedBox(height: 4),
//                     DefaultText(
//                       text: '${billers.length} billers',
//                       color: AppColorV2.bodyTextColor,
//                       maxLines: 1,
//                       maxFontSize: 12,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Map<String, dynamic> _getCategoryData(String category) {
//     switch (category) {
//       case 'Utilities':
//         return {'icon': Icons.bolt_rounded, 'color': Colors.blue};
//       case 'Loans':
//         return {'icon': Icons.money_rounded, 'color': Colors.green};
//       case 'Government':
//         return {'icon': Icons.account_balance_rounded, 'color': Colors.orange};
//       case 'Insurance':
//         return {'icon': Icons.security_rounded, 'color': Colors.purple};
//       default:
//         return {'icon': Icons.receipt_rounded, 'color': Colors.grey};
//     }
//   }

//   void _showBillersBottomSheet(
//     String category,
//     List<Map<String, dynamic>> billers,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.8,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(25),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.05),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.arrow_back_rounded),
//                     ),
//                     const SizedBox(width: 8),
//                     DefaultText(text: category, style: AppTextStyle.h3),
//                     const Spacer(),
//                     DefaultText(
//                       text: '${billers.length} billers',
//                       style: AppTextStyle.h3_semibold,
//                     ),
//                   ],
//                 ),
//               ),

//               // Billers List
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: billers.length,
//                   itemBuilder: (context, index) {
//                     final biller = billers[index];
//                     return _buildBillerListItem(
//                       name: biller['name'] as String,
//                       icon: biller['icon'] as IconData,
//                       color: biller['color'] as Color,
//                       billerName: biller['biller'] as String,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildBillerListItem({
//     required String name,
//     required IconData icon,
//     required Color color,
//     required String billerName,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             Navigator.pop(context); // Close bottom sheet
//             Get.toNamed(Routes.billsPayment, arguments: {'biller': billerName});
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, color: color, size: 20),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DefaultText(
//                     text: name,
//                     color: AppColorV2.onSurface,
//                     style: AppTextStyle.paragraph1,
//                   ),
//                 ),
//                 const Icon(
//                   Icons.arrow_forward_ios_rounded,
//                   size: 16,
//                   color: Colors.grey,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ModernTransactionHistorySection extends StatelessWidget {
//   final List logs;
//   const _ModernTransactionHistorySection({required this.logs});

//   @override
//   Widget build(BuildContext context) {
//     final DashboardController controller = Get.put(DashboardController());
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             DefaultText(
//               text: 'Recent Transactions',
//               color: AppColorV2.onSurface,
//               style: AppTextStyle.h3,
//             ),
//             if (logs.isNotEmpty)
//               TextButton(
//                 onPressed: () {
//                   controller.changePage(1);
//                 },
//                 style: TextButton.styleFrom(
//                   foregroundColor: AppColorV2.primaryVariant,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 2,
//                   ),
//                 ),
//                 child: DefaultText(
//                   text: 'View All',
//                   color: AppColorV2.primaryVariant,
//                   style: AppTextStyle.body1,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         _buildModernTransactionList(),
//       ],
//     );
//   }

//   Widget _buildModernTransactionList() {
//     String formatDate(String dateString) {
//       try {
//         DateTime date = DateTime.parse(dateString);
//         return DateFormat('MMM dd, yyyy • HH:mm').format(date);
//       } catch (e) {
//         return dateString;
//       }
//     }

//     final displayLogs =
//         logs.isEmpty
//             ? []
//             : logs.length <= 5
//             ? logs
//             : logs.sublist(0, 5);

//     if (displayLogs.isEmpty) {
//       return Center(child: NoDataFound());
//     }

//     return ListView.separated(
//       separatorBuilder: (context, index) {
//         return const SizedBox(height: 14);
//       },
//       padding: EdgeInsets.zero,
//       itemCount: displayLogs.length,
//       itemBuilder: (context, index) {
//         return _ModernTransactionTile(
//           name: displayLogs[index]['category'] as String,
//           category: displayLogs[index]['tran_desc'] as String,
//           date: formatDate(displayLogs[index]['tran_date']),
//           amount: displayLogs[index]['amount'] as String,
//           isPositive: !displayLogs[index]['amount'].toString().contains("-"),
//         );
//       },
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//     );
//   }
// }

// class _ModernTransactionTile extends StatelessWidget {
//   final String name;
//   final String category;
//   final String date;
//   final String amount;
//   final bool isPositive;

//   const _ModernTransactionTile({
//     required this.name,
//     required this.category,
//     required this.date,
//     required this.amount,
//     required this.isPositive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.03),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(10),
//           onTap: () {},
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color:
//                       isPositive
//                           ? AppColorV2.success.withOpacity(0.1)
//                           : AppColorV2.error.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   isPositive
//                       ? Icons.arrow_downward_rounded
//                       : Icons.arrow_upward_rounded,
//                   color: isPositive ? AppColorV2.success : AppColorV2.error,
//                   size: 16,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     DefaultText(
//                       text: name,
//                       style: GoogleFonts.inter(
//                         fontWeight: FontWeight.w600,
//                         color: AppColorV2.onSurface,
//                         fontSize: 13,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     DefaultText(
//                       text: category,
//                       style: AppTextStyle.body1,
//                       maxFontSize: 12,
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   DefaultText(
//                     text: amount,
//                     style: AppTextStyle.body1,
//                     color: isPositive ? AppColorV2.success : AppColorV2.error,
//                   ),
//                   const SizedBox(height: 2),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 2,
//                     ),
//                     decoration: BoxDecoration(
//                       color:
//                           isPositive
//                               ? AppColorV2.success.withOpacity(0.1)
//                               : AppColorV2.error.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: DefaultText(
//                       text: isPositive ? 'CREDIT' : 'DEBIT',
//                       style: GoogleFonts.inter(
//                         fontSize: 8,
//                         fontWeight: FontWeight.w600,
//                         color:
//                             isPositive ? AppColorV2.success : AppColorV2.error,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../custom_widgets/app_color_v2.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedTab = 0;
  final PageController _pageController = PageController();
  final double _balance = 12456.75;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorV2.background,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            SizedBox(height: 20),

            // Balance Card
            _buildBalanceCard(),
            SizedBox(height: 30),

            _buildTabBar(),
            SizedBox(height: 20),

            // Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                children: [_buildTransactionsTab(), _buildTopUpTab()],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Profile
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColorV2.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning',
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Alex Morgan',
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Notifications
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColorV2.pastelBlueAccent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColorV2.lpBlueBrand,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColorV2.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: AppColorV2.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColorV2.lpBlueBrand.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₱${_balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '•••• 4512',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColorV2.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColorV2.pastelBlueAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        _selectedTab == 0
                            ? [
                              BoxShadow(
                                color: AppColorV2.boxStroke.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        color:
                            _selectedTab == 0
                                ? AppColorV2.lpBlueBrand
                                : AppColorV2.bodyTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    1,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        _selectedTab == 1
                            ? [
                              BoxShadow(
                                color: AppColorV2.boxStroke.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      'Top Up',
                      style: TextStyle(
                        color:
                            _selectedTab == 1
                                ? AppColorV2.lpBlueBrand
                                : AppColorV2.bodyTextColor,
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTransactionsTab() {
    final transactions = [
      {
        'icon': Icons.shopping_bag_rounded,
        'color': AppColorV2.secondary,
        'title': 'Grocery Store',
        'subtitle': 'Food & Drinks',
        'amount': '-₱1,245.00',
        'time': '2 hours ago',
        'isPositive': false,
      },
      {
        'icon': Icons.arrow_downward_rounded,
        'color': AppColorV2.success,
        'title': 'Salary',
        'subtitle': 'Monthly Income',
        'amount': '+₱25,000.00',
        'time': '1 day ago',
        'isPositive': true,
      },
      {
        'icon': Icons.bolt_rounded,
        'color': AppColorV2.warning,
        'title': 'Electric Bill',
        'subtitle': 'Utilities',
        'amount': '-₱2,345.50',
        'time': '2 days ago',
        'isPositive': false,
      },
      {
        'icon': Icons.local_cafe_rounded,
        'color': AppColorV2.lpBlueBrand,
        'title': 'Coffee Shop',
        'subtitle': 'Food & Drinks',
        'amount': '-₱185.00',
        'time': '3 days ago',
        'isPositive': false,
      },
    ];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        if (transactions.isEmpty) ...[
          NoTransactionsWidget(),
        ] else
          ...transactions.map(
            (transaction) => _buildTransactionItem(transaction),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorV2.boxStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: transaction['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: transaction['color'],
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  transaction['subtitle'],
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  transaction['time'],
                  style: TextStyle(
                    color: AppColorV2.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction['amount'],
                style: TextStyle(
                  color:
                      transaction['isPositive']
                          ? AppColorV2.success
                          : AppColorV2.primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      transaction['isPositive']
                          ? AppColorV2.success.withOpacity(0.1)
                          : AppColorV2.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction['isPositive'] ? 'CREDIT' : 'DEBIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color:
                        transaction['isPositive']
                            ? AppColorV2.success
                            : AppColorV2.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpTab() {
    final banks = [
      {
        'name': 'Maya',
        'image': 'assets/images/w_maya.png',
        'color': AppColorV2.lpBlueBrand,
      },
      {
        'name': 'Landbank',
        'image': 'assets/images/w_landbank.png',
        'color': AppColorV2.success,
      },
      {
        'name': 'UnionBank',
        'image': 'assets/images/w_unionbank.png',
        'color': AppColorV2.secondary,
      },
      {
        'name': 'InstaPay',
        'image': 'assets/images/w_instapay.png',
        'color': AppColorV2.warning,
      },
    ];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Top Up Methods',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Select your preferred bank to top up your wallet',
          style: TextStyle(color: AppColorV2.bodyTextColor, fontSize: 14),
        ),
        SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: banks.length,
          itemBuilder: (context, index) {
            final bank = banks[index];
            return _buildBankCard(bank, context);
          },
        ),
        SizedBox(height: 20),
        _buildQuickTopUpSection(),
      ],
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorV2.boxStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // _showTopUpDetails(context, bank['name']);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Using custom image instead of icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    bank['image'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return Container(
                        decoration: BoxDecoration(
                          color: bank['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getFallbackIcon(bank['name']),
                          color: bank['color'],
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  bank['name'],
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fallback icons in case images don't load
  IconData _getFallbackIcon(String bankName) {
    switch (bankName) {
      case 'Maya':
        return Icons.account_balance_wallet_rounded;
      case 'Landbank':
        return Icons.account_balance_rounded;
      case 'UnionBank':
        return Icons.business_rounded;
      case 'InstaPay':
        return Icons.flash_on_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildQuickTopUpSection() {
    final amounts = [100, 500, 1000, 2000, 5000, 10000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Top Up',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              amounts.map((amount) {
                return ActionChip(
                  label: Text('₱${amount.toString()}'),
                  labelStyle: TextStyle(
                    color: AppColorV2.lpBlueBrand,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColorV2.pastelBlueAccent,
                  onPressed: () {
                    _showTopUpBottomSheet('Quick Top Up', amount: amount);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showTopUpBottomSheet(String method, {int? amount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColorV2.boxStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Top Up via $method',
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter the amount you want to add to your wallet',
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 30),
                // Add your top up form here
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle top up confirmation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorV2.lpBlueBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue to Top Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NoTransactionsWidget extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final VoidCallback? onActionTap;

  const NoTransactionsWidget({
    super.key,
    this.message,
    this.subtitle,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Illustration
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColorV2.pastelBlueAccent.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: AppColorV2.lpBlueBrand.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Subtitle
          Text(
            subtitle ?? 'Your recent transactions will appear here',
            style: TextStyle(
              color: AppColorV2.bodyTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
