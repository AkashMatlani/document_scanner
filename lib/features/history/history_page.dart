import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan history')),
      body: asyncDocs.when(
        data: (docs) => docs.isEmpty
            ? const Center(child: Text('No scans yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index];
                  return Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: File(d.imagePath).existsSync()
                            ? Image.file(File(d.imagePath), fit: BoxFit.cover)
                            : const Icon(Icons.description),
                      ),
                      title: Text(
                        d.text.isEmpty
                            ? 'No text recognized'
                            : d.text
                                  .replaceAll('\n', ' ')
                                  .substring(
                                    0,
                                    d.text.length > 70 ? 70 : d.text.length,
                                  ),
                      ),
                      subtitle: Text(
                        '${d.entities.length} entities • ${d.createdAt}',
                      ),
                      trailing: IconButton(
                        onPressed: () => _confirmDelete(context, ref, d.id),
                        icon: Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
        error: (e, _) => Center(child: Text('$e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text('Are you sure you want to delete this scan?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(documentsProvider.notifier).remove(id);
    }
  }
}
