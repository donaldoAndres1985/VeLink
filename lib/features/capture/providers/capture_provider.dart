import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../models/og_metadata.dart';
import '../services/capture_service.dart';
import '../services/metadata_service.dart';
import '../services/platform_detector.dart';

class DuplicateUrlException implements Exception {
  const DuplicateUrlException();
}

class CaptureState {
  final String? pendingUrl;
  final bool isSaving;
  final bool isFetchingMetadata;
  final OgMetadata? metadata;
  final Set<int> selectedTagIds;
  final bool isFavorite;
  final String? manualTitle;

  CaptureState({
    this.pendingUrl,
    this.isSaving = false,
    this.isFetchingMetadata = false,
    this.metadata,
    Set<int>? selectedTagIds,
    this.isFavorite = false,
    this.manualTitle,
  }) : selectedTagIds = selectedTagIds ?? {};

  CaptureState copyWith({
    String? pendingUrl,
    bool? isSaving,
    bool? isFetchingMetadata,
    OgMetadata? metadata,
    Set<int>? selectedTagIds,
    bool? isFavorite,
    String? manualTitle,
    bool clearUrl = false,
    bool clearMetadata = false,
    bool clearManualTitle = false,
  }) =>
      CaptureState(
        pendingUrl: clearUrl ? null : (pendingUrl ?? this.pendingUrl),
        isSaving: isSaving ?? this.isSaving,
        isFetchingMetadata: isFetchingMetadata ?? this.isFetchingMetadata,
        metadata: clearMetadata ? null : (metadata ?? this.metadata),
        selectedTagIds: selectedTagIds ?? Set.from(this.selectedTagIds),
        isFavorite: isFavorite ?? this.isFavorite,
        manualTitle: clearManualTitle ? null : (manualTitle ?? this.manualTitle),
      );
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final AppDatabase _db;
  final CaptureService _service;
  final MetadataService _metadataService;
  StreamSubscription<String?>? _sub;
  StreamSubscription<String?>? _titleSub;

  CaptureNotifier(this._db, this._service, this._metadataService)
      : super(CaptureState()) {
    _init();
  }

  void _init() async {
    _sub = _service.urlStream.listen((url) {
      if (url != null && url.isNotEmpty) setUrl(url);
    });
    _titleSub = _service.titleStream.listen((title) {
      if (title != null && title.isNotEmpty) setTitle(title);
    });
    final initial = await _service.getInitialUrl();
    if (initial != null && initial.isNotEmpty) setUrl(initial);
    final initialTitle = await _service.getInitialTitle();
    if (initialTitle != null && initialTitle.isNotEmpty) setTitle(initialTitle);
  }

  void setUrl(String url) => state = state.copyWith(pendingUrl: url);

  void setTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(clearManualTitle: true);
    } else {
      state = state.copyWith(manualTitle: trimmed);
    }
  }

  Future<void> fetchMetadata(String url) async {
    state = state.copyWith(isFetchingMetadata: true);
    final metadata = await _metadataService.fetchMetadata(url);
    if (!mounted) return;
    state = state.copyWith(metadata: metadata, isFetchingMetadata: false);
  }

  void toggleTag(int tagId) {
    final updated = Set<int>.from(state.selectedTagIds);
    if (updated.contains(tagId)) {
      updated.remove(tagId);
    } else {
      updated.add(tagId);
    }
    state = state.copyWith(selectedTagIds: updated);
  }

  void toggleFavorite() => state = state.copyWith(isFavorite: !state.isFavorite);

  Future<void> createTag(String name) async {
    await _db.insertTag(TagsCompanion(name: Value(name)));
  }

  Future<void> saveLink() async {
    final url = state.pendingUrl;
    if (url == null) return;
    final existing = await _db.getLinkByUrl(url);
    if (existing != null) throw const DuplicateUrlException();
    state = state.copyWith(isSaving: true);
    final platform = PlatformDetector.detect(url);
    final effectiveTitle = state.manualTitle ?? state.metadata?.title;
    final linkId = await _db.insertLink(LinksCompanion(
      url: Value(url),
      title: Value(effectiveTitle),
      description: Value(state.metadata?.description),
      previewImageUrl: Value(state.metadata?.imageUrl),
      platform: Value(platform.name),
      isFavorite: Value(state.isFavorite),
    ));
    for (final tagId in state.selectedTagIds) {
      await _db.addTagToLink(linkId, tagId);
    }
    _service.reset();
    state = CaptureState();
  }

  void dismiss() {
    _service.reset();
    state = CaptureState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _titleSub?.cancel();
    super.dispose();
  }
}

final captureServiceProvider = Provider<CaptureService>((ref) {
  final service = ReceiveSharingIntentService();
  ref.onDispose(service.dispose);
  return service;
});

final metadataServiceProvider = Provider<MetadataService>((ref) {
  return DioMetadataService();
});

final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(databaseProvider).watchAllTags();
});

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  final db = ref.watch(databaseProvider);
  final service = ref.watch(captureServiceProvider);
  final metadataService = ref.watch(metadataServiceProvider);
  return CaptureNotifier(db, service, metadataService);
});
