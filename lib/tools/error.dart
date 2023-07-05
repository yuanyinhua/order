import 'package:dio/dio.dart';

class MError extends Error {
  int? code;
  String? message;

  MError([this.code, this.message]);

  @override
  String toString() {
    if (message != null) {
      if (message is String) {
        return message ?? "";
      }
      return Error.safeToString(message);
    }
    return "";
  }

  // 处理 Dio 异常
  static Error? error(dynamic err) {
    if (err is DioError) {
      DioError error = err;
      switch (error.type) {
        case DioErrorType.connectTimeout:
          return MError(1, "网络连接超时，请检查网络设置");
        case DioErrorType.receiveTimeout:
          return MError(1, "服务器异常，请稍后重试！");
        case DioErrorType.sendTimeout:
          return MError(1, "网络连接超时，请检查网络设置");
        case DioErrorType.response:
          return MError(1, "服务器异常，请稍后重试！");
        case DioErrorType.cancel:
          return MError(1, "请求已被取消，请重新请求");
        default:
      }
    } else {
      return err;
    }
    return null;
  }

  static String httpError(int? errorCode) {
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
}
