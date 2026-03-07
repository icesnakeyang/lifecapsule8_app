// lib/features/send_task/domain/recipient_payload.dart

class RecipientPayload {
  final String? userCode;
  final String? email;
  final bool self;

  const RecipientPayload({this.userCode, this.email, required this.self});

  Map<String, dynamic> toJson() => {
    'userCode': userCode,
    'email': email,
    'self': self,
  };

  factory RecipientPayload.fromJson(Map<String, dynamic> map) {
    return RecipientPayload(
      userCode: map['userCode'] as String?,
      email: map['email'] as String?,
      self: (map['self'] as bool?) ?? false,
    );
  }
}
