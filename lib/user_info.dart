import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  UserInfo._internal();

  static final UserInfo _instance = UserInfo._internal();

  factory UserInfo() => _instance;
  //"headimgurl" -> "http://thirdwx.qlogo.cn/mmopen/jRoggJ2RF3AicRexNWO1lthpbDfm5icqKBG9avs0CDlEs49CSIEnzvPza1H5GibemAkmbxpe4LGmBzQpJSFzEFcE4LakSQkzi…"
  // 1:"location" -> "中国-湖南-长沙"
  // 2:"nickname" -> "白楚。"
  // 3:"appid" -> "wx9c76e6c8249f2f1e"
  // 4:"openid" -> "oDUYJ1eQxfM_cc-tVBZFksTIeUlk"
  // 5:"state" -> 1
  Map<String, dynamic>? data;

  String? sessionId;
  String? sceneId;
  String? _cookie;
  String _code = ["袁袁", "学学", "雪雪", "峰峰", "珍珍", "答答"].join("\n");
  List<String> orderSuccessDatas = [];
  SharedPreferences? _prefs;

  bool get isLogin {
    return _cookie != null && _cookie!.length > 0;
  }

  updateCode(String code) {
    if (code.length == 0) {
      return;
    }
    _code = code;
    _prefs!.setString('code', code);
  }

  String get code => _code;
  
  updateCookie(String? val) {
    _cookie = val;
    if (val != null && val.length > 0) {
      _prefs?.setString("cookie", val);
    }
  }

  Future setup() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      _prefs = await SharedPreferences.getInstance();
      _cookie = _prefs!.getString('cookie');
      _code = _prefs!.getString('code') == '' ? _code : _prefs!.getString('code') ?? "";
    } catch (e) {}
  }

  String secret = "";
  String windowNo = "";
  String? get cookie => _cookie;
  String get defaultCookie {
    return "PHPSESSID=aad6f7inl423ijghf7dtt1aiko; token-tbtools=340a925965f483adef2973dc757ed514; token-tbtools-oper=53f86dd320393c87f021662cc6f46cbe";
  }
  Map<String, String> serverData = {};
  updateData(Map<String, dynamic> data) {
    this.data = data;
  }
}
