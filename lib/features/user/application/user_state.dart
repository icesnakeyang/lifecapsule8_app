import 'package:lifecapsule8_app/features/user/domain/user_info.dart';

class UserState {
  final bool loading;
  final String? error;
  final String? userId;
  final String? email;
  final bool isEmailBound;
  final UserInfo? currentUser;

  const UserState({
    this.loading = false,
    this.error,
    this.userId,
    this.currentUser,
    this.email,
    required this.isEmailBound,
  });

  factory UserState.initial() {
    return const UserState(
      loading: false,
      error: null,
      currentUser: null,
      userId: null,
      email: null,
      isEmailBound: false,
    );
  }

  UserState copyWith({
    bool? loading,
    String? error,
    String? userId,
    UserInfo? currentUser,
    bool clearError = false,
    String? email,
    bool? isEmailBound,
  }) {
    return UserState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      currentUser: currentUser ?? this.currentUser,
      email: email ?? this.email,
      isEmailBound: isEmailBound ?? this.isEmailBound,
      userId: userId ?? this.userId,
    );
  }
}
