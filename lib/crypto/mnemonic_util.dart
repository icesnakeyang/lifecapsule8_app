// lib/core/crypto/mnemonic_util.dart
import 'dart:math';

class MnemonicUtil {
  // 可以自己换一批你喜欢的简单英文词，数量建议 >= 256 个
  static const List<String> _wordList = [
    'apple', 'river', 'summer', 'winter', 'mountain', 'forest', 'ocean',
    'planet', 'silver', 'gold', 'coffee', 'orange', 'yellow', 'green',
    'shadow', 'mirror', 'future', 'memory', 'silent', 'storm', 'cloud',
    'stone', 'garden', 'dream', 'friend', 'family', 'energy', 'light',
    'secret', 'simple', 'lucky', 'happy', 'focus', 'honest', 'freedom',
    'smile', 'travel', 'wisdom', 'wonder', 'bridge', 'island', 'sunrise',
    'sunset', 'galaxy', 'sky', 'music', 'story', 'paper', 'pencil',
    'door', 'window', 'flower', 'tree', 'road', 'circle',
    'square', 'star', 'rain', 'snow',
    'lake', 'sea', 'beach', 'wave', 'wind', 'fire', 'earth', 'leaf',
    'grass', 'field', 'hill', 'valley', 'desert', 'harbor', 'cliff',
    'moon', 'sun', 'comet', 'orbit',
    'book', 'clock', 'chair', 'table', 'phone', 'camera', 'wallet', 'key',
    'glass', 'bottle', 'box', 'bag', 'letter', 'note', 'stamp',
    'coin', 'ticket', 'map',
    'hope', 'trust', 'faith', 'calm', 'peace', 'balance', 'honor', 'truth',
    'kind', 'brave', 'gentle', 'patient', 'warm', 'clear',
    'past', 'moment', 'promise',
    'walk', 'rest', 'wait', 'listen', 'learn', 'build', 'create', 'protect',
    'remember', 'forget', 'return', 'arrive', 'begin', 'finish', 'follow',
    'morning', 'evening', 'night', 'today', 'tomorrow', 'yesterday',
    'early', 'late', 'north', 'south', 'east', 'west', 'center',

    // ... 后面你可以再扩充一大段
  ];

  static final Random _random = Random.secure();

  /// 生成助记词，例如 12 个单词
  static List<String> generate({int wordCount = 12}) {
    if (wordCount > _wordList.length) {
      throw ArgumentError('wordCount exceeds word list size');
    }
    final list = List<String>.from(_wordList);
    list.shuffle(_random);
    return list.take(wordCount).toList();
  }

  /// 如果你需要字符串形式，可以用这个
  static String generateString({int wordCount = 12}) {
    return generate(wordCount: wordCount).join(' ');
  }
}
