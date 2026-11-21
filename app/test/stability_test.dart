import 'package:ai_news_reader/core/input_check.dart';
import 'package:ai_news_reader/core/serial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serial mutations see each other in order', () async {
    final serial = Serial();
    var value = 0;
    final first = serial.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      value += 1;
      return value;
    });
    final second = serial.run(() async {
      value += 10;
      return value;
    });
    expect(await first, 1);
    expect(await second, 11);
  });

  test('a refresh requested while one is running is kept for one follow-up', () {
    final gate = RefreshGate();
    expect(gate.request(), isTrue);
    expect(gate.request(), isFalse);
    expect(gate.request(), isFalse);
    expect(gate.finish(), isTrue);
    expect(gate.finish(), isFalse);
    expect(gate.request(), isTrue);
    expect(gate.finish(), isFalse);
  });

  test('proxy, repo, and http addresses are rejected before they are saved', () {
    expect(acceptableProxy(''), isTrue);
    expect(acceptableProxy('127.0.0.1:7890'), isTrue);
    expect(acceptableProxy('not a proxy'), isFalse);
    expect(acceptableRepo('martjay/AI-News-Reader'), isTrue);
    expect(acceptableRepo('martjay'), isFalse);
    expect(acceptableHttpUrl('https://api.deepseek.com/v1'), isTrue);
    expect(acceptableHttpUrl('deepseek'), isFalse);
    expect(acceptableHttpUrl(''), isTrue);
  });
}
