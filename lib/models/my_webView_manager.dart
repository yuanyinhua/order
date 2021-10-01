import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task/api/constant.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebViewManager {
  MyWebViewManager._internal();

  static final MyWebViewManager _instance = MyWebViewManager._internal();

  factory MyWebViewManager() => _instance;

  WebViewController? _controller;

  bool _finished = false;

  Widget? _cache;

  Widget initWebView() {
    if (_cache != null) {
      return _cache!;
    }
    _cache = Visibility(
        visible: false,
        maintainState: true,
        child: WebView(
          userAgent:
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36",
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
          },
          javascriptMode: JavascriptMode.unrestricted,
          onPageFinished: (_) {
            _finished = true;
          },
        ));
    return _cache!;
  }

  Future getCookie({Map? wechatData}) async {
    if (wechatData != null) {
      String params = Uri.encodeComponent(json.encode(wechatData));
      String url = "$kBaseUrl/tbtools/index.php/com/Login/qrcodeLogin.html?indexUrl=/yutang/&params=$params";
      await loadUrl(url);
    } else {
      await loadUrl(kTestUrl);
    }
    return await _controller!.evaluateJavascript("document.cookie");
  }

  Future loadUrl(String url) async {
    _finished = false;
    await _controller!.loadUrl(url);
    await Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (_finished) {
        return false;
      }
      return !true;
    });
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
