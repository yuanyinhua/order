import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:task/api/api.dart';
import 'package:task/models/user_info.dart';
import 'package:task/views/my_toast.dart';

class LoginPage extends StatefulWidget {
  final Function complete;
  LoginPage(this.complete, {Key? key}) : super(key: key);
  _LoginPageState createState() => _LoginPageState(complete);
}

class _LoginPageState extends State<LoginPage> {
  Function complete;
  _LoginPageState(this.complete);
  String? qrCode;
  int reqCount = 0;
  final reqCountMax = 100;
  bool isWechatLogin = false;
  @override
  void initState() {
    super.initState();
    _getqrCodeData();
  }

  @override
  Widget build(BuildContext context) {
    return loginUI();
  }

    // 登录
  void _login(String token, String activeCode) async {
    try {
      UserInfo().updateLoginInfo(token, activeCode: activeCode);
      this.complete(); 
    } catch (e) {}
  }
  // 登录UI
  Widget loginUI() {
    final token = TextEditingController();
    token.text = UserInfo().cookie ?? "";
    final activeInfo = TextEditingController();
    return Center(
        child: Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      height: 270,
      child: Column(
        children: [
          if (!isWechatLogin) TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入登录信息"),
            controller: token,
          ),
          if (isWechatLogin) Container(
            child: qrImage(),
          ),
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入认证码"),
            controller: activeInfo,
          ),
          if (!isWechatLogin) Container(
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
                  _login(token.text, activeInfo.text);
                },
                child: Text("登录", style: TextStyle(color: Colors.black87)),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(208, 208, 208, 1))),
              ),
            ),
            margin: EdgeInsets.only(top: 10),
          )
        ],
      ),
    ));
  }
  // 获取
  void _getqrCodeData() {
    Api.qrCodeData().then((data) {
      setState(() {
        qrCode = data as String;
      });
      _waitScan();
    });
  }

  // 等待扫一扫
  void _waitScan() async {
    try {
      await Api.waitScan();
      await Api.login();
    } catch (e) {
      setState(() {
        reqCount += 1;
        if (reqCount <= reqCountMax) {
          _waitScan();
        } else {
          Future.delayed(Duration(seconds: 3)).then((value) {
            setState(() {
              reqCount = 0;
            });
            _waitScan();
          });
        }
      });
    }
  }

    // 获取二维码UI
  Widget qrImage() {
    return Row(
      children: [
        Stack(
          children: [
            QrImage(
              data: qrCode!,
              size: 250,
            ),
          ],
        )
      ],
    );
  }
}