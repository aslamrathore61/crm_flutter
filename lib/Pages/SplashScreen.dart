import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../Config.dart';
import '../InAppWebViewUtil.dart';
import '../SharePrefFile.dart';
import '../bloc/native_item_bloc.dart';
import '../bloc/native_item_event.dart';
import '../bloc/native_item_state.dart';
import '../model/native_item.dart';
import '../model/user_info.dart';

class SplashScreen extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final NativeItemBloc nativeItemBloc = NativeItemBloc();

    BuildContext savedContext = context;

   // nativeItemBloc.add(GetMenuDetailsEvents());

    /// GET APP INFO FIRST AFTER IF MENU VERSION GREATER THEN CALL UPDATE MENU API
    nativeItemBloc.add(GetAppDeailsDetailsEvents());
    nativeItemBloc.stream.listen((state) async {
      if (state is AppConfigItemLoaded) {

        print('appCOnfigItem: ${state.appConfig}');

        PackageInfo packageInfo = await PackageInfo.fromPlatform();

        String currentVersion = packageInfo.buildNumber;
        print("currentVersion : $currentVersion");

        final String platformVersionKey = Platform.isAndroid ? Config.ANDROID_VERSION : Config.IOS_VERSION;
        final int platformVersion = await getPrefIntegerValue(platformVersionKey);
        final bool isMaintenance = await getPrefBoolValue(Config.isMaintenance);
        int menuVersion = await getPrefIntegerValue(Config.REQUEST_APP_VERSION);


        if (platformVersion > int.parse(currentVersion)) {
          // FlutterNativeSplash.remove();
          Navigator.of(savedContext).pushReplacementNamed('/forceUpdatePage');
        }else if(isMaintenance){
          // FlutterNativeSplash.remove();
          Navigator.of(savedContext).pushReplacementNamed('/maintenancePage');
        }/*else if(menuVersion < state.appConfig.menuVersion) {
          // call second menu api
        }*/ else {

          Timer(const Duration(seconds: 3), () {
            Navigator.of(savedContext).pushReplacementNamed(
              '/home',
              arguments: {
                'userInfo': [],
                'nativeItem': [],
              },
            );
          });


        }
      } else if (state is NativeItemError) {

      } else {
      }
    });


    void handleDatabaseUpdate(BuildContext savedContext) {
      Timer(const Duration(seconds: 3), () {
        getSavedDataFromDatabase(savedContext);
      });
    }

  /*  nativeItemBloc.stream.listen((state) async {
      if (state is NativeItemLoaded && state.nativeItem.bottom!.isNotEmpty) {
        saveDataToDatabase(state.nativeItem);
        handleDatabaseUpdate(savedContext);
      } else if (state is NativeItemError) {
        handleDatabaseUpdate(savedContext);
      } else {
        handleDatabaseUpdate(savedContext);
      }
    });*/


    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image.asset(
            'assets/images/splash_image.png',
            width: 230,
            height: 230,
          ),
        ),
      ),
    );
  }
}

void saveDataToDatabase(NativeItem nativeItem) async {
  await Hive.openBox<NativeItem>(Config.NATIVE_ITEM_BOX);
  var box = Hive.box<NativeItem>(Config.NATIVE_ITEM_BOX);
  await box.put(Config.NATIVE_ITEM_KEY, nativeItem);
}

void getSavedDataFromDatabase(BuildContext savedContext) async {
  UserInfo? userInfoItem;
  try{
    // Open the Hive box
    var userBox = await Hive.openBox<UserInfo>(Config.USER_INFO_BOX);
    // Get the UserInfo object from the box
    userInfoItem = userBox.get(Config.USER_INFO_KEY);
  }catch(e){
  }


  try {

    // get native item from local
    var box = await Hive.openBox<NativeItem>(Config.NATIVE_ITEM_BOX); // Open the box
    NativeItem? nativeItem = box.get(Config.NATIVE_ITEM_KEY); // Get the NativeItem object from the box

    if (nativeItem != null) {

      // PackageInfo packageInfo = await PackageInfo.fromPlatform();
      //
      // String currentVersion = packageInfo.buildNumber;
      //
      // final String platformVersionKey = Platform.isAndroid ? Config.ANDROID_VERSION : Config.IOS_VERSION;
      // final int platformVersion = await getPrefIntegerValue(platformVersionKey);
      // final bool isMaintenance = await getPrefBoolValue(Config.isMaintenance);
      //
      //
      // if (platformVersion > int.parse(currentVersion)) {
      //  // FlutterNativeSplash.remove();
      //   Navigator.of(savedContext).pushReplacementNamed('/forceUpdatePage');
      // }else if(isMaintenance){
      //  // FlutterNativeSplash.remove();
      //   Navigator.of(savedContext).pushReplacementNamed('/maintenancePage');
      // } else {
      //  // FlutterNativeSplash.remove();
      //   Navigator.of(savedContext).pushReplacementNamed(
      //     '/home',
      //     arguments: {
      //       'userInfo': userInfoItem,
      //       'nativeItem': nativeItem,
      //     },
      //   );
      // }

    } else {
      showDialog(
          context: savedContext,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Please check your internet'),
              content: Text('Turn on mobile data or wifi'),
              actions: [
                TextButton(
                    onPressed: () {
                      SystemNavigator.pop(); // Use this on Android
                      // Or use exit(0); on iOS
                    },
                    child: Text("Close"))
              ],
            );
          });
    }
  } catch (e) {
    print('Error retrieving data: $e');
    return null;
  }

  Future<String> getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
