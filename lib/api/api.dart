import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:html/parser.dart' show parse;

import 'package:m/models/webview_manager.dart';
import 'package:m/tools/error.dart';
import 'package:m/models/platform_account_data.dart';
import 'package:m/models/user_info.dart';
import 'request.dart';
import 'package:dio/dio.dart';
import 'package:m/api/constant.dart';

String? _kParamsSceneId;

class Api {
  static Future<String> createOrder(PlatformAccountData task) async {
    try {
      var response1 = await _search(task);
      List datas = response1["list"];
      if ((datas.isEmpty)) {
        return Future.error("预约失败");
      }
      Map data = datas[Random().nextInt(datas.length)];
      Map<String, dynamic> params = {
        'c_gender': response1["c_gender"],
        'c_platform': task.platform.name,
        'c_vip_code': task.name,
        'i_job_id': data["i_job_id"],
        'i_shop_id': data["i_shop_id"],
        'path': ["job", "desktopVip"],
        'i_platform_id': task.name
      };
      // await Future.delayed(Duration(milliseconds: (UserInfo().delayTime * 1000).toInt()));
      var response2 = await Request.post(
          "yutang/index.php/index/Order/addOrder",
          params: params);
      jsonDecode(response2);
      return "预约成功;${data["c_name"]}${data["c_shop_name"]}";
    } on MError catch (e) {
      return Future.error(e);
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future queryTaskAvailable(PlatformAccountData task) async {
    try {
      await Request.post("yutang/index.php/toolsapi/ToolsApi/queryVipCode",
          params: {
            "c_vip_code": task.name,
            "api": "getVipCodeDown",
            "path": ["job", "desktopVip"]
          });
      return "查询成功";
    } catch (e) {
      return Future.error(e);
    }
  }

  // 搜索商品
  static Future _search(PlatformAccountData task) async {
    try {
      return await Request.post("yutang/index.php/index/Job/getJobByVipCode",
          params: {
            "page": 1,
            "limit": 10,
            "c_vip_code": task.name,
            "i_platform_id": task.platform.id,
            "windowNo": "137be1530135d041807cf5e03365b0cf",
            "sign": "3c922f937cb3388151463087333abd40",
          });
    } catch (e) {
      return Future.error(e);
    }
  }

  // 加载，获取必要参数
  static Future<bool> load() async {
    try {
      await UserInfo().setup();
      return true;
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<String?> qrCodeData() async {
    try {
      var response = await Request.get(
          "tbtools/index.php/index/Wechat/qrCodePath?indexUrl=/yutang/");
      _kParamsSceneId =
          parse(response).getElementById("sceneid")?.attributes["value"] ?? "";
      return "https://wxgzh.cklerp.com/yt/auth?sceneid=$_kParamsSceneId";
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future waitLogin() async {
    // 等待扫描
    try {
      var response = await Request.post("wx/qrcode.status",
          params: {"sceneid": _kParamsSceneId});
      if (response is Map) {
        var cookies = await MyWebViewManager().getCookie(wechatData: response);
        UserInfo().login(cookies,
            wechatData: response,
            activeCode: "",
            userAgent: (Platform.isAndroid ? androidUserAgent : iosUserAgent));
        return Future.value();
      } else {
        return Future.error("等待扫描");
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  static updateConfig(bool checkPassword) async {
    try {
      var response = await Dio(BaseOptions(
        connectTimeout: 10000,
        receiveTimeout: 3000)).get('https://gitee.com/yuan-xuefeng111/config.json/blob/master/data');
      if (response.statusCode == 200) {
        var document = parse(response.data);
        var text = document.getElementById("LC1")!.text.trim();
        UserInfo().updateTimeConfig(text, checkPassword);
      } else {
        return Future.error("登录失败");
      }
    } catch (e) {
      return Future.error(MError.error(e).toString());
    }
  }
}
