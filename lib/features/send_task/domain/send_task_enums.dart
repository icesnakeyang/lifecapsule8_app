// lib/features/send_task/domain/send_task_enums.dart

enum SendTaskType { future, loveLetter, lastWish, noteShare }

enum SendScheduleType { atTime, immediately }

enum SendTaskStatus { pending, sending, sent, failed, canceled }

enum CryptoMode { none, e2ee }
