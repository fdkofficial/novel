import 'package:hive_flutter/hive_flutter.dart';
import '../../features/library/data/models/novel_model.dart';
import '../../features/reader/data/models/chapter_model.dart';

class HiveStorage {
  static const String novelBoxName = 'novels';
  static const String chapterBoxName = 'chapters';
  static const String syncQueueBoxName = 'sync_queue';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registering adapters would happen here if we used @HiveType
    // For now, let's use Map<String, dynamic> if we want to move fast,
    // or properly define adapters. Since Phase 10 says "polish", 
    // let's do it properly with adapters if possible OR simple maps for speed.
    // Given the complexity of Novel object, Maps are easier to manage without generating files
    // every time the model changes.
    
    await Hive.openBox(novelBoxName);
    await Hive.openBox(chapterBoxName);
    await Hive.openBox(syncQueueBoxName);
  }

  // Generic methods to save/get
  static Future<void> saveNovel(Map<String, dynamic> novelJson) async {
    final box = Hive.box(novelBoxName);
    await box.put(novelJson['id'], novelJson);
  }

  static List<dynamic> getAllNovels() {
    final box = Hive.box(novelBoxName);
    return box.values.toList();
  }

  static Future<void> saveChapter(String novelId, Map<String, dynamic> chapterJson) async {
    final box = Hive.box(chapterBoxName);
    final key = '${novelId}_${chapterJson['id']}';
    await box.put(key, chapterJson);
  }

  static Map<String, dynamic>? getChapter(String novelId, String chapterId) {
    final box = Hive.box(chapterBoxName);
    final key = '${novelId}_${chapterId}';
    final data = box.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> addToSyncQueue(Map<String, dynamic> update) async {
    final box = Hive.box(syncQueueBoxName);
    await box.add(update);
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    final box = Hive.box(syncQueueBoxName);
    return box.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }

  static Future<void> clearSyncQueue() async {
    final box = Hive.box(syncQueueBoxName);
    await box.clear();
  }
}
