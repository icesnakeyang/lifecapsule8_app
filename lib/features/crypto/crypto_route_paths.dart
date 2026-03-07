abstract class CryptoRoutePaths {
  static const manage = '/crypto/manage';

  // enable encryption: generate 12 words -> create masterKey
  static const setupMnemonic = '/crypto/setup-mnemonic';

  // unlock this device (hasMnemonic but no masterKey on this device)
  static const restoreMasterKey = '/crypto/restore-master-key';

  // global restore (always available, may replace existing key)
  static const mnemonicRestore = '/crypto/mnemonic-restore';

  static const verifyMnemonic = '/crypto/verify-mnemonic';
}
