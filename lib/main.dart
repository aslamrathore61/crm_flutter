import 'package:crm_flutter/bloc/gpsBloc/gps_bloc.dart';
import 'package:crm_flutter/bloc/gpsBloc/gps_event.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'Component/UpdateMaintainance/ForceUpdateScreen.dart';
import 'Component/UpdateMaintainance/MaintenanceScreen.dart';
import 'Network/ApiProvider.dart';
import 'Pages/SplashScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'Pages/TabBarPage.dart';
import 'model/native_item.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'model/user_info.dart';

FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
AndroidNotificationChannel? channel;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
 // // If you're going to use other Firebase services in the background, such as Firestore,
 // // make sure you call `initializeApp` before using other Firebase services.
 //  print("HandlingBackgroundMessage: ${message.messageId}");
 //  Fluttertoast.showToast(
 //      msg: "${message.messageId} Notification",
 //      toastLength: Toast.LENGTH_SHORT,
 //      gravity: ToastGravity.CENTER,
 //      timeInSecForIosWeb: 1,
 //      backgroundColor: Colors.red,
 //      textColor: Colors.white,
 //      fontSize: 16.0
 //  );

}

Future<void> main() async {


  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NativeItemAdapter());
    Hive.registerAdapter(BottomAdapter());
    Hive.registerAdapter(UserInfoAdapter());
  }

  final fcmToken = await messaging.getToken();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('fcmToakenValue ${fcmToken}');
  await prefs.setString('fcmToken', '$fcmToken');

  channel = const AndroidNotificationChannel(
      'flutter_notification', // id
      'flutter_notification_title', // title
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
      playSound: true);


  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await messaging
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await initializeHive();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);


  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.light, // Always use light theme
      theme: ThemeData(fontFamily: 'Nunito',),
    home: RepositoryProvider(

      create: (context) => ApiProvider(),
      child: SplashScreen(),
    ),
    routes: {
      '/home': (context) {
        final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        final UserInfo? userInfo = args['userInfo'];
        final NativeItem nativeItem = args['nativeItem'];
        return BlocProvider(
          create: (context) => GPSBloc()..add(CheckGPS()),
            child: TabBarPage(nativeItem: nativeItem, userInfo: userInfo,));
      },
      '/forceUpdatePage': (context) {
        return ForceUpdateScreen();
      },
      '/maintenancePage': (context) {
        return MaintenanceScreen();
      },
    },

  ));
}
