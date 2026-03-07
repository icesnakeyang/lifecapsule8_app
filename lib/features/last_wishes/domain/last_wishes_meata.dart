// lib/features/last_wishes/domain/last_wishes_meta.dart

import 'package:lifecapsule8_app/features/last_wishes/domain/last_wishes_keys.dart';

class LastWishesMeta {
  final String? recipientEmail;
  final int? waitingYears;
  final bool enabled;
  final String? messageNote;

  /// 预留：以后支持具体时间发送
  final String? sendMode;
  final DateTime? sendAt;

  const LastWishesMeta({
    this.recipientEmail,
    this.waitingYears,
    this.enabled = false,
    this.messageNote,
    this.sendMode,
    this.sendAt,
  });

  LastWishesMeta copyWith({
    String? recipientEmail,
    int? waitingYears,
    bool? enabled,
    String? messageNote,
    bool clearRecipientEmail = false,
    bool clearWaitingYears = false,
    bool clearMessageNote = false,
    String? sendMode,
    DateTime? sendAt,
    bool clearSendAt = false,
    bool clearSendMode = false,
  }) {
    return LastWishesMeta(
      recipientEmail: clearRecipientEmail
          ? null
          : (recipientEmail ?? this.recipientEmail),
      waitingYears: clearWaitingYears
          ? null
          : (waitingYears ?? this.waitingYears),
      enabled: enabled ?? this.enabled,
      messageNote: clearMessageNote ? null : (messageNote ?? this.messageNote),
      sendMode: clearSendMode ? null : (sendMode ?? this.sendMode),
      sendAt: clearSendAt ? null : (sendAt ?? this.sendAt),
    );
  }

  Map<String, dynamic> toJson() => {
    LastWishesKeys.recipientEmail: recipientEmail,
    LastWishesKeys.waitingYears: waitingYears,
    LastWishesKeys.enabled: enabled,
    LastWishesKeys.messageNote: messageNote,
    LastWishesKeys.sendMode: sendMode,
    LastWishesKeys.sendAtMs: sendAt?.millisecondsSinceEpoch,
  };

  static LastWishesMeta fromJson(Map<String, dynamic>? m) {
    if (m == null) return const LastWishesMeta();

    final sendAtMs = m[LastWishesKeys.sendAtMs];
    DateTime? sendAt;
    if (sendAtMs is num) {
      sendAt = DateTime.fromMillisecondsSinceEpoch(sendAtMs.toInt());
    }

    return LastWishesMeta(
      recipientEmail: m[LastWishesKeys.recipientEmail] as String?,
      waitingYears: (m[LastWishesKeys.waitingYears] as num?)?.toInt(),
      enabled: (m[LastWishesKeys.enabled] as bool?) ?? false,
      messageNote: m[LastWishesKeys.messageNote] as String?,
      sendMode: m[LastWishesKeys.sendMode] as String?,
      sendAt: sendAt,
    );
  }
}
