import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../models/og_metadata.dart';
import '../providers/capture_provider.dart';
import '../services/platform_detector.dart';
import '../../collections/providers/collection_providers.dart';
import '../../premium/domain/premium_limits.dart';
import '../../premium/screens/paywall_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String url;

  const CaptureScreen({super.key, required this.url});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  bool _selectAllOnFocus = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onTitleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(captureProvider.notifier).fetchMetadata(widget.url);
    });
  }

  // Fires when the title field gains focus. If a metadata title was just
  // auto-filled, we set the full selection AFTER Flutter's own focus handler
  // has run (nested post-frame), preventing it from resetting the cursor.
  void _onTitleFocusChange() {
    if (_titleFocusNode.hasFocus && _selectAllOnFocus) {
      _selectAllOnFocus = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _titleFocusNode.hasFocus) {
          _titleController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _titleController.text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final platformInfo =
        PlatformInfo.forPlatform(PlatformDetector.detect(widget.url));
    final s = ref.watch(appStringsProvider);

    ref.listen<OgMetadata?>(
      captureProvider.select((s) => s.metadata),
      (prev, next) {
        if (next?.title != null && _titleController.text.isEmpty) {
          _titleController.text = next!.title!;
          _selectAllOnFocus = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _titleFocusNode.requestFocus();
          });
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.captureTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlatformBadge(platformInfo),
              const SizedBox(height: 14),
              TextField(
                key: const Key('title_field'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  labelText: s.titleLabel,
                  hintText: s.titleHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) =>
                    ref.read(captureProvider.notifier).setTitle(v),
              ),
              if (state.metadata?.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.metadata!.description!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              _buildImageSection(context, state, s),
              const SizedBox(height: 16),
              _buildLinkSection(context, s),
              const SizedBox(height: 20),
              _buildTagsSection(context, state, tagsAsync, s),
              const SizedBox(height: 16),
              _buildCollectionsSection(context, state, collectionsAsync, s),
              const SizedBox(height: 16),
              _buildFavoriteRow(context, state, s),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: s.cancel,
                      button: true,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: state.isSaving
                            ? null
                            : () {
                                ref.read(captureProvider.notifier).dismiss();
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                        child: Text(s.cancel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: s.save,
                      button: true,
                      child: FilledButton(
                        onPressed: state.isSaving
                            ? null
                            : () async {
                                final canCreate = await ref.read(canCreateLinkProvider.future);
                                if (!canCreate) {
                                  if (context.mounted) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                                  }
                                  return;
                                }
                                try {
                                  await ref
                                      .read(captureProvider.notifier)
                                      .saveLink(url: widget.url);
                                  if (context.mounted) {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  }
                                } on DuplicateUrlException {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(s.alreadySaved),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: state.isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(s.save),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sección imagen ────────────────────────────────────────────────────────

  Widget _buildImageSection(BuildContext context, CaptureState state, dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, s.imageSection),
        const SizedBox(height: 8),
        _buildImageCard(context, state, s),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, CaptureState state, dynamic s) {
    if (state.isPickingImage) {
      return _imageShell(
        context,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.pickImageError) {
      return _imageShell(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 28),
              const SizedBox(height: 6),
              Text(
                s.errorLoadImage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.read(captureProvider.notifier).clearPickedImage(),
                child: Text(s.retry, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    final localPath = state.pickedImagePath;
    final remoteUrl =
        state.ogImageDismissed ? null : state.metadata?.imageUrl;

    if (localPath != null || remoteUrl != null) {
      return _buildSelectedImageCard(context, state, localPath, remoteUrl, s);
    }

    return _buildEmptyImageCard(context, s);
  }

  Widget _buildEmptyImageCard(BuildContext context, dynamic s) {
    final scheme = Theme.of(context).colorScheme;
    return _imageShell(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 28, color: scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              s.addImageHint,
              style:
                  TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: s.gallery,
                  button: true,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 15),
                    label: Text(s.gallery),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(88, 48),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () =>
                        ref.read(captureProvider.notifier).pickFromGallery(),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: s.camera,
                  button: true,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 15),
                    label: Text(s.camera),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(88, 48),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () =>
                        ref.read(captureProvider.notifier).pickFromCamera(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageCard(BuildContext context, CaptureState state,
      String? localPath, String? remoteUrl, dynamic s) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: localPath != null
                ? Image.file(
                    File(localPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(context),
                  )
                : Image.network(
                    remoteUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(context),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: Text(s.changeImage),
              style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 13)),
              onPressed: () => _showChangePicker(context, s),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: Text(s.delete),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: () {
                if (localPath != null) {
                  ref.read(captureProvider.notifier).clearPickedImage();
                } else {
                  ref.read(captureProvider.notifier).dismissOgImage();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _imageShell(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _showChangePicker(BuildContext context, dynamic s) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.gallery),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(captureProvider.notifier).pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(s.camera),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(captureProvider.notifier).pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección Link ──────────────────────────────────────────────────────────

  Widget _buildLinkSection(BuildContext context, dynamic s) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, s.linkSectionLabel),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.link, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.url,
                  style: TextStyle(color: scheme.primary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  Widget _buildTagsSection(
    BuildContext context,
    CaptureState state,
    AsyncValue tagsAsync,
    dynamic s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tagsSection,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        tagsAsync.when(
          data: (tags) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tags.map((tag) {
                final sel = state.selectedTagIds.contains(tag.id);
                return _SelectableChip(
                  label: tag.name,
                  selected: sel,
                  onTap: () =>
                      ref.read(captureProvider.notifier).toggleTag(tag.id),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(s.newTagLabel),
                onPressed: () => _showCreateTagDialog(context, s),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Collections ──────────────────────────────────────────────────────────

  Widget _buildCollectionsSection(
    BuildContext context,
    CaptureState state,
    AsyncValue<List<Collection>> collectionsAsync,
    dynamic s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.collectionInSection,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        collectionsAsync.when(
          data: (collections) => collections.isEmpty
              ? Text(
                  s.noCollectionsYet,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: collections
                      .map((col) {
                        final sel =
                            state.selectedCollectionIds.contains(col.id);
                        return _SelectableChip(
                          label: col.name,
                          selected: sel,
                          onTap: () => ref
                              .read(captureProvider.notifier)
                              .toggleCollection(col.id),
                        );
                      })
                      .toList(),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Favorito ──────────────────────────────────────────────────────────────

  Widget _buildFavoriteRow(BuildContext context, CaptureState state, dynamic s) {
    return Row(
      children: [
        Icon(
          Icons.star_outline,
          size: 20,
          color: state.isFavorite
              ? Colors.amber
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.markFavorite,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Switch(
          value: state.isFavorite,
          onChanged: (_) =>
              ref.read(captureProvider.notifier).toggleFavorite(),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlatformBadge(PlatformInfo info) {
    return Row(
      children: [
        Icon(info.icon, size: 16, color: info.color),
        const SizedBox(width: 6),
        Text(
          info.label,
          style: TextStyle(
            color: info.color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showCreateTagDialog(BuildContext context, dynamic s) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.createTagTitle),
        content: TextField(
          key: const Key('tag_name_field'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: s.tagNameHint),
          onSubmitted: (value) => _submitNewTag(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => _submitNewTag(context, controller.text),
            child: Text(s.create),
          ),
        ],
      ),
    );
  }

  void _submitNewTag(BuildContext context, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    ref.read(captureProvider.notifier).createTag(trimmed);
    Navigator.pop(context);
  }
}

// ── Selectable chip — tags and collections ───────────────────────────────────

class _SelectableChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // Selected palette — soft green that works on both light and dark surfaces
  static const _kSelBg     = Color(0xFFA8D37B);
  static const _kSelText   = Color(0xFF1A2D0C);
  static const _kSelBorder = Color(0xFF8ABF5A);
  static const _kSelGlow   = Color(0xFF8FBF6A);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sel = widget.selected;

    final bg = sel
        ? _kSelBg
        : isDark ? const Color(0xFF1B1B22) : Colors.white;
    final textColor = sel
        ? _kSelText
        : isDark ? const Color(0xFF9292AE) : const Color(0xFF5E5E66);
    final borderColor = sel
        ? _kSelBorder
        : isDark ? const Color(0xFF2B2B3E) : const Color(0xFFE8E4DC);

    return Semantics(
      label: widget.label,
      selected: sel,
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (ctx, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: sel ? 1.5 : 1.0,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _kSelGlow.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: sel
                      ? const Padding(
                          key: ValueKey('check'),
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: _kSelText,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: textColor,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
