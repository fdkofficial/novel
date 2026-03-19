import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_novel_provider.dart';
import '../../data/models/user_novel_model.dart';

class MyNovelsScreen extends ConsumerWidget {
  const MyNovelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelsAsync = ref.watch(userNovelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Novels'),
        elevation: 0,
      ),
      body: novelsAsync.when(
        data: (novels) {
          if (novels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No novels yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start creating your first novel!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(userNovelsProvider.notifier).loadNovels(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: novels.length,
              itemBuilder: (context, index) {
                final novel = novels[index];
                return _NovelCard(novel: novel);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(userNovelsProvider.notifier).loadNovels(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/library/my-novels/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Novel'),
      ),
    );
  }
}

class _NovelCard extends ConsumerWidget {
  final UserNovel novel;

  const _NovelCard({required this.novel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/library/my-novels/${novel.id}/chapters'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: novel.coverImage != null
                    ? Image.network(
                        novel.coverImage!,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                      )
                    : _placeholderCover(),
              ),
              const SizedBox(width: 12),
              // Novel Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(status: novel.status),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${novel.totalChapters} chapters',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.text_fields, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${(novel.wordCount / 1000).toStringAsFixed(1)}k words',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/library/my-novels/${novel.id}/edit'),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showPublishDialog(context, ref),
                            icon: Icon(
                              novel.status == 'published' ? Icons.unpublished : Icons.publish,
                              size: 16,
                            ),
                            label: Text(novel.status == 'published' ? 'Unpublish' : 'Publish'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 80,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 40, color: Colors.grey),
    );
  }

  void _showPublishDialog(BuildContext context, WidgetRef ref) {
    final isPublished = novel.status == 'published';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPublished ? 'Unpublish Novel?' : 'Publish Novel?'),
        content: Text(
          isPublished
              ? 'This will make your novel private and remove it from public listings.'
              : 'This will make your novel visible to all readers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(userNovelsProvider.notifier).publishNovel(
                    novel.id,
                    publish: !isPublished,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isPublished ? 'Novel unpublished' : 'Novel published successfully!')
                        : 'Failed to update novel status'),
                  ),
                );
              }
            },
            child: Text(isPublished ? 'Unpublish' : 'Publish'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'published':
        color = Colors.green;
        label = 'Published';
        break;
      case 'draft':
        color = Colors.orange;
        label = 'Draft';
        break;
      case 'archived':
        color = Colors.grey;
        label = 'Archived';
        break;
      default:
        color = Colors.blue;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
