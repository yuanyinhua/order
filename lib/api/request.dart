import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:task/models/user_info.dart';
import 'package:task/tools/error.dart';
import 'package:task/tools/bigInt.dart';
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
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
      // 'User-Agent':
      //     'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.63 Safari/537.36',
      // 'Accept-Encoding': 'gzip, deflate, br',
      // 'Accept-Language': 'zh-CN,zh;q=0.9',
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
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Connection': 'Keep-Alive',
      if (UserInfo().isLogin) 'Cookie': UserInfo().cookie ?? "",
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
      if (arr_type == null) arr_type = '';

      if (arr_type != null && (arr_type is Object || arr_type is List))
        str = "$str${arr[i]}=[${config(arr_type)}]";
      else
        str = "$str${arr[i]}=${arr_type.toString()}";
    }
    return str.toString().replaceAll("[^a-zA-Z0-9]", "");
  }

  static String sign(dynamic platform) {
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
    str = md5.convert(Utf8Encoder().convert(str)).toString();
    return str;
  }

  // 参数处理
  static FormData requestParams(params, String path) {
    var formData = params != null ? FormData.fromMap(params) : FormData();
    if (params != null) {
      if (_kParamsWindowNo.isNotEmpty) {
        formData.fields
            .add(MapEntry("sign", sign(params?["i_platform_id"] ?? 1)));
        formData.fields.add(MapEntry("windowNo", _kParamsWindowNo));
      }
    }
    return formData;
  }

  static dynamic responseData(Response response) {
    if (response.data is Map) {
      return response.data;
    }
    if (response.data is String) {
      try {
        var val = jsonDecode(response.data);
        if (val is Map) {
          return val;
        }
      } catch (e) {}
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
          data: requestParams(params, path), options: options);
      if (response.statusCode == 200) {
        var data = responseData(response);
        if (!(data is Map)) {
          return data;
        }
        int? code = data["code"];
        if (code == null) {
          return data;
        }
        if (code == 0) {
          return data["data"];
        }
        String? msg = response.data["msg"];
        if (code == -1 && msg != null && msg.contains("操作频繁")) {
          code = -100;
        } else if (code == -99 && msg == null) {
          msg = "服务异常";
        }
        return Future.error(MError(code, msg));
      } else {
        return Future.error(_httpError(response.statusCode));
      }
    } on DioError catch (e, _) {
      return Future.error(_dioError(e));
    } catch (e, _) {
      return Future.error(e);
    }
  }

  // 处理 Dio 异常
  static String _dioError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectTimeout:
        return "网络连接超时，请检查网络设置";
      case DioErrorType.receiveTimeout:
        return "服务器异常，请稍后重试！";
      case DioErrorType.sendTimeout:
        return "网络连接超时，请检查网络设置";
      case DioErrorType.response:
        return "服务器异常，请稍后重试！";
      case DioErrorType.cancel:
        return "请求已被取消，请重新请求";
      case DioErrorType.other:
        return "其它错误";
      default:
        return "其它错误";
    }
  }

  static String _httpError(int? errorCode) {
    String message;
    switch (errorCode) {
      case 400:
        message = '请求语法错误';
        break;
      case 401:
        message = '未授权，请登录';
        break;
      case 403:
        message = '拒绝访问';
        break;
      case 404:
        message = '请求出错';
        break;
      case 408:
        message = '请求超时';
        break;
      case 500:
        message = '服务器异常';
        break;
      case 501:
        message = '服务未实现';
        break;
      case 502:
        message = '网关错误';
        break;
      case 503:
        message = '服务不可用';
        break;
      case 504:
        message = '网关超时';
        break;
      case 505:
        message = 'HTTP版本不受支持';
        break;
      default:
        message = '请求失败，错误码：$errorCode';
    }
    return message;
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
      var content = Utf8Encoder().convert(timestamp.toString());
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
    await server();
    return _request(path, 'post', params: params);
  }

  static Future get(String path, {Map<String, dynamic>? params}) {
    return _request(path, 'get', params: params);
  }
}
