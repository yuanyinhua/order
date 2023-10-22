import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:m/models/user_info.dart';
import 'package:m/tools/error.dart';
import 'package:m/tools/big_int.dart';
import 'constant.dart';

// 创建 Dio 实例
Dio _dio = Dio(BaseOptions(
  baseUrl: kBaseUrl,
  connectTimeout: 5000,
  receiveTimeout: 3000,
));

Dio _wxDio = Dio(BaseOptions(
  baseUrl: 'https://wxgzh.cklerp.com',
  connectTimeout: 5000,
  receiveTimeout: 3000,
));

// 公共参数
String _kParamsSecret = "";
String _kParamsWindowNo = "";

class Request {
  static Map<String, dynamic> _headers(String path) {
    final commonParams = {
      'Accept':'application/json, text/plain, */*',
      'User-Agent': UserInfo().userAgent ?? pcUserAgent
    };
    if (path.contains("qrCodePath")) {
      return {
        'sec-ch-ua':
            "'Google Chrome';v='93', ' Not;A Brand';v='99', 'Chromium';v='93'",
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': 'macOS',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Cache-Control': 'max-age=0',
        'Connection': 'Keep-Alive',
        'Sec-Fetch-Dest': 'iframe',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        ...commonParams
      };
    }
    return {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json;charset=utf-8',
      if (UserInfo().isLogin) 'ser': UserInfo().cookie ?? "",
      ...commonParams
    };
  }

  //
  static String configSort(dynamic config) {
    List arr = [];
    if (config is List) {
      for (var item in config) {
        arr.add(item);
      }
    } else {
      config.keys.toList();
    }
    arr.sort();
    String str = '';
    for (var i = 0; i < arr.length; i++) {
      // ignore: non_constant_identifier_names
      dynamic arr_type = config[arr[i]];
      arr_type ??= '';

      if (arr_type != null && (arr_type is Object || arr_type is List)) {
        str = "$str${arr[i]}=[${config(arr_type)}]";
      } else {
        str = "$str${arr[i]}=${arr_type.toString()}";
      }
    }
    return str.toString().replaceAll("[^a-zA-Z0-9]", "");
  }

  static String _sign(dynamic platform) {
    var configData = {
      "filter": {
        "i_addorder_mode": 1,
        "i_platform_id": (platform ?? 1).toString(),
        "i_shop_id": "",
        "search": ""
      },
      "path": ["job", "desktopVip"],
      "windowNo": _kParamsWindowNo
    };
    var str = "$_kParamsSecret${configSort(configData)}$_kParamsSecret";
    str = md5.convert(const Utf8Encoder().convert(str)).toString();
    return str;
  }

  // 参数处理
  static FormData _requestParams(params, String path) {
    var formData = params != null ? FormData.fromMap(params) : FormData();
    // if (params != null) {
    //   if (_kParamsWindowNo.isNotEmpty) {
    //     formData.fields
    //         .add(MapEntry("sign", _sign(params?["i_platform_id"] ?? 1)));
    //     formData.fields.add(MapEntry("windowNo", _kParamsWindowNo));
    //   }
    // }
    return formData;
  }

  static dynamic _responseData(Response response) {
    if (response.data is Map) {
      return response.data;
    }
    if (response.data is String) {
      try {
        var val = jsonDecode(response.data);
        if (val is Map) {
          return val;
        }
      } catch (_) {}
    }
    return response.data;
  }

  // 请求入口
  static Future _request(String path, String method,
      {Map<String, dynamic>? params}) async {
    try {
      final isWx = path.contains("wx/");
      final dio = isWx ? _wxDio : _dio;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
      ));
      final options = isWx
          ? Options(method: method)
          : Options(method: method, headers: _headers(path));
      var response = await dio.request('/$path',
          data: _requestParams(params, path), options: options);
      if (response.statusCode == 200) {
        var data = _responseData(response);
        if (data is! Map) {
          return data;
        }
        int? code = data["code"];
        if (code == null) {
          return data;
        }
        if (code == 0) {
          return data["data"];
        }
        String? msg = data["msg"];
        if (msg is String && msg.isNotEmpty && msg.substring(msg.length - 1, msg.length) == "。") {
          msg = msg.substring(0, msg.length - 1);
        }
        if (code == -1 && msg != null && msg.contains("操作频繁")) {
          code = -100;
        } else if (code == -99 && msg == null) {
          msg = "服务异常";
        }
        return Future.error(MError(code, msg));
      } else {
        return Future.error(MError.httpError(response.statusCode));
      }
    } on DioError catch (e, _) {
      return Future.error(MError.error(e).toString());
    } catch (e, _) {
      return Future.error(e);
    }
  }


  static server() async {
    if (_kParamsWindowNo.isNotEmpty) {
      return Future.value();
    }
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
      var content = const Utf8Encoder().convert(timestamp.toString());
      var windowNo = md5.convert(content).toString();

      var session = await _request("yutang/index.php/bas/Sign/server", 'post',
          params: {'A': strA, 'windowNo': windowNo});

      var B = bigIntObj.str2bigInt(session["B"], 10, 0);
      var secret = bigIntObj.powMod(B, biga, bigp);
      secret = bigIntObj.bigInt2str(secret, 10);
      secret += ',';
      _kParamsWindowNo = windowNo;
      _kParamsSecret = secret;
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future post(String path, {Map<String, dynamic>? params}) async {
    // await server();
    return _request(path, 'post', params: params);
  }

  static Future get(String path, {Map<String, dynamic>? params}) async {
    return _request(path, 'get', params: params);
  }

}
