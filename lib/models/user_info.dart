import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:m/api/api.dart';
import 'package:m/components/my_toast.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

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
      queryDelayTime: 0.3,
      minDelayTime: Platform.isAndroid ? 2 : 1.2);
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

  double get defaultDelayTime => Platform.isAndroid ? 2 : 1.2;

  bool get isActive => _config.isActive;
  String? get platformAccount => _config.platformAccount;

  String? get cookie => _loginInfo?.cookies;
  // 保存配置信息
  saveConfig({
    String? platformAccount,
    String? activeCode,
    double? delayTime,
    double? queryDelayTime,
    double? defaultDelayTime,
  }) {
    if (platformAccount != null) {
      _config.platformAccount = platformAccount;
    }
    if (activeCode != null) {
      _config.isActive = (activeCode == "10496${DateTime.now().hour}");
    }
    if (delayTime != null) {
      _config.delayTime = delayTime;
    }
    if (defaultDelayTime != null) {
      _config.minDelayTime = defaultDelayTime;
    }
    if (queryDelayTime != null) {
      _config.queryDelayTime = queryDelayTime;
    }
    _prefs!.setString("config", _config.toString());
  }

  saveDelayTime(String val) {
    saveConfig(
        delayTime: max(isActive ? 0 : _config.minDelayTime, double.parse(val)));
    notifyListeners();
  }

  // 更新登录信息
  updateLoginInfo(String? cookies,
      {Map? wechatData, String? activeCode, String? password}) async {
    if (cookies == null || cookies.isEmpty) {
      MyToast.showToast("输入登录信息");
      return;
    }
    if (Platform.isAndroid && "451601023" != password) {
      MyToast.showToast("密码错误");
      return;
    }
    try {
      if (cookies is String && cookies.isNotEmpty) {
        if (!cookies.contains("PHPSESSID")) {
          cookies = "PHPSESSID=;$cookies";
        }
        if (!cookies.contains("tbtools")) {
          MyToast.showToast("登录信息不正确");
          return;
        }
      } else {
        MyToast.showToast("登录信息不正确");
        return;
      }
      EasyLoading.show(status: "正在登录...");
      await Api.updateConfig();
      _loginInfo = LoginInfo(
          cookies: cookies,
          weChatData: wechatData as Map<String, dynamic>?,
          password: password);
      isLogin = true;
      _prefs!.setString("loginInfo", _loginInfo.toString());
      saveConfig(activeCode: activeCode ?? "");
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      MyToast.showToast(e.toString());
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
      try {
        if (prefs.getString("config") != null) {
        _config =
            Config.fromJson(json.decode(prefs.getString("config") as String));
      } else {
        _config.delayTime = defaultDelayTime;
      }
      } catch (e) {
        _config.minDelayTime = defaultDelayTime;
      }
      return true;
    } catch (_) {}
  }

  // 更新时间配置
  updateTimeConfig(Map data) {
    try {
      double delayTime;
      if (Platform.isAndroid) {
        delayTime = (data["android"]["delayTime"] as num).toDouble();
      } else {
        delayTime = (data["delayTime"] as num).toDouble();
      }
      saveConfig(delayTime: delayTime, defaultDelayTime: delayTime);
    } catch (_) {}
  }

  // 退出
  logout() {
    isLogin = false;
    if (Platform.isAndroid) {
      _prefs?.remove("config");
    }
  }
}
