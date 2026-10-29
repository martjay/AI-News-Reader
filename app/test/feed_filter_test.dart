import 'package:ai_news_reader/core/feed_filter.dart';
import 'package:flutter_test/flutter_test.dart';

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
