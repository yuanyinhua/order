import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class LoginInfo {
  // 登录后获取，调接口有用
  String cookies;
  // 微信扫码数据
  Map? weChatData;
  LoginInfo({required this.cookies, this.weChatData});

  factory LoginInfo.fromJson(Map<String, dynamic> json) => _$LoginInfoFromJson(json);

  @override
  String toString() {
    return json.encode(_$LoginInfoToJson(this));
  }
}

LoginInfo _$LoginInfoFromJson(Map<String, dynamic> json) => LoginInfo(
  cookies: json['cookies'] as String,
  weChatData: json['weChatData'] == null ? null : json['weChatData'] as Map
);

Map<String, dynamic> _$LoginInfoToJson(LoginInfo instance) => <String, dynamic>{
  'cookies': instance.cookies,
  'weChatData': instance.weChatData
};
