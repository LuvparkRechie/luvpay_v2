import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../dialogs/dialogs.dart';
import '../../widgets/colors.dart';
import '../../widgets/luvpay_text.dart';
import '../../widgets/custom_scaffold.dart';

class WebviewPage extends StatefulWidget {
  final String urlDirect, label;
  final bool isBuyToken;
  final bool? hasAgree;
  final Function? onAgree;
  final Function? callback;
  final EdgeInsetsGeometry? bodyPadding;
  final Map<String, dynamic>? lbReturn;
  final Map<String, dynamic>? userData;

  const WebviewPage({
    super.key,
    required this.urlDirect,
    this.isBuyToken = true,
    this.hasAgree = false,
    this.onAgree,
    this.callback,
    required this.label,
    this.bodyPadding,
    this.lbReturn,
    this.userData,
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
  bool hasError = false;
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          CustomDialogStack.showConfirmation(
            context,
            "Confirmation",
            "Are you sure you want to close this page?",
            leftText: "No",
            rightText: "Yes",
            () => Get.back(),
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
          () => Get.back(),
          () {
            Get.back();
            Get.back();
          },
        );
      },
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
      bottomNavigationBar:
          widget.urlDirect.toLowerCase().contains("landbank") &&
                  !isLoading &&
                  !hasError &&
                  widget.lbReturn?["status"]?.toString().toLowerCase() ==
                      "success"
              ? Container(
                height: MediaQuery.of(context).size.height * 0.45,
                padding: EdgeInsets.all(8),
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    LuvpayText(
                      text: "Transfer fees may apply",
                      style: AppTextStyle.body1(context),
                    ),
                    SizedBox(height: 15),
                    LuvpayText(
                      text: "${widget.userData?["name"] ?? ""}",
                      style: AppTextStyle.h2(context),
                      color: AppColorV2.lpBlueBrand,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LuvpayText(text: "Mobile No: "),
                        LuvpayText(
                          text:
                              (() {
                                final n =
                                    widget.userData?["to_mobile_no"] ?? "";
                                return n.length < 4
                                    ? n
                                    : n.replaceRange(
                                      n.length - 4,
                                      n.length,
                                      "••••",
                                    );
                              })(),
                          style: AppTextStyle.body1(context),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LuvpayText(text: "Reference No: "),
                        LuvpayText(
                          text:
                              (() {
                                final n =
                                    widget.lbReturn?["reference_no"]
                                        ?.toString() ??
                                    "";
                                return n.length < 10
                                    ? "•" * n.length
                                    : n.replaceRange(0, 10, "•" * 10);
                              })(),
                          style: AppTextStyle.body1(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    LuvpayText(
                      text: "${widget.lbReturn?["amount"] ?? ""}",
                      style: AppTextStyle.h2(context),
                    ),
                    if (widget.lbReturn?["service_fee"] != null &&
                        widget.lbReturn!["service_fee"] != "0")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LuvpayText(text: "Service Fee: "),
                          LuvpayText(
                            text: "${widget.lbReturn?["service_fee"]}",
                            style: AppTextStyle.body1(context),
                          ),
                        ],
                      ),
                  ],
                ),
              )
              : null,
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

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            index++;
            if (index <= 1 && mounted) setState(() => isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted)
              setState(() {
                isLoading = false;
                hasError = false;
              });
            widget.callback?.call(true);
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.host == 'luvpark.ph' && uri.path.startsWith('/webhooks/')) {
              final status = uri.queryParameters['_st']?.toUpperCase();
              Get.back(result: {'status': status, 'url': request.url});
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted)
              setState(() {
                isLoading = false;
                hasError = true;
              });
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

    setState(() => _controller = controller);
  }
}
