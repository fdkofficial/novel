import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../library/data/repositories/novel_repository.dart';
import '../../../library/presentation/providers/library_providers.dart';

class NovelDetailScreen extends ConsumerWidget {
  final String novelId;

  const NovelDetailScreen({super.key, required this.novelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelAsync = ref.watch(novelDetailsProvider(novelId));

    return novelAsync.when(
      data: (novel) {
        if (novel == null) return const Scaffold(body: Center(child: Text('Novel not found')));
        
        return Scaffold(
          appBar: AppBar(
            title: Text(novel.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border), 
                onPressed: () async {
                  final success = await ref.read(novelRepositoryProvider).toggleFavorite(novelId);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Library updated'))
                    );
                    // Refresh novel details to update favorite count if needed
                    ref.invalidate(novelDetailsProvider(novelId));
                  }
                }
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: novel.coverImage != null 
                      ? DecorationImage(image: NetworkImage(novel.coverImage!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: novel.coverImage == null 
                    ? const Center(child: Icon(Icons.image, size: 100, color: Colors.grey))
                    : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        novel.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('${novel.author} • ${novel.isOngoing ? "Ongoing" : "Completed"} • ${novel.chaptersCount} Chapters'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Rating', '${novel.rating} ★'),
                          _buildStatColumn('Genre', novel.genre ?? 'None'),
                          _buildStatColumn('Status', novel.isOngoing ? 'Ongoing' : 'End'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/library/novel/${novel.id}/reader/1');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Start Reading Chapter 1', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(novel.description ?? 'No description available.'),
                      
                      const SizedBox(height: 24),
                      const Text('Chapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: novel.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = novel.chapters[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              radius: 15,
                              child: Text('${chapter.chapterNumber}', style: const TextStyle(fontSize: 12, color: Colors.black)),
                            ),
                            title: Text(chapter.title, style: const TextStyle(fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 16),
                            onTap: () {
                               context.push('/library/novel/${novel.id}/reader/${chapter.id}');
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }


  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

