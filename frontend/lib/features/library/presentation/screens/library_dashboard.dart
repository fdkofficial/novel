import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/sync_service.dart';
import '../../data/models/novel_model.dart';
import '../../data/repositories/novel_repository.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';
import '../providers/library_providers.dart';

class LibraryDashboard extends ConsumerStatefulWidget {
  const LibraryDashboard({super.key});

  @override
  ConsumerState<LibraryDashboard> createState() => _LibraryDashboardState();
}

class _LibraryDashboardState extends ConsumerState<LibraryDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeView(),
    const _ExploreView(),
    const _CommunityView(),
    const _ProfileView(),
  ];

  void _refreshCurrentPage() {
    setState(() {});
    if (_currentIndex == 3) {
      // Profile tab
      ref.refresh(readingProgressProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncServiceProvider); // Initialize sync service
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          _refreshCurrentPage();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeView extends ConsumerStatefulWidget {
  const _HomeView();
  @override
  ConsumerState<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<_HomeView> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final readingProgressAsync = ref.watch(readingProgressProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search novels...', border: InputBorder.none),
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
            )
          : const Text('My Library', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search), 
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) ref.read(searchQueryProvider.notifier).state = '';
            }
          ),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchQuery.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Search Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ref.watch(novelsProvider).when(
                data: (novels) => novels.isEmpty 
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No novels found')))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: novels.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(novels[index].title),
                        onTap: () => context.go('/library/novel/${novels[index].id}'),
                      ),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ] else ...[
              ref.watch(activeSurveysProvider).when(
                data: (surveys) {
                  if (surveys.isEmpty) return const SizedBox.shrink();
                  final survey = surveys.first;
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment_ind, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Quick Survey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(survey.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue[700]),
                          onPressed: () => context.go('/library/survey/${survey.id}'),
                          child: const Text('Take Survey'),
                        )
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Continue Reading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 180,
                child: readingProgressAsync.when(
                  data: (progressList) => progressList.isEmpty
                    ? const Center(child: Text('No recent reading history'))
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: progressList.length,
                      itemBuilder: (context, index) {
                        final progress = progressList[index];
                        return GestureDetector(
                          onTap: () => context.go('/library/novel/${progress.novel.id}/reader/${progress.lastChapterId}'),
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              image: progress.novel.coverImage != null
                                ? DecorationImage(
                                    image: NetworkImage(progress.novel.coverImage!),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                                  )
                                : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    progress.novel.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress.percentage / 100,
                                    backgroundColor: Colors.white24,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${progress.percentage.toInt()}% completed',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Recommended For You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              
              recommendationsAsync.when(
                data: (novels) => Column(
                  children: novels.take(5).map((novel) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[400],
                        image: novel.coverImage != null 
                          ? DecorationImage(image: NetworkImage(novel.coverImage!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: novel.coverImage == null ? const Icon(Icons.image) : null,
                    ),
                    title: Text(novel.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${novel.genre ?? "Drama"} • ${novel.rating} ★', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/library/novel/${novel.id}'),
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text('Trending Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: ref.watch(trendingNovelsProvider).when(
                  data: (novels) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: novels.length,
                    itemBuilder: (context, index) => _buildVerticalCard(context, novels[index]),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
              const SizedBox(height: 32),
            ]
          ],
        ),
      ),
    );
  }
}

Widget _buildVerticalCard(BuildContext context, Novel novel) {
  return GestureDetector(
    onTap: () => context.go('/library/novel/${novel.id}'),
    child: Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
                image: novel.coverImage != null 
                  ? DecorationImage(image: NetworkImage(novel.coverImage!), fit: BoxFit.cover)
                  : null,
              ),
              child: novel.coverImage == null ? const Center(child: Icon(Icons.book)) : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            novel.title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            novel.author, 
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class _ExploreView extends ConsumerWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    final allNovelsAsync = ref.watch(novelsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for novels, authors...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Genres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 50,
              child: genresAsync.when(
                data: (genres) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: genres.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final genre = isAll ? null : genres[index - 1];
                    final currentGenre = ref.watch(selectedGenreProvider);
                    final isSelected = isAll ? (currentGenre == null) : (currentGenre == genre?.id.toString());

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(isAll ? 'All' : genre!.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(selectedGenreProvider.notifier).state = isAll ? null : genre!.id.toString();
                        },
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('Trending Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 220,
              child: ref.watch(trendingNovelsProvider).when(
                data: (novels) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: novels.length,
                  itemBuilder: (context, index) {
                    final novel = novels[index];
                    return _buildVerticalCard(context, novel);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('Most Popular', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 220,
              child: ref.watch(popularNovelsProvider).when(
                data: (novels) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: novels.length,
                  itemBuilder: (context, index) {
                    final novel = novels[index];
                    return _buildVerticalCard(context, novel);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('New Releases', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            allNovelsAsync.when(
              data: (novels) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6, // Increased vertical room
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: novels.length,
                itemBuilder: (context, index) {
                  final novel = novels[index];
                  return GestureDetector(
                    onTap: () => context.go('/library/novel/${novel.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 0.7, // Fixed aspect ratio for the image part
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[300],
                              image: novel.coverImage != null 
                                ? DecorationImage(image: NetworkImage(novel.coverImage!), fit: BoxFit.cover)
                                : null,
                            ),
                            child: novel.coverImage == null ? const Center(child: Icon(Icons.book, size: 40)) : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            novel.title, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            novel.author, 
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityView extends ConsumerWidget {
  const _CommunityView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(communityReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold))),
      body: reviewsAsync.when(
        data: (reviews) => reviews.isEmpty
          ? const Center(child: Text('No reviews yet. Be the first!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => context.go('/library/novel/${review.novelId}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.primaries[index % Colors.primaries.length],
                                child: Text(review.userName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', 
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  Icons.star, 
                                  color: i < review.rating ? Colors.amber : Colors.grey[300], 
                                  size: 16
                                )),
                              ),
                              Text(' ${review.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            review.review,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Reviewed: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(review.novelTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'Guest User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'Not logged in',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Reading History'),
              onTap: () {
                // Navigate to reading history screen
                context.go('/library/reading-history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('My Bookmarks'),
              onTap: () {
                // Navigate to bookmarks screen
                context.go('/library/bookmarks');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

