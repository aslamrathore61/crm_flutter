import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:call_log/call_log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Component/buttons/socal_button.dart';
import '../Config.dart';
import '../SharePrefFile.dart';
import '../Utils.dart';
import '../bloc/gpsBloc/gps_bloc.dart';
import '../bloc/gpsBloc/gps_state.dart';
import '../main.dart';
import '../model/ProfileResponse.dart';
import '../model/native_item.dart';
import '../model/user_info.dart';
import 'NoInternetConnectionPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart' as ph;

/// Flutter code sample for [TabBar].

class TabBarPage extends StatefulWidget {
  final NativeItem nativeItem;
  late final UserInfo? userInfo;

  TabBarPage({required this.nativeItem, required this.userInfo});

  @override
  State<TabBarPage> createState() => _TabBarPageState();
}

/// [AnimationController]s can be created with `vsync: this` because of
/// [TickerProviderStateMixin].
class _TabBarPageState extends State<TabBarPage> with TickerProviderStateMixin {
  bool tabbarvisibility = false;
  late final TabController _tabController;
  late final WebViewController _webViewController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isProfileMenuVisible = false;
  bool userDetailsAvaible = false;
  bool LoadPageError = false;
  UserInfo? _userInfo;
  String mSelectedLanguageID = "";
  String mSelectedLanguageURL = "";
  File? _image;
  final picker = ImagePicker();
  late String deepLinkingURL;
  int currentTabIndex = 0;
  int delaySec = 0;
  String _locationMessage = "";

  ProfileResponse? profileResponse;

  bool tabGetChangesAfterInternetGon = false;
  bool IsInternetConnected = true;

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo? androidInfo;
  IosDeviceInfo? iosInfo;

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
      _handleMessage(initialMessage);
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
      final String? url = payloadMap['url'];
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

