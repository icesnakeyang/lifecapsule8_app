// lib/features/send_task/domain/send_task.dart
import 'send_task_enums.dart';
import 'recipient_payload.dart';

class SendTask {
  final String id;
  final String userId;

  final SendTaskType type;
  final SendScheduleType scheduleType;
  final String? scheduleAtIso; // UTC ISO string if atTime
  final RecipientPayload recipient;

  /// payloadRef: 指向业务数据，比如 futureLetter.noteId
  final String payloadRef;

  final CryptoMode cryptoMode;
  final String idemKey;

  final SendTaskStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime? nextRetryAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const SendTask({
    required this.id,
    required this.userId,
    required this.type,
    required this.scheduleType,
    required this.scheduleAtIso,
    required this.recipient,
    required this.payloadRef,
    required this.cryptoMode,
    required this.idemKey,
    required this.status,
    required this.retryCount,
    required this.lastError,
    required this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });

  SendTask copyWith({
    SendTaskStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? nextRetryAt,
    DateTime? updatedAt,
  }) {
    return SendTask(
      id: id,
      userId: userId,
      type: type,
      scheduleType: scheduleType,
      scheduleAtIso: scheduleAtIso,
      recipient: recipient,
      payloadRef: payloadRef,
      cryptoMode: cryptoMode,
      idemKey: idemKey,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'scheduleType': scheduleType.name,
    'scheduleAtIso': scheduleAtIso,
    'recipient': recipient.toJson(),
    'payloadRef': payloadRef,
    'cryptoMode': cryptoMode.name,
    'idemKey': idemKey,
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'nextRetryAt': nextRetryAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SendTask.fromJson(Map<String, dynamic> map) {
    return SendTask(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      type: SendTaskType.values.byName((map['type'] as String?) ?? 'future'),
      scheduleType: SendScheduleType.values.byName(
        (map['scheduleType'] as String?) ?? 'atTime',
      ),
      scheduleAtIso: map['scheduleAtIso'] as String?,
      recipient: RecipientPayload.fromJson(
        (map['recipient'] as Map).cast<String, dynamic>(),
      ),
      payloadRef: (map['payloadRef'] as String?) ?? '',
      cryptoMode: CryptoMode.values.byName(
        (map['cryptoMode'] as String?) ?? 'none',
      ),
      idemKey: (map['idemKey'] as String?) ?? '',
      status: SendTaskStatus.values.byName(
        (map['status'] as String?) ?? 'pending',
      ),
      retryCount: (map['retryCount'] as int?) ?? 0,
      lastError: map['lastError'] as String?,
      nextRetryAt: DateTime.tryParse((map['nextRetryAt'] as String?) ?? ''),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
