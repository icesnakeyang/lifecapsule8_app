import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:lifecapsule8_app/features/notes_base/data/notes_repository.dart';

import '../domain/note_base.dart';
import '../domain/note_kind.dart';

class HiveNotesRepository implements NotesRepository {
  final Box<String> box;
  HiveNotesRepository(this.box);

  Map<String, dynamic>? _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  NoteBase? _toNote(String raw) {
    final m = _decode(raw);
    if (m == null) return null;
    try {
      return NoteBase.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  List<NoteBase> _filterSort(
    Iterable<String> raws, {
    NoteKind? kind,
    bool includeDeleted = false,
  }) {
    final out = <NoteBase>[];
    for (final raw in raws) {
      final n = _toNote(raw);
      if (n == null) continue;
      if (!includeDeleted && n.isDeleted) continue;
      if (kind != null && n.kind != kind) continue;
      out.add(n);
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  @override
  Future<NoteBase?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return _toNote(raw);
  }

  @override
  Future<List<NoteBase>> list({
    NoteKind? kind,
    bool includeDeleted = false,
  }) async {
    return _filterSort(box.values, kind: kind, includeDeleted: includeDeleted);
  }

  /// ✅ UI 实时刷新：Hive box 变化 -> 重新 list
  @override
  Stream<List<NoteBase>> watchList({
    NoteKind? kind,
    bool includeDeleted = false,
  }) async* {
    // 先吐一次当前快照（避免页面空等）
    yield await list(kind: kind, includeDeleted: includeDeleted);

    // 监听 box 变化：任意 key 更新/删除都触发
    await for (final _ in box.watch()) {
      yield await list(kind: kind, includeDeleted: includeDeleted);
    }
  }

  @override
  Future<void> upsert(NoteBase note) async {
    await box.put(note.id, jsonEncode(note.toJson()));
  }

  @override
  Future<void> markDeleted(String id) async {
    final n = await getById(id);
    if (n == null) return;
    await upsert(
      n.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
        version: n.version + 1,
      ),
    );
  }

  /// ✅ 移动模块：只改 kind（meta 保留）
  @override
  Future<void> changeKind({required String id, required NoteKind kind}) async {
    final n = await getById(id);
    if (n == null) return;

    // kind 没变就不写
    if (n.kind == kind) return;

    await upsert(
      n.copyWith(
        kind: kind,
        isSynced: false,
        updatedAt: DateTime.now(),
        version: n.version + 1,
      ),
    );
  }

  /// ✅ 同步成功回写（serverNoteId / isSynced / version / updatedAt）
  @override
  Future<void> markSynced({
    required String id,
    required String serverNoteId,
    required DateTime updatedAt,
    required int version,
  }) async {
    final n = await getById(id);
    if (n == null) return;

    await upsert(
      n.copyWith(
        serverNoteId: serverNoteId,
        isSynced: true,
        updatedAt: updatedAt,
        version: version,
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
