import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/capture/providers/capture_provider.dart';
import '../../../features/capture/services/platform_detector.dart';
import '../../../features/notifications/providers/notification_provider.dart';
import '../providers/detail_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Link link;

  const DetailScreen({super.key, required this.link});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final FocusNode _titleFocusNode;
  bool _urlWasOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController =
        TextEditingController(text: widget.link.title ?? '');
    _notesController =
        TextEditingController(text: widget.link.notes ?? '');
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) _saveTitle();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleFocusNode.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _urlWasOpened && mounted) {
      _urlWasOpened = false;
      Navigator.of(context).pop();
    }
  }

  void _saveTitle() {
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();
    ref.read(databaseProvider).updateLinkTitle(widget.link.id, title);
  }

  void _saveNotes() {
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    ref.read(databaseProvider).updateLinkNotes(widget.link.id, notes);
  }

  void _copyUrl(String copiedMsg) {
    Clipboard.setData(ClipboardData(text: widget.link.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copiedMsg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.link.remindAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.link.remindAt ?? now),
    );
    if (time == null || !mounted) return;
    final scheduledAt = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    final title = widget.link.title ?? widget.link.url;
    await ref
        .read(linkReminderUseCaseProvider)
        .schedule(linkId: widget.link.id, title: title, scheduledAt: scheduledAt);
  }

  Future<void> _clearReminder() async {
    await ref.read(linkReminderUseCaseProvider).cancel(linkId: widget.link.id);
  }

  String _formatRemindAt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  String _formatCreatedAt(DateTime dt, List<String> months) {
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(watchLinkTagsProvider(widget.link.id));
    final allTagsAsync = ref.watch(allTagsProvider);
    final platformInfo =
        PlatformInfo.forPlatform(PlatformDetector.detect(widget.link.url));
    final s = ref.watch(appStringsProvider);
    final hasImage = widget.link.previewImageUrl != null;

    final vc = VeLinkSemanticColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.detailTitle),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: vc.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: vc.textSecondary,
                ),
              ),
              tooltip: s.linkMenuTooltip,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(context, platformInfo, s, hasImage),
              const SizedBox(height: 20),
              _buildTagsSection(context, tagsAsync, allTagsAsync, s),
              const SizedBox(height: 20),
              _buildNotesSection(context, s),
              const SizedBox(height: 20),
              _buildReminderSection(context, s),
              const SizedBox(height: 20),
              _buildInfoSection(platformInfo, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    PlatformInfo platformInfo,
    dynamic s,
    bool hasImage,
  ) {
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: vc.shadow08,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                widget.link.previewImageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: platformInfo.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            platformInfo.icon,
                            size: 11,
                            color: platformInfo.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            platformInfo.label,
                            style: TextStyle(
                              color: platformInfo.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.link.isFavorite) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: vc.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('title_field'),
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: vc.textPrimary,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: s.noTitle,
                    filled: false,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveTitle(),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.link.url,
                  style: const TextStyle(
                    color: VerLinkColors.greenSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.link.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.link.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: vc.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(s.openLink),
                        onPressed: () async {
                          _urlWasOpened = true;
                          try {
                            await launchUrl(
                              Uri.parse(widget.link.url),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(s.copyUrl),
                      onPressed: () => _copyUrl(s.urlCopied),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    AsyncValue<List<Tag>> tagsAsync,
    AsyncValue<List<Tag>> allTagsAsync,
    dynamic s,
  ) {
    final vc = VeLinkSemanticColors.of(context);
    return _SectionCard(
      title: s.tagsSection,
      icon: Icons.label_outline_rounded,
      child: allTagsAsync.when(
        data: (allTags) => allTags.isEmpty
            ? Text(
                s.noTagsAssigned,
                style: TextStyle(
                  fontSize: 13,
                  color: vc.textTertiary,
                ),
              )
            : tagsAsync.when(
                data: (linkTags) {
                  final linkTagIds = linkTags.map((t) => t.id).toSet();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags
                        .map((tag) => FilterChip(
                              label: Text(tag.name),
                              selected: linkTagIds.contains(tag.id),
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                      .read(databaseProvider)
                                      .addTagToLink(widget.link.id, tag.id);
                                } else {
                                  ref
                                      .read(databaseProvider)
                                      .removeTagFromLink(
                                          widget.link.id, tag.id);
                                }
                              },
                            ))
                        .toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, dynamic s) {
    final vc = VeLinkSemanticColors.of(context);
    return _SectionCard(
      title: s.notesSection,
      icon: Icons.notes_rounded,
      child: Column(
        children: [
          TextField(
            key: const Key('notes_field'),
            controller: _notesController,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: vc.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: vc.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: VerLinkColors.green, width: 1.5),
              ),
              hintText: s.notesHint,
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: vc.surfaceContainer,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveNotes,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
              ),
              child: Text(s.save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(BuildContext context, dynamic s) {
    final vc = VeLinkSemanticColors.of(context);
    return _SectionCard(
      title: s.reminderSection,
      icon: Icons.alarm_rounded,
      child: Container(
        decoration: BoxDecoration(
          color: vc.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.link.remindAt != null
            ? _buildReminderActive(context, s)
            : _buildReminderEmpty(context, s),
      ),
    );
  }

  Widget _buildReminderActive(BuildContext context, dynamic s) {
    final vc = VeLinkSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.alarm_rounded,
            size: 18,
            color: VerLinkColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatRemindAt(widget.link.remindAt!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: vc.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearReminder,
            style: TextButton.styleFrom(
              foregroundColor: VerLinkColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              s.deleteReminderLabel,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderEmpty(BuildContext context, dynamic s) {
    final vc = VeLinkSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.alarm_outlined,
            size: 18,
            color: vc.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.noReminder,
              style: TextStyle(
                fontSize: 14,
                color: vc.textTertiary,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add_alarm_rounded, size: 15),
            label: Text(
              s.addReminderLabel,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _pickReminder,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(PlatformInfo platformInfo, dynamic s) {
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vc.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            platformInfo.icon,
            size: 16,
            color: vc.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.savedOnDate(
                platformInfo.label,
                _formatCreatedAt(widget.link.createdAt, s.monthAbbrevs),
              ),
              style: TextStyle(
                fontSize: 13,
                color: vc.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final vc = VeLinkSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vc.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: vc.shadow06,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: VerLinkColors.green),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: vc.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
