import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_flutter/Config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Component/buttons/socal_button.dart';
import '../InAppWebViewUtil.dart';
import '../Utils/constants.dart';
import '../bloc/gpsBloc/gps_bloc.dart';
import '../bloc/gpsBloc/gps_state.dart';
import '../locationbasedrawer/canada_drawer.dart';
import '../main.dart';
import '../model/native_item.dart';
import '../model/user_info.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:image/image.dart' as img; // Add this package in pubspec.yaml

import 'NoInternetConnectionPage.dart';

final webViewTabStateKey = GlobalKey<_WebViewTabState>();

class WebViewTab extends StatefulWidget {

  final NativeItem nativeItem;
  late final UserInfo? userInfo;

  WebViewTab({required this.nativeItem, required this.userInfo});

  @override
  State<WebViewTab> createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> with WidgetsBindingObserver, TickerProviderStateMixin {



  late final TabController _tabController;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGestureDisabled = false; // Track whether gestures are disabled



  static const MethodChannel _channel = MethodChannel('dialer_channel');

  InAppWebViewController? _webViewController;
  FindInteractionController? _findInteractionController;
  bool _isWindowClosed = false;
  bool IsInternetConnected = true;
  bool tabBarVisibliy = false;
  bool tabBarVisibliyTemp = false;
  late GPSBloc _gpsBloc;

  AlertDialog? _gpsDialog;
  UserInfo? _userInfo;
  late String deepLinkingURL;

  final TextEditingController _httpAuthUsernameController =
  TextEditingController();
  final TextEditingController _httpAuthPasswordController =
  TextEditingController();

  Future<void> setupInteractedMessage() async {
    // To handle messages while your application is in the foreground, listen to the onMessage stream
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        String action = jsonEncode(message.data);
        print('action ${action}');

        flutterLocalNotificationsPlugin!.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel!.id,
                channel!.name,
                priority: Priority.high,
                importance: Importance.high,
                styleInformation: DefaultStyleInformation(true, true),
                largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                channelShowBadge: true,
                autoCancel: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: action);
      }
      print('A new event was published!');
    });

    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
  //  showToast(message: 'test:${initialMessage.data['url']}');
      // Delay the deep link handling while other code runs
      Future.delayed(Duration(seconds: 3), () {
        _handleMessage(initialMessage);
      });
    }
    /*else {
      handleDeepLink(null);
    }*/

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: android, iOS: iOS);

    await flutterLocalNotificationsPlugin!.initialize(initSettings,
        onDidReceiveNotificationResponse: notificationTapForeGround,
        onDidReceiveBackgroundNotificationResponse: notificationTapForeGround);
  }

  void notificationTapForeGround(NotificationResponse notificationResponse) {
    final String? payloadString = notificationResponse.payload;
    if (payloadString != null) {
      final Map<String, dynamic> payloadMap = jsonDecode(payloadString);
      print('notificationPayLoad ${payloadMap}');
      final String? url = payloadMap['url'];
      print('notificationPayLoadurl ${url}');

      handleDeepLink(url);
    }
  }

  void _handleMessage(RemoteMessage message) {
    handleDeepLink(message.data['url']);
  }

  void handleDeepLink(String? redirectLink) {
    if (redirectLink != null && redirectLink.isNotEmpty) {
      Uri uri = Uri.parse(redirectLink);
      String segmentPath = uri.path + '?' + uri.query;
      deepLinkingURL = Config.HOME_URL + segmentPath;
    } else {
      deepLinkingURL = Config.HOME_URL;
    }
   _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(deepLinkingURL)));
  }


  @override
  void initState() {
    print('thisOneGetCall');
    WidgetsBinding.instance.addObserver(this);
    super.initState();


    _tabController = TabController(
      length: widget.nativeItem.bottom!.length,
      vsync: this,
    );

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent, // Change this to the desired color
    ));

    _gpsBloc = BlocProvider.of<GPSBloc>(context);

    // Set up the GPS listener here
    _gpsBloc.stream.listen((state) {
      if (state is GPSStatusUpdated) {
        print('gpsUpdateStatus $state');
        if (!state.isGPSEnabled || !state.isPermissionGranted) {
          _showGPSDialog(context);
        } else {
          _dismissGPSDialog(context);
        }
      }
    });


    monitorConnectivity();

  //  _internetConnectionStatus();
    _findInteractionController = FindInteractionController();

    if (widget.userInfo != null) {
      _userInfo = widget.userInfo;
    }

    setupInteractedMessage();


    /* Timer.periodic(Duration(hours: 1), (timer) {
      _webViewController?.clearCache();
    });*/

  }





  @override
  void dispose() {

    _webViewController?.dispose();
    _httpAuthUsernameController.dispose();
    _httpAuthPasswordController.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController != null && Util.isAndroid()) {
      if (state == AppLifecycleState.paused) {
        pauseAll();
      } else {
        resumeAll();
      }
    }
  }

  void pauseAll() {
    if (Util.isAndroid()) {
      _webViewController?.pause();
    }
    pauseTimers();
  }

  void resumeAll() {
    if (Util.isAndroid()) {
      _webViewController?.resume();
    }
    resumeTimers();
  }

  void pause() {
    if (Util.isAndroid()) {
      _webViewController?.pause();
    }
  }

  void resume() {
    if (Util.isAndroid()) {
      _webViewController?.resume();
    }
  }

  void pauseTimers() {
    _webViewController?.pauseTimers();
  }

  void resumeTimers() {
    _webViewController?.resumeTimers();
  }


  late double _statusBarHeight;
  bool canPop = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {

    _statusBarHeight = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _exitApp(context, _webViewController!);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: Platform.isAndroid ? true : false,
        bottomNavigationBar: Visibility(
          visible: tabBarVisibliyTemp,
          child: AbsorbPointer(
            absorbing: _isGestureDisabled, // Disable gestures when true
            child: Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.lightBlue.shade900,
                unselectedLabelStyle: TextStyle(fontSize: 13, fontFamily: 'Poppins',fontWeight: FontWeight.w400),
                unselectedLabelColor: Colors.grey,
                controller: _tabController,
                indicator: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.lightBlue.shade900, // Color of the indicator
                      width: 4.0, // Height of the indicator
                    ),
                  ),
                ),
                labelPadding: EdgeInsets.symmetric(vertical: 0),
                labelStyle: TextStyle(fontSize: 13, fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                splashFactory: NoSplash.splashFactory,
                onTap: (index) {
                  _onBottomTabTapped(
                      widget.nativeItem.bottom![index].id ?? "",
                      widget.nativeItem.bottom![index].uRL ?? "",
                      _webViewController!);

                  setState(() {
                    _isGestureDisabled = true;
                  });

                  // Set the boolean to true after 500 milliseconds
                  Future.delayed(Duration(milliseconds: 500), () {
                    setState(() {
                      _isGestureDisabled = false;
                    });
                  });
                },
                tabs: widget.nativeItem.bottom!.map((item) {
                  final svgBytes = base64Decode(item.icon!);
                  final svgString = utf8.decode(svgBytes);
                  print('titleName : ${item.title}');

                  return Tab(
                    icon: SvgPicture.string(
                      svgString,
                      width: 24.0,
                      height: 24.0,
                      color: _tabController.index ==
                          widget.nativeItem.bottom!.indexOf(item)
                          ? Colors.lightBlue.shade900
                          : Colors.grey,
                    ),
                    text: item.title,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        drawer: Container(
            width: MediaQuery.of(context).size.width - 125,
            color: Colors.white,
            margin: EdgeInsets.only(top: _statusBarHeight-10),
            child:  Drawer(
              child: Column(
                children: [
                  // The top 80% space
                  Expanded(
                    flex: 9,  // 80% of the space
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: CanadaDrawerWidget(
                        onRadioButtonUpdate: (String radioBtValue) {
                          print("radioButtonValue : $radioBtValue");

                        //  String radioAvaiBreak = radioBtValue == "Available" ? "available" : "onBreak";

                          if(radioBtValue == "Available") {
                            _webViewController?.evaluateJavascript(
                                source: "window.onFlutterEvent('available');"
                            );
                          }else if(radioBtValue == "On Break") {
                            _webViewController?.evaluateJavascript(
                                source: "window.onFlutterEvent('onBreak');"
                            );
                          }


                        },
                        onProfileTap: () {
                          print("onprofiueTab 2");
                          _scaffoldKey.currentState?.closeDrawer();
                          _onBottomTabTapped("", "${Config.HOME_URL}profile", _webViewController);
                        },
                        userInfo: _userInfo,
                        nativeItem: widget.nativeItem,
                        onSideMenuItemTap: (String url, String id, String icon) async {
                          _scaffoldKey.currentState?.closeDrawer();
                          print("onSideMenuItemTap : $url");
                          int _index = 0;
                          int foundIndex = -1;
                          widget.nativeItem.bottom?.forEach((element) {
                            if (element.id == id) {
                              foundIndex = _index;
                              return;
                            }
                            _index++;
                          });

                          if (foundIndex != -1) {
                            print("changesPaswIndex 1 $foundIndex");
                            _tabController.index = foundIndex;
                            _onBottomTabTapped(id, url, _webViewController);
                          } else {
                            // need to unselected all bottom tab
                            if(id == "0265f6dd48064f2a9dcb59798changespwd") {
                              setState(() {
                                tabBarVisibliy =false;
                              });
                            }
                            print("changesPaswIndex $foundIndex");
                            _onBottomTabTapped(id, url, _webViewController);

                          }

                          // Your side menu item onTap implementation
                        },
                      ),
                    ),
                  ),
                  ),


                  Container(
                    width: double.infinity, // Thickness of the divider
                    height: 1.0, // Matches the parent's height
                    color: Colors.grey.shade300, // Color of the divider
                  ),


                  // The bottom 20% space
                  Expanded(
                    flex: 1,  // 20% of the space
                    child: Container(
                      color: Colors.white,  // Replace with your widget
                      child: Center(
                        child: GestureDetector(
                          onTap:() async {
                            // Clear all cookies
                            await CookieManager.instance().deleteAllCookies();

                            // Clear web storage
                            if (_webViewController != null) {
                              await _webViewController!
                                  .clearCache(); // Clear cache (optional but useful)

                              // Run JavaScript to clear local and session storage
                              await _webViewController!.evaluateJavascript(source: '''
                                 window.localStorage.clear();
                                   window.sessionStorage.clear();
                                      ''');

                            }

                            _scaffoldKey.currentState?.closeDrawer();
                            _onBottomTabTapped("", "${Config.HOME_URL}/login", _webViewController);


                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 16,
                              ),
                              Icon(
                                Icons.logout,
                                size: 18,
                                color: Colors.redAccent.shade700,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.redAccent.shade700,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            )),
            /*child: Drawer(
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: CanadaDrawerWidget(
                      onRadioButtonUpdate: (String radioBtValue) {
                        print("radioButtonValue : $radioBtValue");
                      },
                      userDetailsAvailable: userDetailsAvaible,
                      userInfo: widget.userInfo,
                      nativeItem: widget.nativeItem,
                      onSideMenuItemTap: (String url, String id, String icon) async {
                        _scaffoldKey.currentState?.closeDrawer();
                        print("onSideMenuItemTap : $url");
                        int _index = 0;
                        int foundIndex = -1;
                        widget.nativeItem.bottom?.forEach((element) {
                          if (element.id == id) {
                            foundIndex = _index;
                            return;
                          }
                          _index++;
                        });

                        if (foundIndex != -1) {
                          _tabController.index = foundIndex;
                          _onBottomTabTapped(id, url, _webViewController);
                        } else {
                          // need to unselected all bottom tab
                       //   _tabController.index = 3;
                          _onBottomTabTapped(id, url, _webViewController);
                        }

                        // Your side menu item onTap implementation
                      },
                    ),
                  ),
                ))),*/
        body: Container(
        //  margin: EdgeInsets.only(top: _statusBarHeight),
          color: Colors.white,
          //child: _buildWebView(),
          child: IsInternetConnected == false ?
          Center(
            child: NoInternetConnectionPage(
              tryAgain: checkConnectivity,
            ),
          ) : Stack(
              children: [
                Container(
                  color: Colors.white,
                  margin: EdgeInsets.only(top: _statusBarHeight),
                  child: _buildWebView(), // Only WebView UI remains here
                ),
                if (_isLoading) ...[
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0054a0),
                      )),
                ],
              ],
          ),


        ),
      ),
    );
  }

  InAppWebView _buildWebView() {

    if (!kReleaseMode && Util.isAndroid()) {
      InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    var initialSettings = InAppWebViewSettings();
    initialSettings.mixedContentMode = MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW;
    initialSettings.builtInZoomControls = false;
    initialSettings.supportZoom = false;
   // initialSettings.initialSettings.allowFileAccessFromFileURLs = true;
    initialSettings.allowUniversalAccessFromFileURLs = true;
    initialSettings.textZoom = 100;
    initialSettings.useShouldOverrideUrlLoading = true;
    initialSettings.javaScriptCanOpenWindowsAutomatically = true;
    initialSettings.userAgent = "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36";
    initialSettings.transparentBackground = false;
    initialSettings.safeBrowsingEnabled = true;
    initialSettings.disableDefaultErrorPage = true;
    initialSettings.cacheEnabled = true; // Enable caching
    initialSettings.verticalScrollbarThumbColor =
    const Color.fromRGBO(0, 0, 0, 0.5);
    initialSettings.horizontalScrollbarThumbColor =
    const Color.fromRGBO(0, 0, 0, 0.5);
    initialSettings.allowsLinkPreview = false;
    initialSettings.disableLongPressContextMenuOnLinks = true;

    return InAppWebView(
   initialUrlRequest: URLRequest(url: WebUri(Config.HOME_URL)),
    initialSettings: initialSettings,
      findInteractionController: _findInteractionController,
      onWebViewCreated: (controller) async {
        initialSettings.transparentBackground = false;
        await controller.setSettings(settings: initialSettings);
        _webViewController = controller;
        _webViewController?.setSettings(
            settings:InAppWebViewSettings(builtInZoomControls:false,javaScriptEnabled: true,useHybridComposition: true)
        );

        addJavaScriptHandlers(controller, context);
        if (Util.isAndroid()) {
          controller.startSafeBrowsing();
        }

      },

      onLoadStart: (controller, url) async {
       print("onLoadStart : $url");
    //  print('onLoadStart $url');
      },
      onLoadStop: (controller, url) async {
      //  print('onLoadStop $url');
      },
      onProgressChanged: (controller, progress) {
      //  print('onProgressChanged $progress');
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
      },
      onConsoleMessage: (controller, consoleMessage) {
        Color consoleTextColor = Colors.black;
        Color consoleBackgroundColor = Colors.transparent;
        IconData? consoleIconData;
        Color? consoleIconColor;
        if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
          consoleTextColor = Colors.red;
          consoleIconData = Icons.report_problem;
          consoleIconColor = Colors.red;
        } else if (consoleMessage.messageLevel == ConsoleMessageLevel.TIP) {
          consoleTextColor = Colors.blue;
          consoleIconData = Icons.info;
          consoleIconColor = Colors.blueAccent;
        } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
          consoleBackgroundColor = const Color.fromRGBO(255, 251, 227, 1);
          consoleIconData = Icons.report_problem;
          consoleIconColor = Colors.orangeAccent;
        }
      },
      onLoadResource: (controller, resource) {

      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        var url = navigationAction.request.url;
        print('shouldOverrideUrl $url');

        if (url != null && !["http", "https", "file", "chrome", "data", "javascript", "about"].contains(url.scheme)) {
          if (await canLaunchUrl(url)) {
            print('thisOneGetCall 0');

            // Launch the App
            await launchUrl(
              url,
            );
            // and cancel the request
            return NavigationActionPolicy.CANCEL;
          }
        }
        return NavigationActionPolicy.ALLOW;
      },

      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        var sslError = challenge.protectionSpace.sslError;
        print('checkServerTrust $sslError');
        if (sslError != null && (sslError.code != null)) {
          if (Util.isIOS() && sslError.code == SslErrorType.UNSPECIFIED) {
            return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED);
          }

          return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.CANCEL);
        }
        return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.PROCEED);
      },
      onReceivedError: (controller, request, error) async {

        //   || error.description.contains("net::ERR_NAME_NOT_RESOLVED")
        // || error.description.contains("net::ERR_TIMED_OUT")
        //  || error.description.contains("net::ERR_FAILED")
        //  || error.description.contains("net::ERR_ADDRESS_UNREACHABLE")
        if(error.description.contains("net::ERR_INTERNET_DISCONNECTED")) {
          setState(() {
            IsInternetConnected = false;
          });
          return;
        }

        print("Receivederror: ${error.description}");
        var isForMainFrame = request.isForMainFrame ?? false;
        if (!isForMainFrame) {
          return;
        }

      },
      onTitleChanged: (controller, title) async {
     // user this titlechanges when navigate page changes in webview
     if(title != null) {
       for (int index = 0; index < widget.nativeItem.bottom!.length; index++) {
         var element = widget.nativeItem.bottom![index];
         if (element.naivgate!.contains(title)) {
           setState(() {
             _tabController.index = index;
           });
         }
       }
     }


     if(title != null && title.contains("Login") && tabBarVisibliy) {
          setState(() {
            tabBarVisibliy = false;
          });
        }else if(title != null && title.contains("Change Password") && tabBarVisibliy) {
       setState(() {
         tabBarVisibliy = false;
       });
     } else if(title != null && !tabBarVisibliy){
          setState(() {
            tabBarVisibliy = true;
          });
        }
      },
      onCreateWindow: (controller, createWindowRequest) async {
      },
      onCloseWindow: (controller) {
        if (_isWindowClosed) {
          return;
        }
        _isWindowClosed = true;
      //  await controller.clearCache();

      },
      onPermissionRequest: (controller, permissionRequest) async {
        return PermissionResponse(
            resources: permissionRequest.resources,
            action: PermissionResponseAction.GRANT);
      },
      onReceivedHttpAuthRequest: (controller, challenge) async {

        var username = "uat@savemax"; // Replace with actual username or obtain from user input
        var password = "uat@54321"; // Replace with actual password or obtain from user input
        return HttpAuthResponse(
          username: username,
          password: password,
          action: HttpAuthResponseAction.PROCEED,
        );

      },
    );

  }




  void addJavaScriptHandlers(InAppWebViewController controller, BuildContext context) {

    controller.addJavaScriptHandler(handlerName: 'fromWebToFlutter', callback: (args) async {
      final messageFromWeb = args[0];
      print("checkfun : $messageFromWeb");

      if (messageFromWeb == "agentClockOut" || messageFromWeb == "agentClockIn" || messageFromWeb == "TrackCall" || messageFromWeb == "getActivityCoordinate") {
        return await setLatLongToWeb(context);
      }else if (messageFromWeb == "CaptureSiteImage") {

        if(Config.IMAGE_UPLOAD == "https://crmapi.savemax.com/api/file-upload/image") {
          final responseValue = await showOptions(context,true);
          Map<String, dynamic> response = jsonDecode(responseValue);
          return response;
        }else{
          final responseValue = await showOptions(context,true);
          List<dynamic> parsedResponse = jsonDecode(responseValue);
          String str = jsonEncode(parsedResponse[0]);
          return str;
        }
      }else if (messageFromWeb == "ProfileImage") {
        final responseValue = await showOptions(context,false);
        print("responseValue $responseValue");
        return responseValue;
      }else if (messageFromWeb == "GenerateFCMToken") {
       return await Util.sentDeviceInfoToWeb();
        //_hideSystemUI();
      }else if (messageFromWeb == "showMap") {
        //_hideSystemUI();
      } else if (messageFromWeb == "closeMap") {
      //  _showSystemUI();
      }else {
        final decode = jsonDecode(messageFromWeb);
        _handleJsonMessageUserInfo(decode);
      }

      // Convert the JSON string to a JSON object

     // print('responseFlutter $response');
     // return response;

    });



    controller.addJavaScriptHandler(handlerName: 'getFlutterMenu', callback: (args) async {
      print('whatsappGetCall ${args[0]}');

      return true;

    });

    controller.addJavaScriptHandler(handlerName: 'OpenSideMenu', callback: (args) async {
     // _scaffoldKey.currentState?.openDrawer();
      return "1";
    });


    controller.addJavaScriptHandler(handlerName: 'availableApiResponse', callback: (args) async {

      // Log the response
      print('availableApiResponse ${args[0]}');

      try {
        final jsonData = jsonDecode(args[0]);
        final int code = jsonData['data']['code'];
       // final String? msgDescription = jsonData['data']['resultmsg'][0]['msgdescription'];
        if(code == 200) {
          _userInfo  = await updateAvaiableTagUserInfo(true,true,"","","");
          showCustomToast(
            context,
            "Resumed work successfully",
            'assets/icons/success_icon.png',
          );

         // showToast(message: "Resumed work successfully");
        }
      } catch (e) {
        print('Error parsing JSON: $e');
      }


    });

    controller.addJavaScriptHandler(handlerName: 'onBreakApiResponse', callback: (args) async {

      print('onBreakApiResponse ${args[0]}');

      try {
        final jsonData = jsonDecode(args[0]);
        final int code = jsonData['data']['code'];
     //   final String? msgDescription = jsonData['data']['resultmsg'][0]['msgdescription'];
        if(code == 200) {

          _userInfo  = await updateAvaiableTagUserInfo(true,false,"","","");

        //  _userInfo = await updateAvaiableTagUserInfo(true);


          showCustomToast(
            context,
            "Started break successfully",
            'assets/icons/success_icon.png',
          );

        }
      } catch (e) {
        print('Error parsing JSON: $e');
      }


    });





    controller.addJavaScriptHandler(handlerName: 'getProfileDetails', callback: (args) async {
    // print('getpprofileDetails :  ${args[0]}');

      String userName = "";
      String profileImageUrl = "";
      String title = "";
      late bool? available;
      available = null;

      final jsonData = jsonDecode(args[0]);

      if(jsonData['title'] != null) {
          title = jsonData['title'];
      }

      if(jsonData['name'] != null) {
        userName = jsonData['name'];
      }

      if(jsonData['profileImageUrl'] != null) {
        profileImageUrl = jsonData['profileImageUrl'];
      }

      if(jsonData['available'] != null) {
        available = jsonData['available'];
      }


      _userInfo  = await updateAvaiableTagUserInfo(false,available,userName,title,profileImageUrl);

    });


    controller.addJavaScriptHandler(handlerName: 'openWhatsapp', callback: (args) async {
      print('whatsappGetCall ${args[0]}');

      String whatsappUrl = args[0]; // The full WhatsApp URL (e.g., https://wa.me?text=...)

      // Since the URL is already in the wa.me format, we can directly launch it
      if (whatsappUrl.contains('wa.me')) {
        if (await canLaunch(whatsappUrl)) {
          await launch(whatsappUrl, forceSafariVC: false, forceWebView: false); // Opens WhatsApp directly
        } else {
          throw 'Could not launch $whatsappUrl';
        }
      } else {
        throw 'Invalid WhatsApp URL format';
      }
    });


    controller.addJavaScriptHandler(handlerName: 'openDialer', callback: (args) async {
      String phoneNumber = args[0];
      if(Platform.isAndroid) {
        try {
          await _channel.invokeMethod('dial', {'phoneNumber': phoneNumber});
        } on PlatformException catch (e) {
          print("Failed to dial: '${e.message}'.");
        }
      }else{
        String url = 'tel:$phoneNumber';
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        };
      }
    });

  }


  Future<void> _handleJsonMessageUserInfo(Map<String, dynamic> data) async {

    print("userIfoDetails ; $data");
    try {
     if (data['type'] == 'login') {

       final UserInfo userInfo = UserInfo.fromJson(data);
       var box = await Hive.openBox<UserInfo>(Config.USER_INFO_BOX);
       await box.put(Config.USER_INFO_KEY, userInfo);
       setState(() {
         print("userInforDe : ${userInfo.profileImageUrl}");
         _userInfo = userInfo;
       });

        // String barearToken = data['token'];
        // String username = data['name'];
        // String profileImage = data['profileImageUrl'];
        // await setPrefStringValue(Config.BarearToken, barearToken);
        // await setPrefStringValue(Config.ProfileImageUrl, profileImage);
        // await setPrefStringValue(Config.UseName, username);
      } else {

      }
    } catch (e) {
      print('Error saving user info: $e');
    }
  }




