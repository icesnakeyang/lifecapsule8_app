// lib/provider/sync/outbox_item.dart
enum OutboxType { noteUpsert, noteDelete, futureLetterUpsert, sendTaskUpsert }

class OutboxItem {
  final String id; // uuid
  final OutboxType type;
  final String refId; // noteId / futureLetterId / sendTaskId
  final String payloadJson; // 上传需要的最小数据（可以是加密后的）
  final int createdAtMs;
  final int tryCount;
  final String? lastError;

  const OutboxItem({
    required this.id,
    required this.type,
    required this.refId,
    required this.payloadJson,
    required this.createdAtMs,
    this.tryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'refId': refId,
    'payloadJson': payloadJson,
    'createdAtMs': createdAtMs,
    'tryCount': tryCount,
    'lastError': lastError,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    id: j['id'],
    type: OutboxType.values.firstWhere((e) => e.name == j['type']),
    refId: j['refId'],
    payloadJson: j['payloadJson'],
    createdAtMs: j['createdAtMs'],
    tryCount: j['tryCount'] ?? 0,
    lastError: j['lastError'],
  );

  OutboxItem copyWith({int? tryCount, String? lastError}) => OutboxItem(
    id: id,
    type: type,
    refId: refId,
    payloadJson: payloadJson,
    createdAtMs: createdAtMs,
    tryCount: tryCount ?? this.tryCount,
    lastError: lastError ?? this.lastError,
  );
}
