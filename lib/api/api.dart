import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' show parse;
import 'package:task/api/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'request.dart';
import 'bigInt.dart';

class Api {
  static Future<String> autoAddOrder(PlatformAccountData task) async {
    try {
      var response = await _search(task);
      List list = response["list"];
      Map<String, dynamic> params = {
        'c_gender': response["c_gender"],
        'c_platform': task.platform.name,
        'c_vip_code': task.name,
        'i_job_id': list[0]["i_job_id"],
        'i_shop_id': list[0]["i_shop_id"],
        'path': ["job", "desktopVip"],
        'i_platform_id': task.name
      };
      var data = await Request.post("yutang/index.php/index/Order/addOrder",
          params: params);
      jsonDecode(data);
      return "预约成功;${list[0]["c_name"]}${list[0]["c_shop_name"]}";
    } on MError catch (e) {
      return Future.error(e);
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future queryTaskAvailable(PlatformAccountData task) async {
    try {
      await _search(task);
      return Future.value("查询成功");
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future _search(PlatformAccountData task) async {
    try {
      return await Request.post("yutang/index.php/index/Job/getJobByVipCode", params: {
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

  static Future<bool> load() async {
    try {
      await UserInfo().setup();
      await Api.server();
      return UserInfo().isLogin;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> check() async {
    try {
      await Request.post("tbtools/index.php/com/Login/getRongUserToken",
          params: {});
      return true;
    } catch (e) {
      return false;
    }
  }

  static server() async {
    try {
      var g = "2";
      var p =
          "1060250871334882992391293512479216326438167258746469805890028339770628303789813787064911279666129";
      var bigIntObj = MyBigInt();
      var biga = bigIntObj.randBigInt(100, 0);
      var bigp = bigIntObj.str2bigInt(p, 10, 0);
      var bigg = bigIntObj.str2bigInt(g, 10, 0);
      var A = bigIntObj.powMod(bigg, biga, bigp);
      var strA = bigIntObj.bigInt2str(A, 10);
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      var content = Utf8Encoder().convert(timestamp.toString());
      var windowNo = md5.convert(content).toString();

      var session = await Request.post("yutang/index.php/bas/Sign/server",
          params: {'A': strA, 'windowNo': windowNo});

      var B = bigIntObj.str2bigInt(session["B"], 10, 0);
      var secret = bigIntObj.powMod(B, biga, bigp);
      secret = bigIntObj.bigInt2str(secret, 10);
      secret += ',';
      UserInfo().windowNo = windowNo;
      UserInfo().secret = secret;
      return session;
    } catch (e) {}
  }

  static Future<String?> qrCodeData() async {
    try {
      var response = await Request.get(
          "tbtools/index.php/index/Wechat/qrCodePath?indexUrl=/yutang/");
      var sceneid =
          parse(response).getElementById("sceneid")?.attributes["value"] ?? "";
      UserInfo().sceneId = sceneid;
      return "https://wxgzh.cklerp.com/yt/auth?sceneid=$sceneid";
    } catch (e) {}
  }

  static Future waitScan() async {
    await Future.delayed(Duration(milliseconds: 1500));
    try {
      Request.post("wx/qrcode.status", params: {"sceneid": UserInfo().sceneId});
    } catch (e) {}
  }

  static Future login({Map<String, dynamic>? data}) async {
    if (data == null) {
      data = {
        "headimgurl":
            "http://thirdwx.qlogo.cn/mmopen/jRoggJ2RF3AicRexNWO1lthpbDfm5icqKBG9avs0CDlEs49CSIEnzvPza1H5GibemAkmbxpe4LGmBzQpJSFzEFcE4LakSQkziaW1/132",
        "location": "中国-湖南-长沙",
        "nickname": "白楚。",
        "appid": "wx9c76e6c8249f2f1e",
        "openid": "oDUYJ1eQxfM_cc-tVBZFksTIeUlk",
      };
    }
    String params = Uri.encodeComponent(json.encode(data));
    String path =
        "tbtools/index.php/com/Login/qrcodeLogin.html?indexUrl=/yutang/&params=$params";
    try {
      var response = await Request.post(path,
          params: {"indexUrl": "/yutang/&params=$params"});
      UserInfo().data = response;
      autoAddOrder(PlatformAccountData(name: "袁袁"));
    } catch (e) {}
  }
}