//Show options to get image from camera or gallery
  Future<String> showOptions(BuildContext context,bool isCameraOnly) async {

    String response = "";
    AndroidDeviceInfo? deviceInfo;

    if (Platform.isAndroid) {
      deviceInfo = await DeviceInfoPlugin().androidInfo;
    }

    if(isCameraOnly) {
      if (Platform.isAndroid && deviceInfo != null && deviceInfo.version.sdkInt <= 32) {
        var permissionStatus = await Permission.camera.request();

        if (permissionStatus.isGranted) {
          // get image from camera
          response = await getImageFromCamera(false);
        } else if (permissionStatus.isPermanentlyDenied) {
          showPermissionSettingsDialog(context,
              'Please enable storage permission in app settings to use this feature.');
        }
      } else {
        final permissionStatus = await Permission.camera.status;
        if (permissionStatus.isPermanentlyDenied) {
          showPermissionSettingsDialog(context,
              'Please enable storage permission in app settings to use this feature.');
        } else {
          response = await getImageFromCamera(false);
        }
      }
    }else{
    //  response = await _showPickerDialog(context);

      String selectedResponse = await _showPickerDialog(context);
      print("SelectedOption: $selectedResponse");
      if (selectedResponse == "camera") {
        response = await getImageFromCamera(true);
      } else if (selectedResponse == "gallery") {
        response = await getImageFromGallery(true);
      }

    }


    return response;

  }

  final picker = ImagePicker();

  Future<String> getImageFromCamera(bool isProfileImage) async {
    String response = "";
    await picker.pickImage(source: ImageSource.camera, imageQuality: 40, maxHeight: 1024,maxWidth: 1024)
        .then((value) async => {
      if (value != null) {
     //  response = await cropImageCall(File(value.path))
       response = await uploadImage(File(value.path),isProfileImage)
      }
    });

    return response;
  }

  Future<String> getImageFromGallery(bool isProfileImage) async {
    String response = "";
    await picker
        .pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxHeight: 1024,
      maxWidth: 1024,
    )
        .then((value) async {
      if (value != null) {
        // Process the selected image
        // Example: Crop the image or upload it
        // response = await cropImageCall(File(value.path));
        response = await uploadImage(File(value.path),isProfileImage);
      }
    });

    return response;
  }


  Future<String> uploadImage(File resizedImage, bool isProfileImg) async {
    setState(() {
      _isLoading = true;
    });

    String? bearerToken = _userInfo?.token;
    print('BearerToken $bearerToken');
    final dio = Dio();

    // Set the correct URL based on the 'isProfileImg' flag
    String url = isProfileImg ? Config.PROFILEiMG_UPLOAD : Config.IMAGE_UPLOAD;
    print("urlTest $url");

    // Generate the current date and time in the desired format
    String formattedDate = DateFormat('yyyy-MM-dd HHmmss').format(DateTime.now());
    String noSpacesStr = formattedDate.replaceAll(' ', '_');
    String name = 'properties_$noSpacesStr.png';

    // Choose the correct form-data field name based on the API being called
    String fileName = isProfileImg ? "file" : Config.fileTageName;

    // Prepare the form data
    FormData formData = FormData.fromMap({
      '$fileName': await MultipartFile.fromFile(resizedImage.path, filename: name,contentType: DioMediaType('image', 'png'),),
    });

    try {
      final response = await dio.post(url,
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $bearerToken', // Include the Bearer Token
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Referer': 'https://sync.savemax.com/',
              'platform': 'web',
              'sec-ch-ua': '"Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"',
              'sec-ch-ua-mobile': '?0',
              'sec-ch-ua-platform': '"Windows"',
              'Content-Type': 'multipart/form-data' // Ensure correct content type
            },
          ));

      var responseData = jsonEncode(response.data);

      print('responseCheck $responseData');

      if(isProfileImg) {
        setState(() {
          _isLoading = false;
        });
        return response.statusCode.toString();
      }else {
        if (response.statusCode == 200) {
          setState(() {
            _isLoading = false;
          });
          return responseData;
        } else {
          showToast(message: "Image upload failed. Please try again.");
          return "";
        }
      }

    } catch (e) {
      print('exceptionCheck ${e}');
      showToast(message: "Image upload failed. Please try again.");
      setState(() {
        _isLoading = false;
      });
      return "";
    }
  }



  //
  // Future<String> uploadImage(File resizedImage, bool isProfileImg) async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //
  //   String bearerToken = await getPrefStringValue(Config.BarearToken);
  //   print('BearerToken $bearerToken');
  //   final dio = Dio();
  //
  //  String url = isProfileImg ? Config.PROFILEiMG_UPLOAD : Config.IMAGE_UPLOAD;
  //  print("urlTest $url");
  //  // String url = Config.IMAGE_UPLOAD;
  //
  //   // Generate the current date and time in the desired format
  //   String formattedDate = DateFormat('yyyy-MM-dd HHmmss').format(DateTime.now());
  //   String noSpacesStr = formattedDate.replaceAll(' ', '_');
  //   String name = 'properties_$noSpacesStr.png';
  //
  //   String fileName = isProfileImg ? "file" : Config.fileTageName;
  //   FormData formData = FormData.fromMap({'$fileName}': await MultipartFile.fromFile(resizedImage.path, filename: name),
  //   });
  //
  //   try {
  //     final response = await dio.post(url,
  //         data: formData,
  //         options: Options(
  //           headers: {
  //             'Authorization': 'Bearer $bearerToken', // Replace with your token
  //             'User-Agent':
  //             'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  //             'Accept': 'application/json, text/plain, */*',
  //             'Referer': 'https://sync.savemax.com/',
  //             'platform': 'web',
  //             'sec-ch-ua':
  //             '"Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"',
  //             'sec-ch-ua-mobile': '?0',
  //             'sec-ch-ua-platform': '"Windows"'
  //           },
  //         ));
  //
  //     var responseData = jsonEncode(response.data);
  //
  //     print('responseCheck $responseData');
  //     if (response.statusCode == 200) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       return responseData;
  //     } else {
  //       showToast(message: "Image upload failed. Please try again.");
  //       return "";
  //     }
  //   } catch (e) {
  //     print('exceptionCheck ${e}');
  //     showToast(message: "Image upload failed. Please try again.");
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     return "";
  //   }
  // }



  Future<String> _showPickerDialog(BuildContext context) async {
    String response = ""; // Default response
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select an option"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text("Camera"),
                onTap: () {
                  response = "camera"; // Default camera response
                  Navigator.pop(context); // Dismiss dialog
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Gallery"),
                onTap: () {
                  response = "gallery"; // Default gallery response
                  Navigator.pop(context); // Dismiss dialog
                },
              ),
            ],
          ),
        );
      },
    );
    return response; // Return the selected response
  }


  void _showGPSDialog(BuildContext context) {
    if (_gpsDialog == null) {
      _gpsDialog = AlertDialog(
        title: Center(child: Text('Location Required')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/lottie/lotti_gps.json', width: 150, height: 150),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Enable device location to use the CRM app.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 16,left: 16,top: 10,bottom: 8), // Equivalent to @dimen/_16sdp
            child: SocalButton(
              color: Color(0xFF0054a0),
              icon: Icon(Icons.location_off, color: Colors.white, size: 16),
              press: () async {
                Location location = Location();
                bool serviceEnabled = await location.serviceEnabled();
                if (!serviceEnabled) {
                  serviceEnabled = await location.requestService();
                  if (!serviceEnabled) {
                    return;
                  }
                }

                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();

                  if (permission == LocationPermission.deniedForever) {
                    ph.openAppSettings();
                    return;
                  } else if (permission != LocationPermission.whileInUse &&
                      permission != LocationPermission.always) {
                    return;
                  }
                }
              },
              text: "Enable Location",
            ),
          ),
        ],
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _gpsDialog!,
      );
    }
  }


  void _dismissGPSDialog(BuildContext context) {
    if (_gpsDialog != null) {
      Navigator.of(context, rootNavigator: true).pop();
      _gpsDialog = null;
    }
  }

  void monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      for (var result in results) {
        switch (result) {
          case ConnectivityResult.mobile:
          //  print("Nomini :Switched to Mobile Network");
            setState(() {
              IsInternetConnected = true;
            });
            break;
          case ConnectivityResult.wifi:
          //  print("Nomini :Switched to Wi-Fi");
            setState(() {
              IsInternetConnected = true;
            });
            break;
          case ConnectivityResult.none:
         //   print("Nomini :No Network Connection");
            setState(() {
              IsInternetConnected = false;
            });
            break;
          default:
         //   print("Nomini :Unknown Network State");
            setState(() {
              IsInternetConnected = false;
            });
        }
      }
    });
  }


  Future<void> checkConnectivity() async {
   var connectivityResult = await Connectivity().checkConnectivity();
    String connectivityValue = connectivityResult.toString().replaceAll(RegExp(r'[\[\]]'), '');

    if (connectivityValue == ConnectivityResult.mobile.toString()) {
     print("Nomini :Connected to Mobile Network");
      setState(() {
        IsInternetConnected = true;
      });
    } else if (connectivityValue == ConnectivityResult.wifi.toString()) {
      print('Nomini connectivityResul wifi : $connectivityValue');
      setState(() {
        IsInternetConnected = true;
      });
    } else {
    //  print("Nomini :No Network Connection");
      setState(() {
        IsInternetConnected = false;
      });
    }
  }


  Future<void> _exitApp(BuildContext context, InAppWebViewController inAppWebViewController) async {
    if (await inAppWebViewController.canGoBack()) {
      print('WxistApp 1');
      inAppWebViewController.goBack();
      setState(() {
        canPop = false;
      });
    } else {
      inAppWebViewController.getUrl().then((currentUrl) {
        print('CurrentURL: $currentUrl');
        if (currentUrl == Config.HOME_URL + "leads") {
          setState(() {
            SystemNavigator.pop();
            //canPop = true;
          });
        }
      });
    }
  }
}


