import 'package:lifecapsule8_app/provider/user/user_info.dart';

class UserState {
  final bool loading;
  final String? error;
  final String? userId;
  final UserInfo? currentUser;

  const UserState({
    this.loading = false,
    this.error,
    this.userId,
    this.currentUser,
  });

  factory UserState.initial() {
    return const UserState(loading: false, error: null, currentUser: null);
  }

  UserState copyWith({
    bool? loading,
    String? error,
    String? userId,
    UserInfo? currentUser,
    bool clearError = false,
  }) {
    return UserState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      currentUser: currentUser ?? this.currentUser,
      userId: userId ?? this.userId,
    );
  }
}
