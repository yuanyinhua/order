import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:m/api/constant.dart';
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

  String? _password;
  String? _activeCode;

  double get delayTime => _config.delayTime;

  double get defaultDelayTime => Platform.isAndroid ? 5 : 1.2;

  bool isActive = false;
  String? get platformAccount => _config.platformAccount;
  String get filterDataIds => _config.filterDataIds ?? "";

  String? get cookie => _loginInfo?.cookies;
  String? get qifengCookies => _loginInfo?.qifengCookies;
  String? get userAgent => _loginInfo?.userAgent;
  String? get userSer => _loginInfo?.userSer;
  bool get isShowPassword {
    if (!Platform.isAndroid) {
      return false;
    }
    return true;
  }

  bool get isLoginInPast30Days {
    if (_loginInfo == null || _loginInfo?.lastLoginTime == null) {
      return false;
    }
    return (DateTime.now().millisecond - _loginInfo!.lastLoginTime!) /
            (1000 * 60 * 60 * 24) >
        30;
  }

  // 保存配置信息
  saveConfig({
    String? platformAccount,
    double? delayTime,
    double? queryDelayTime,
    double? defaultDelayTime,
    String? filterDataIds,
    String? filterData1,
    String? filterData2,
  }) {

    if (platformAccount != null) {
      _config.platformAccount = platformAccount;
    }
    if (delayTime != null) {
      _config.delayTime = delayTime;
    }
    if (filterDataIds != null) {
      _config.filterDataIds = filterDataIds;
    }
    if (filterData1 != null) {
      _config.filterData1 = filterData1;
    }
     if (filterData2 != null) {
      _config.filterData2 = filterData2;
    }
    if (defaultDelayTime != null) {
      _config.minDelayTime = defaultDelayTime;
    }
    if (queryDelayTime != null) {
      _config.queryDelayTime = queryDelayTime;
    }
    if (delayTime != null &&
        defaultDelayTime != null &&
        delayTime > _config.delayTime) {
      saveDelayTime(delayTime.toString());
    }
    _prefs!.setString("config", _config.toString());
  }

  saveDelayTime(String val) {
    saveConfig(
        delayTime: max(isActive ? 0 : _config.minDelayTime, double.parse(val)));
    notifyListeners();
  }

  Map getFilterData(String baseUrl) {
    if (baseUrl == kBaseQiziUrl) {
      return jsonDecode(_config.filterData1 ?? "");
    } else {
      return jsonDecode(_config.filterData2 ?? "");
    }
  }

  // 更新登录信息
  login(String? cookies,
      {Map? wechatData,
      String? activeCode,
      String? password,
      String? userAgent}) async {
    try {
      if (isShowPassword && (password == null || password.isEmpty)) {
        MyToast.showToast("请输入密码");
        return;
      }
      EasyLoading.show(status: "正在登录...");
      await Api.updateConfig(false);
      if (isShowPassword && _password != password) {
        EasyLoading.dismiss();
        MyToast.showToast("密码错误");
        return;
      }
      activeCode ??= _activeCode;
      if (userAgent is String && userAgent.isEmpty) {
        userAgent = null;
      }
      _loginInfo = LoginInfo(
          cookies: _loginInfo?.cookies,
          qifengCookies: _loginInfo?.qifengCookies,
          weChatData: wechatData as Map<String, dynamic>?,
          password: password,
          userAgent: userAgent,
          activeCode: activeCode);
      isLogin = true;
      _prefs!.setString("loginInfo", _loginInfo.toString());
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
        if (loginInfo.lastLoginTime == null) {
          loginInfo.lastLoginTime = DateTime.now().millisecond;
          _prefs!.setString("loginInfo", _loginInfo.toString());
        }
        _updateGithubData();
        if (Platform.isAndroid) {
          // 三十天后退出登录
          // if (isLoginInPast30Days || (loginInfo.password != _password)) {
          //   isLogin = false;
          // } else {
            // isLogin = true;
            _loginInfo = loginInfo;
          // }
        } else {
          _loginInfo = loginInfo;
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

  updateLoginToken(String cookies, String baseUrl) {
    if (baseUrl.contains(kBaseQifengUrl)) {
      _loginInfo?.qifengCookies = cookies;
    } else {
      _loginInfo?.cookies = cookies;
    }
    _prefs?.setString("loginInfo", _loginInfo.toString());
  }

  // 更新时间配置
  updateTimeConfig(String str, bool checkPassword) {
    try {
      Map data = jsonDecode(str);
      double delayTime;
      if (Platform.isAndroid) {
        delayTime = (data["android"]["delayTime"] as num).toDouble();
      } else {
        delayTime = (data["delayTime"] as num).toDouble();
      }
      _prefs?.setString("GithubData", str);
      _updateGithubData();
      if (!isActive) {
        saveConfig(delayTime: delayTime, defaultDelayTime: delayTime);
      }
      // 密码不对退出登录
      if (Platform.isAndroid &&
          checkPassword &&
          (_password != _loginInfo?.password || isLoginInPast30Days)) {
        _loginInfo?.password = null;
        _prefs?.setString("loginInfo", _loginInfo.toString());
        logout();
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 更新github获取的配置数据
  _updateGithubData() {
    String? str = _prefs?.getString("GithubData");
    if (str == null) {
      return;
    }
    Map data = jsonDecode(str);
    _password = data["password"];
    _activeCode = data["activeCode"];
    isActive = _activeCode == _loginInfo?.activeCode;
  }

  // 退出
  logout() {
    isLogin = false;
    if (Platform.isAndroid) {
      _prefs?.remove("config");
    }
  }
}
