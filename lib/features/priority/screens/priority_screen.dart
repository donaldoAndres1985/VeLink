import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PriorityScreen extends ConsumerWidget {
  const PriorityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prioritarios')),
      body: const Center(child: Text('Prioritarios — próximamente')),
    );
  }
}
