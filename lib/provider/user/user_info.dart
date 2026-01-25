// 用户数据模型（可扩展）
class UserInfo {
  final String userId;
  final String token;
  final String userCode;
  final String nickname;
  final bool isGuest;
  final int status; // 1=GUEST, 2=NORMAL
  final String loginName;
  final DateTime? createTime;
  final DateTime? primaryTimer;
  final DateTime? tokenTime;
  final String? boundEmail;

  UserInfo({
    required this.userId,
    required this.token,
    required this.userCode,
    required this.nickname,
    required this.isGuest,
    required this.loginName,
    required this.status,
    this.createTime,
    this.primaryTimer,
    this.tokenTime,
    this.boundEmail,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // 优化：UTC 时间字符串 → 解析为 UTC 对象 → 转为本地时区
    DateTime? parseUtcToLocal(String? timeStr) {
      if (timeStr == null) return null;
      try {
        final utcDateTime = DateTime.parse(timeStr);
        return utcDateTime.toLocal(); // 转为本地时区后返回
      } catch (e) {
        print('时间解析失败：$e');
        return null;
      }
    }

    return UserInfo(
      userId: json['userId'].toString(),
      token: json['token'] ?? '',
      userCode: json['userCode'] ?? '',
      nickname: json['nickname'] ?? '',
      isGuest: json['isGuest'] ?? false,
      status: int.tryParse(json['status'].toString()) ?? 0,
      loginName: json['loginName'] ?? '',
      createTime: parseUtcToLocal(json['createTime']),
      primaryTimer: parseUtcToLocal(json['primaryTimer']),
      tokenTime: parseUtcToLocal(json['tokenTime']),
      boundEmail: (json['boundEmail'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'token': token,
    'userCode': userCode,
    'nickname': nickname,
    'isGuest': isGuest,
    'status': status,
    'loginName': loginName,
    'createTime': createTime?.toUtc().toIso8601String(),
    'primaryTimer': primaryTimer?.toUtc().toIso8601String(),
    'tokenTime': tokenTime?.toUtc().toIso8601String(),
    'boundEmail': boundEmail,
  };

  // ✅ 可选：便捷 copyWith（推荐加，绑定时更干净）
  UserInfo copyWith({String? boundEmail, DateTime? primaryTimer}) {
    return UserInfo(
      userId: userId,
      token: token,
      userCode: userCode,
      nickname: nickname,
      isGuest: isGuest,
      loginName: loginName,
      status: status,
      createTime: createTime,
      primaryTimer: primaryTimer,
      tokenTime: tokenTime,
      boundEmail: boundEmail ?? this.boundEmail,
    );
  }
}
