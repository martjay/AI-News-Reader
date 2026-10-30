import 'package:ai_news_reader/core/feed_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

void main() {
  test('first launch uses catalog defaults when nothing is stored', () {
    expect(
      resolveEnabledSourceIds(
        enabledSources: const [],
        seenSourceIds: const [],
        catalogEnabledIds: const ['aihot', 'qbit'],
      ),
      {'aihot', 'qbit'},
    );
  });

  test('returning users who disabled every source see an empty set', () {
    expect(
      resolveEnabledSourceIds(
        enabledSources: const [],
        seenSourceIds: const ['aihot'],
        catalogEnabledIds: const ['aihot', 'qbit'],
      ),
      isEmpty,
    );
  });

  test('explicit enabled sources win', () {
    expect(
      resolveEnabledSourceIds(
        enabledSources: const ['openai'],
        seenSourceIds: const ['aihot', 'openai'],
        catalogEnabledIds: const ['aihot', 'qbit'],
      ),
      {'openai'},
    );
  });

  test('toggling off one default source does not disable the rest', () {
    expect(
      applySourceEnabled(
        enabledSources: const [],
        seenSourceIds: const [],
        catalogEnabledIds: const ['aihot', 'qbit', 'openai'],
        id: 'openai',
        on: false,
      ),
      ['aihot', 'qbit'],
    );
  });

  test('unseen default sources are enabled for returning users', () {
    final adopted = adoptUnseenSources(
      enabledSources: const ['aihot'],
      seenSourceIds: const ['aihot'],
      sources: [
        _source('aihot'),
        _source('openai'),
        _source('zhihu', board: true),
        _source('hidden', enabled: false),
      ],
    );
    expect(adopted.seen, ['aihot', 'openai', 'zhihu', 'hidden']);
    expect(adopted.enabled, ['aihot', 'openai']);
  });

  test('sources the user already saw stay disabled', () {
    final adopted = adoptUnseenSources(
      enabledSources: const ['aihot'],
      seenSourceIds: const ['aihot', 'openai'],
      sources: [
        _source('aihot'),
        _source('openai'),
      ],
    );
    expect(adopted.enabled, ['aihot']);
    expect(adopted.seen, ['aihot', 'openai']);
  });

  test('turning every source off is unchanged when nothing new appears', () {
    final adopted = adoptUnseenSources(
      enabledSources: const [],
      seenSourceIds: const ['aihot'],
      sources: [_source('aihot')],
    );
    expect(adopted.enabled, isEmpty);
  });

  test('toggling on a source starts from catalog defaults', () {
    expect(
      applySourceEnabled(
        enabledSources: const [],
        seenSourceIds: const [],
        catalogEnabledIds: const ['aihot'],
        id: 'qbit',
        on: true,
      ),
      ['aihot', 'qbit'],
    );
  });
}

SourceDef _source(String id, {bool enabled = true, bool board = false}) {
  return SourceDef(
    id: id,
    name: id,
    nameEn: id,
    category: SourceCategory.china,
    access: SourceAccess.direct,
    type: SourceType.rss,
    url: 'https://example.com/$id',
    home: 'https://example.com/$id',
    intervalMinutes: 30,
    enabled: enabled,
    board: board,
  );
}
