import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:news_core/news_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses http proxy host and port', () {
    expect(parseHttpProxy('127.0.0.1:7890'), '127.0.0.1:7890');
    expect(parseHttpProxy('http://127.0.0.1:7890'), '127.0.0.1:7890');
    expect(parseHttpProxy('https=127.0.0.1:7890;http=127.0.0.1:7890'), '127.0.0.1:7890');
    expect(parseHttpProxy('socks5://127.0.0.1:7891'), isNull);
    expect(parseHttpProxy('DIRECT'), isNull);
  });

  test('canonicalize strips tracking params', () {
    expect(
      canonicalizeUrl('https://Example.com/a?utm_source=x&id=1/'),
      'https://example.com/a?id=1',
    );
    expect(canonicalizeUrl('https://Example.com/p?utm_source=x'), canonicalizeUrl('https://example.com/p/'));
  });

  test('article ids are namespaced by source and ignore tracking params', () {
    final a = articleIdFor(sourceId: 'a', url: 'https://Example.com/p?utm_source=x');
    final b = articleIdFor(sourceId: 'b', url: 'https://example.com/p');
    final again = articleIdFor(sourceId: 'a', url: 'https://example.com/p/');
    expect(a, isNot(b));
    expect(a, again);
    expect(a.length, 64);
  });

  test('mergeIncoming keeps stored id and extra sources', () {
    final stored = [
      const NewsItem(
        id: 'stored-1',
        sourceId: 'a',
        title: 'OpenAI releases GPT',
        url: 'https://x.com/p',
        summary: 'short',
      ),
    ];
    final incoming = [
      const NewsItem(
        id: 'fresh-2',
        sourceId: 'b',
        title: 'OpenAI releases GPT',
        url: 'https://x.com/p?utm_source=1',
        summary: 'a longer summary from the second feed',
      ),
    ];
    final merged = mergeIncoming(stored, incoming);
    expect(merged.length, 1);
    expect(merged.first.id, 'stored-1');
    expect(merged.first.extraSourceIds, ['b']);
    expect(merged.first.summary, 'a longer summary from the second feed');
  });

  test('snapshot url rejects http and loopback', () {
    expect(isAllowedSnapshotUrl('https://cdn.jsdelivr.net/gh/a/b@main/data/snapshot.json'), isTrue);
    expect(isAllowedSnapshotUrl('http://cdn.jsdelivr.net/gh/a/b@main/data/snapshot.json'), isFalse);
    expect(isAllowedSnapshotUrl('https://127.0.0.1/snapshot.json'), isFalse);
    expect(isAllowedSnapshotUrl('https://localhost/snapshot.json'), isFalse);
    expect(jsdelivrUrlForRepo('../etc/passwd'), isNull);
    expect(jsdelivrUrlForRepo('owner/repo'), contains('owner/repo'));
  });

  test('retention keeps saved and recent, drops old unsaved', () {
    const now = 1_000_000_000_000;
    const window = 21 * 24 * 60 * 60 * 1000;
    expect(shouldKeepArticle(saved: true, pubMs: 1, nowMs: now, retentionMs: window), isTrue);
    expect(shouldKeepArticle(saved: false, pubMs: now - 1000, nowMs: now, retentionMs: window), isTrue);
    expect(shouldKeepArticle(saved: false, pubMs: now - window - 1, nowMs: now, retentionMs: window), isFalse);
    expect(shouldKeepArticle(saved: false, pubMs: null, nowMs: now, retentionMs: window), isFalse);
  });

  test('merge duplicate urls and similar titles', () {
    final items = [
      const NewsItem(id: '1', sourceId: 'a', title: 'OpenAI releases GPT', url: 'https://x.com/p?utm_source=1'),
      const NewsItem(id: '2', sourceId: 'b', title: 'OpenAI releases GPT', url: 'https://x.com/p'),
    ];
    final merged = mergeAndDedupe(items);
    expect(merged.length, 1);
    expect(merged.first.extraSourceIds, ['b']);
  });

  test('detects chinese vs english', () {
    expect(isPrimarilyChinese('OpenAI releases GPT-5'), isFalse);
    expect(isPrimarilyChinese('量子位：大模型新进展'), isTrue);
    expect(
      isPrimarilyChinese('导读指出机器人仍依赖人类。Very insightful survey paper from MIT Stanford Google Microsoft about robot self-improvement studies.'),
      isFalse,
    );
    expect(hasTranslatableLatin('导读 MIT Stanford Google Microsoft robot'), isTrue);
  });

  test('brief groups similar titles across sources', () {
    final now = DateTime(2026, 10, 15, 18);
    final stories = buildBrief(
      now: now,
      unreadIds: {'1'},
      items: [
        NewsItem(
          id: '1',
          sourceId: 'openai',
          title: 'OpenAI releases GPT-5',
          url: 'https://a',
          summary: 'labs',
          pubDate: now.subtract(const Duration(hours: 2)),
        ),
        NewsItem(
          id: '2',
          sourceId: 'qbit',
          title: 'OpenAI releases GPT-5',
          url: 'https://b',
          pubDate: now.subtract(const Duration(hours: 1)),
        ),
        NewsItem(
          id: '3',
          sourceId: 'qbit',
          title: '量子位独家快讯',
          url: 'https://c',
          pubDate: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );
    expect(stories.first.sourceIds.toSet(), {'openai', 'qbit'});
    expect(stories.length, 2);
  });

  test('uses host selectors and drops site bylines', () {
    const html = '''
      <html><body>
        <div class="post_recommend">相关阅读 别的新闻标题占位足够长</div>
        <div id="paragraph">
          <p>韩国特检组申请延长金建希羁押期限，并说明案件目前仍在最高法院审理当中。</p>
          <p>IT之家讯 这是短署名行应被丢掉。</p>
          <p>财联社15日电，韩国特别检察组向大法院提交申请，要求对金建希签发新的逮捕令。</p>
        </div>
      </body></html>
    ''';
    final text = extractReadableHtml(html, url: 'https://www.ithome.com/0/123/456.htm');
    expect(text.contains('金建希羁押'), isTrue);
    expect(text.contains('相关阅读'), isFalse);
    expect(text.contains('IT之家讯'), isFalse);
  });

  test('keeps article images as markdown', () {
    const html = '''
      <html><body>
        <article>
          <p>First paragraph of the story with enough length to keep.</p>
          <img src="/photos/hero.jpg" alt="hero">
          <p>Second paragraph continues the argument for the reader.</p>
        </article>
      </body></html>
    ''';
    final text = extractReadableHtml(html, url: 'https://example.com/post');
    expect(text.contains('First paragraph'), isTrue);
    expect(text.contains('![image](https://example.com/photos/hero.jpg)'), isTrue);
    expect(readerImageUrl('![image](https://example.com/photos/hero.jpg)'), 'https://example.com/photos/hero.jpg');
  });

  test('extracts readable text from article html', () {
    const html = '''
      <html><body>
        <nav>ignore</nav>
        <article>
          <p>First paragraph of the story with enough length to keep.</p>
          <p>Second paragraph continues the argument for the reader.</p>
        </article>
      </body></html>
    ''';
    final text = extractReadableHtml(html);
    expect(text.contains('First paragraph'), isTrue);
    expect(text.contains('ignore'), isFalse);
    expect(text.contains('\n'), isTrue);
  });

  test('strips jina markdown wrapper and nav links', () {
    const md = '''
Title: 快讯：当地时间15日，伊朗军队海军宣布，数小时前，伊朗海军监视小队在霍尔木兹海峡东部巡逻期间，发现一艘违规油轮起火。伊朗海军强调，霍尔木兹海峡目前完全处于伊朗军队海军和伊朗伊斯兰革命卫队海军的控制和监督中。（央视新闻）

URL Source: https://wallstreetcn.com/livenews/3179511

Markdown Content:
[](https://wallstreetcn.com/)
* [首页](https://wallstreetcn.com/)
* [资讯](https://wallstreetcn.com/news)
* [快讯](https://wallstreetcn.com/live)
* [行情](https://wallstreetcn.com/markets)
* [日历](https://wallstreetcn.com/calendar)
* [APP](https://wallstreetcn.com/download)
''';
    final text = cleanReadableMarkdown(md);
    expect(text.contains('违规油轮起火'), isTrue);
    expect(text.contains('Title:'), isFalse);
    expect(text.contains('URL Source'), isFalse);
    expect(text.contains('Markdown Content'), isFalse);
    expect(text.contains('wallstreetcn.com/news'), isFalse);
    expect(text.contains('[首页]'), isFalse);
  });

  test('drops English and forum chrome from readable extract', () {
    const html = '''
      <html><body>
        <div id="Top">V2EX</div>
        <div class="cell">请不要在回答技术问题时复制粘贴 AI 生成的内容</div>
        <div class="topic_content">
          <div class="markdown_body">
            <p>AI 太牛逼了，总想用 ai 来搞点副业，但是用 ai 扫了一圈不少的苹果论坛， reddit 啥的， ai 都不太建议做，大家有啥好想法么？</p>
          </div>
        </div>
        <div>iamnotorobot0 · Just Now · 1 views</div>
        <div>No Comments Yet</div>
        <div id="Bottom">
          About · Help · Advertise · Blog · API · FAQ · Privacy · Solana
          World is powered by solitude
          VERSION: 3.9.8.5 · 31ms · UTC 12:44 · PVG 20:44
        </div>
      </body></html>
    ''';
    final text = extractReadableHtml(html);
    expect(text.contains('苹果论坛'), isTrue);
    expect(text.contains('请不要在回答技术问题'), isFalse);
    expect(text.contains('No Comments Yet'), isFalse);
    expect(text.contains('Advertise'), isFalse);
    expect(text.contains('powered by'), isFalse);
    expect(text.contains('VERSION'), isFalse);
  });

  test('drops site chrome from readable extract', () {
    const html = '''
      <html><body>
        <main>
          <div>关于我们 网站声明 联系方式 用户反馈 网站地图 帮助</div>
          <article>
            <p>韩国特检组申请延长金建希羁押期限，并说明案件目前仍在最高法院审理。</p>
            <p>财联社10月15日电，韩国特别检察组15日向韩国大法院提交申请，要求对前总统尹锡悦妻子金建希签发新的逮捕令。</p>
          </article>
          <div>关于我们 | 网站声明 | 联系方式 | 用户反馈 | 网站地图 | 友情链接</div>
          <div>财联社©2018-2026上海界面财联社科技股份有限公司 版权所有 沪ICP备14040942号-9</div>
        </main>
      </body></html>
    ''';
    final text = extractReadableHtml(html);
    expect(text.contains('金建希'), isTrue);
    expect(text.contains('关于我们'), isFalse);
    expect(text.contains('沪ICP'), isFalse);
    expect(text.contains('友情链接'), isFalse);
  });

  test('does not glue adjacent inline nodes', () {
    const html = '''
      <html><body><article>
        <div><span>Rohan Paul</span><span>Rohan Paul</span></div>
        <p>Second paragraph continues the argument for the reader.</p>
      </article></body></html>
    ''';
    final text = extractReadableHtml(html);
    expect(text.contains('Rohan Paul Rohan Paul') || text.contains('Rohan Paul\n'), isTrue);
    expect(splitReaderParagraphs(text).length, greaterThan(1));
  });

  test('rejects waf json as unreadable', () {
    const waf = '{"_waf_":true,"rid":"abc","status":403,"data":{"a":1}}';
    expect(looksUnreadable(waf), isTrue);
    expect(looksUnreadable('## 访问触发保护，请完成人机验证\n\n检测到当前网络环境的访问频率异常。'), isTrue);
    expect(looksUnreadable('韩国特检组申请延长金建希羁押期限，并说明案件目前仍在最高法院审理当中。'), isFalse);
  });

  test('speech plaintext drops 阅读原文 and urls', () {
    const body =
        '腾讯云回应称这是对第三方开发者所建模型的评估活动，并非混元团队模型，未发现蓄意针对或协同行动的证据。 🔗 阅读原文 via AIHOT · https://aihot.news/items/mixkq919lfpp7nhtni3dearqm';
    final spoken = speechPlaintext(body);
    expect(spoken.contains('腾讯云回应'), isTrue);
    expect(spoken.contains('阅读原文'), isFalse);
    expect(spoken.contains('https://'), isFalse);
  });

  test('puts 阅读原文 on its own paragraph', () {
    const body =
        '腾讯云回应称这是对第三方开发者所建模型的评估活动，并非混元团队模型，未发现蓄意针对或协同行动的证据。 🔗 阅读原文 via AIHOT · https://aihot.news/items/mixkq919lfpp7nhtni3dearqm';
    final paras = splitReaderParagraphs(body);
    expect(paras, [
      '腾讯云回应称这是对第三方开发者所建模型的评估活动，并非混元团队模型，未发现蓄意针对或协同行动的证据。',
      '阅读原文 via AIHOT',
      '🔗 https://aihot.news/items/mixkq919lfpp7nhtni3dearqm',
    ]);
  });

  test('reader paragraphs keep mixed product names on one line', () {
    const body = '用 Kimi Work 自动化你的工作流 - 教程 #3\n\n- 用 Swarm 拆解复杂任务';
    final paras = splitReaderParagraphs(body);
    expect(paras, ['用 Kimi Work 自动化你的工作流 - 教程 #3', '- 用 Swarm 拆解复杂任务']);
  });

  test('marks ranking sources as boards', () {
    expect(defaultBoardIds.contains('weibo'), isTrue);
    expect(defaultBoardIds.contains('openai'), isFalse);
  });

  test('groups items by RSS source order', () {
    final catalog = {
      'openai': const SourceDef(
        id: 'openai',
        name: 'OpenAI',
        nameEn: 'OpenAI',
        category: SourceCategory.labs,
        access: SourceAccess.snapshot,
        type: SourceType.rss,
        url: 'https://example.com',
        home: 'https://example.com',
        intervalMinutes: 30,
      ),
      'qbit': const SourceDef(
        id: 'qbit',
        name: '量子位',
        nameEn: 'Qbit',
        category: SourceCategory.china,
        access: SourceAccess.direct,
        type: SourceType.rss,
        url: 'https://example.com',
        home: 'https://example.com',
        intervalMinutes: 30,
      ),
    };
    final now = DateTime(2026, 10, 14, 15);
    final sections = buildBySource(
      catalog: catalog,
      sourceOrder: const ['qbit', 'openai'],
      items: [
        NewsItem(id: '1', sourceId: 'openai', title: '实验室', url: 'https://b', pubDate: now.subtract(const Duration(hours: 1))),
        NewsItem(id: '2', sourceId: 'qbit', title: '国内新', url: 'https://a', pubDate: now),
        NewsItem(id: '3', sourceId: 'qbit', title: '国内旧', url: 'https://c', pubDate: now.subtract(const Duration(hours: 2))),
      ],
    );
    expect(sections.map((s) => s.id).toList(), ['qbit', 'openai']);
    expect(sections.first.items.map((e) => e.title).toList(), ['国内新', '国内旧']);
  });

  test('readerImageUrl ignores ordinary paragraphs', () {
    expect(readerImageUrl('Just a sentence about models.'), isNull);
    expect(readerImageUrl('![image](https://cdn.example.com/a.png)'), 'https://cdn.example.com/a.png');
  });

  test('fetchReadable returns excerpt when remote fetch fails', () async {
    final client = FetchClient(
      client: MockClient((request) async => http.Response('blocked', 500)),
    );
    addTearDown(client.close);
    final result = await fetchReadable(
      client,
      'https://example.com/post',
      seedHtml: '<p>${List.filled(40, 'word').join(' ')}</p>',
      preferRemote: true,
    );
    expect(result.status, 'excerpt');
    expect(result.text.toLowerCase(), contains('word'));
  });

  test('mergeSnapshot keeps previous items when this fetch is empty', () {
    final previous = NewsSnapshot(
      generatedAt: DateTime.utc(2026, 10, 29),
      sources: {
        'openai': SourceFetchResult(
          sourceId: 'openai',
          status: 'ok',
          updatedAt: DateTime.utc(2026, 10, 29, 1),
          items: const [
            NewsItem(id: 'old', sourceId: 'openai', title: 'Old', url: 'https://openai.com/a'),
          ],
        ),
        'empty-before': SourceFetchResult(
          sourceId: 'empty-before',
          status: 'error',
          updatedAt: DateTime.utc(2026, 10, 29, 1),
        ),
      },
    );
    final fresh = {
      'openai': SourceFetchResult(
        sourceId: 'openai',
        status: 'error',
        updatedAt: DateTime.utc(2026, 10, 30),
        error: 'timeout',
      ),
      'nvidia': SourceFetchResult(
        sourceId: 'nvidia',
        status: 'ok',
        updatedAt: DateTime.utc(2026, 10, 30, 2),
        items: const [
          NewsItem(id: 'new', sourceId: 'nvidia', title: 'New', url: 'https://nvidia.com/b'),
        ],
      ),
      'empty-before': SourceFetchResult(
        sourceId: 'empty-before',
        status: 'error',
        updatedAt: DateTime.utc(2026, 10, 30),
        error: 'HTTP 403',
      ),
    };
    final merged = mergeSnapshot(previous, fresh, DateTime.utc(2026, 10, 30, 3));
    expect(merged.sources['openai']!.status, 'stale');
    expect(merged.sources['openai']!.items.single.id, 'old');
    expect(merged.sources['openai']!.error, 'timeout');
    expect(merged.sources['nvidia']!.items.single.id, 'new');
    expect(merged.sources['empty-before']!.items, isEmpty);
    expect(merged.sources['empty-before']!.status, 'error');
  });

  test('fetchReadable returns empty when remote fails and seed is empty', () async {
    final client = FetchClient(
      client: MockClient((request) async => http.Response('blocked', 500)),
    );
    addTearDown(client.close);
    final result = await fetchReadable(
      client,
      'https://example.com/post',
      seedHtml: '',
      preferRemote: true,
    );
    expect(result.status, 'empty');
    expect(result.text, isEmpty);
  });
}
