// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      isActive: json['isActive'] as bool,
      platformAccount: json['platformAccount'] as String?,
      delayTime: (json['delayTime'] as num).toDouble(),
      queryDelayTime: (json['queryDelayTime'] as num).toDouble(),
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'isActive': instance.isActive,
      'platformAccount': instance.platformAccount,
      'delayTime': instance.delayTime,
      'queryDelayTime': instance.queryDelayTime,
    };
