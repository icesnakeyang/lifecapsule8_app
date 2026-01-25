import 'package:flutter/material.dart';
import 'package:lifecapsule8_app/pages/future/future_letter_list.dart';
import 'package:lifecapsule8_app/pages/future/future_letter_preview.dart';
import 'package:lifecapsule8_app/pages/future/future_letter_recipient.dart';
import 'package:lifecapsule8_app/pages/future/future_letter_schedule.dart';
import 'package:lifecapsule8_app/pages/future/future_letter_write.dart';
import 'package:lifecapsule8_app/pages/inspiration/inspiration_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_destination_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_done_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_intro_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_preview_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_recipient_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_view_page.dart';
import 'package:lifecapsule8_app/pages/last_wishes/last_wishes_write_page.dart';
import 'package:lifecapsule8_app/pages/love/love_letter.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_list.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_next2.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_passcode.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_preview.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_recipient.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_send_spectime.dart';
import 'package:lifecapsule8_app/pages/love/love_letter_user_search.dart';
import 'package:lifecapsule8_app/pages/note/note_edit.dart';
import 'package:lifecapsule8_app/pages/note/note_list.dart';
import 'package:lifecapsule8_app/pages/settings/crypto_setting.dart';
import 'package:lifecapsule8_app/pages/settings/mnemonic_restore.dart';
import 'package:lifecapsule8_app/pages/settings/my_profile.dart';
import 'package:lifecapsule8_app/pages/settings/restore_master_key.dart';
import 'package:lifecapsule8_app/pages/settings/settings_page.dart';
import 'package:lifecapsule8_app/pages/settings/setup_mnemonic.dart';

// 按需改成你 lifecapsule8 的页面
import 'package:lifecapsule8_app/pages/welcome_page.dart';
import 'package:lifecapsule8_app/pages/dashboard/home_page.dart';
import 'package:lifecapsule8_app/pages/login/login_page.dart';
// 以后新页面在这里 import

class AppRoute {
  final String name;
  final WidgetBuilder builder;
  final bool requireAuth;

  const AppRoute({
    required this.name,
    required this.builder,
    this.requireAuth = false,
  });
}

/// 统一路由表 —— 以后新页面就来这里复制一行
final List<AppRoute> appRoutes = [
  AppRoute(name: '/welcome', builder: (context) => const WelcomePage()),
  AppRoute(
    name: '/',
    builder: (context) => const HomePage(),
    requireAuth: true,
  ),
  AppRoute(name: '/login', builder: (context) => const LoginPage()),

  AppRoute(name: '/settings', builder: (context) => const SettingsPage()),
  AppRoute(name: '/noteedit', builder: (context) => const NoteEdit()),
  AppRoute(name: '/notelist', builder: (context) => const NoteList()),
  AppRoute(name: '/cryptosetting', builder: (context) => const CryptoSetting()),
  AppRoute(
    name: '/setupMnemonic',
    builder: (context) => const SetupMnemonicPage(),
  ),
  AppRoute(
    name: '/MnemonicRestore',
    builder: (context) => const MnemonicRestorePage(),
  ),
  AppRoute(
    name: '/RestoreMasterKey',
    builder: (context) => const RestoreMasterKey(),
  ),
  AppRoute(name: '/MyProfile', builder: (context) => const MyProfile()),
  AppRoute(name: '/LoveLetter', builder: (context) => const LoveLetter()),
  AppRoute(
    name: '/LoveLetterList',
    builder: (context) => const LoveLetterList(),
  ),
  AppRoute(
    name: '/LoveLetterNext2',
    builder: (context) => const LoveLetterNext2(),
  ),
  AppRoute(
    name: '/LoveLetterSendSpectime',
    builder: (context) => const LoveLetterSendSpectime(),
  ),
  AppRoute(
    name: '/LoveLetterRecipient',
    builder: (context) => const LoveLetterRecipient(),
  ),
  AppRoute(
    name: '/LoveLetterPreview',
    builder: (context) => const LoveLetterPreview(),
  ),
  AppRoute(
    name: '/LoveLetterUserSearch',
    builder: (context) => const LoveLetterUserSearch(),
  ),
  AppRoute(
    name: '/LoveLetterPasscode',
    builder: (context) => const LoveLetterPasscode(),
  ),
  AppRoute(
    name: '/LastWishesDestinationPage',
    builder: (context) => const LastWishesDestinationPage(),
  ),

  AppRoute(
    name: '/LastWishesDonePage',
    builder: (context) => const LastWishesDonePage(),
    requireAuth: true,
  ),

  AppRoute(
    name: '/LastWishesIntroPage',
    builder: (context) => const LastWishesIntroPage(),
    requireAuth: true,
  ),

  AppRoute(
    name: '/LastWishesPreviewPage',
    builder: (context) => const LastWishesPreviewPage(),
    requireAuth: true,
  ),

  AppRoute(
    name: '/LastWishesRecipientPage',
    builder: (context) => const LastWishesRecipientPage(),
    requireAuth: true,
  ),

  AppRoute(
    name: '/LastWishesWritePage',
    builder: (context) => const LastWishesWritePage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/LastWishesViewPage',
    builder: (context) => const LastWishesViewPage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/InspirationPage',
    builder: (context) => const InspirationPage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/FutureLetterWritePage',
    builder: (context) => const FutureLetterWritePage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/FutureLetterRecipientPage',
    builder: (context) => const FutureLetterRecipientPage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/FutureLetterSchedulePage',
    builder: (context) => const FutureLetterSchedulePage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/FutureLetterPreviewPage',
    builder: (context) => const FutureLetterPreviewPage(),
    requireAuth: true,
  ),
  AppRoute(
    name: '/FutureLetterListPage',
    builder: (context) => const FutureLetterListPage(),
    requireAuth: true,
  ),
];

/// 未知路由页
class UnknownPage extends StatelessWidget {
  final String? name;
  const UnknownPage({super.key, this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('页面不存在：$name')));
  }
}

/// 全局路由生成方法 —— 在 main.dart 里直接用
Route<dynamic> appGenerateRoute(RouteSettings settings) {
  final rawName = settings.name ?? '/';
  final uri = Uri.tryParse(rawName);
  final path = uri?.path ?? rawName;

  // 在路由表中查找
  final matchingRoute = appRoutes.firstWhere(
    (route) => route.name == path,
    orElse: () => AppRoute(
      name: '/unknown',
      builder: (context) => UnknownPage(name: path),
    ),
  );

  // 合并 query 参数和 arguments（可选）
  final mergedArgs = _mergeArgs(settings.arguments, uri?.queryParameters);

  return MaterialPageRoute(
    builder: matchingRoute.builder,
    settings: RouteSettings(name: path, arguments: mergedArgs),
  );
}

Map<String, dynamic>? _mergeArgs(Object? original, Map<String, String>? query) {
  final Map<String, dynamic> base = {};
  if (original is Map) {
    original.forEach((k, v) => base[k.toString()] = v);
  }
  if (query != null) {
    query.forEach((k, v) {
      base[k] = v;
    });
  }
  return base.isEmpty ? null : base;
}
