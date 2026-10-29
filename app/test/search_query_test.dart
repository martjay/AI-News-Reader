import 'package:ai_news_reader/core/article_record.dart';
import 'package:ai_news_reader/core/search_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

ArticleRecord rec({
  required String id,
  required String sourceId,
  required String title,
  String summary = '',
  String body = '',
  bool saved = false,
}) {
  return ArticleRecord(
    item: NewsItem(id: id, sourceId: sourceId, title: title, url: 'https://x/$id', summary: summary),
    body: body,
    saved: saved,
  );
}

void main() {
  final openai = rec(id: '1', sourceId: 'openai', title: 'GPT-5 launch', summary: 'models', body: 'hidden token body');
  final qbit = rec(id: '2', sourceId: 'qbit', title: '量子位报道', summary: '国内', body: 'token appears only in body');
  final savedOff = rec(
    id: '3',
    sourceId: 'off',
    title: 'Disabled source story',
    saved: true,
  );

  test('search stays in enabled sources plus saved', () {
    final hits = searchArticles(
      records: [openai, qbit, savedOff],
      enabledSourceIds: {'openai'},
      query: 'story',
    );
    expect(hits.map((e) => e.item.id), ['3']);
  });

  test('disabled unsaved articles are omitted', () {
    final hits = searchArticles(
      records: [openai, qbit],
      enabledSourceIds: {'openai'},
      query: '量子',
    );
    expect(hits, isEmpty);
  });

  test('single-character queries do not scan body', () {
    final hits = searchArticles(
      records: [openai],
      enabledSourceIds: {'openai'},
      query: 'k',
    );
    expect(hits, isEmpty);
  });

  test('queries of two or more characters can match body', () {
    final hits = searchArticles(
      records: [qbit],
      enabledSourceIds: {'qbit'},
      query: 'token',
    );
    expect(hits.map((e) => e.item.id), ['2']);
  });

  test('title match still works for a single character', () {
    final hits = searchArticles(
      records: [qbit],
      enabledSourceIds: {'qbit'},
      query: '量',
    );
    expect(hits.map((e) => e.item.id), ['2']);
  });
}
