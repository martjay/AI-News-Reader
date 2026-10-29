import 'package:flutter_test/flutter_test.dart';
import 'package:ai_news_reader/core/tts_controller.dart';

void main() {
  test('packs short paragraphs until the 1400-character budget', () {
    final text = List.generate(5, (i) => '段落$i：${'字' * 40}').join('\n\n');
    final chunks = speechChunks(text);
    expect(chunks, isNotEmpty);
    expect(chunks.first.firstPart, 0);
    expect(chunks.last.lastPart, 4);
    expect(chunks.every((c) => c.text.length <= 1400), isTrue);
  });

  test('hard-splits a paragraph longer than the budget', () {
    final long = '字' * 3000;
    final chunks = speechChunks(long, maxChars: 1400);
    expect(chunks.length, 3);
    expect(chunks.every((c) => c.firstPart == 0 && c.lastPart == 0), isTrue);
    expect(chunks.map((c) => c.text).join(), long);
  });

  test('maps packed chunks back to part ranges', () {
    const text = '标题在此足够长了吧\n\n第一段正文也要足够长才不会被丢掉。\n\n第二段继续讲故事给读者听。';
    final parts = speechPartsOf(text);
    final chunks = speechChunks(text, maxChars: 80);
    expect(parts.length, 3);
    expect(chunks, isNotEmpty);
    expect(chunks.first.firstPart, 0);
    expect(chunks.last.lastPart, parts.length - 1);
  });

  test('speaksText matches only the current part range', () {
    const state = TtsState(
      status: TtsStatus.playing,
      speechParts: ['标题足够长了吧这个', '第一段正文也要足够长才不会被丢掉。', '第二段继续讲故事给读者听。'],
      partFrom: 1,
      partTo: 1,
    );
    expect(state.speaksText('第一段正文也要足够长才不会被丢掉。'), isTrue);
    expect(state.speaksText('第二段继续讲故事给读者听。'), isFalse);
    expect(state.speaksText('标题足够长了吧这个'), isFalse);
  });

  test('clock formatting is mm:ss', () {
    expect(formatTtsClock(Duration.zero), '0:00');
    expect(formatTtsClock(const Duration(seconds: 5)), '0:05');
    expect(formatTtsClock(const Duration(minutes: 2, seconds: 9)), '2:09');
  });
}
