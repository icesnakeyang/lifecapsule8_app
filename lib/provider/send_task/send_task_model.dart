import 'dart:convert';

enum SendTaskType { love, future, lastWishes }

enum SendTaskStatus { pending, scheduled, sending, sent, failed, canceled }

enum SendScheduleType { instantly, atTime }

enum CryptoMode { none, passcode, qa }

class RecipientPayload {
  final String? email; // 用户填写
  final String? userCode; // 用户选择/填写
  final bool self; // UI 快捷方式：发给自己（不入库/不上云）

  const RecipientPayload({this.email, this.userCode, this.self = false});

  RecipientPayload copyWith({String? email, String? userCode, bool? self}) {
    return RecipientPayload(
      email: email ?? this.email,
      userCode: userCode ?? this.userCode,
      self: self ?? this.self,
    );
  }

  String? get emailTrim {
    final v = email?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  String? get userCodeTrim {
    final v = userCode?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// ✅ 最合理规则：email / userCode 必须且只能有一个
  void validate() {
    final hasEmail = emailTrim != null;
    final hasUser = userCodeTrim != null;
    if (hasEmail == hasUser) {
      throw StateError(
        'Recipient must provide exactly one of email or userCode',
      );
    }
  }

  /// ✅ 上云 / 入库用：不携带 self（因为它只是 UI shortcut）
  Map<String, dynamic> toCloudJson() => {
    'email': emailTrim,
    'userCode': userCodeTrim,
  };

  /// 本地存储可以保留 self（用于 UI 恢复）
  Map<String, dynamic> toJson() => {
    'email': email,
    'userCode': userCode,
    'self': self,
  };

  static RecipientPayload fromJson(Map<String, dynamic> m) {
    return RecipientPayload(
      email: m['email'] as String?,
      userCode: m['userCode'] as String?,
      self: (m['self'] as bool?) ?? false,
    );
  }

  static RecipientPayload fromCloudJson(Map<String, dynamic> m) {
    return RecipientPayload(
      email: m['email'] as String?,
      userCode: m['userCode'] as String?,
      self: false,
    );
  }
}

class SendTask {
  final String taskId;
  final String idemKey;

  final SendTaskType type;
  final SendTaskStatus status;

  final SendScheduleType scheduleType;
  final String? scheduleAtIso; // for atTime
  final String? triggerRef; // countdownId / conditionId

  final RecipientPayload recipient;

  final String payloadRef; // noteId / futureId / wishId

  final CryptoMode cryptoMode;
  final String? cryptoHint;

  final int retryCount;
  final String? lastError;

  final String createdAtIso;
  final String updatedAtIso;

  const SendTask({
    required this.taskId,
    required this.idemKey,
    required this.type,
    required this.status,
    required this.scheduleType,
    required this.recipient,
    required this.payloadRef,
    required this.cryptoMode,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.scheduleAtIso,
    this.triggerRef,
    this.cryptoHint,
    this.retryCount = 0,
    this.lastError,
  });

  SendTask copyWith({
    SendTaskStatus? status,
    String? scheduleAtIso,
    String? triggerRef,
    RecipientPayload? recipient,
    CryptoMode? cryptoMode,
    String? cryptoHint,
    int? retryCount,
    String? lastError,
    String? updatedAtIso,
  }) {
    return SendTask(
      taskId: taskId,
      idemKey: idemKey,
      type: type,
      status: status ?? this.status,
      scheduleType: scheduleType,
      scheduleAtIso: scheduleAtIso ?? this.scheduleAtIso,
      triggerRef: triggerRef ?? this.triggerRef,
      recipient: recipient ?? this.recipient,
      payloadRef: payloadRef,
      cryptoMode: cryptoMode ?? this.cryptoMode,
      cryptoHint: cryptoHint ?? this.cryptoHint,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAtIso: createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
    );
  }

  /// ✅ 严格校验：recipient 二选一，atTime 必须有时间
  void validate() {
    recipient.validate();

    if (scheduleType == SendScheduleType.atTime) {
      final s = scheduleAtIso?.trim() ?? '';
      if (s.isEmpty) {
        throw StateError(
          'SendTask(scheduleType=atTime) requires scheduleAtIso',
        );
      }
    }

    if (type == SendTaskType.lastWishes) {
      assert(
        scheduleType == SendScheduleType.atTime,
        'lastWishes must use atTime schedule',
      );
    }
  }

  /// ✅ 上云 payload（最合理、最干净）：不包含 self，也不包含任何 recipientType/recipientRef
  Map<String, dynamic> toCloudJson() => {
    'idemKey': idemKey,
    'clientTaskId': taskId,
    'type': type.name.toUpperCase(),
    'scheduleType': scheduleType.name,
    'scheduleAtIso': scheduleAtIso,
    'triggerRef': triggerRef,
    'recipient': recipient.toCloudJson(),
    'payloadRef': payloadRef,
    'cryptoMode': cryptoMode.name,
    'cryptoHint': cryptoHint,
    'clientCreatedAtIso': createdAtIso,
    'clientUpdatedAtIso': updatedAtIso,
  };

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'idemKey': idemKey,
    'type': type.name,
    'status': status.name,
    'scheduleType': scheduleType.name,
    'scheduleAtIso': scheduleAtIso,
    'triggerRef': triggerRef,
    'recipient': recipient.toJson(),
    'payloadRef': payloadRef,
    'cryptoMode': cryptoMode.name,
    'cryptoHint': cryptoHint,
    'retryCount': retryCount,
    'lastError': lastError,
    'createdAtIso': createdAtIso,
    'updatedAtIso': updatedAtIso,
  };

  static SendTask fromJson(Map<String, dynamic> m) {
    return SendTask(
      taskId: m['taskId'] as String,
      idemKey: (m['idemKey'] as String?) ?? '',
      type: SendTaskType.values.byName(m['type'] as String),
      status: SendTaskStatus.values.byName(m['status'] as String),
      scheduleType: SendScheduleType.values.byName(m['scheduleType'] as String),
      scheduleAtIso: m['scheduleAtIso'] as String?,
      triggerRef: m['triggerRef'] as String?,
      recipient: RecipientPayload.fromJson(
        (m['recipient'] as Map).cast<String, dynamic>(),
      ),
      payloadRef: m['payloadRef'] as String,
      cryptoMode: CryptoMode.values.byName(m['cryptoMode'] as String),
      cryptoHint: m['cryptoHint'] as String?,
      retryCount: (m['retryCount'] as num?)?.toInt() ?? 0,
      lastError: m['lastError'] as String?,
      createdAtIso: m['createdAtIso'] as String,
      updatedAtIso: m['updatedAtIso'] as String,
    );
  }

  String encode() => jsonEncode(toJson());
  static SendTask decode(String raw) => fromJson(jsonDecode(raw));
}
