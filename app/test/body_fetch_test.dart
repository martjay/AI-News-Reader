import 'package:ai_news_reader/core/body_fetch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto-fetch runs when body and status are empty regardless of summary length', () {
    expect(shouldAutoFetchBody('', ''), isTrue);
    expect(shouldAutoFetchBody('already here', ''), isFalse);
    expect(shouldAutoFetchBody('', 'fail'), isFalse);
    expect(shouldAutoFetchBody('', 'ok'), isFalse);
  });

  test('keeps existing translation when fetched body is unchanged', () {
    const previous =
        'Full article text that is long enough to count as complete body content for the reader.';
    final stored = applyFetchedBody(
      previousBody: previous,
      previousBodyZh: '已有译文',
      fetchedText: previous,
      fetchedStatus: 'ok',
      summaryFallback: 'summary',
    );
    expect(stored.status, 'ok');
    expect(stored.bodyZh, '已有译文');
  });

  test('clears translation when fetched body changes', () {
    final stored = applyFetchedBody(
      previousBody: 'old body',
      previousBodyZh: '旧译文',
      fetchedText: List.filled(20, 'paragraph').join(' '),
      fetchedStatus: 'ok',
      summaryFallback: 'summary',
    );
    expect(stored.status, 'ok');
    expect(stored.bodyZh, isEmpty);
  });

  test('persists fail without dropping a previous body', () {
    final stored = applyFailedBody(
      previousBody: 'kept',
      previousBodyZh: '译文',
      summaryFallback: 'rss summary',
    );
    expect(stored.status, 'fail');
    expect(stored.body, 'kept');
    expect(stored.bodyZh, '译文');
  });

  test('failed fetch with empty body falls back to the summary', () {
    final stored = applyFailedBody(
      previousBody: '',
      previousBodyZh: '',
      summaryFallback: 'rss summary',
    );
    expect(stored.status, 'fail');
    expect(stored.body, 'rss summary');
  });

  test('short remote text is stored as excerpt not full text', () {
    final stored = applyFetchedBody(
      previousBody: '',
      previousBodyZh: '',
      fetchedText: 'too short',
      fetchedStatus: 'ok',
      summaryFallback: 'rss summary',
    );
    expect(stored.status, 'excerpt');
    expect(isFullBodyStatus(stored.status), isFalse);
    expect(isWeakBodyStatus(stored.status), isTrue);
  });

  test('failed refetch still counts a long previous body as full text', () {
    const previous =
        'Full article text that is long enough to count as complete body content for the reader.';
    expect(hasUsableFullBody(previous, 'fail'), isTrue);
    expect(hasUsableFullBody('rss only', 'fail'), isFalse);
  });
}
