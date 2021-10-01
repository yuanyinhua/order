import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class LoginInfo {
  // 登录后获取，调接口有用
  String cookies;
  // 微信扫码数据
  //"headimgurl" -> "http://thirdwx.qlogo.cn/mmopen/jRoggJ2RF3AicRexNWO1lthpbDfm5icqKBG9avs0CDlEs49CSIEnzvPza1H5GibemAkmbxpe4LGmBzQpJSFzEFcE4LakSQkzi…"
  // 1:"location" -> "中国-湖南-长沙"
  // 2:"nickname" -> "白楚。"
  // 3:"appid" -> "wx9c76e6c8249f2f1e"
  // 4:"openid" -> "oDUYJ1eQxfM_cc-tVBZFksTIeUlk"
  // 5:"state" -> 1
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
