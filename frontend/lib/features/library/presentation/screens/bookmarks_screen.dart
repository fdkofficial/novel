import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../reader/data/repositories/reader_repository.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerRepo = ref.watch(readerRepositoryProvider);
    // TODO: Replace with actual novelId or user context
    final novelId = '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookmarks')),
      body: FutureBuilder<List<dynamic>>(
        future: readerRepo.getBookmarks(novelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookmarks found.'));
          }
          final bookmarks = snapshot.data!;
          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bm = bookmarks[index];
              return ListTile(
                title: Text(bm['title'] ?? 'Bookmark'),
                subtitle: Text('Novel: ${bm['novel']}\nChapter: ${bm['chapter']}\nPosition: ${bm['position']}'),
                onTap: () {
                  // Navigate to reader screen for this bookmark
                  context.go('/library/novel/${bm['novel']}/reader/${bm['chapter']}');
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
