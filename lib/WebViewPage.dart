import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'Config.dart';
import 'NoInternetConnectionPage.dart';
import 'Utils/constants.dart';
import 'controller/LoadUrlController.dart';
import 'main.dart';
import 'network/Internet.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';

String? initialUrl;

class WebViewPage extends StatefulWidget {
  WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool canPop = false;
  bool screenshotEnable = true;
  ScreenshotController screenshotController = ScreenshotController();
  late WebViewController controller;

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
                priority: Priority.defaultPriority,
                importance: Importance.max,
                setAsGroupSummary: true,
                styleInformation: DefaultStyleInformation(true, true),
                largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                channelShowBadge: true,
                autoCancel: true,
                icon: '@mipmap/ic_launcher_round',
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
    } else {
      handleDeepLink(null);
    }

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
    initialUrl = message.data['url'];
    handleDeepLink(initialUrl);
  }

  void handleDeepLink(String? redirectLink) {
    String deepLinkingURL;

    if (redirectLink != null && redirectLink.isNotEmpty) {
      Uri uri = Uri.parse(redirectLink);
      String segmentPath = uri.path + '?' + uri.query;
      deepLinkingURL = Config.HOME_URL + segmentPath;
    } else {
      deepLinkingURL = Config.HOME_URL;
    }
    setState(() {
      controller = LoadUrlController(controller, deepLinkingURL, context);
      javaScriptCall(controller,context);

    });
  }

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    setupInteractedMessage();
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  Widget build(BuildContext context) {
    // Hide the system overlays.
    // Hide the system overlays except for the status bar.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPos) async {
        if (await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) {
            setState(() {
              canPop = true;
            });
          }
        }
      },
      child: Scaffold(
        // Use an empty app bar to hide the default app bar.
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<bool>(
      future: checkInternetConnectivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            if (snapshot.data == true) {
              return Screenshot(
                controller: screenshotController,
                child: FloatingDraggableWidget(
                  floatingWidget: screenshotEnable
                      ? FloatingActionButton(
                          elevation: 0.2,
                          backgroundColor: Colors.blue.shade100,
                          onPressed: () {
                            screenshotController
                                .capture(delay: Duration(milliseconds: 10))
                                .then((capturedImage) async {
                              // Convert the captured image to a file
                              final imageFile =
                                  await createFile(capturedImage!);

                              // Share the captured image on social media
                            //  Share.shareFiles([imageFile.path]);
                            }).catchError((onError) {
                              print(onError);
                            });
                          },
                          child: const Icon(
                            Icons.camera,
                            size: 25,
                            color: Colors.white60,
                          ),
                        )
                      : const SizedBox(
                          height: 0,
                          width: 0,
                        ),
                  floatingWidgetHeight: 50,
                  floatingWidgetWidth: 50,
                  dx: MediaQuery.sizeOf(context).width - 90,
                  dy: 75,
                  deleteWidgetDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white12, Colors.grey],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.0, 1],
                    ),
                  ),
                  deleteWidget: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 2, color: Colors.black87),
                    ),
                    child: const Icon(Icons.close, color: Colors.black87),
                  ),
                  onDeleteWidget: () {
                    debugPrint('Widget deleted');
                  },
                  mainScreenWidget: Scaffold(
                    body: WebViewWidget(
                      controller: controller,
                      gestureRecognizers: Set()
                        ..add(Factory<VerticalDragGestureRecognizer>(
                          () => VerticalDragGestureRecognizer(),
                        )),
                    ),
                  ),
                ),
              );
            } else {
              return NoInternetConnectionPage(tryAgain: _recheckInternet);
            }
          }
        }
      },
    );
  }

  void _recheckInternet() {
    controller.reload();
    Future.delayed(Duration(milliseconds: 700), () {
      setState(() {
        _buildBody();
      });
    });
  }
}

void javaScriptCall(WebViewController webViewController, BuildContext context) {
  webViewController.addJavaScriptChannel(
      'FlutterChannel',
      onMessageReceived: (message) async {
    //    print('LoginFCMToken: ${message.message}');
        if(message.message == "GenerateFCMToken") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? fcmToken = prefs.getString('fcmToken');
          print('fcmToken : $fcmToken');
          webViewController.runJavaScript('setToken("$fcmToken")');
        }else if(message.message == "agentClockIn"){
          print("check 1");
          String clockInLatLong = "clockInLatLong";
          webViewController.runJavaScript('setLatlng("$clockInLatLong")');

        }else if(message.message == "agentClockOut"){
          print("check 2");
          String clockOutLatLong = "clockOutLatLong";
          webViewController.runJavaScript('setLatlng("$clockOutLatLong")');

        }else if(message.message == "TrackCall"){

          setLatLongToWeb(webViewController,false,context );

        }

      }
  );
}

Future<void> setLatLongToWeb(WebViewController webViewController, bool isAgentClock, BuildContext context) async {

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

    if(permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Permission Required'),
          content: Text('Please enable location permissions in your device settings to use this feature.'),
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
                openAppSettings();
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

  Position? position = await Geolocator.getLastKnownPosition();
  print('CurrentLatLong - Latitude: ${position?.latitude}, Longitude: ${position?.longitude}');

  String TrackLatLong = '${position?.latitude},${position?.longitude}';

  if(isAgentClock) {
    webViewController.runJavaScript('setLatlng("$TrackLatLong")');
  }else{
    webViewController.runJavaScript('setTrackLatLng("$TrackLatLong")');
  }

}

