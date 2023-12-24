// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      platformAccount: json['platformAccount'] as String?,
      delayTime: (json['delayTime'] as num).toDouble(),
      queryDelayTime: (json['queryDelayTime'] as num).toDouble(),
      minDelayTime: (json['minDelayTime'] as num).toDouble(),
      filterDataIds: json['filterDataIds'] as String?
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'platformAccount': instance.platformAccount,
      'delayTime': instance.delayTime,
      'queryDelayTime': instance.queryDelayTime,
      'minDelayTime': instance.minDelayTime,
      'filterDataIds': instance.filterDataIds
    };
