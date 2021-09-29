import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'platform_account_data.dart';

@JsonSerializable()
class Config {
  // 是否激活
  bool isActive;
  // 平台账号
  String? platformAccounts;
  // 下单延迟，防止接口响应频繁
  double delayTime;
  // 查询延迟，防止接口响应频繁
  double queryDelayTime;

  Config(
      {required this.isActive,
      this.platformAccounts,
      required this.delayTime,
      required this.queryDelayTime});

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  @override
  String toString() {
    return json.encode(_$ConfigToJson(this));
  }

  // 当前平台账号
  List<PlatformAccountData> get platformAccountDatas {
    if (this.platformAccounts?.length == 0) {
      return [];
    }
    List<PlatformAccountData> datas = this
        .platformAccounts!
        .split("\n")
        .map((e) => PlatformAccountData(name: e.trim()))
        .toList();
    return datas;
  }
}

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
    isActive: json['isActive'] as bool,
    platformAccounts: json['platformAccounts'],
    delayTime: json['delayTime'],
    queryDelayTime: json['queryDelayTime']);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'platformAccounts': instance.platformAccounts,
      'delayTime': instance.delayTime,
      'queryDelayTime': instance.queryDelayTime
    };