    CommonLoadRequest(deepLinkingURL, _webViewController, context);
  }

  Future<void> CommonLoadRequest(String url,
      WebViewController webViewController, BuildContext _context) async {
    javaScriptCall(webViewController, _context);
    // _webViewController.loadHtmlString(html);
    _webViewController.loadRequest(Uri.parse(url));
  }

  void CallAppIconChangerMethod(String message) async {
    // await platform.invokeMethod('AppIconChange', message);
  }

  void _internetConnectionStatus() {
    InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:
          setState(() {
            IsInternetConnected = true;
            if (tabGetChangesAfterInternetGon) {
              CommonLoadRequest(deepLinkingURL, _webViewController, context);
            }
          });
          break;
        case InternetStatus.disconnected:
          setState(() {
            IsInternetConnected = false;
          });
          break;
      }
    });
  }

  static const platform = MethodChannel('com.example.webview/settings');

  Future<void> _configureWebView() async {
    try {
      await platform.invokeMethod('configureWebView', {
        'textZoom': 30, // Example value
        'textSize': 'SMALLEST', // Example value
      });
    } on PlatformException catch (e) {
      print("Failed to configure webview: ${e.message}");
    }
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  Future<void> _fetchCallLogs(String specificNumber, DateTime from, DateTime to) async {

    int totalCallDuration = 0;
    int totalCallCount = 0;

    if (await Permission.phone.request().isGranted) {
      // Convert DateTime to milliseconds since epoch
      int fromTimestamp = from.millisecondsSinceEpoch;
      int toTimestamp = to.millisecondsSinceEpoch;

      // Query the call logs with specific number and time range
      Iterable<CallLogEntry> entries = await CallLog.query(
        dateFrom: fromTimestamp,
        dateTo: toTimestamp,
        number: specificNumber,
      );

      // Print call log details for the specific number within the time range
      for (var entry in entries) {
        totalCallDuration += entry.duration!;
        totalCallCount + 1;
        print('entiryCount 1');
    //    print('Number: ${entry.number}, Date: ${DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0)}, Duration: ${entry.duration}');
      }

      print('toalCallDuration $totalCallDuration');
      print('selectedMobileNumber $specificNumber');
      print('totalCallCount $totalCallCount');


    }
  }


  @override
  void initState() {
    super.initState();

    //  _configureWebView();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params);

    _internetConnectionStatus();

    // Define specific number and time range
    String specificNumber = '8755090585'; // Replace with the number you want to filter
    DateTime from = DateTime(2024, 7, 19, 18, 55); // 2024-07-19 20:30
    DateTime to = DateTime.now(); // Current time

    _fetchCallLogs(specificNumber, from, to);


    if (widget.userInfo != null) {
      userDetailsAvaible = true;
      _userInfo = widget.userInfo;
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent, // Change this to the desired color
    ));

    // #docregion platform_features

    _checkInitialConnectivity();
    setupInteractedMessage();

    _tabController = TabController(
      length: widget.nativeItem.bottom!.length,
      vsync: this,
    );

    // Load the initial URL for the first tab
    if (widget.nativeItem.bottom!.isNotEmpty &&
        widget.nativeItem.bottom![0].uRL!.isNotEmpty) {
      if (widget.nativeItem.bottom![0].uRL != null) {
        Uri uri = Uri.parse(widget.nativeItem.bottom![0].uRL!);
        String segmentPath = uri.path + '?' + uri.query;
        deepLinkingURL = Config.HOME_URL + segmentPath;
      } else {
        deepLinkingURL = Config.HOME_URL;
      }
      CommonLoadRequest(deepLinkingURL, _webViewController, context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onTabTapped(int index, String url, String _id) async {
    currentTabIndex = index;

    if (url.isEmpty) return;

    // Load the URL for the selected tab
    if (url.startsWith(Config.HOME_URL) ||
        url.startsWith('https://syncmb-uat.savemax.com/') ||
        url.startsWith('https://syncmb.savemax.com/')) {
      if (url.isNotEmpty) {
        Uri uri = Uri.parse(url);
        String segmentPath = uri.path + '?' + uri.query;
        deepLinkingURL = Config.HOME_URL + segmentPath;
      } else {
        deepLinkingURL = Config.HOME_URL;
      }

      setState(() {
        CommonLoadRequest(deepLinkingURL, _webViewController, context);
        // _webViewController.loadHtmlString(html);
      });
    } else {
      if (widget.userInfo != null) {
        print('launchURL $url${widget.userInfo?.token}');
        _launchUrl('$url ${widget.userInfo?.token}');
      } else {
        _launchUrl(url);
      }
    }
  }

  Future<void> _launchUrl(String _url) async {
    if (!await launchUrl(Uri.parse(_url))) {
      throw Exception('Could not launch $_url');
    }
  }

  Future<void> _checkInitialConnectivity() async {
    bool isConnected = await InternetConnection().hasInternetAccess;

    if (isConnected) _webViewController.reload();

    if (isConnected) {
      IsInternetConnected = isConnected;
    }

    setState(() {
      IsInternetConnected;
    });
  }

  bool canPop = false;
  bool _isLoading = false;

  late double _statusBarHeight;



  @override
  Widget build(BuildContext context) {
    _statusBarHeight = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _exitApp(context);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: IsInternetConnected == false
            ? Center(
                child: NoInternetConnectionPage(
                  tryAgain: _checkInitialConnectivity,
                ),
              )
            : Stack(
                children: [
                  Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(top: _statusBarHeight),
                    child: BlocConsumer<GPSBloc, GPSState>(
                      listener: (context, state) {
                        print('gpsState : xy');
                        if (state is GPSStatusUpdated) {
                          print('gpsState 1: ${state.isGPSEnabled}');
                          print('gpsState 2: ${state.isPermissionGranted}');

                          if (!state.isGPSEnabled || !state.isPermissionGranted) {
                            _showGPSDialog(context);
                          } else {
                            _dismissGPSDialog(context);
                          }
                        }
                      },
                      builder: (context, state) {
                          return WebViewWidget(
                            controller: _webViewController
                            //  ..loadRequest(Uri.parse(deepLinkingURL))
                              ..enableZoom(false)
                            ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
                              print("ddd [${message.level.name}] ${message.message}");
                            })
                              ..setJavaScriptMode(JavaScriptMode.unrestricted)
                              ..setBackgroundColor(const Color(0x00000000))
                              ..setNavigationDelegate(
                                NavigationDelegate(
                                  onProgress: (int progress) {
                                    print('progress $progress');
                                  },
                                  onPageStarted: (String url) {
                                    setState(() {
                                      if (url == Config.HOME_URL) {
                                        _tabController.index = 1;
                                      } else if (url.contains('leads') &&
                                          !url.contains('bulk')) {
                                        _tabController.index = 0;
                                        setState(() {
                                          print('leadGetCall');
                                          tabbarvisibility = true;
                                        });
                                      } else if (url.contains('bulk-leads')) {
                                        _tabController.index = 2;
                                      } else if (url.contains('dialer')) {
                                        _tabController.index = 3;
                                      } else if (url.contains('bucket')) {
                                        _tabController.index = 4;
                                      } else if (url.contains('login')) {
                                        setState(() {
                                          print('logingetCall');
                                          tabbarvisibility = false;
                                        });
                                      } else {}
                                    });
                                    print('onPageStarted $url');
                                  },
                                  onPageFinished: (String url) {
                                    print('onPageFinished $url');
                                  },
                                  onWebResourceError: (WebResourceError error) {
                                    print('onWebResourceError ${error
                                            .errorCode} ${error.description}');

                                    if (error.errorCode == -10) {
                                    }
                                  },
                                  onHttpError: (HttpResponseError error) {
                                    print('httpResponseError $error');
                                  },
                                  onNavigationRequest:
                                      (NavigationRequest request) {
                                    final url = request.url;

                                    if (url
                                        .contains("https://api.whatsapp.com")) {
                                      _launchUrl(url);
                                      return NavigationDecision.prevent;
                                    } else if (url.contains("tel:")) {
                                      _launchUrl(url);
                                      return NavigationDecision.prevent;
                                    }

                                    // Handle mailto links
                                    if (url.startsWith('mailto:')) {
                                      _launchUrl(url);
                                      return NavigationDecision.prevent;
                                    }

                                    // Handle social media and store links
                                    final socialMediaPrefixes = [
                                      'https://play.google.com',
                                      'https://apps.apple.com',
                                      'https://www.facebook.com',
                                      'https://twitter.com',
                                      'https://www.instagram.com',
                                      'https://www.linkedin.com',
                                      'https://www.youtube.com',
                                      'https://www.tiktok.com',
                                    ];

                                    for (var prefix in socialMediaPrefixes) {
                                      if (url.startsWith(prefix)) {
                                        _launchUrl(url);
                                        return NavigationDecision.prevent;
                                      }
                                    }

                                    return NavigationDecision.navigate;
                                  },
                                ),
                              ),
                          );
                      },
                    ),
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

                  /* if (_isLoading) ...[
                ModalBarrier(
                  dismissible: false,
                  color: Colors.black.withOpacity(0.3),
                ),
                Center(
                  child: AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        CircularProgressIndicator(color: Colors.blue.shade900,),
                        SizedBox(height: 20),
                        Text("Uploading Image.."),
                      ],
                    ),
                  ),
                ),
              ],*/
                ],
              ),
        /* bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey, // Top border color for the TabBar
                width: 0.5, // Width of the top border
              ),
            ),
          ),
          child: Visibility(
            visible: tabbarvisibility,
            child: TabBar(
              labelColor: Colors.blue.shade900,
              unselectedLabelColor: Colors.grey.shade700,
              controller: _tabController,
              indicator: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.blue.shade900, // Color of the indicator
                    width: 4.0, // Height of the indicator
                  ),
                ),
              ),
              labelPadding: EdgeInsets.symmetric(vertical: 0),
              labelStyle: TextStyle(fontSize: 11, fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.normal
              ),
              splashFactory: NoSplash.splashFactory,
              onTap: (index) {
                final url = widget.nativeItem.bottom![index].uRL!;
                _onTabTapped(
                    index, url, widget.nativeItem.bottom![index].id!);
              },
              tabs: widget.nativeItem.bottom!.map((item) {
                final svgBytes = base64Decode(item.icon!);
                final svgString = utf8.decode(svgBytes);
                return Tab(
                  icon: SvgPicture.string(
                    svgString,
                    width: 21.0,
                    height: 21.0,
                    color: _tabController.index ==
                            widget.nativeItem.bottom!.indexOf(item)
                        ? Colors.blue.shade900
                        : Colors.black,
                  ),
                  text: item.title,
                );
              }).toList(),
            ),
          ),
        ),*/
      ),
    );
  }



  void javaScriptCall(
      WebViewController webViewController, BuildContext context) {
    webViewController.removeJavaScriptChannel('FlutterChannel');
    webViewController.addJavaScriptChannel('FlutterChannel',
        onMessageReceived: (message) async {
      print('FlutterChannelDetails ${message.message}');
      try {
        var data = jsonDecode(message.message);
        if (data is Map<String, dynamic>) {
          _handleJsonMessageUserInfo(data);
        } else {
          print('ReceivedNonJsonMessage: ${message.message}');
        }
      } catch (e) {
        // Handle as a plain string message
        print('ReceivedStringMessage: ${message.message}');
        _handleStringMessage(message.message, webViewController);
      }
    });
  }

  Future<void> _handleJsonMessageUserInfo(Map<String, dynamic> data) async {
    try {
      if (data['action'] == 'Share') {
        print('actionshare ${data['action']}');
        shareURL(data['text'], data['url']);
        //title
      } else if (data['type'] == 'login') {
        String barearToken = data['token'];
        await setPrefStringValue(Config.BarearToken, barearToken);
      } else if (data['flutter'] == 'profile') {
        setState(() {
          profileResponse = ProfileResponse.fromJson(data);
        });

        //  print('profileRespons ${profileResponse!.toJson()}');
      } else if (data['action'] == 'BottomViewVisibility') {
        final dynamic boolValue = data['visibility'];
        final parsedValue = boolValue is bool
            ? boolValue
            : boolValue.toString().toLowerCase() == 'true';

        setState(() {
          tabbarvisibility = parsedValue;
          print('visibilityCheck $tabbarvisibility');
        });
      } else {
        final UserInfo userInfo = UserInfo.fromJson(data);
        var box = await Hive.openBox<UserInfo>(Config.USER_INFO_BOX);
        await box.put(Config.USER_INFO_KEY, userInfo);
        setState(() {
          _userInfo = userInfo;
          userDetailsAvaible = true;
        });
      }
    } catch (e) {
      print('Error saving user info: $e');
    }
  }

  void shareURL(String url, String text) {
    Share.share('$text\n$url');
  }

  Future<void> _handleStringMessage(
      String message, WebViewController webViewController) async {
    if (message == "getBottomToolbar") {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionNumber = packageInfo.version;
      final bundleNumber = packageInfo.buildNumber;
      print('versionNumber $versionNumber : bundleNumber $bundleNumber');
      String jsCode =
          '{"versionNumber": "${versionNumber}", "bundleNumber": "${bundleNumber}"}';
      webViewController.runJavaScript('getVersion(`$jsCode`)');

      //  String jsCode = '{"logoutvalue"}';
      // webViewController.runJavaScript('getLogout(`$jsCode`)');
    } else if (message == "CaptureSiteImage") {
      print('CaptureSiteImage');
      showOptions();
    } else if (message == "GenerateFCMToken") {
      sentDeviceInfoToWeb(_webViewController);
    }
    /* else if (message == "GetLocation") {
      setLatLongToWeb(webViewController, context,false);
    }*/
    else if (message == "TrackCall") {
      setLatLongToWeb(webViewController, context, 2);
    } else if (message == "agentClockOut" || message == "agentClockIn") {
      setLatLongToWeb(webViewController, context, 1);
    } else if (message == "getActivityCoordinate") {
      print('getActivityCoordinate');
      setLatLongToWeb(webViewController, context, 0);
    } else if (message == "showMap") {
      _hideSystemUI();
    } else if (message == "closeMap") {
      _showSystemUI();
    }
  }

  Future<void> sentDeviceInfoToWeb(WebViewController webViewController) async {
    print("getCallSystem");
    try {

      final packageInfo = await PackageInfo.fromPlatform();

      if (Theme.of(context).platform == TargetPlatform.android) {
        androidInfo = await deviceInfo.androidInfo;
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        iosInfo = await deviceInfo.iosInfo;
      }

      String jsCode = "";
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcmToken');

      if(androidInfo != null) {
        print("androidDeviceInfo : ${androidInfo!.manufacturer}, ${androidInfo!.model} ,${androidInfo!.version.release}");
        jsCode = '{"DeviceInfo": "${androidInfo!.manufacturer} ${androidInfo!.model} ${androidInfo!.version.release} ", "AppVersion": "${packageInfo.buildNumber}", "FirebaseFCM": "$fcmToken"}';
      }else if(iosInfo != null) {
        print("IOSDeviceInfo : ${iosInfo!.systemName}, ${iosInfo!.model} ,${iosInfo!.systemVersion} ");
        jsCode = '{"DeviceInfo": "${iosInfo!.systemName} ${iosInfo!.model} ${iosInfo!.systemVersion} ", "AppVersion": "${packageInfo.buildNumber}", "FirebaseFCM": "$fcmToken"}';
      }

      print("jsCode $jsCode");
      webViewController.runJavaScript('setDeviceInfo(`$jsCode`)');


    } catch (e) {
      print('Failed to get device info: $e');
    }
  }


  Future<void> setLatLongToWeb(WebViewController webViewController,
      BuildContext context, int coordinateType) async {
    // coordinateType =  0 means required activity coordinate
    // coordinateType = 1 means clock in and out
    // coordinateType = 2 means punch
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Location Permission Required'),
            content: Text(
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
        return;
      } else if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    // setState(() {
    //   _isLoading = true;
    // });

    Position? position = await Geolocator.getLastKnownPosition();

    position ??= await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high);

    // setState(() {
    //   _isLoading = false;
    // });

    if (coordinateType == 0) {
      print('Coordinate0: ${position.latitude}, ${position.longitude}');
      String cordinate = "${position.latitude},${position.longitude}";
      webViewController.runJavaScript('setActivityCoordinate(`$cordinate`)');
    } else if (coordinateType == 1) {
      print('Coordinate1: ${position.latitude}, ${position.longitude}');
      String cordinate = "${position.latitude},${position.longitude}";
      webViewController.runJavaScript('setLatlng(`$cordinate`)');
    } else if (coordinateType == 2) {
      print('Coordinate2: ${position.latitude}, ${position.longitude}');
      String cordinate = "${position.latitude},${position.longitude}";
      webViewController.runJavaScript('setTrackLatLng("$cordinate")');
    }

