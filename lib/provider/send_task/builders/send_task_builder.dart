import '../send_task_model.dart';

abstract class SendTaskBuilder<TDraft> {
  /// 将某种草稿（Love/Future/Wish）转换成统一 SendTask 的参数
  SendTaskBuildResult build(TDraft draft);
}

class SendTaskBuildResult {
  final SendTaskType type;
  final SendScheduleType scheduleType;
  final String? scheduleAtIso;
  final String? triggerRef;

  final RecipientPayload recipient;

  final String payloadRef;

  final CryptoMode cryptoMode;
  final String? cryptoHint;
  final String idemKey;

  const SendTaskBuildResult({
    required this.type,
    required this.scheduleType,
    required this.recipient,
    required this.payloadRef,
    required this.cryptoMode,
    this.scheduleAtIso,
    this.triggerRef,
    this.cryptoHint,
    required this.idemKey,
  });
}
