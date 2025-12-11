import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../custom_widgets/alert_dialog.dart';
import '../custom_widgets/app_color_v2.dart';

class WebviewPage extends StatefulWidget {
  final String urlDirect, label;
  final bool isBuyToken;
  final bool? hasAgree;
  final Function? onAgree;
  final Function? callback;
  final EdgeInsetsGeometry? bodyPadding;

  const WebviewPage({
    super.key,
    required this.urlDirect,
    this.isBuyToken = true,
    this.hasAgree = false,
    this.onAgree,
    this.callback,
    required this.label,
    this.bodyPadding,
  });

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer()),
  };

  WebViewController? _controller;
  final UniqueKey _key = UniqueKey();
  bool isLoading = true;
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      useNormalBody: true,
      backgroundColor: AppColorV2.lpBlueBrand,
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          CustomDialogStack.showConfirmation(
            context,
            "Confirmation",
            "Are you sure you want to close this page?",
            leftText: "No",
            rightText: "Yes",
            () {
              Get.back();
            },
            () {
              Get.back();
              Get.back();
            },
          );
        }
      },
      enableCustom: false,
      enableToolBar: true,
      onPressedLeading: () {
        CustomDialogStack.showConfirmation(
          context,
          "Confirmation",
          "Are you sure you want to close this page?",
          leftText: "No",
          rightText: "Yes",
          () {
            Get.back();
          },
          () {
            Get.back();
            Get.back();
          },
        );
      },

      // canPop: index <= 1,
      padding:
          widget.bodyPadding ?? EdgeInsets.only(top: 10, left: 0, right: 0),
      scaffoldBody:
          isLoading
              ? Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    color: AppColorV2.lpBlueBrand,
                  ),
                ),
              )
              : WebViewWidget(
                controller: _controller!,
                key: _key,
                gestureRecognizers: gestureRecognizers,
              ),
    );
  }

  void initialize() {
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
              allowsInlineMediaPlayback: true,
              mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
            )
            : const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Intercept page loads, including redirect success URLs
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            index++;

            if (index <= 1) {
              if (mounted) setState(() => isLoading = true);
            }
          },
          onPageFinished: (url) {
            if (mounted) setState(() => isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);

            if (uri.host == 'luvpark.ph' && uri.path.startsWith('/webhooks/')) {
              final status = uri.queryParameters['_st']?.toUpperCase();

              Get.back(result: {'status': status, 'url': request.url});

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (message) {
          if (message.message == 'payment_success') {
            Get.back(result: {'status': 'success'});
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message.message)));
          }
        },
      )
      ..enableZoom(false)
      ..loadRequest(Uri.parse(widget.urlDirect));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // Android-Specific (Optional)
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    setState(() => _controller = controller);
  }
}
