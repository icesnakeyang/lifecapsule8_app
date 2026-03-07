import 'package:lifecapsule8_app/core/crypto/note_cipher.dart';
import 'package:lifecapsule8_app/core/network/api.dart';
import 'package:lifecapsule8_app/features/notes_base/domain/note_kind.dart';
import '../domain/note_base.dart';

/// 云端上传成功后的回写信息
class CloudUploadResult {
  final String serverNoteId;
  final DateTime updatedAt;
  final int version;

  const CloudUploadResult({
    required this.serverNoteId,
    required this.updatedAt,
    required this.version,
  });
}

class CloudNotesService {
  String _toServerEntityType(NoteKind kind) {
    switch (kind) {
      case NoteKind.privateNote:
        return 'PRIVATE_NOTE';
      case NoteKind.loveLetter:
        return 'LOVE_LETTER';
      case NoteKind.futureLetter:
        return 'FUTURE_LETTER';
      case NoteKind.inspiration:
        return 'INSPIRATION';
      case NoteKind.lastWishes:
        return 'LAST_WISHES';

      default:
        return 'PRIVATE_NOTE';
    }
  }

  Future<CloudUploadResult> upload(NoteBase note) async {
    // ✅ 没有 enc 直接视为不可上传（否则你会永远“看不到 upload”）
    final enc = note.enc;
    if (enc == null || enc.isEmpty) {
      throw StateError('note.enc is empty, cannot upload');
    }

    String isoUtc(DateTime dt) => dt.toUtc().toIso8601String();
    final cipher = NoteCipherResult.unpackCompact(enc);
    final int? serverIdInt = int.tryParse(note.serverNoteId ?? '');

    final payload = <String, dynamic>{
      if (serverIdInt != null) 'noteId': serverIdInt,

      'clientNoteId': note.id,
      'entityType': _toServerEntityType(note.kind),

      'cipherText': cipher.ctB64,
      'ivB64': cipher.ivB64,
      'tagB64': cipher.tagB64,
      'encAlg': 'AES_GCM',

      'createdAt': isoUtc(note.createdAt),
      'updatedAt': isoUtc(note.updatedAt),
      'deleted': note.isDeleted,
    };

    final result = await Api.apiSaveNote(payload);

    final code = int.tryParse('${result['code']}') ?? -1;
    if (code != 0) {
      throw StateError('apiSaveNote failed: code=$code msg=${result['msg']}');
    }

    final data = (result['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final serverNoteId = '${data['noteId'] ?? ''}'; // 后端一般会回 Long
    if (serverNoteId.isEmpty) {
      throw StateError('upload ok but server noteId empty');
    }
    final version = int.tryParse('${data['version'] ?? 1}') ?? 1;
    final updatedAt =
        DateTime.tryParse('${data['updatedAt'] ?? ''}')?.toUtc() ??
        note.updatedAt.toUtc();

    return CloudUploadResult(
      serverNoteId: serverNoteId,
      updatedAt: updatedAt,
      version: version,
    );
  }
}
