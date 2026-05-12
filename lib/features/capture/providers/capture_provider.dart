import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../models/og_metadata.dart';
import '../services/capture_service.dart';
import '../services/image_picker_service.dart';
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
  final Set<int> selectedCollectionIds;
  final bool isFavorite;
  final String? manualTitle;
  final String? pickedImagePath;
  final bool isPickingImage;
  final bool pickImageError;
  final bool ogImageDismissed;

  CaptureState({
    this.pendingUrl,
    this.isSaving = false,
    this.isFetchingMetadata = false,
    this.metadata,
    Set<int>? selectedTagIds,
    Set<int>? selectedCollectionIds,
    this.isFavorite = false,
    this.manualTitle,
    this.pickedImagePath,
    this.isPickingImage = false,
    this.pickImageError = false,
    this.ogImageDismissed = false,
  })  : selectedTagIds = selectedTagIds ?? {},
        selectedCollectionIds = selectedCollectionIds ?? {};

  CaptureState copyWith({
    String? pendingUrl,
    bool? isSaving,
    bool? isFetchingMetadata,
    OgMetadata? metadata,
    Set<int>? selectedTagIds,
    Set<int>? selectedCollectionIds,
    bool? isFavorite,
    String? manualTitle,
    String? pickedImagePath,
    bool? isPickingImage,
    bool? pickImageError,
    bool? ogImageDismissed,
    bool clearUrl = false,
    bool clearMetadata = false,
    bool clearManualTitle = false,
    bool clearPickedImagePath = false,
  }) =>
      CaptureState(
        pendingUrl: clearUrl ? null : (pendingUrl ?? this.pendingUrl),
        isSaving: isSaving ?? this.isSaving,
        isFetchingMetadata: isFetchingMetadata ?? this.isFetchingMetadata,
        metadata: clearMetadata ? null : (metadata ?? this.metadata),
        selectedTagIds: selectedTagIds ?? Set.from(this.selectedTagIds),
        selectedCollectionIds: selectedCollectionIds ?? Set.from(this.selectedCollectionIds),
        isFavorite: isFavorite ?? this.isFavorite,
        manualTitle: clearManualTitle ? null : (manualTitle ?? this.manualTitle),
        pickedImagePath:
            clearPickedImagePath ? null : (pickedImagePath ?? this.pickedImagePath),
        isPickingImage: isPickingImage ?? this.isPickingImage,
        pickImageError: pickImageError ?? this.pickImageError,
        ogImageDismissed: ogImageDismissed ?? this.ogImageDismissed,
      );
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final AppDatabase _db;
  final CaptureService _service;
  final MetadataService _metadataService;
  final ImagePickerService _imagePicker;
  StreamSubscription<String?>? _sub;
  StreamSubscription<String?>? _titleSub;

  CaptureNotifier(
      this._db, this._service, this._metadataService, this._imagePicker)
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

  void toggleFavorite() =>
      state = state.copyWith(isFavorite: !state.isFavorite);

  void toggleCollection(int collectionId) {
    final updated = Set<int>.from(state.selectedCollectionIds);
    if (updated.contains(collectionId)) {
      updated.remove(collectionId);
    } else {
      updated.add(collectionId);
    }
    state = state.copyWith(selectedCollectionIds: updated);
  }

  Future<int> createCollection(String name, {String color = '#6366F1', String icon = 'folder'}) async {
    return await _db.insertCollection(CollectionsCompanion(
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
    ));
  }

  Future<void> createTag(String name) async {
    await _db.insertTag(TagsCompanion(name: Value(name)));
  }

  Future<void> pickFromGallery() async {
    state = state.copyWith(isPickingImage: true, pickImageError: false);
    try {
      final path = await _imagePicker.pickFromGallery();
      if (!mounted) return;
      if (path != null) {
        state = state.copyWith(pickedImagePath: path, isPickingImage: false);
      } else {
        state = state.copyWith(isPickingImage: false);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isPickingImage: false, pickImageError: true);
    }
  }

  Future<void> pickFromCamera() async {
    state = state.copyWith(isPickingImage: true, pickImageError: false);
    try {
      final path = await _imagePicker.pickFromCamera();
      if (!mounted) return;
      if (path != null) {
        state = state.copyWith(pickedImagePath: path, isPickingImage: false);
      } else {
        state = state.copyWith(isPickingImage: false);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isPickingImage: false, pickImageError: true);
    }
  }

  void clearPickedImage() => state = state.copyWith(clearPickedImagePath: true);

  void dismissOgImage() => state = state.copyWith(ogImageDismissed: true);

  Future<void> saveLink({String? url}) async {
    final resolvedUrl = url ?? state.pendingUrl;
    if (resolvedUrl == null) return;
    final existing = await _db.getLinkByUrl(resolvedUrl);
    if (existing != null) throw const DuplicateUrlException();
    state = state.copyWith(isSaving: true);
    final platform = PlatformDetector.detect(resolvedUrl);
    final effectiveTitle = state.manualTitle ?? state.metadata?.title;
    final effectiveImageUrl =
        state.ogImageDismissed ? null : state.metadata?.imageUrl;
    final linkId = await _db.insertLink(LinksCompanion(
      url: Value(resolvedUrl),
      title: Value(effectiveTitle),
      description: Value(state.metadata?.description),
      previewImageUrl: Value(effectiveImageUrl),
      previewImagePath: Value(state.pickedImagePath),
      platform: Value(platform.name),
      isFavorite: Value(state.isFavorite),
    ));
    for (final tagId in state.selectedTagIds) {
      await _db.addTagToLink(linkId, tagId);
    }
    for (final collectionId in state.selectedCollectionIds) {
      await _db.addLinkToCollection(linkId, collectionId);
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

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerServiceImpl();
});

final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(databaseProvider).watchAllTags();
});

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  final db = ref.watch(databaseProvider);
  final service = ref.watch(captureServiceProvider);
  final metadataService = ref.watch(metadataServiceProvider);
  final imagePicker = ref.watch(imagePickerServiceProvider);
  return CaptureNotifier(db, service, metadataService, imagePicker);
});