Future<UserInfo?> updateAvaiableTagUserInfo(bool CallThisFunFromAvaiableOnBreak, bool? available, String name, String department,String profileImage) async {

  print('updateTag : $available : $name : $department : $profileImage}');

  var userBox = await Hive.openBox<UserInfo>(Config.USER_INFO_BOX);
  UserInfo? userInfoItem = userBox.get(Config.USER_INFO_KEY);
  if (userInfoItem != null) {

    if(available != null) {
      userInfoItem.available = available;
    }

    if(name.isNotEmpty) {
      userInfoItem.name = name;
    }
    if(department.isNotEmpty) {
      userInfoItem.department = department;
    }
    if(profileImage.isNotEmpty || !CallThisFunFromAvaiableOnBreak) {
      userInfoItem.profileImageUrl = profileImage;
    }
    await userBox.put(Config.USER_INFO_KEY, userInfoItem);
    return userInfoItem;
  } else {
    return userInfoItem;
  }

}


void showPermissionSettingsDialog(BuildContext context, String msg) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permission Required'),
      content: Text('$msg'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ph.openAppSettings();
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}


// send coordinate to web
Future<String> setLatLongToWeb(BuildContext context) async {

  Location location = Location();
  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return 'Service not enabled';
    }
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'Please enable location permissions in your device settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Open the app settings
                Navigator.pop(context);
                ph.openAppSettings();
              },
              child: Text('Settings'),
            ),
          ],
        ),
      );
      return 'Permission denied forever';
    } else if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return 'Permission denied';
    }
  }

  Position? position = await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.low);

  String coordinate = "${position.latitude},${position.longitude}";
    print('cordinateCheck $coordinate');
  return coordinate;
}


void _onBottomTabTapped(
    String id, String url, InAppWebViewController? webViewController) async {
  if (url.isNotEmpty) {
    print("urlCHeckCOn : $url");
    webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }
}


const String htmlContent = """
      <!DOCTYPE html>
      <html>
      <head>
        <title>My HTML Content</title>
      </head>
      <body>
        <h1>Hello, Flutter InAppWebView!</h1>
        <p>This is a sample HTML content.</p>
        <button onclick="sendMessageToFlutter()">Send Message to Flutter</button>
        <script>
          function sendMessageToFlutter() {
          if(window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('fromWebToFlutter', 'CaptureSiteImage').then(function(response) {
              console.log('aslamrathore ',response)
            });
          }else {
          console.log('noFLutterfound')
          }
          
          }
        </script>
        <p id="response"></p>
      </body>
      </html>
    """;