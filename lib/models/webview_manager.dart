import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m/api/constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebViewManager {
  MyWebViewManager._internal();

  static final MyWebViewManager _instance = MyWebViewManager._internal();

  factory MyWebViewManager() => _instance;

  WebViewController? _controller;

  bool _finished = false;

  Widget initWebView() {
    return Visibility(
        visible: false,
        maintainState: true,
        child: Text("12"),
        // child: WebView(
        //   userAgent: (Platform.isAndroid ? androidUserAgent : iosUserAgent),
        //   onWebViewCreated: (WebViewController webViewController) {
        //     _controller = webViewController;
        //   },
        //   onPageStarted: (url) {

        //   },
        //   javascriptChannels: {
        //     JavascriptChannel(
        //         name: 'tudouApp', //handleName
        //         onMessageReceived: (JavascriptMessage message) {
        //         }),
        //     JavascriptChannel(
        //         name: 'JSHandle', //handleName
        //         onMessageReceived: (JavascriptMessage message) {
        //         }),
        //   },
        //   javascriptMode: JavascriptMode.unrestricted,
        //   onPageFinished: (url) async {
        //     _finished = true;
        //   },
        // )
        );
  }

  Future getCookie({Map? wechatData}) async {
    try {
      if (null != wechatData) {
        String params = Uri.encodeComponent(json.encode(wechatData));
        String url =
            "$kBaseUrl/tbtools/index.php/com/Login/qrcodeLogin.html?indexUrl=/yutang/&params=$params";
        await loadUrl(url);
      } else {
        if (kDebugMode) {
          await loadUrl(kTestUrl);
        }
      }
      // await _controller!.runJavascriptReturningResult("document.cookie");
    } catch (_) {
    }
  }

  Future loadUrl(String url) async {
    _finished = false;
    // await _controller!.loadUrl(url);
    // await Future.doWhile(() async {
    //   await Future.delayed(const Duration(seconds: 1));
    //   if (_finished) {
    //     return false;
    //   }
    //   return !true;
    // });
    return Future.value(this);
  }

  Future loadHTML(String path) async {
    String fileHtmlContents = await rootBundle.loadString(path);
    var url = Uri.dataFromString(fileHtmlContents,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString();
    return loadUrl(url);
  }
}
