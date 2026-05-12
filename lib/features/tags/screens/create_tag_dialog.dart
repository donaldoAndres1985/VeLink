import 'package:drift/drift.dart' hide isNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

const _kColors = [
  '#6366F1',
  '#EF4444',
  '#22C55E',
  '#F59E0B',
  '#3B82F6',
  '#8B5CF6',
];

Color _hexToColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class CreateTagDialog extends ConsumerStatefulWidget {
  const CreateTagDialog({super.key});

  @override
  ConsumerState<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends ConsumerState<CreateTagDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = _kColors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(databaseProvider).insertTag(
          TagsCompanion.insert(
            name: name,
            color: Value(_selectedColor),
          ),
        );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva etiqueta',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _kColors
                .map((hex) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          shape: BoxShape.circle,
                          border: _selectedColor == hex
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
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
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
