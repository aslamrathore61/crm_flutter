import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

WebViewController LoadUrlController(
    WebViewController controller, String url, BuildContext context) {
  controller = WebViewController.fromPlatformCreationParams(
    WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    )
        : const PlatformWebViewControllerCreationParams(),
  );

  controller
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          debugPrint('WebView is loading (progress : $progress%)');
        },
        onPageStarted: (String url) {
          debugPrint('Page started loading: $url');
        },
        onPageFinished: (String url) {
          debugPrint('Page finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {
          print('errorCHeck ${error.errorType}');
          debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
        ''');
        },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            debugPrint('blocking navigation to ${request.url}');
            return NavigationDecision.prevent;
          }
          debugPrint('allowing navigation to ${request.url}');
          return NavigationDecision.navigate;
        },
        onUrlChange: (UrlChange change) {
          debugPrint('url change to ${change.url}');
        },
      ),
    )
    ..addJavaScriptChannel(
      'Toaster',
      onMessageReceived: (JavaScriptMessage message) {
        print('Message from JavaScript 1: ${message.message}');

       /* ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );*/
      },
    )
   // ..loadHtmlString(html);
    ..loadRequest(Uri.parse(url));

  if (controller.platform is AndroidWebViewController) {
    AndroidWebViewController.enableDebugging(true);
    (controller.platform as AndroidWebViewController)
        .setMediaPlaybackRequiresUserGesture(false);
  }

  return controller;
}


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
        function sendToFlutter() {
          // if (window.FlutterChannel) {
          //     console.error("FlutterChannel available");
          //   window.FlutterChannel.postMessage("Button Clicked");
          // } else {
          //   console.error("FlutterChannel not available");
          // }
          
           if (window.NativeJavascriptInterface) {
        window.NativeJavascriptInterface.generateToken()
    } else if (
        window.webkit &&
        window.webkit.messageHandlers.NativeJavascriptInterface
    ) {
        // Call iOS interface
        window.webkit.messageHandlers.NativeJavascriptInterface.postMessage(
            'callPostMessage'
        )
    }else if (window.FlutterChannel) {
         // Call Flutter code
         window.FlutterChannel.postMessage("GenerateFCMToken");

    } else {
        // No Android or iOS, Flutter interface found
        console.log('No native APIs found.')
        window.setToken(null)
    }
    
        }
    </script>
</head>
<body>
<h1>Hello, Flutter!</h1>
<p>This is an example HTML file loaded into a WebView in a Flutter app.</p>
<button onclick="sendToFlutter()">Send Message to Flutter</button>
</body>
</html>
    """;


// String html = """
//       <html>
// <head>
//     <title>Login Page</title>
// </head>
// <body>
// <button id="loginBtn">Login</button>
//
// <script>
//     const handleLoginBtnClick = () => {
//         const handleApiRes = (res) => {
//
//             if (code === 200) {
//                 setUserToken(result)
//
//                 showToastSucces({
//                     message: msgdescription,
//                     options: {
//                         autoClose: 2000,
//                     },
//                 })
//
//             } else {
//                 showToastError({
//                     message: msgdescription,
//                     options: {
//                         autoClose: 2000,
//                     },
//                 })
//             }
//
//             window.setToken = null
//         }
//
//         window.setToken = (token) => {
//             console.log('token ->', token)
//         }
//
//     try {
//     if (window.NativeJavascriptInterface) {
//         window.NativeJavascriptInterface.generateToken()
//     } else if (
//         window.webkit &&
//         window.webkit.messageHandlers.NativeJavascriptInterface
//     ) {
//         // Call iOS interface
//         window.webkit.messageHandlers.NativeJavascriptInterface.postMessage(
//             'callPostMessage'
//         )
//     }else if (window.FlutterChannel) {
//          // Call Flutter code
//          window.FlutterChannel.postMessage("GenerateFCMToken");
//
//     } else {
//         // No Android or iOS, Flutter interface found
//         console.log('No native APIs found.')
//         window.setToken(null)
//     }
// } catch (err) {
//     console.log(err)
//     window.alert(err)
// }
//
//     }
//
//     document.getElementById('loginBtn').addEventListener('click', handleLoginBtnClick)
// </script>
// </body>
// </html>
//     """;
