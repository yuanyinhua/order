import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

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

  double minDelayTime;

  Config(
      {required this.isActive,
      this.platformAccount,
      required this.delayTime,
      required this.queryDelayTime,
      required this.minDelayTime});

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  @override
  String toString() {
    return json.encode(_$ConfigToJson(this));
  }
}