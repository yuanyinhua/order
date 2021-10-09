// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Login _$LoginFromJson(Map<String, dynamic> json) => Login(
      cookies: json['cookies'] as String,
      weChatData: json['weChatData'] as Map<String, dynamic>?,
      password: json['password'] as String?,
    );

Map<String, dynamic> _$LoginToJson(Login instance) => <String, dynamic>{
      'cookies': instance.cookies,
      'weChatData': instance.weChatData,
      'password': instance.password,
    };
