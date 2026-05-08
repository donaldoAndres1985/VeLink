import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../services/capture_service.dart';

class CaptureState {
  final String? pendingUrl;
  final bool isSaving;

  const CaptureState({this.pendingUrl, this.isSaving = false});

  CaptureState copyWith({
    String? pendingUrl,
    bool? isSaving,
    bool clearUrl = false,
  }) =>
      CaptureState(
        pendingUrl: clearUrl ? null : (pendingUrl ?? this.pendingUrl),
        isSaving: isSaving ?? this.isSaving,
      );
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final AppDatabase _db;
  final CaptureService _service;
  StreamSubscription<String?>? _sub;

  CaptureNotifier(this._db, this._service) : super(const CaptureState()) {
    _init();
  }

  void _init() async {
    _sub = _service.urlStream.listen((url) {
      if (url != null && url.isNotEmpty) setUrl(url);
    });
    final initial = await _service.getInitialUrl();
    if (initial != null && initial.isNotEmpty) setUrl(initial);
  }

  void setUrl(String url) => state = state.copyWith(pendingUrl: url);

  Future<void> saveLink() async {
    final url = state.pendingUrl;
    if (url == null) return;
    state = state.copyWith(isSaving: true);
    await _db.insertLink(LinksCompanion(url: Value(url)));
    _service.reset();
    state = const CaptureState();
  }

  void dismiss() {
    _service.reset();
    state = state.copyWith(clearUrl: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final captureServiceProvider = Provider<CaptureService>((ref) {
  final service = ReceiveSharingIntentService();
  ref.onDispose(service.dispose);
  return service;
});

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  final db = ref.watch(databaseProvider);
  final service = ref.watch(captureServiceProvider);
  return CaptureNotifier(db, service);
});
