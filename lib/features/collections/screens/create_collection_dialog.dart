import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../premium/domain/premium_limits.dart';
import '../../premium/screens/paywall_screen.dart';

const _kColors = [
  '#6366F1',
  '#EF4444',
  '#22C55E',
  '#F59E0B',
  '#3B82F6',
  '#8B5CF6',
  '#EC4899',
  '#14B8A6',
];

const _kIcons = [
  'folder',
  'star',
  'code',
  'work',
  'book',
  'music',
  'video',
  'link',
  'heart',
];

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData _iconData(String icon) {
  switch (icon) {
    case 'star':
      return Icons.star_outline;
    case 'code':
      return Icons.code;
    case 'work':
      return Icons.work_outline;
    case 'book':
      return Icons.book_outlined;
    case 'music':
      return Icons.music_note_outlined;
    case 'video':
      return Icons.videocam_outlined;
    case 'link':
      return Icons.link;
    case 'heart':
      return Icons.favorite_outline;
    default:
      return Icons.folder_outlined;
  }
}

class CreateCollectionDialog extends ConsumerStatefulWidget {
  final Collection? existing;

  const CreateCollectionDialog({super.key, this.existing});

  @override
  ConsumerState<CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState
    extends ConsumerState<CreateCollectionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _selectedColor;
  late String _selectedIcon;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _descController =
        TextEditingController(text: widget.existing?.description ?? '');
    _selectedColor = widget.existing?.color ?? _kColors.first;
    _selectedIcon = widget.existing?.icon ?? _kIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError =
          ref.read(appStringsProvider).collectionNameRequired);
      return;
    }

    final db = ref.read(databaseProvider);
    final duplicate = await db.collectionNameExists(
      name,
      excludeId: widget.existing?.id,
    );
    if (duplicate) {
      if (!mounted) return;
      setState(() => _nameError =
          ref.read(appStringsProvider).collectionNameDuplicate);
      return;
    }

    if (widget.existing == null) {
      final canCreate = await ref.read(canCreateCollectionProvider.future);
      if (!canCreate) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
        }
        return;
      }
    }

    final desc = _descController.text.trim();
    if (widget.existing != null) {
      await db.updateCollection(
        widget.existing!.id,
        name,
        desc.isEmpty ? null : desc,
        _selectedColor,
        _selectedIcon,
      );
    } else {
      await db.insertCollection(CollectionsCompanion.insert(
        name: name,
        description: Value(desc.isEmpty ? null : desc),
        color: Value(_selectedColor),
        icon: Value(_selectedIcon),
      ));
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isEdit = widget.existing != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? s.editCollection : s.createCollection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.collectionNameLabel,
                  hintText: s.collectionNameHint,
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: s.collectionDescLabel,
                  hintText: s.collectionDescHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(s.collectionColorLabel,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kColors
                    .map((hex) => GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _hexToColor(hex),
                              shape: BoxShape.circle,
                              border: _selectedColor == hex
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(s.collectionIconLabel,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kIcons
                    .map((icon) => GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIcon = icon),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedIcon == icon
                                  ? _hexToColor(_selectedColor)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedIcon == icon
                                    ? Colors.transparent
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                              ),
                            ),
                            child: Icon(
                              _iconData(icon),
                              size: 22,
                              color: _selectedIcon == icon
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(s.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
