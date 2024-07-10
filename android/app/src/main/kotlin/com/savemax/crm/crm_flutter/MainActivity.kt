package com.savemax.crm.crm_flutter

import android.webkit.WebSettings
import android.webkit.WebView
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                if (call.method == "configureWebView") {
                    val textZoom = call.argument<Int>("textZoom")!!
                    val textSize = call.argument<String>("textSize")
                    configureWebView(textZoom, textSize)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun configureWebView(textZoom: Int, textSize: String?) {
        val webView = WebView(this)
        val webSettings = webView.settings
        webSettings.textZoom = textZoom
            Toast.makeText(this,"configureWebview",Toast.LENGTH_SHORT).show();
        when (textSize) {
            "SMALLEST" -> webSettings.textSize = WebSettings.TextSize.SMALLEST
            "SMALLER" -> webSettings.textSize = WebSettings.TextSize.SMALLER
            "NORMAL" -> webSettings.textSize = WebSettings.TextSize.NORMAL
            "LARGER" -> webSettings.textSize = WebSettings.TextSize.LARGER
            "LARGEST" -> webSettings.textSize = WebSettings.TextSize.LARGEST
        }
    }

    companion object {
        private const val CHANNEL = "com.example.webview/settings"
    }
}