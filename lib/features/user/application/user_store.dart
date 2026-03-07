// lib/features/user/application/user_store.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:lifecapsule8_app/core/network/api.dart';
import 'package:lifecapsule8_app/core/constants/hive_boxes.dart';
import 'package:lifecapsule8_app/features/user/application/user_state.dart';
import 'package:lifecapsule8_app/features/user/domain/user_info.dart';

final userProvider = NotifierProvider<UserStore, UserState>(UserStore.new);

class UserStore extends Notifier<UserState> {
  static const _userKey = 'local_user_info';
  static const _tokenKey = 'token';

  late final Box _settings = Hive.box(HiveBoxes.settings);

  @override
  UserState build() {
    final raw = _settings.get(_userKey);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final user = UserInfo.fromJson(map);
        _writeTokenToLocal(user.token);
        return UserState.initial().copyWith(
          currentUser: user,
          userId: user.userId,
        );
      } catch (_) {
        _settings.delete(_userKey);
        _settings.delete(_tokenKey);
      }
    }
    return UserState.initial();
  }

  @override
  set state(UserState value) {
    final oldToken = super.state.currentUser?.token;
    super.state = value;
    final newToken = super.state.currentUser?.token;
    if (newToken != oldToken) {
      Future.microtask(() => _writeTokenToLocal(newToken));
    }
  }

  Future<bool> login() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final token = state.currentUser?.token ?? '';
      if (token.trim().isNotEmpty) {
        final response = await Api.apiTokenLogin();
        final code = int.tryParse(response['code'].toString(), radix: 10) ?? -1;

        if (code == 0) {
          final userMap = response['data']['user'] as Map<String, dynamic>;
          final userInfo = UserInfo.fromJson(userMap);
          state = state.copyWith(
            currentUser: userInfo,
            userId: userInfo.userId,
            clearError: true,
          );
          await _saveUserToLocal(userInfo);
          return true;
        }

        if (state.userId == null && state.currentUser != null) {
          state = state.copyWith(userId: state.currentUser!.userId);
        }
        return true;
      }

      return await createGuestUser();
    } catch (_) {
      state = state.copyWith(error: 'Network error during login');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> createGuestUser() async {
    state = state.copyWith(loading: true, clearError: true, currentUser: null);
    try {
      final response = await Api.apiCreateGuest();
      final code = int.tryParse(response['code'].toString()) ?? -1;

      if (code == 0) {
        final data = response['data'] as Map<String, dynamic>;
        final user = UserInfo.fromJson(data);
        state = state.copyWith(
          currentUser: user,
          userId: user.userId,
          clearError: true,
        );
        await _saveUserToLocal(user);
        return true;
      } else {
        state = state.copyWith(
          error: (response['message'] as String?) ?? 'Guest login failed',
        );
        return false;
      }
    } catch (_) {
      state = state.copyWith(error: 'Network error during guest login');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> bindEmailSimulated(String email) async {
    final e = email.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
    if (!ok) {
      state = state.copyWith(error: 'Invalid email format');
      return;
    }

    final cur = state.currentUser;
    if (cur == null) {
      state = state.copyWith(error: 'No user session');
      return;
    }

    final updated = cur.copyWith(boundEmail: e);
    state = state.copyWith(currentUser: updated, clearError: true);
    await _saveUserToLocal(updated);
  }

  Future<void> unbindEmail() async {
    final cur = state.currentUser;
    if (cur == null) return;

    final updated = cur.copyWith(boundEmail: null);
    state = state.copyWith(currentUser: updated, clearError: true);
    await _saveUserToLocal(updated);
  }

  Future<void> clearUserLocal() async {
    await _settings.delete(_userKey);
    await _settings.delete(_tokenKey);
    state = state.copyWith(currentUser: null, userId: null, clearError: true);
  }

  Future<void> _saveUserToLocal(UserInfo user) async {
    await _settings.put(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _writeTokenToLocal(String? token) async {
    if (token != null && token.trim().isNotEmpty) {
      await _settings.put(_tokenKey, token);
    } else {
      await _settings.delete(_tokenKey);
    }
  }
}
