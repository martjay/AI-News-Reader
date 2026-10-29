import 'package:flutter_test/flutter_test.dart';
import 'package:news_core/news_core.dart';

void main() {
  test('catalog parses bundled yaml shape', () {
    const yaml = '''
snapshot:
  defaultUrl: ""
sources:
  - id: qbitai
    name: 量子位
    nameEn: QbitAI
    category: china
    access: direct
    type: rss
    url: https://www.qbitai.com/feed
    home: https://www.qbitai.com
    intervalMinutes: 15
''';
    final catalog = SourceCatalog.parse(yaml);
    expect(catalog.byId('qbitai')?.name, '量子位');
  });
}
