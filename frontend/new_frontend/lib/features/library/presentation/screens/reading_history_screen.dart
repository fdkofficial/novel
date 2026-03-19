import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/library_providers.dart';

class ReadingHistoryScreen extends ConsumerWidget {
  const ReadingHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingProgressAsync = ref.watch(readingProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reading History')),
      body: readingProgressAsync.when(
        data: (progressList) => progressList.isEmpty
            ? const Center(child: Text('No recent reading history'))
            : ListView.builder(
                itemCount: progressList.length,
                itemBuilder: (context, index) {
                  final progress = progressList[index];
                  return ListTile(
                    title: Text(progress.novel.title),
                    subtitle: Text(
                        'Chapter: ${progress.lastChapterId} • ${progress.percentage.toInt()}% completed'),
                    onTap: () => context.go(
                        '/library/novel/${progress.novel.id}/reader/${progress.lastChapterId}'),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
