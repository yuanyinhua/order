import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'login_info.dart';
import 'platform_account_data.dart';

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

  String? sceneId;
  LoginInfo? _loginInfo;
  Config config = Config(isActive: false, platformAccounts: "", delayTime: 1.2, queryDelayTime: 0.5);
  // 本地存储
  SharedPreferences? _prefs;
  // 是否登录
  bool get isLogin {
    return _loginInfo != null;
  }
  
  // 保存配置信息
  saveConfig({String? platformAccounts, String? activeCode, double? delayTime, double? queryDelayTime}) {
    if (platformAccounts != null) {
      config.platformAccounts = platformAccounts;
    }
    if (activeCode != null) {
      config.isActive = activeCode == "10496${DateTime.now().hour}";
    }
    if (delayTime != null) {
      config.delayTime = delayTime;
    }
    if (queryDelayTime != null) {
      config.queryDelayTime = queryDelayTime;
    }
    _prefs!.setString("config", config.toString());
  }

  // 更新登录信息
  updateLoginInfo(String cookies, {Map? wechatData, String? activeCode}) {
    if (cookies is String && cookies.length > 0 && !cookies.contains("PHPSESSID")) {
      cookies = "PHPSESSID=;$cookies";
    }
    if (activeCode != null) {
      saveConfig(activeCode: activeCode);
    }
    _loginInfo = LoginInfo(cookies: cookies, weChatData: wechatData);
    _prefs!.setString("loginInfo", _loginInfo.toString());
  }

  // 初始化本地缓存
  Future setup() async {
    try {
      await Future.delayed(Duration(seconds: 1));
      _prefs = await SharedPreferences.getInstance();
      if (_prefs!.getString("loginInfo") != null) {
        _loginInfo = LoginInfo.fromJson(json.decode(_prefs!.getString("loginInfo") as String));
      }
      if (_prefs!.getString("config") != null) {
        config = Config.fromJson(json.decode(_prefs!.getString("config") as String));
      }
    } catch (e) {}
  }
  // 公共参数
  String secret = "";
  String windowNo = "";
  String? get cookie => _loginInfo?.cookies;
}
