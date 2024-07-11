// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInfo _$LoginFromJson(Map<String, dynamic> json) => LoginInfo(
      cookies: json['cookies'] as String?,
      qifengCookies: json['qifengCookies'] as String?,
      weChatData: json['weChatData'] as Map<String, dynamic>?,
      password: json['password'] as String?,
      userAgent: json['userAgent'] as String?,
      lastLoginTime: json['lastLoginTime'] as int?,
      activeCode: json['activeCode'] as String?
    );

Map<String, dynamic> _$LoginToJson(LoginInfo instance) => <String, dynamic>{
      'cookies': instance.cookies,
      'qifengCookies': instance.qifengCookies,
      'weChatData': instance.weChatData,
      'password': instance.password,
      'userAgent': instance.userAgent,
      'lastLoginTime': instance.lastLoginTime,
      'activeCode': instance.activeCode
    };
