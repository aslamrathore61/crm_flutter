import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Config.dart';
import '../SharePrefFile.dart';
import '../model/native_item.dart';
import '../Utils.dart';

class ApiProvider {
  final Dio _dio = Dio();

  ApiProvider() {
    // Add interceptors for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Log request details only in debug mode
        assert(() {
          print('Request: ${options.method} ${options.path}');
          print('Request headers: ${options.headers}');
          print('Request data: ${options.data}');
          return true;
        }());
        return handler.next(options); // continue the request
      },
      onResponse: (response, handler) {
        // Log response details only in debug mode
        assert(() {
          print('Response: ${response.statusCode}');
          print('Response data: ${response.data}');
          return true;
        }());
        return handler.next(response); // continue the response
      },
      onError: (DioError e, handler) {
        // Log error details only in debug mode
        assert(() {
          print('Error: ${e.response?.statusCode}');
          print('Error message: ${e.message}');
          return true;
        }());
        return handler.next(e); // continue the error
      },
    ));
  }


  /***  Native Item Get From API ***/

  Future<NativeItem> fetchMenuDetails() async {
    int menuVersion = await getPrefIntegerValue(Config.REQUEST_APP_VERSION);
    String barearToken = await getPrefStringValue(Config.BarearToken);
    print('SavedRequestAppVersion: $menuVersion');

    try {
      Response response = await _dio.get(
        '${Config.MENU_API}app-version',
        queryParameters: {'requestAppVersion': menuVersion},
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
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data: ${response.data}');

      // ios & android force update and check maintenance
      final bool isMaintenance = response.data['isMaintenance'] as bool;
      final String platformVersionKey =
          Platform.isAndroid ? Config.ANDROID_VERSION : Config.IOS_VERSION;
      final int appserverVersion = Platform.isAndroid
          ? response.data['androidVersion'] as int
          : response.data['iosversion'] as int;
      await setPrefIntegerValue(platformVersionKey, appserverVersion);
      await setPrefBoolValue(Config.isMaintenance, isMaintenance);

      if (response.data != null && response.data['responseAppMenu'] != null) {
        var responseAppVersion = response.data['responseAppMenu'];
        await setPrefIntegerValue(
            Config.REQUEST_APP_VERSION, responseAppVersion);
      }

      var jsonResponse = response.data['jsonResponse'];

      if (jsonResponse is String && jsonResponse.isEmpty) {
        // Handle empty jsonResponse
        return NativeItem(bottom: []);
      } else if (jsonResponse is Map &&
          jsonResponse.containsKey('BottomMenu')) {
        // Handle jsonResponse with BottomMenu
        var bottomMenu = jsonResponse['BottomMenu']['Bottom'] as List?;

        var requestAppVersion = response.data['responseAppVersion'];
        print('requestAppVersion22222 ${requestAppVersion}');
        print('BottomMenuBottomMenu ${bottomMenu}');

        if (bottomMenu == null) {
          return NativeItem(bottom: []);
        } else {
          var bottomItems = bottomMenu.map((e) => Bottom.fromJson(e)).toList();
          return NativeItem(bottom: bottomItems);
        }
      } else {
        // Handle unexpected jsonResponse format
        print('Unexpected jsonResponse format');
        return NativeItem(bottom: []);
      }
    } catch (e) {
      if (e is DioError) {
        print('ExceptionError DioError: ${e.response?.statusCode}');
        print('DioError response data: ${e.response?.data}');
        print('DioError message: ${e.message}');
      } else {
        print('ExceptionError $e');
      }
      return NativeItem(bottom: []);
    }
  }
}
