import 'package:ai_news_reader/core/article_record.dart';
import 'package:ai_news_reader/core/refresh_publish.dart';
import 'package:ai_news_reader/services/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

void main() {
  test('a finished source is published before the slower ones', () async {
    final service = FeedService();
    final order = <String>[];
    await service.fetchDirect(
      [_source('slow'), _source('fast')],
      parallelism: 2,
      fetchOne: (source) async {
        await Future<void>.delayed(Duration(milliseconds: source.id == 'slow' ? 120 : 15));
        return SourceFetchResult(sourceId: source.id, status: 'ok', updatedAt: DateTime.now());
      },
      onEach: (result) async {
        order.add(result.sourceId);
      },
    );
    expect(order, ['fast', 'slow']);
  });

  test('incoming rows show immediately and keep an unchanged translation', () {
    final older = ArticleRecord(
      item: NewsItem(
        id: 'old',
        sourceId: 'a',
        title: 'Older',
        url: 'https://example.com/old',
        pubDate: DateTime.utc(2026, 1, 1),
      ),
      titleZh: '旧',
      body: 'full text',
      bodyStatus: 'ok',
    );
    final current = ArticleRecord(
      item: const NewsItem(id: 'same', sourceId: 'a', title: 'Same title', url: 'https://example.com/same', summary: 'same'),
      titleZh: '同样',
      summaryZh: '同样摘要',
    );
    final renamed = const NewsItem(id: 'same', sourceId: 'a', title: 'New title', url: 'https://example.com/same', summary: 'same');
    final fresh = NewsItem(
      id: 'fresh',
      sourceId: 'b',
      title: 'Fresh',
      url: 'https://example.com/fresh',
      pubDate: DateTime.utc(2026, 2, 1),
    );

    final renamedList = recordsAfterIncoming([older, current], [renamed]);
    final renamedRow = renamedList.firstWhere((row) => row.item.id == 'same');
    expect(renamedRow.titleZh, isEmpty);
    expect(renamedRow.summaryZh, '同样摘要');

    final next = recordsAfterIncoming([older, current], [fresh]);
    expect(next.map((row) => row.item.id), ['fresh', 'old', 'same']);
    expect(next.firstWhere((row) => row.item.id == 'old').body, 'full text');
    expect(next.firstWhere((row) => row.item.id == 'same').titleZh, '同样');
    final unchanged = [older];
    expect(identical(recordsAfterIncoming(unchanged, const []), unchanged), isTrue);
  });
}

SourceDef _source(String id) {
  return SourceDef(
    id: id,
    name: id,
    nameEn: id,
    category: SourceCategory.labs,
    access: SourceAccess.direct,
    type: SourceType.rss,
    url: 'https://example.com/$id',
    home: 'https://example.com',
    intervalMinutes: 30,
  );
}
