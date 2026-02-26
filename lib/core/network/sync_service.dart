import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage/hive_storage.dart';
import '../../features/reader/data/repositories/reader_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final readerRepo = ref.watch(readerRepositoryProvider);
  return SyncService(readerRepo);
});

class SyncService {
  final ReaderRepository _readerRepo;

  SyncService(this._readerRepo) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncQueue();
      }
    });
  }

  Future<void> _syncQueue() async {
    final queue = HiveStorage.getSyncQueue();
    if (queue.isEmpty) return;

    print('Starting sync for ${queue.length} items...');
    
    // We can use the batch sync endpoint if our backend supports it, 
    // or just iterate for now.
    // For now, let's process progress updates.
    
    for (var item in queue) {
      if (item['type'] == 'progress') {
        final d = item['data'];
        await _readerRepo.updateProgress(
          d['novel_id'], 
          d['chapter_id'], 
          (d['percentage_completed'] as num) / 100,
          minutes: d['session_minutes'] ?? 0,
          pages: d['session_pages'] ?? 0
        );
      }
    }
    
    await HiveStorage.clearSyncQueue();
    print('Sync complete.');
  }

  Future<void> manualSync() async => await _syncQueue();
}
