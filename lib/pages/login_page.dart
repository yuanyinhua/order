import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:m/api/api.dart';
import 'package:m/models/user_info.dart';
import 'package:m/models/webview_manager.dart';

import 'package:m/components/alert_dialog.dart';
import 'package:m/components/loading_widget.dart';
import 'package:m/components/my_toast.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  _LoginPageState();
  // 扫码结果
  String? _qrCode;
  // 是否微信登录:
  bool _isWechatLogin = false;
  // 激活信息
  String _activeInfo = "";

  Future<String>? _getQrCodeData;

  Timer? _timer;

  int _waitScanReqCount = 0;
  final _waitScanreqCountMax = 100;

  bool _isShowKeyword = false;

  final _token = TextEditingController();
  final _password = TextEditingController();
  final _userAgent = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _getQrCodeData = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [MyWebViewManager().initWebView(), _mainUI(context)],
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isShowKeyword = MediaQuery.of(context).viewInsets.bottom != 0;
      });
    });
  }

  Widget _mainUI(BuildContext context) {
    if (_token.text == '') {
       _token.text = UserInfo().cookie ?? "";
    }
    // _password.text = UserInfo().password ?? "";
    _userAgent.text = UserInfo().userAgent ?? "";

    if (_isWechatLogin) {
      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 200),
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
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.only(
            left: 20, right: 20, top: _isShowKeyword ? 150 : 200),
        child: Column(
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(hintText: "输入登录信息"),
              controller: _token,
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 10,
            ),
            if (UserInfo().isShowPassword)
              TextField(
                obscureText: true,
                decoration: const InputDecoration(hintText: "输入密码"),
                controller: _password,
              ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    UserInfo().login(_token.text,
                        activeCode: _activeInfo,
                        password: _password.text,
                        userAgent: _userAgent.text);
                  },
                  child:
                      const Text("登录", style: TextStyle(color: Colors.black87)),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromRGBO(208, 208, 208, 1))),
                ),
              ),
            ),
            _buttonUI(context),
          ],
        ),
      ),
    );
  }

  Widget _buttonUI(BuildContext context) {
    return Row(
      mainAxisAlignment:
          _isWechatLogin ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
      GestureDetector(
          child: const SizedBox(
            height: 40,
            child: Center(
              child: Text("UserAgent"),
            ),
          ),
          onTap: () {
            showAlertDialog(context, "UserAgent", (value) {
              _userAgent.text = value;
            }, placeholder: "请输入UserAgent", obscureText: true);
          },
        ),
        Container(
          width: 20,
        ),
        GestureDetector(
          child: const SizedBox(
            height: 40,
            child: Center(
              child: Text("认证码"),
            ),
          ),
          onTap: () {
            showAlertDialog(context, "认证码", (value) {
              _activeInfo = value;
            }, placeholder: "请输入认证码 ", obscureText: true);
          },
        ),
        Container(
          width: 20,
        ),
        // GestureDetector(
        //   child: SizedBox(
        //     height: 40,
        //     child: Center(
        //       child: Text(_isWechatLogin ? "手动登录" : "微信登录"),
        //     ),
        //   ),
        //   onTap: () {
        //     setState(() {
        //       _isWechatLogin = !_isWechatLogin;
        //       _isWechatLogin ? _waitLogin() : _stopWaitLogin();
        //     });
        //   },
        // ),
      ],
    );
  }

  // 等待扫一扫
  void _waitLogin() async {
    if (_getQrCodeData == null) {
      // 获取二维码内容
      _getQrCodeData = Future.delayed(const Duration(seconds: 0), () async {
        var response = await Api.qrCodeData();
        setState(() {
          _qrCode = response as String;
        });
        _waitLogin();
        return _qrCode!;
      });
      return;
    }
    _timer ??= Timer.periodic(Duration(milliseconds: (1.5 * 1000).toInt()),
        (timer) async {
      if (!_isWechatLogin || !mounted) {
        return;
      }
      try {
        await Api.waitLogin();
      } catch (e) {
        _waitScanReqCount += 1;
        if (_waitScanReqCount > _waitScanreqCountMax) {
          _waitScanReqCount = 0;
          _stopWaitLogin();
          await Future.delayed(const Duration(seconds: 5));
          _waitLogin();
        }
      }
    });
  }

  void _stopWaitLogin() {
    _timer?.cancel();
    _timer = null;
  }

  // 获取二维码UI
  Widget qrImage() {
    GlobalKey _globalKey = GlobalKey();
    return FutureBuilder(
      future: _getQrCodeData,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            onTap: () {
              if (kDebugMode) {
                // MyWebViewManager().getCookie();
              }
            },
            onLongPress: () async {
              try {
                // 添加图片权限
                // var status = await Permission.storage.status;
                // if (!status.isGranted) {
                //   status = await Permission.storage.request();
                //   return;
                // }
                // 生成图片
                RenderRepaintBoundary boundary = _globalKey.currentContext!
                    .findRenderObject() as RenderRepaintBoundary;
                ui.Image image = await boundary.toImage(pixelRatio: 3);
                ByteData byteData = await image.toByteData(
                    format: ui.ImageByteFormat.png) as ByteData;
                // 保存图片
                await ImageGallerySaver.saveImage(
                    byteData.buffer.asUint8List());
                // 打开微信
                launchUrlString('weixin://');
              } catch (e) {
                MyToast.showToast(e.toString());
              }
            },
            child: RepaintBoundary(
              key: _globalKey,
              child:  QrImageView(data: snapshot.data!, size: 200),
            ),
          );
        } else {
          return const SizedBox(
            height: 200,
            width: 200,
            child: LoadingWidget(),
          );
        }
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isShowKeyword', _isShowKeyword));
  }
}
