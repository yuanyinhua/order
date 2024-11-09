import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  // 平台账号
  String? platformAccount;
  // 下单延迟，防止接口响应频繁
  double delayTime;

  // 查询延迟，防止接口响应频繁
  double queryDelayTime;

  double minDelayTime;

  String? filterDataIds;
  String? filterData1;
  String? filterData2;
  Config(
      {this.platformAccount,
      required this.delayTime,
      required this.queryDelayTime,
      required this.minDelayTime,
      this.filterDataIds,
      this.filterData1,
      this.filterData2});

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  @override
  String toString() {
    return json.encode(_$ConfigToJson(this));
  }
}