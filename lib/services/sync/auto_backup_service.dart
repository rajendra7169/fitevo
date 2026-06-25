import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import '../../data/db.dart';
import '../../data/models/custom_food.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/workout_session.dart';
import 'sync_service.dart';

/// Background auto-backup service. Listens to lazy-watch streams on the
/// Isar collections that matter for cloud sync (profile, food, daily
/// logs, custom foods, workout sessions). On any change, debounces for
/// [_debounce] and then pushes everything to Firestore via the existing
/// [SyncService.pushAll].
///
/// Why pushAll and not per-collection diff?
/// - Simplicity. Last-write-wins is the existing model; partial pushes
///   would need a per-row dirty bit and is more code to maintain.
/// - The biggest user has maybe 1000 food entries — push payload stays
///   small enough that a 30-second debounced full push is fine.
///
/// Why debounce 30s instead of immediate?
/// - Avoid pushing on every keystroke (e.g. when logging a meal).
/// - 30s is short enough that "I edited at 12:00, app force-quit at
///   12:01" still loses at most one entry. Most users won't.
///
/// Anonymous users are skipped — Firestore identity is the uid, and
/// anonymous uids reset on reinstall. The share-sheet JSON export is
/// the backup path for anonymous users.
class AutoBackupService {
  AutoBackupService({
    required Db db,
    required SyncService sync,
    FirebaseAuth? auth,
    Duration debounce = const Duration(seconds: 30),
  })  : _db = db,
        _sync = sync,
        _auth = auth ?? FirebaseAuth.instance,
        _debounce = debounce;

  final Db _db;
  final SyncService _sync;
  final FirebaseAuth _auth;
  final Duration _debounce;

  Isar get _isar => _db.isar;

  final List<StreamSubscription<void>> _subs = [];
  Timer? _pendingPush;
  bool _pushing = false;
  DateTime? _lastPushAt;

  bool get isPushing => _pushing;
  DateTime? get lastPushAt => _lastPushAt;

  /// Start watching collections. Safe to call multiple times — calls
  /// after the first are no-ops.
  void start() {
    if (_subs.isNotEmpty) return;
    _subs.addAll([
      _isar.profiles.watchLazy().listen((_) => _schedulePush()),
      _isar.foodEntrys.watchLazy().listen((_) => _schedulePush()),
      _isar.dailyLogs.watchLazy().listen((_) => _schedulePush()),
      _isar.customFoods.watchLazy().listen((_) => _schedulePush()),
      _isar.workoutSessions.watchLazy().listen((_) => _schedulePush()),
    ]);
  }

  Future<void> stop() async {
    _pendingPush?.cancel();
    _pendingPush = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  bool _eligibleUser() {
    final u = _auth.currentUser;
    return u != null && !u.isAnonymous;
  }

  void _schedulePush() {
    if (!_eligibleUser()) return;
    _pendingPush?.cancel();
    _pendingPush = Timer(_debounce, _runPush);
  }

  Future<void> _runPush() async {
    if (_pushing) {
      // Re-schedule rather than dropping; another change may have
      // landed while we were already pushing.
      _schedulePush();
      return;
    }
    if (!_eligibleUser()) return;
    _pushing = true;
    try {
      await _sync.pushAll();
      _lastPushAt = DateTime.now();
    } catch (_) {
      // Silent: this runs in the background; toasting on a network
      // blip would be hostile. The user's last manual backup time
      // remains correct until the next successful push.
    } finally {
      _pushing = false;
    }
  }
}
