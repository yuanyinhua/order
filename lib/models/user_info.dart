import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/api/api.dart';
import 'package:task/views/my_toast.dart';

import 'config.dart';
import 'login.dart';

class UserInfo extends ChangeNotifier {
  UserInfo._internal();

  static final UserInfo _instance = UserInfo._internal();

  factory UserInfo() => _instance;

  LoginInfo? _loginInfo;
  Config _config = Config(
            isActive: false,
            platformAccount: "",
            delayTime: 0.5,
            queryDelayTime: 0.3);
  // 本地存储
  SharedPreferences? _prefs;
  // 是否登录
  bool _isLogin = false;
  String? get password => _loginInfo?.password;
  bool get isLogin => _isLogin;
  set isLogin(bool val) {
    _isLogin = val;
    notifyListeners();
  }

  double get delayTime => _config.delayTime;

  double _defaultDelayTime = Platform.isAndroid ? 2 : 1.2;

  bool get isActive => _config.isActive;
  String? get platformAccount => _config.platformAccount;

  String? get cookie => _loginInfo?.cookies;
  // 保存配置信息
  saveConfig(
      {String? platformAccount,
      String? activeCode,
      double? delayTime,
      double? queryDelayTime}) {
    if (platformAccount != null) {
      _config.platformAccount = platformAccount;
    }
    if (activeCode != null) {
      _config.isActive = (activeCode == "10496${DateTime.now().hour}");
    }
    if (delayTime != null) {
      _config.delayTime = max(_defaultDelayTime, delayTime);
      notifyListeners();
    }
    if (queryDelayTime != null) {
      _config.queryDelayTime = queryDelayTime;
    }
    _prefs!.setString("config", _config.toString());
  }

  // 更新登录信息
  updateLoginInfo(String? cookies,
      {Map? wechatData, String? activeCode, String? password}) {
    if (cookies?.length == 0) {
      MyToast.showToast("输入登录信息");
      return;
    }
    if (Platform.isAndroid && "451601023" != password) {
      MyToast.showToast("密码错误");
      return;
    }
    Api.updateConfig();
    saveConfig(activeCode: activeCode ?? "");
    if (cookies is String && cookies.length > 0) {
      if (!cookies.contains("PHPSESSID")) {
        cookies = "PHPSESSID=;$cookies";
      }
      if (!cookies.contains("tbtools")) {
        MyToast.showToast("登录信息不正确");
        return;
      }
      _loginInfo = LoginInfo(
          cookies: cookies,
          weChatData: wechatData as Map<String, dynamic>?,
          password: password);
      isLogin = true;
      _prefs!.setString("loginInfo", _loginInfo.toString());
    } else {
      isLogin = false;
      _loginInfo = null;
      _prefs!.remove("loginInfo");
    }
  }

  // 初始化本地缓存
  Future setup() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      if (prefs.getString("loginInfo") != null) {
        final loginInfo = LoginInfo.fromJson(
            json.decode(prefs.getString("loginInfo") as String));
        if (!(Platform.isAndroid && loginInfo.password == null)) {
          _loginInfo = loginInfo;
          isLogin = true;
        }
      }
      if (prefs.getString("config") != null) {
        _config =
            Config.fromJson(json.decode(prefs.getString("config") as String));
      } else {
        _config.delayTime = _defaultDelayTime;
      }
      return true;
    } catch (e) {}
  }

  updateConfig(Map data) {
    try {
      if (Platform.isAndroid) {
         _defaultDelayTime = (data["android"]["delayTime"] as num).toDouble();
      } else {
        _defaultDelayTime = (data["delayTime"] as num).toDouble();
      }
      if (_defaultDelayTime > delayTime) {
        saveConfig(delayTime: _defaultDelayTime);
      }
    } catch (e) {
      print(e);
    }
  }
}
