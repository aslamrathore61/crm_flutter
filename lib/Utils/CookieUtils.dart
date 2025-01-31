import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CookieUtils {
  /// Saves cookies for the given URL to local storage or logs them.
  static Future<void> saveCookies(Uri url) async {
    WebUri webUrl = WebUri(url.toString());
    List<Cookie> cookies = await CookieManager.instance().getCookies(url: webUrl);
    for (var cookie in cookies) {
      // Optionally save cookies to local storage or secure storage
      print("Saving cookie: ${cookie.name} = ${cookie.value}");
    }
  }

  /// Restores saved cookies to the WebView for the given URL.
  /// Pass a list of saved cookies to restore them.
  static Future<void> restoreCookies(Uri url, List<Cookie> savedCookies) async {
    for (var cookie in savedCookies) {
      await CookieManager.instance().setCookie(
        url: WebUri(url.toString()),
        name: cookie.name,
        value: cookie.value,
        domain: cookie.domain,
        isSecure: cookie.isSecure ?? false,
        isHttpOnly: cookie.isHttpOnly ?? false,
      );
      print("Restored cookie: ${cookie.name} = ${cookie.value}");
    }
  }
}
