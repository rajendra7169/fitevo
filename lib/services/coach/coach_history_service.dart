import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_service.dart';

/// Persists coach chat sessions across app restarts. Each session is a
/// list of [CoachMessage]s with a started-at timestamp. Stored as JSON
/// in SharedPreferences — chat volume is small and we don't need
/// queries beyond "list newest first" + "load by id".
class CoachHistoryService {
  static const _key = 'coach.history.v1';

  /// Returns every session stored, newest first.
  static Future<List<CoachSession>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      final out = parsed
          .whereType<Map<String, dynamic>>()
          .map(CoachSession.fromJson)
          .toList();
      out.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Upserts a session — matched by [session.id]. Creates a new entry
  /// when no match. Caller decides when to upsert (e.g. after each AI
  /// reply lands so partial sessions are recoverable on crash).
  static Future<void> upsert(CoachSession session) async {
    final all = List<CoachSession>.from(await list());
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.add(session);
    }
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(all.map((s) => s.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> delete(String id) async {
    final all = List<CoachSession>.from(await list());
    all.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(all.map((s) => s.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class CoachSession {
  final String id;
  final DateTime startedAt;
  final List<CoachMessage> messages;
  final String? title; // optional — first 40 chars of the first user msg

  CoachSession({
    required this.id,
    required this.startedAt,
    required this.messages,
    this.title,
  });

  factory CoachSession.fresh() {
    final now = DateTime.now();
    return CoachSession(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      messages: const [],
    );
  }

  CoachSession copyWith({List<CoachMessage>? messages, String? title}) {
    return CoachSession(
      id: id,
      startedAt: startedAt,
      messages: messages ?? this.messages,
      title: title ?? this.title,
    );
  }

  /// Derived preview text — last bit of the user's first message so the
  /// list page can show "What should I eat tonight…" rather than just
  /// "Session 2026-04-12".
  String get previewText {
    if (title != null && title!.isNotEmpty) return title!;
    final firstUser = messages.firstWhere(
      (m) => m.fromUser,
      orElse: () => CoachMessage(
          fromUser: false, text: '(empty session)', timestamp: startedAt),
    );
    final t = firstUser.text.trim();
    return t.length > 60 ? '${t.substring(0, 60)}…' : t;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'title': title,
        'messages': messages
            .map((m) => {
                  'fromUser': m.fromUser,
                  'text': m.text,
                  'ts': m.timestamp.toIso8601String(),
                })
            .toList(),
      };

  static CoachSession fromJson(Map<String, dynamic> j) {
    final msgs = (j['messages'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) => CoachMessage(
              fromUser: m['fromUser'] == true,
              text: (m['text'] as String?) ?? '',
              timestamp: DateTime.tryParse(m['ts'] as String? ?? '') ??
                  DateTime.now(),
            ))
        .toList();
    return CoachSession(
      id: (j['id'] as String?) ?? '${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ??
          DateTime.now(),
      messages: msgs,
      title: j['title'] as String?,
    );
  }
}
