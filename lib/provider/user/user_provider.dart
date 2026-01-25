import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/api/api.dart';
import 'package:lifecapsule8_app/provider/user/user_info.dart';
import 'package:lifecapsule8_app/provider/user/user_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserState> {
  static const _userKey = 'local_user_info';

  @override
  UserState build() {
    return UserState.initial();
  }

  // 重写 state setter：只要 state 变化，就检查 token 是否变了，并异步同步到 prefs
  @override
  set state(UserState value) {
    final oldToken = super.state.currentUser?.token;
    super.state = value;
    final newToken = super.state.currentUser?.token;

    if (newToken != oldToken) {
      Future.microtask(() => _updateTokenInPrefs(newToken));
    }
  }

  // ────────────────────── 公开方法 ──────────────────────

  Future<bool> login() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await loadUserFromLocal(); // 确保最新本地状态

      if (state.currentUser != null && state.currentUser!.token.isNotEmpty) {
        final response = await Api.apiTokenLogin();
        final code = int.tryParse(response['code'].toString(), radix: 10) ?? -1;

        if (code == 0) {
          final userMap = response['data']['user'] as Map<String, dynamic>;
          final userInfo = UserInfo.fromJson(userMap);
          state = state.copyWith(
            currentUser: userInfo,
            userId: userInfo.userId,
          );
          final prefs = await SharedPreferences.getInstance();
          prefs.setString(_userKey, jsonEncode(userInfo.toJson()));
          return true;
        } else {
          /// 暂时用当前的用户信息进入
          final userId = state.currentUser!.userId;
          if (state.userId == null) {
            state = state.copyWith(userId: userId);
          }
          return true;
          // token 失效 → 不能自动创建新游客，应让用户选择找
          // return false; // 虽然旧 token 失效，但已自动恢复登录态
        }
      } else {
        // 没有本地用户 → 创建新游客
        bool success = await createGuestUser();
        if (success) {
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Network error during login');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> loadUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userKey);

      if (jsonString == null || jsonString.isEmpty) {
        state = state.copyWith(currentUser: null);
        return true;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final user = UserInfo.fromJson(json);
      state = state.copyWith(currentUser: user);
      return true;
    } catch (e) {
      await clearUserLocal();
      state = state.copyWith(currentUser: null);
      return false;
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

        state = state.copyWith(currentUser: user);
        await _saveUserToLocal(user); // 会自动触发 listenSelf → 同步 token
        return true;
      } else {
        final msg = response['message'] as String? ?? 'Guest login failed';
        state = state.copyWith(error: msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Network error during guest login');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> bindEmailSimulated(String email) async {
    final e = email.trim();

    // 可选：轻量校验（不发验证码，不做归属验证）
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

    // 更新 state（你的 token 同步逻辑不会受影响，因为 token 没变）
    state = state.copyWith(currentUser: updated, clearError: true);

    // 持久化到 local_user_info
    await _saveUserToLocal(updated);
  }

  Future<void> unbindEmail() async {
    final cur = state.currentUser;
    if (cur == null) return;

    final updated = cur.copyWith(boundEmail: null);
    state = state.copyWith(currentUser: updated, clearError: true);
    await _saveUserToLocal(updated);
  }

  // ────────────────────── 私有方法 ──────────────────────

  /// 所有保存用户的地方都走这里 → 保证 token 同步
  Future<void> _saveUserToLocal(UserInfo user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    // 注意：这里不要再手动写 token！
    // 因为 ref.listenSelf 已经监听了 state 变化，会自动调用 _updateTokenInPrefs
    // 重复写反而可能造成并发问题
  }

  /// 统一更新 token 到 SharedPreferences（唯一出口）
  Future<void> _updateTokenInPrefs(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString('token', token);
      // debugPrint('Token updated: ${token.substring(0, 10)}...');
    } else {
      await prefs.remove('token');
      // debugPrint('Token cleared');
    }
  }

  Future<void> clearUserLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove('token'); // 务必一起清！
    state = state.copyWith(currentUser: null);
  }

  Future<bool> snoozePrimaryTimer() async {
    final cur = state.currentUser;
    if (cur == null) {
      state = state.copyWith(error: 'No user session');
      return false;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      // 你的 API 封装：params 可以传空
      final resp = await Api.apiSnooze({});

      final code = int.tryParse(resp['code'].toString()) ?? -1;
      if (code != 0) {
        final msg = resp['message'] as String? ?? 'Snooze failed';
        state = state.copyWith(error: msg);
        return false;
      }

      // 尽量从后端返回取最新 primaryTimer（推荐后端返回 user 或 primaryTimer）
      DateTime? newTimer;

      final data = resp['data'];
      if (data is Map<String, dynamic>) {
        // 情况 A：后端返回 { user: {...} }
        if (data['user'] is Map<String, dynamic>) {
          final userMap = data['user'] as Map<String, dynamic>;
          final userInfo = UserInfo.fromJson(userMap);

          state = state.copyWith(
            currentUser: userInfo,
            userId: userInfo.userId,
          );
          await _saveUserToLocal(userInfo);
          return true;
        }

        // 情况 B：后端只返回 primaryTimer
        final pt = data['primaryTimer'] ?? data['primary_timer'];
        if (pt is String && pt.isNotEmpty) {
          newTimer = DateTime.tryParse(pt);
        }
      }

      // 兜底：如果后端没给 primaryTimer，就先本地加 30 天（不推荐长期依赖）
      newTimer ??= DateTime.now().add(const Duration(days: 30));

      final updated = cur.copyWith(primaryTimer: newTimer);
      state = state.copyWith(currentUser: updated);
      await _saveUserToLocal(updated);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Network error during snooze');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}
