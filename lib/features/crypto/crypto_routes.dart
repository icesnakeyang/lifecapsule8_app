import 'package:lifecapsule8_app/app/router/app_route.dart';
import 'package:lifecapsule8_app/features/crypto/crypto_route_paths.dart';

import 'package:lifecapsule8_app/features/crypto/presentation/crypto_setting_page.dart';
import 'package:lifecapsule8_app/features/crypto/presentation/mnemonic_verify_page.dart';
import 'package:lifecapsule8_app/features/crypto/presentation/setup_mnemonic_page.dart';
import 'package:lifecapsule8_app/features/crypto/presentation/restore_master_key_page.dart';
import 'package:lifecapsule8_app/features/crypto/presentation/mnemonic_restore_page.dart';

final List<AppRoute> cryptoRoutes = [
  AppRoute(
    name: CryptoRoutePaths.manage,
    builder: (_) => const CryptoSettingPage(),
  ),
  AppRoute(
    name: CryptoRoutePaths.setupMnemonic,
    builder: (_) => const SetupMnemonicPage(),
  ),
  AppRoute(
    name: CryptoRoutePaths.restoreMasterKey,
    builder: (_) => const RestoreMasterKeyPage(),
  ),
  AppRoute(
    name: CryptoRoutePaths.mnemonicRestore,
    builder: (_) => const MnemonicRestorePage(),
  ),
  AppRoute(name: CryptoRoutePaths.verifyMnemonic, builder: (_)=>const MnemonicVerifyPage())
];
