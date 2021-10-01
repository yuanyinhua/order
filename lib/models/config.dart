import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Config {
  // 是否激活
  bool isActive;
  // 平台账号
  String? platformAccount;
  // 下单延迟，防止接口响应频繁
  double delayTime;
  // 查询延迟，防止接口响应频繁
  double queryDelayTime;

  Config(
      {required this.isActive,
      this.platformAccount,
      required this.delayTime,
      required this.queryDelayTime});

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  @override
  String toString() {
    return json.encode(_$ConfigToJson(this));
  }
}

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
    isActive: json['isActive'] as bool,
    platformAccount: json['platformAccount'],
    delayTime: json['delayTime'],
    queryDelayTime: json['queryDelayTime']);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'platformAccount': instance.platformAccount,
      'delayTime': instance.delayTime,
      'queryDelayTime': instance.queryDelayTime
    };
