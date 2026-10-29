import 'dart:convert';
import 'dart:io';

import 'package:news_core/news_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/article_record.dart';

class NewsDatabase {
  NewsDatabase(this._db);

  final Database _db;

  static const retentionDays = 21;
  static const maxArticles = 2500;

  static Future<NewsDatabase> open() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationSupportDirectory();
    return openAt(p.join(dir.path, 'inkbrief.db'));
  }

  static Future<NewsDatabase> openAt(String path) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE articles (
              id TEXT PRIMARY KEY,
              source_id TEXT NOT NULL,
              title TEXT NOT NULL,
              url TEXT NOT NULL,
              summary TEXT NOT NULL,
              pub_ms INTEGER,
              extra_json TEXT NOT NULL,
              saved INTEGER NOT NULL DEFAULT 0,
              read INTEGER NOT NULL DEFAULT 0,
              updated_ms INTEGER NOT NULL,
              title_zh TEXT NOT NULL DEFAULT '',
              summary_zh TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL DEFAULT '',
              body_zh TEXT NOT NULL DEFAULT '',
              body_status TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE source_status (
              source_id TEXT PRIMARY KEY,
              status TEXT NOT NULL,
              error TEXT,
              updated_ms INTEGER NOT NULL,
              items_json TEXT NOT NULL
            )
          ''');
          await _createIndexes(db);
        },
        onUpgrade: (db, oldVersion, _) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE articles ADD COLUMN title_zh TEXT NOT NULL DEFAULT ''");
            await db.execute("ALTER TABLE articles ADD COLUMN summary_zh TEXT NOT NULL DEFAULT ''");
          }
          if (oldVersion < 3) {
            await db.execute("ALTER TABLE articles ADD COLUMN body TEXT NOT NULL DEFAULT ''");
            await db.execute("ALTER TABLE articles ADD COLUMN body_zh TEXT NOT NULL DEFAULT ''");
            await db.execute("ALTER TABLE articles ADD COLUMN body_status TEXT NOT NULL DEFAULT ''");
          }
          if (oldVersion < 4) {
            await _migrateArticleIds(db);
            await _createIndexes(db);
          }
        },
      ),
    );
    return NewsDatabase(db);
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS articles_source_pub ON articles(source_id, pub_ms DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS articles_saved ON articles(saved)');
  }

  static Future<void> _migrateArticleIds(Database db) async {
    final rows = await db.query('articles');
    final byNew = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final newId = articleIdFor(sourceId: row['source_id'] as String, url: row['url'] as String);
      byNew.putIfAbsent(newId, () => []).add(row);
    }
    final batch = db.batch();
    for (final entry in byNew.entries) {
      final group = [...entry.value]..sort((a, b) {
          final saved = ((b['saved'] as int?) ?? 0).compareTo((a['saved'] as int?) ?? 0);
          if (saved != 0) return saved;
          final read = ((b['read'] as int?) ?? 0).compareTo((a['read'] as int?) ?? 0);
          if (read != 0) return read;
          return ((b['updated_ms'] as int?) ?? 0).compareTo((a['updated_ms'] as int?) ?? 0);
        });
      final keep = group.first;
      for (final drop in group.skip(1)) {
        batch.delete('articles', where: 'id = ?', whereArgs: [drop['id']]);
      }
      final oldId = keep['id'] as String;
      if (oldId != entry.key) {
        batch.update('articles', {'id': entry.key}, where: 'id = ?', whereArgs: [oldId]);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertItems(List<NewsItem> items) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _db.batch();
    for (final item in items) {
      batch.rawInsert(
        '''
        INSERT INTO articles (id, source_id, title, url, summary, pub_ms, extra_json, saved, read, updated_ms, title_zh, summary_zh)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?, '', '')
        ON CONFLICT(id) DO UPDATE SET
          title=excluded.title,
          url=excluded.url,
          summary=excluded.summary,
          pub_ms=excluded.pub_ms,
          extra_json=excluded.extra_json,
          source_id=excluded.source_id,
          updated_ms=excluded.updated_ms,
          title_zh=CASE WHEN articles.title = excluded.title THEN articles.title_zh ELSE '' END,
          summary_zh=CASE WHEN articles.summary = excluded.summary THEN articles.summary_zh ELSE '' END
        ''',
        [
          item.id,
          item.sourceId,
          item.title,
          item.url,
          item.summary,
          item.pubDate?.millisecondsSinceEpoch,
          jsonEncode(item.extraSourceIds),
          now,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertStatus(SourceFetchResult result) async {
    await _db.insert(
      'source_status',
      {
        'source_id': result.sourceId,
        'status': result.status,
        'error': result.error,
        'updated_ms': result.updatedAt.millisecondsSinceEpoch,
        'items_json': '[]',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArticleRecord>> loadArticles({int limit = maxArticles}) async {
    final rows = await _db.query('articles', orderBy: 'pub_ms DESC', limit: limit);
    return rows.map(_rowToRecord).toList();
  }

  Future<List<NewsItem>> loadRecentForDedupe({int limit = 4000}) async {
    final rows = await _db.query(
      'articles',
      columns: ['id', 'source_id', 'title', 'url', 'summary', 'pub_ms', 'extra_json'],
      orderBy: 'pub_ms DESC',
      limit: limit,
    );
    return [
      for (final row in rows)
        NewsItem(
          id: row['id'] as String,
          sourceId: row['source_id'] as String,
          title: row['title'] as String,
          url: row['url'] as String,
          summary: row['summary'] as String,
          pubDate: row['pub_ms'] == null ? null : DateTime.fromMillisecondsSinceEpoch(row['pub_ms'] as int),
          extraSourceIds: (jsonDecode(row['extra_json'] as String? ?? '[]') as List).cast<String>(),
        ),
    ];
  }

  Future<int> prune({int? nowMs, String? keepId}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - const Duration(days: retentionDays).inMilliseconds;
    final dropped = await _db.delete(
      'articles',
      where: 'saved = 0 AND id != ? AND (pub_ms IS NULL OR pub_ms < ?)',
      whereArgs: [keepId ?? '', cutoff],
    );
    final countRow = await _db.rawQuery('SELECT COUNT(*) AS n FROM articles');
    final count = (countRow.first['n'] as int?) ?? 0;
    var extra = 0;
    if (count > maxArticles) {
      final overflow = count - maxArticles;
      extra = await _db.rawDelete(
        '''
        DELETE FROM articles WHERE id IN (
          SELECT id FROM articles
          WHERE saved = 0 AND id != ?
          ORDER BY pub_ms ASC
          LIMIT ?
        )
        ''',
        [keepId ?? '', overflow],
      );
    }
    return dropped + extra;
  }

  Future<Map<String, SourceFetchResult>> loadStatuses() async {
    final rows = await _db.query('source_status');
    final map = <String, SourceFetchResult>{};
    for (final row in rows) {
      map[row['source_id'] as String] = SourceFetchResult(
        sourceId: row['source_id'] as String,
        status: row['status'] as String,
        error: row['error'] as String?,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_ms'] as int),
      );
    }
    return map;
  }

  Future<void> setSaved(String id, bool saved) async {
    await _db.update('articles', {'saved': saved ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setRead(String id, bool read) async {
    await _db.update('articles', {'read': read ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setTranslation(String id, {required String titleZh, required String summaryZh}) async {
    await _db.update(
      'articles',
      {'title_zh': titleZh, 'summary_zh': summaryZh},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setTranslations(List<(String id, String titleZh, String summaryZh)> rows) async {
    if (rows.isEmpty) return;
    final batch = _db.batch();
    for (final row in rows) {
      batch.update(
        'articles',
        {'title_zh': row.$2, 'summary_zh': row.$3},
        where: 'id = ?',
        whereArgs: [row.$1],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setBody(String id, {required String body, required String bodyZh, required String status}) async {
    await _db.update(
      'articles',
      {'body': body, 'body_zh': bodyZh, 'body_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update('articles', {'read': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  ArticleRecord _rowToRecord(Map<String, Object?> row) {
    return ArticleRecord(
      saved: (row['saved'] as int? ?? 0) == 1,
      read: (row['read'] as int? ?? 0) == 1,
      titleZh: row['title_zh'] as String? ?? '',
      summaryZh: row['summary_zh'] as String? ?? '',
      body: row['body'] as String? ?? '',
      bodyZh: row['body_zh'] as String? ?? '',
      bodyStatus: row['body_status'] as String? ?? '',
      item: NewsItem(
        id: row['id'] as String,
        sourceId: row['source_id'] as String,
        title: row['title'] as String,
        url: row['url'] as String,
        summary: row['summary'] as String,
        pubDate: row['pub_ms'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['pub_ms'] as int),
        extraSourceIds: (jsonDecode(row['extra_json'] as String? ?? '[]') as List).cast<String>(),
      ),
    );
  }
}
