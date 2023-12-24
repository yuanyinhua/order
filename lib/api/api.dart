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
  static Future<String> createOrder(PlatformAccountData task, Map shop) async {
    try {
      var response1 = await _search(task, shop);
      List datas = response1["yppList"];
      if (datas.isNotEmpty) {
        datas = datas.where((element) => element["check_lv"] == -1).toList();
      }
      if (datas.isNotEmpty && UserInfo().filterDataIds.isNotEmpty) {
        datas = datas.where((element) => !UserInfo().filterDataIds.contains(element["c_product_id"])).toList();
      }
      if ((datas.isEmpty)) {
        return Future.error("无预约");
      }
      Map data = datas[Random().nextInt(datas.length)];
      Map<String, dynamic> params = {
        'c_platform': shop.isNotEmpty ? shop["c_platform"] : task.platform.name,
        'c_vip_code': task.name,
        'i_plan_id': data["i_plan_id"],
        "i_plan_product_id": data["i_plan_product_id"],
        'i_plan_schedule_id': data["i_plan_schedule_id"]
      };
      // await Future.delayed(Duration(milliseconds: (UserInfo().delayTime * 1000).toInt()));
      await Request.post(
          "index.php//ztai/YbpPlanDesktop/readyPlan",
          params: params);
      Map product = data["product"];
      return "预约成功;${product["c_product_title"]}";
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
  static Future _search(PlatformAccountData task, Map shop) async {
    try {
      return await Request.post("index.php//ztai/YbpPlanDesktop/getPlan",
          params: {
            "search": {
              "i_mode_type": "1",
              "c_platform": shop.isNotEmpty ? shop["c_platform"] : task.platform.name,
              "c_vip_code": task.name,
              if (shop.isNotEmpty) 'i_shop_id' : shop["id"]
          }
          });
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<List<Map>> getShopDatas() async {
    try {
      final data = await Request.get("index.php/bas/Oper/dict", params: {
        'funKey': ["shop"]
      });
      var values = data['shop'] is Map ? data["shop"].values : [];
      List<Map> tvalues = [];
      for (var item in values) {
        if (item is Map) {
          tvalues.add(item);
        }
      }
      return tvalues;
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
