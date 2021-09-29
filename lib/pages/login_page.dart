import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:task/api/api.dart';
import 'package:task/models/user_info.dart';
import 'package:task/views/toast_widget.dart';

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

  @override
  void initState() {
    super.initState();
    Api.login();
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
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入登录信息"),
            controller: token,
          ),
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入认证码"),
            controller: activeInfo,
          ),
          Container(
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
  // ignore: unused_element
  void _getqrCodeData() {
    Api.qrCodeData().then((data) {
      setState(() {
        qrCode = data as String;
      });
      _waitScan();
    });
  }

  // 重新开始等待扫描
  void _retryWaitScan() {
    setState(() {
      reqCount = 0;
    });
    _waitScan();
  }

  // 等待扫一扫
  void _waitScan() async {
    Api.waitScan().then((data) {
      Api.login();
    }).onError((error, stackTrace) {
      setState(() {
        reqCount += 1;
        if (reqCount <= reqCountMax) {
          _waitScan();
        }
      });
    });
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
            if (reqCount > reqCountMax)
              GestureDetector(
                child: Container(
                  child: Center(
                      child: Text(
                    "二维码失效,点击重试",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  )),
                  width: 250,
                  height: 250,
                  color: Colors.white.withOpacity(0.9),
                ),
                onTap: _retryWaitScan,
              )
          ],
        )
      ],
    );
  }

}