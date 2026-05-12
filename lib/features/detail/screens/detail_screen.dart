import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
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
    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
    final theme = Theme.of(context);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.detailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: s.linkMenuTooltip,
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLinkCard(context, platformInfo, theme, s),
              const SizedBox(height: 20),
              _buildTagsSection(context, tagsAsync, allTagsAsync, theme, s),
              const SizedBox(height: 20),
              _buildNotesSection(context, theme, s),
              const SizedBox(height: 20),
              _buildReminderSection(context, theme, s),
              const SizedBox(height: 20),
              _buildInfoSection(platformInfo, theme, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    PlatformInfo platformInfo,
    ThemeData theme,
    dynamic s,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.link.previewImageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                widget.link.previewImageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(platformInfo.icon, size: 13, color: platformInfo.color),
                    const SizedBox(width: 4),
                    Text(
                      platformInfo.label,
                      style: TextStyle(
                        color: platformInfo.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('title_field'),
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: s.noTitle,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveTitle(),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.link.url,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.link.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.link.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 15),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 15),
                      label: Text(s.copyUrl),
                      onPressed: () => _copyUrl(s.urlCopied),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    ThemeData theme,
    dynamic s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.tagsSection,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        allTagsAsync.when(
          data: (allTags) => allTags.isEmpty
              ? Text(
                  s.noTagsAssigned,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : tagsAsync.when(
                  data: (linkTags) {
                    final linkTagIds = linkTags.map((t) => t.id).toSet();
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allTags
                          .map((tag) => FilterChip(
                                label: Text(
                                  tag.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
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
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, ThemeData theme, dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.notesSection,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('notes_field'),
          controller: _notesController,
          maxLines: null,
          minLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            hintText: s.notesHint,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _saveNotes,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(s.save),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection(
      BuildContext context, ThemeData theme, dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.reminderSection,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: widget.link.remindAt != null
              ? _buildReminderActive(theme, s)
              : _buildReminderEmpty(theme, s),
        ),
      ],
    );
  }

  Widget _buildReminderActive(ThemeData theme, dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.alarm, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatRemindAt(widget.link.remindAt!),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _clearReminder,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildReminderEmpty(ThemeData theme, dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.alarm_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.noReminder,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 15),
            label: Text(
              s.addReminderLabel,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _pickReminder,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      PlatformInfo platformInfo, ThemeData theme, dynamic s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            platformInfo.icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.savedOnDate(
                platformInfo.label,
                _formatCreatedAt(widget.link.createdAt, s.monthAbbrevs),
              ),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