/*    if(isTrackCall) {
      print('isTrackCall: ${position.latitude}, ${position.longitude}');
      String cordinate = "${position.latitude},${position.longitude}";
      //  webViewController.runJavaScript('setTrackLatLngFlutter(`$cordinate`)');
       webViewController.runJavaScript('setTrackLatLng("$cordinate")');

    }else {
      print('!isTrackCall: ${position.latitude}, ${position.longitude}');
      String cordinate = "${position.latitude},${position.longitude}";
        webViewController.runJavaScript('setLatlng(`$cordinate`)');

    }*/
  }

  Future<void> _exitApp(BuildContext context) async {
    if (await _webViewController.canGoBack()) {
      print('WxistApp 1');
      _webViewController.goBack();
      setState(() {
        canPop = false;
      });
    } else {
      _webViewController.currentUrl().then((currentUrl) {
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

  //Show options to get image from camera or gallery
  Future showOptions() async {
    var permissionStatus = await ph.Permission.camera.request();

    if (permissionStatus.isGranted) {
      // get image from camera
      getImageFromCamera();
    } else if (permissionStatus.isPermanentlyDenied) {
      showPermissionSettingsDialog(context,
          'Please enable storage permission in app settings to use this feature.');
    }

    // showCupertinoModalPopup(
    //   context: context,
    //   builder: (context) =>
    //       CupertinoActionSheet(
    //         actions: [
    //           /*  CupertinoActionSheetAction(
    //         child: Text('Photo Gallery'),
    //         onPressed: () async {
    //           // close the options modal
    //           Navigator.of(context).pop();
    //
    //           AndroidDeviceInfo? deviceInfo;
    //
    //           if (Platform.isAndroid) {
    //             deviceInfo = await DeviceInfoPlugin().androidInfo;
    //           }
    //
    //           if (Platform.isAndroid &&
    //               deviceInfo != null &&
    //               deviceInfo.version.sdkInt <= 32) {
    //             var permissionStatus = await Permission.storage.request();
    //             if (permissionStatus.isGranted) {
    //               getImageFromGallery();
    //             } else if (permissionStatus.isPermanentlyDenied) {
    //               showPermissionSettingsDialog(context,
    //                   'Please enable storage permission in app settings to use this feature.');
    //             }
    //           } else {
    //             var permissionStatus = await Permission.photos.request();
    //             if (permissionStatus.isGranted) {
    //               getImageFromGallery();
    //             } else if (permissionStatus.isPermanentlyDenied) {
    //               showPermissionSettingsDialog(context,
    //                   'Please enable storage permission in app settings to use this feature.');
    //             }
    //           }
    //         },
    //       ),*/
    //           CupertinoActionSheetAction(
    //             child: Text('Camera'),
    //             onPressed: () async {
    //               // close the options modal
    //               Navigator.of(context).pop();
    //               var permissionStatus = await ph.Permission.camera.request();
    //
    //               if (permissionStatus.isGranted) {
    //                 // get image from camera
    //                 getImageFromCamera();
    //               } else if (permissionStatus.isPermanentlyDenied) {
    //                 showPermissionSettingsDialog(context,
    //                     'Please enable storage permission in app settings to use this feature.');
    //               }
    //             },
    //           ),
    //         ],
    //       ),
    // );
  }

  //Image Picker function to get image from gallery
  Future getImageFromGallery() async {
    await picker
        .pickImage(source: ImageSource.gallery, imageQuality: 25)
        .then((value) => {
              if (value != null) {cropImageCall(File(value.path))}
            });
  }

  //Image Picker function to get image from camera
  Future getImageFromCamera() async {
    await picker
        .pickImage(source: ImageSource.camera, imageQuality: 25)
        .then((value) async => {
              if (value != null) {cropImageCall(File(value.path))}
            });
  }

  cropImageCall(File imgFile) async {
    String? croppedImagePath = await cropImage(imgFile);
    print("croppedImagePath $croppedImagePath");
    File file = File('$croppedImagePath');

    // Read the file at the specified path
    uploadImage(file);
  }

  Future<void> uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    String barearToken = await getPrefStringValue(Config.BarearToken);
    final dio = Dio();
    const url = Config.IMAGE_UPLOAD;

    // Generate the current date and time in the desired format
    String formattedDate =
        DateFormat('yyyy-MM-dd HHmmss').format(DateTime.now());
    String noSpacesStr = formattedDate.replaceAll(' ', '_');
    String name = 'properties_$noSpacesStr.png';

    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: name),
    });

    try {
      final response = await dio.post(url,
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $barearToken', // Replace with your token
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/plain, */*',
              'Referer': 'https://sync.savemax.com/',
              'platform': 'web',
              'sec-ch-ua':
                  '"Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"',
              'sec-ch-ua-mobile': '?0',
              'sec-ch-ua-platform': '"Windows"'
            },
          ));
      var responseData = jsonEncode(response.data);

      setState(() {
        _isLoading = false;
      });

      print("jsonResponse : $responseData");

      if (response.statusCode == 200) {
        _webViewController.runJavaScript('getSiteVisitImage($responseData)');
      } else {
        print('Image upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
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
}


AlertDialog? _gpsDialog;

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


// const String html = """
// <html>
// <head>
//     <title>Example Page</title>
//     <style>
//         body {
//             font-family: Arial, sans-serif;
//             background-color: #f0f0f0;
//             padding: 20px;
//             font-size: 28px; /* Increased font size for body */
//         }
//         h1 {
//             color: #333;
//             font-size: 42px; /* Increased font size for h1 */
//         }
//         p {
//             color: #666;
//             font-size: 40px; /* Increased font size for p */
//         }
//     </style>
//     <script>
//         window.getSiteVisitImage = (responseData) => {
//             console.log('responseData:', responseData);
//             const imgElement = document.getElementById('imagePreview');
//             imgElement.src = filePath;
//         };
//
//         window.setLatlng = (responseData) => {
//             console.log('responseData:', responseData);
//         };
//
//         function sendToFlutter() {
//             if (window.FlutterChannel) {
//                 window.FlutterChannel.postMessage('TrackCall');
//             } else {
//                 console.log('No native APIs found.');
//             }
//         }
//     </script>
// </head>
// <body>
//     <h1>Hello, Flutter!</h1>
//     <p>This is an example HTML file loaded into a WebView in a Flutter app.</p>
//     <button onclick="sendToFlutter()">Send Message to Flutter</button>
//     <br/><br/>
//     <img id="imagePreview" src="" alt="Image Preview" style="max-width: 100%; height: auto;"/>
// </body>
// </html>
// """;

//
// String html = """<html>
// <head>
// <title>Image Preview</title>
// </head>
// <body>
// <h1>Image Preview</h1>
// <input type="file" id="fileInput">
//  <button onclick="sendToFlutter()">Send Message to Flutter</button>
// <button onclick="previewImage()">Preview Image</button>
// <br><br>
// <div id="imagePreview"></div>
//
// <script>
//
//
//  function sendToFlutter() {
//        if(window.FlutterChannel) {
//         window.FlutterChannel.postMessage('ProvideProfileImageFormData');
// }
// };
//
// function previewImage() {
//   const fileInput = document.getElementById('fileInput');
//   const file = fileInput.files[0];
//   if (!file) {
//     alert('Please select a file.');
//     return;
//   }
//
//   const reader = new FileReader();
//   reader.onload = function (e) {
//     const base64String = e.target.result.split(',')[1];
//     getFileBytesData(base64String);
//   };
//   reader.readAsDataURL(file);
// }
//
// window.getFileBytesData = async base64String => {
// console.log('base64', base64String);
// try {
// const mimeType = base64String.match(/data:(.*);base64/)[1];
// const byteString = atob(base64String.split(',')[1]);
// const ab = new ArrayBuffer(byteString.length);
// const ia = new Uint8Array(ab);
// for (let i = 0; i < byteString.length; i++) {
// ia[i] = byteString.charCodeAt(i);
// }
// const blob = new Blob([ab], { type: mimeType });
// const formData = new FormData();
// formData.append('file', blob, 'fileName');
//
// // Create object URL from Blob
// const imageUrl = URL.createObjectURL(blob);
// console.log('imageUrl', imageUrl);
//
// // Create image element and set its source to the object URL
// const image = new Image();
// image.src = imageUrl;
// const imagePreviewDiv = document.getElementById('imagePreview');
// imagePreviewDiv.innerHTML = '';
// imagePreviewDiv.appendChild(image);
//
// // Log form data entries
// for (const entry of formData.entries()) {
// console.log('formdataEntry', entry);
// }
// // await uploadProfileImage(formData);
// } catch (error) {
// console.error('Error in loop:', error);
// }
// };
// </script>
// </body>
// </html>
//     """;
//

String html = """
<html>
<head>
    <title>Example Page</title>
    <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #f0f0f0;
          padding: 20px;
        }
        h1 {
          color: #333;
        }
        p {
          color: #666;
        }
    </style>
    <script>
        // Function to send a message to the WebView
        const commonNotifyFun = (key, boolValue) => {
            const message = JSON.stringify({
                action: key,
                visibility: boolValue,
            });
            // Sending the message to the Flutter WebView
            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage(message);
            } 
        };

        // Example function to send a predefined message to Flutter
        function sendToFlutter() {
            commonNotifyFun('BottomViewVisibility', 'true');
        }

        // Other existing functions
        window.getFileBytesData = (response) => {
            try {
                console.log('parsedData', JSON.stringify(response));
            } catch (error) {
                console.error('Error parsing JSON', error);
            }
        };
    </script>
</head>
<body>
<h1>Hello, Flutter!</h1>
<p>This is an example HTML file loaded into a WebView in a Flutter app.</p>
<button onclick="sendToFlutter()">Send Message to Flutter</button>
</body>
</html>
""";
