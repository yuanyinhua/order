import 'package:flutter/material.dart';
import 'package:task/api/api.dart';
import 'package:task/models/user_info.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyCookies {
  MyCookies._internal();

  static final MyCookies _instance = MyCookies._internal();

  factory MyCookies() => _instance;

  WebViewController? _controller;

  Widget getToken(Function complete) {
    Api.server();
    String url =
        "http://47.115.36.80:8889/tbtools/index.php/com/Login/qrcodeLogin.html?indexUrl=/yutang/&params=%7B%22headimgurl%22%3A%22http%3A%2F%2Fthirdwx.qlogo.cn%2Fmmopen%2FjRoggJ2RF3AicRexNWO1lthpbDfm5icqKBG9avs0CDlEs49CSIEnzvPza1H5GibemAkmbxpe4LGmBzQpJSFzEFcE4LakSQkziaW1%2F132%22%2C%22location%22%3A%22%E4%B8%AD%E5%9B%BD-%E6%B9%96%E5%8D%97-%E9%95%BF%E6%B2%99%22%2C%22nickname%22%3A%22%E7%99%BD%E6%A5%9A%E3%80%82%22%2C%22appid%22%3A%22wx9c76e6c8249f2f1e%22%2C%22openid%22%3A%22oDUYJ1eQxfM_cc-tVBZFksTIeUlk%22%7D";
    return Visibility(
        visible: false,
        maintainState: true,
        child: WebView(
          initialUrl: url,
          userAgent:
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36",
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
          },
          javascriptMode: JavascriptMode.unrestricted,
          onPageFinished: (u) async {
            String s = await _getCookie();
            UserInfo().updateLoginInfo(s);
            complete(s);
          },
        ));
  }

  Future<String> _getCookie() async {
    await Future.delayed(Duration(seconds: 2));
    final String cookies =
        await _controller!.evaluateJavascript("document.cookie");
    return cookies;
  }
}
