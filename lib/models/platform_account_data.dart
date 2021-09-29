enum AccountPlatform {
  taobao,
  jingdong,
  other,
  pinduoduo,
  tikTok,
}

extension AccountPlatformExtension on AccountPlatform {
  // 平台名字
  String get name {
    switch (this) {
      case AccountPlatform.taobao: return "淘宝";
      case AccountPlatform.jingdong: return "京东";
      case AccountPlatform.other: return "其它";
      case AccountPlatform.pinduoduo: return "拼多多";
      case AccountPlatform.tikTok: return "抖音";
    }
  }
  // 平台id
  int get id {
    switch (this) {
      case AccountPlatform.taobao: return 1;
      case AccountPlatform.jingdong: return 2;
      case AccountPlatform.other: return 3;
      case AccountPlatform.pinduoduo: return 4;
      case AccountPlatform.tikTok: return 5;
    }
  }
}

class PlatformAccountData {
  String name;
  // 平台id
  AccountPlatform platform = AccountPlatform.taobao;
  PlatformAccountData({required this.name});
}

class PlatformAccountLog {
  // 任务
  PlatformAccountData accountData;
  String? log;
  PlatformAccountLog({required this.accountData, this.log});
}