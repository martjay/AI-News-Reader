import 'package:news_core/news_core.dart';

void main() {
  final merged = mergeAndDedupe([
    const NewsItem(id: '1', sourceId: 'a', title: 'Hello', url: 'https://x.test/p'),
    const NewsItem(id: '2', sourceId: 'b', title: 'Hello', url: 'https://x.test/p?utm_source=1'),
  ]);
  print('merged ${merged.length} extra=${merged.first.extraSourceIds}');
}
