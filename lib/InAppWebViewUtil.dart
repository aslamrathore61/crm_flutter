import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Util {
  static bool urlIsSecure(Uri url) {
    return (url.scheme == "https") || Util.isLocalizedContent(url);
  }

  static bool isLocalizedContent(Uri url) {
    return (url.scheme == "file" ||
        url.scheme == "chrome" ||
        url.scheme == "data" ||
        url.scheme == "javascript" ||
        url.scheme == "about");
  }

  static bool isAndroid() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static bool isIOS() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }



 static Future<String> sentDeviceInfoToWeb() async {

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo? androidInfo;
    IosDeviceInfo? iosInfo;

    final packageInfo = await PackageInfo.fromPlatform();

    if (Util.isAndroid()) {
      androidInfo = await deviceInfo.androidInfo;
    } else if (Util.isIOS()) {
      iosInfo = await deviceInfo.iosInfo;
    }

    String jsCode = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? fcmToken = prefs.getString('fcmToken');
    print("fcmToken : "+fcmToken.toString());

    if(androidInfo != null) {
      print("androidDeviceInfo : ${androidInfo.manufacturer}, ${androidInfo.model} ,${androidInfo.version.release}");
      jsCode = '{"DeviceInfo": "${androidInfo.manufacturer} ${androidInfo.model} ${androidInfo.version.release} ", "AppVersion": "${packageInfo.buildNumber}", "FirebaseFCM": "$fcmToken"}';
    }else if(iosInfo != null) {
      print("getnotifyfromweb 2");
      print("IOSDeviceInfo : ${iosInfo.systemName}, ${iosInfo.model} ,${iosInfo.systemVersion} ");
      jsCode = '{"DeviceInfo": "${iosInfo.systemName} ${iosInfo.model} ${iosInfo.systemVersion} ", "AppVersion": "${packageInfo.buildNumber}", "FirebaseFCM": "$fcmToken"}';
    }else {
      print("getnotifyfromweb 3");

    }

    return jsCode;
  }



}