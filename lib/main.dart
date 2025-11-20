import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/variables.dart';
import 'package:luvpay/notification_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'custom_widgets/app_color_v2.dart';
import 'pages/routes/pages.dart';
import 'pages/routes/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  DartPingIOS.register();

  final packageInfo = await PackageInfo.fromPlatform();
  Variables.version = packageInfo.version;

  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  NotificationController.initializeLocalNotifications();
  NotificationController.initializeIsolateReceivePort();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _onUserActivity() {} // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MyApp',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColorV2.background,
          colorScheme: ColorScheme(
            primary: AppColorV2.lpBlueBrand,
            onPrimaryFixedVariant: AppColorV2.lpBlueBrand,
            secondary: AppColorV2.lpTealBrand,
            onSecondaryFixedVariant: AppColorV2.lpTealBrand,
            surface: Colors.white,
            error: AppColorV2.incorrectState,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColorV2.primaryTextColor,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          useMaterial3: false,
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 28 / 18,
              color: AppColorV2.background,
              fontStyle: FontStyle.normal,
            ),
            backgroundColor: AppColorV2.lpBlueBrand,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppColorV2.lpBlueBrand,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade300,
            thickness: 0.5,
            space: 15,
            indent: 5,
          ),
        ),
        navigatorObservers: [GetObserver()],
        initialRoute: Routes.splash,
        getPages: AppPages.pages,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:ikchatbot/ikchatbot.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   final List<String> keywords = [
//     'who are you',
//     'what is flutter',
//     'fuck',
//     'sorry',
//   ];

//   final List<String> responses = [
//     'I am a bot created by Iksoft Original, a proud Ghanaian',
//     'Flutter transforms the app development process. Build, test, and deploy beautiful mobile, web, desktop, and embedded apps from a single codebase.',
//     'You are such an idiot to tell me this. you dont have future. Look for Iksoft Original and seek for knowledge. here is his number +233550138086. call him you lazy deep shit',
//     'Good! i have forgiven you. dont do that again!',
//   ];
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     final chatBotConfig = IkChatBotConfig(
//       //SMTP Rating to your mail Settings
//       ratingIconYes: const Icon(Icons.star),
//       ratingIconNo: const Icon(Icons.star_border),
//       ratingIconColor: Colors.black,
//       ratingBackgroundColor: Colors.white,
//       ratingButtonText: 'Submit Rating',
//       thankyouText: 'Thanks for your rating!',
//       ratingText: 'Rate your experience:',
//       ratingTitle: 'Thank you for using the chatbot!',
//       body: 'This is a test email sent from Flutter and Dart.',
//       subject: 'Test Rating',
//       recipient: 'recipient@example.com',
//       isSecure: false,
//       senderName: 'Your Name',
//       smtpUsername: 'Your Email',
//       smtpPassword: 'your password',
//       smtpServer: 'stmp.gmail.com',
//       smtpPort: 587,
//       //Settings to your system Configurations
//       sendIcon: const Icon(Icons.send, color: Colors.black),
//       userIcon: const Icon(Icons.animation, color: Colors.white),
//       botIcon: const Icon(Icons.android, color: Colors.white),
//       botChatColor: Color.fromARGB(255, 104, 0, 101),
//       delayBot: 100,
//       closingTime: 1,
//       delayResponse: 1,
//       userChatColor: const Color.fromARGB(255, 103, 0, 0),
//       waitingTime: 1,
//       keywords: keywords,
//       responses: responses,
//       backgroundColor: Colors.white,
//       backgroundImage:
//           'https://i.pinimg.com/736x/d2/bf/d3/d2bfd3ea45910c01255ae022181148c4.jpg',
//       backgroundAssetimage: "lib/assets/bg.jpeg",
//       initialGreeting:
//           "Hello! \nWelcome to IkChatBot.\nHow can I assist you today?",
//       defaultResponse: "Sorry, I didn't understand your response.",
//       inactivityMessage: "Is there anything else you need help with?",
//       closingMessage: "This conversation will now close.",
//       inputHint: 'Send a message',
//       waitingText: 'Please wait...',
//       useAsset: false,
//     );

//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: MyHomePage(chatBotConfig: chatBotConfig),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   final IkChatBotConfig chatBotConfig;

//   const MyHomePage({super.key, required this.chatBotConfig});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final bool _chatIsOpened = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(centerTitle: true, title: const Text('ikChatBot Example')),
//       // floatingActionButton: FloatingActionButton(onPressed: () {
//       //   if(_chatIsOpened =  false) {
//       //     setState(() {
//       //     _chatIsOpened = true;
//       //     });
//       //   }else {
//       //     setState(() {
//       //       _chatIsOpened = false;
//       //     });
//       //   }
//       //
//       // },
//       // child: Icon(Icons.chat),),
//       body:
//           _chatIsOpened
//               ? const Center(child: Text('Welcome to my app,'))
//               : ikchatbot(config: widget.chatBotConfig),
//     );
//   }
// }
