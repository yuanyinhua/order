import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:task/api/api.dart';
import 'package:task/models/user_info.dart';
import 'package:task/models/my_webView_manager.dart';

import 'package:task/views/alert_dialog.dart';
import 'package:task/views/loading_widget.dart';
import 'package:task/views/my_toast.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  _LoginPageState();
  // 扫码结果
  String? _qrCode;
  // 是否微信登录
  bool _isWechatLogin = false;
  // 激活信息
  String _activeInfo = "";

  Future<String>? _getQrCodeData;

  Timer? timer;

  int _waitScanReqCount = 0;
  final _waitScanreqCountMax = 100;
  @override
  void initState() {
    super.initState();
    // 获取二维码内容
    _getQrCodeData = Future.delayed(Duration(seconds: 1), () async {
      var response = await Api.qrCodeData();
      setState(() {
        _qrCode = response as String;
      });
      _waitLogin();
      return _qrCode!;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [MyWebViewManager().initWebView(), _mainUI(context)],
    );
  }

  Widget _mainUI(BuildContext context) {
    final token = TextEditingController();
    token.text = UserInfo().cookie ?? "";
    if (_isWechatLogin) {
      return Container(
        margin: EdgeInsets.only(left: 20, right: 20, top: 200),
        child: Column(
          children: [
            Container(
              child: qrImage(),
            ),
            _buttonUI(context)
          ],
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, top: 200),
      child: Column(
        children: [
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入登录信息"),
            controller: token,
          ),
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  if (token.text.length == 0) {
                    MyToast.showToast("输入登录信息");
                    return;
                  }
                  if (!token.text.contains("tbtools")) {
                    MyToast.showToast("登录信息不正确");
                    return;
                  }
                  _login(token.text);
                },
                child: Text("登录", style: TextStyle(color: Colors.black87)),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(208, 208, 208, 1))),
              ),
            ),
          ),
          _buttonUI(context),
        ],
      ),
    );
  }

  // 登录
  void _login(String token) async {
    try {
      UserInfo().updateLoginInfo(token, activeCode: _activeInfo);
    } catch (e) {}
  }

  Widget _buttonUI(BuildContext context) {
    return Row(
      mainAxisAlignment:
          _isWechatLogin ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        GestureDetector(
          child: Container(
            height: 40,
            child: Center(
              child: Text("认证码"),
            ),
          ),
          onTap: () {
            showAlertDialog(context, "认证码", "请输入认证码", (value) {
              _activeInfo = value;
            });
          },
        ),
        Container(
          width: 20,
        ),
        GestureDetector(
          child: Container(
            height: 40,
            child: Center(
              child: Text(_isWechatLogin ? "手动登录" : "微信登录"),
            ),
          ),
          onTap: () {
            setState(() {
              _isWechatLogin = !_isWechatLogin;
            });
          },
        ),
      ],
    );
  }

  // 等待扫一扫
  void _waitLogin() async {
    if (timer == null) {
      timer = Timer.periodic(Duration(milliseconds: (1.5 * 1000).toInt()),
          (timer) async {
        if (!_isWechatLogin) {
          return;
        }
        try {
          await Api.waitLogin();
        } catch (e) {
          _waitScanReqCount += 1;
          if (_waitScanReqCount > _waitScanreqCountMax) {
            _waitScanReqCount = 0;
            _stopWaitLogin();
            await Future.delayed(Duration(seconds: 5));
            _waitLogin();
          }
        }
      });
    }
  }

  void _stopWaitLogin() {
    timer?.cancel();
    timer = null;
  }

  // 获取二维码UI
  Widget qrImage() {
    GlobalKey _globalKey = new GlobalKey();
    return FutureBuilder(
      future: _getQrCodeData,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            onLongPress: () async {
              // 访问权限
              var status = await Permission.storage.status;
              if (!status.isGranted) {
                status = await Permission.storage.request();
                return;
              }
              // 保存图片
              RenderRepaintBoundary boundary = _globalKey.currentContext!
                  .findRenderObject() as RenderRepaintBoundary;
              ui.Image image = await boundary.toImage(pixelRatio: 0);
              ByteData byteData = await image.toByteData(
                  format: ui.ImageByteFormat.png) as ByteData;
              await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
              launch('weixin://');
            },
            child: RepaintBoundary(
              key: _globalKey,
              child: QrImage(data: snapshot.data!, size: 200),
            ),
          );
        } else {
          return Container(
            height: 200,
            width: 200,
            child: LoadingWidget(),
          );
        }
      },
    );
  }
}
