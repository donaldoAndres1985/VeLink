import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/capture_provider.dart';

class CaptureScreen extends ConsumerWidget {
  final String url;

  const CaptureScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(captureProvider).isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardar link')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Link capturado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            ref.read(captureProvider.notifier).dismiss();
                            Navigator.pop(context);
                          },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            ref.read(captureProvider.notifier).setUrl(url);
                            await ref.read(captureProvider.notifier).saveLink();
                            if (context.mounted) Navigator.pop(context);
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
