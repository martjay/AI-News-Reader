import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html_parser;

import 'article_id.dart';
import 'fetch_client.dart';
import 'models.dart';

Future<List<NewsItem>> fetchNewsnow(FetchClient client, SourceDef source) async {
  switch (source.id) {
    case 'v2ex':
    case 'v2ex-share':
      return _v2ex(client, source);
    case 'zhihu':
      return _zhihu(client, source);
    case 'weibo':
      return _weibo(client, source);
    case 'zaobao':
      return _zaobao(client, source);
    case 'coolapk':
      return _coolapk(client, source);
    case 'mktnews':
    case 'mktnews-flash':
      return _mktnews(client, source);
    case 'wallstreetcn':
    case 'wallstreetcn-quick':
      return _wallLive(client, source);
    case 'wallstreetcn-news':
      return _wallNews(client, source);
    case 'wallstreetcn-hot':
      return _wallHot(client, source);
    case '36kr':
    case '36kr-quick':
      return _kr36Quick(client, source);
    case '36kr-renqi':
      return _kr36Renqi(client, source);
    case 'douyin':
      return _douyin(client, source);
    case 'hupu':
      return _hupu(client, source);
    case 'dongqiudi':
      return _dongqiudi(client, source);
    case 'tieba':
      return _tieba(client, source);
    case 'toutiao':
      return _toutiao(client, source);
    case 'thepaper':
      return _thepaper(client, source);
    case 'sputniknewscn':
      return _sputnik(client, source);
    case 'cankaoxiaoxi':
      return _cankaoxiaoxi(client, source);
    case 'pcbeta':
    case 'pcbeta-windows11':
      return _rssFallback(client, source, 'https://bbs.pcbeta.com/forum.php?mod=rss&fid=563&auth=0');
    case 'pcbeta-windows':
      return _rssFallback(client, source, 'https://bbs.pcbeta.com/forum.php?mod=rss&fid=521&auth=0');
    case 'cls':
    case 'cls-telegraph':
      return _clsTelegraph(client, source);
    case 'cls-depth':
      return _clsDepth(client, source);
    case 'cls-hot':
      return _clsHot(client, source);
    case 'xueqiu':
    case 'xueqiu-hotstock':
      return _xueqiu(client, source);
    case 'gelonghui':
      return _gelonghui(client, source);
    case 'fastbull':
    case 'fastbull-express':
      return _fastbullExpress(client, source);
    case 'fastbull-news':
      return _fastbullNews(client, source);
    case 'hackernews':
      return _rssFallback(client, source, 'https://hnrss.org/frontpage?count=30');
    case 'producthunt':
      return _rssFallback(client, source, 'https://www.producthunt.com/feed');
    case 'github':
    case 'github-trending-today':
      return _github(client, source);
    case 'bilibili':
    case 'bilibili-hot-search':
      return _biliSearch(client, source);
    case 'bilibili-hot-video':
      return _biliVideo(client, source, 'https://api.bilibili.com/x/web-interface/popular');
    case 'bilibili-ranking':
      return _biliVideo(client, source, 'https://api.bilibili.com/x/web-interface/ranking/v2');
    case 'kuaishou':
      return _kuaishou(client, source);
    case 'kaopu':
      return _rssFallback(client, source, 'https://kaopunews.com/feed.xml');
    case 'jin10':
      return _jin10(client, source);
    case 'baidu':
      return _baidu(client, source);
    case 'nowcoder':
      return _nowcoder(client, source);
    case 'ifeng':
      return _ifeng(client, source);
    case 'chongbuluo':
    case 'chongbuluo-hot':
      return _chongbuluoHot(client, source);
    case 'chongbuluo-latest':
      return _rssFallback(client, source, 'https://www.chongbuluo.com/forum.php?mod=rss&view=newthread');
    case 'douban':
      return _douban(client, source);
    case 'steam':
      return _steam(client, source);
    case 'tencent':
    case 'tencent-hot':
      return _tencent(client, source);
    case 'freebuf':
      return _rssFallback(client, source, 'https://www.freebuf.com/feed');
    case 'qqvideo':
    case 'qqvideo-tv-hotsearch':
      return _qqvideo(client, source);
    case 'iqiyi':
    case 'iqiyi-hot-ranklist':
      return _iqiyi(client, source);
    default:
      throw Exception('Unknown hot source ${source.id}');
  }
}

NewsItem _item(SourceDef source, String id, String title, String url, {String summary = '', DateTime? pub}) {
  final href = url.trim().isEmpty ? id : url;
  return makeItem(
    sourceId: source.id,
    title: title.trim(),
    url: href,
    summary: summary.trim(),
    pubDate: pub,
  );
}

DateTime? _ms(dynamic raw) {
  if (raw is num) {
    final n = raw.toInt();
    if (n > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(n);
    if (n > 1000000000) return DateTime.fromMillisecondsSinceEpoch(n * 1000);
  }
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

Future<List<NewsItem>> _rssFallback(FetchClient client, SourceDef source, String url) async {
  final rss = SourceDef(
    id: source.id,
    name: source.name,
    nameEn: source.nameEn,
    category: source.category,
    access: source.access,
    type: SourceType.rss,
    url: url,
    home: source.home,
    intervalMinutes: source.intervalMinutes,
  );
  final fetcher = SourceFetcherProxy(client);
  return fetcher.rss(rss);
}

class SourceFetcherProxy {
  SourceFetcherProxy(this.client);
  final FetchClient client;
  Future<List<NewsItem>> rss(SourceDef source) async {
    return parseRssItems(source, await client.getText(source.url));
  }
}

List<NewsItem> parseRssItems(SourceDef source, String xmlText) {
  final items = <NewsItem>[];
  final xml = xmlText;
  final blocks = RegExp(r'<item[\s\S]*?</item>', caseSensitive: false).allMatches(xml);
  for (final block in blocks) {
    final chunk = block.group(0)!;
    final title = _xmlTag(chunk, 'title');
    final link = _xmlTag(chunk, 'link');
    if (title.isEmpty || link.isEmpty) continue;
    items.add(_item(source, _xmlTag(chunk, 'guid'), title, link, summary: _xmlTag(chunk, 'description')));
  }
  if (items.isNotEmpty) return items;
  final entries = RegExp(r'<entry[\s\S]*?</entry>', caseSensitive: false).allMatches(xml);
  for (final block in entries) {
    final chunk = block.group(0)!;
    final title = _xmlTag(chunk, 'title');
    final link = RegExp(r'<link[^>]+href="([^"]+)"').firstMatch(chunk)?.group(1) ?? _xmlTag(chunk, 'link');
    if (title.isEmpty || link.isEmpty) continue;
    items.add(_item(source, _xmlTag(chunk, 'id'), title, link));
  }
  if (items.isEmpty) {
    throw Exception('Empty RSS for ${source.id}');
  }
  return items;
}

String _xmlTag(String xml, String tag) {
  final m = RegExp('<$tag[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]></$tag>').firstMatch(xml) ??
      RegExp('<$tag[^>]*>([\\s\\S]*?)</$tag>').firstMatch(xml);
  if (m == null) return '';
  return m.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<List<NewsItem>> _v2ex(FetchClient client, SourceDef source) async {
  final feeds = ['create', 'ideas', 'programmer', 'share'];
  final items = <NewsItem>[];
  for (final name in feeds) {
    final json = await client.getJson('https://www.v2ex.com/feed/$name.json');
    for (final raw in (json as Map)['items'] as List? ?? const []) {
      final m = raw as Map;
      items.add(_item(source, '${m['id']}', '${m['title']}', '${m['url']}', pub: DateTime.tryParse('${m['date_published'] ?? ''}')));
    }
  }
  items.sort((a, b) => (b.pubDate ?? DateTime(0)).compareTo(a.pubDate ?? DateTime(0)));
  return items;
}

Future<List<NewsItem>> _zhihu(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://www.zhihu.com/api/v3/feed/topstory/hot-list-web?limit=20&desktop=true');
  return [
    for (final raw in (json as Map)['data'] as List? ?? const [])
      _item(
        source,
        '${(((raw as Map)['target'] as Map?)?['link'] as Map?)?['url'] ?? ''}',
        '${((raw['target'] as Map?)?['title_area'] as Map?)?['text'] ?? ''}',
        '${((raw['target'] as Map?)?['link'] as Map?)?['url'] ?? ''}',
        summary: '${((raw['target'] as Map?)?['excerpt_area'] as Map?)?['text'] ?? ''}',
      ),
  ].where((e) => e.title.isNotEmpty && e.url.isNotEmpty).toList();
}

Future<List<NewsItem>> _weibo(FetchClient client, SourceDef source) async {
  const url = 'https://s.weibo.com/top/summary?cate=realtimehot';
  final html = await client.getText(url, headers: {
    'Cookie': 'SUB=_2AkMWIuNSf8NxqwJRmP8dy2rhaoV2ygrEieKgfhKJJRMxHRl-yT9jqk86tRB6PaLNvQZR6zYUcYVT1zSjoSreQHidcUq7',
    'Referer': url,
  });
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final row in doc.querySelectorAll('#pl_top_realtimehot table tbody tr').skip(1)) {
    final a = row.querySelectorAll('td.td-02 a').where((el) {
      final href = el.attributes['href'] ?? '';
      return href.isNotEmpty && !href.contains('javascript');
    }).firstOrNull;
    if (a == null) continue;
    final title = a.text.trim();
    final href = a.attributes['href'] ?? '';
    if (title.isEmpty || href.isEmpty) continue;
    items.add(_item(source, title, title, href.startsWith('http') ? href : 'https://s.weibo.com$href'));
  }
  return items;
}

Future<List<NewsItem>> _zaobao(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.zaochenbao.com/realtime/');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final a in doc.querySelectorAll('div.list-block > a.item')) {
    final href = a.attributes['href'] ?? '';
    final title = a.querySelector('.eps')?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href.startsWith('http') ? href : 'https://www.zaochenbao.com$href'));
  }
  return items;
}

Future<List<NewsItem>> _coolapk(FetchClient client, SourceDef source) async {
  final token = _coolapkToken();
  final json = await client.getJson(
    'https://api.coolapk.com/v6/page/dataList?url=%2Ffeed%2FstatList%3FcacheExpires%3D300%26statType%3Dday%26sortField%3Ddetailnum%26title%3D%E4%BB%8A%E6%97%A5%E7%83%AD%E9%97%A8&title=%E4%BB%8A%E6%97%A5%E7%83%AD%E9%97%A8&subTitle=&page=1',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'X-App-Id': 'com.coolapk.market',
      'X-App-Token': token,
      'X-Sdk-Int': '29',
      'X-App-Version': '11.0',
      'X-Api-Version': '11',
      'X-App-Code': '2101202',
      'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 10; Redmi K30 5G) +CoolMarket/11.0-2101202',
    },
  );
  return [
    for (final raw in (json as Map)['data'] as List? ?? const [])
      if ((raw as Map)['id'] != null)
        _item(
          source,
          '${raw['id']}',
          '${raw['editor_title'] ?? ''}'.trim().isEmpty ? '${raw['message'] ?? ''}'.split('\n').first : '${raw['editor_title']}',
          'https://www.coolapk.com${raw['url'] ?? ''}',
        ),
  ].where((e) => e.title.isNotEmpty).toList();
}

String _coolapkToken() {
  final rand = Random();
  String chunk(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(n, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  final device = '${chunk(8)}-${chunk(4)}-${chunk(4)}-${chunk(4)}-${chunk(12)}';
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final hexNow = '0x${now.toRadixString(16)}';
  final md5Now = md5.convert(utf8.encode('$now')).toString();
  final s = 'token://com.coolapk.market/c67ef5943784d09750dcfbb31020f0ab?$md5Now\$$device&com.coolapk.market';
  final md5s = md5.convert(utf8.encode(base64Encode(utf8.encode(s)))).toString();
  return '$md5s$device$hexNow';
}

Future<List<NewsItem>> _mktnews(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://api.mktnews.net/api/flash?type=0&limit=50', headers: {
    'Origin': 'https://mktnews.net',
    'Referer': 'https://mktnews.net/',
  });
  return [
    for (final raw in (json as Map)['data'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['id']}',
        '${(raw['data'] as Map?)?['title'] ?? (raw['data'] as Map?)?['content'] ?? ''}',
        'https://mktnews.net/flashDetail.html?id=${raw['id']}',
        summary: '${(raw['data'] as Map?)?['content'] ?? ''}',
        pub: DateTime.tryParse('${raw['time'] ?? ''}'),
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _wallLive(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://api-one.wallstcn.com/apiv1/content/lives?channel=global-channel&limit=30');
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['items'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['id']}',
        '${raw['title'] ?? raw['content_text'] ?? ''}',
        '${raw['uri'] ?? ''}',
        summary: '${raw['content_text'] ?? raw['content_short'] ?? ''}',
        pub: _ms(raw['display_time']),
      ),
  ].where((e) => e.title.isNotEmpty && e.url.isNotEmpty).toList();
}

Future<List<NewsItem>> _wallNews(FetchClient client, SourceDef source) async {
  final json = await client.getJson(
    'https://api-one.wallstcn.com/apiv1/content/information-flow?channel=global-channel&accept=article&limit=30',
  );
  final items = <NewsItem>[];
  for (final raw in ((json as Map)['data'] as Map?)?['items'] as List? ?? const []) {
    final m = raw as Map;
    if (m['resource_type'] == 'theme' || m['resource_type'] == 'ad') continue;
    final h = m['resource'] as Map? ?? const {};
    if (h['type'] == 'live' || '${h['uri'] ?? ''}'.isEmpty) continue;
    items.add(_item(
      source,
      '${h['id']}',
      '${h['title'] ?? h['content_short'] ?? ''}',
      '${h['uri']}',
      summary: '${h['content_text'] ?? h['content_short'] ?? ''}',
      pub: _ms(h['display_time']),
    ));
  }
  return items;
}

Future<List<NewsItem>> _wallHot(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://api-one.wallstcn.com/apiv1/content/articles/hot?period=all');
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['day_items'] as List? ?? const [])
      _item(source, '${(raw as Map)['id']}', '${raw['title'] ?? ''}', '${raw['uri'] ?? ''}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _kr36Quick(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.36kr.com/newsflashes');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.newsflash-item')) {
    final a = el.querySelector('a.item-title');
    final href = a?.attributes['href'] ?? '';
    final title = a?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href.startsWith('http') ? href : 'https://www.36kr.com$href'));
  }
  return items;
}

Future<List<NewsItem>> _kr36Renqi(FetchClient client, SourceDef source) async {
  final day = DateTime.now().toIso8601String().substring(0, 10);
  final html = await client.getText('https://36kr.com/hot-list/renqi/$day/1', headers: {
    'Referer': 'https://36kr.com/',
  });
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.article-item-info')) {
    final a = el.querySelector('a.article-item-title');
    final href = a?.attributes['href'] ?? '';
    final title = a?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(
      source,
      href,
      title,
      href.startsWith('http') ? href : 'https://36kr.com$href',
      summary: el.querySelector('a.article-item-description')?.text.trim() ?? '',
    ));
  }
  return items.isEmpty ? _kr36Quick(client, source) : items;
}

Future<List<NewsItem>> _douyin(FetchClient client, SourceDef source) async {
  final cookie = await client.cookieFrom('https://www.douyin.com/');
  final json = await client.getJson(
    'https://www.douyin.com/aweme/v1/web/hot/search/list/?device_platform=webapp&aid=6383&channel=channel_pc_web&detail_list=1',
    headers: {if (cookie.isNotEmpty) 'Cookie': cookie, 'Referer': 'https://www.douyin.com/'},
  );
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['word_list'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['sentence_id']}',
        '${raw['word'] ?? ''}',
        'https://www.douyin.com/hot/${raw['sentence_id']}',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _hupu(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://bbs.hupu.com/topic-daily-hot');
  final re = RegExp(r'<a href="(/[^"]+?\.html)"[^>]*?class="p-title"[^>]*>([^<]+)</a>');
  return [
    for (final m in re.allMatches(html))
      _item(source, m.group(1)!, m.group(2)!.trim(), 'https://bbs.hupu.com${m.group(1)}'),
  ];
}

Future<List<NewsItem>> _dongqiudi(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://api.dongqiudi.com/app/tabs/web/1.json');
  return [
    for (final raw in (json as Map)['articles'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['id']}',
        '${raw['title'] ?? ''}',
        '${raw['share'] ?? raw['url'] ?? 'https://www.dongqiudi.com/article/${raw['id']}'}',
        pub: DateTime.tryParse('${raw['created_at'] ?? ''}'),
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _tieba(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://tieba.baidu.com/hottopic/browse/topicList');
  return [
    for (final raw in (((json as Map)['data'] as Map?)?['bang_topic'] as Map?)?['topic_list'] as List? ?? const [])
      _item(source, '${(raw as Map)['topic_id']}', '${raw['topic_name'] ?? ''}', '${raw['topic_url'] ?? ''}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _toutiao(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc');
  return [
    for (final raw in (json as Map)['data'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['ClusterIdStr']}',
        '${raw['Title'] ?? ''}',
        'https://www.toutiao.com/trending/${raw['ClusterIdStr']}/',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _thepaper(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://cache.thepaper.cn/contentapi/wwwIndex/rightSidebar');
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['hotNews'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['contId']}',
        '${raw['name'] ?? ''}',
        'https://www.thepaper.cn/newsDetail_forward_${raw['contId']}',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _sputnik(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://sputniknews.cn/services/widget/lenta/');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.lenta__item')) {
    final a = el.querySelector('a');
    final href = a?.attributes['href'] ?? '';
    final title = a?.querySelector('.lenta__item-text')?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href.startsWith('http') ? href : 'https://sputniknews.cn$href'));
  }
  return items;
}

Future<List<NewsItem>> _cankaoxiaoxi(FetchClient client, SourceDef source) async {
  final items = <NewsItem>[];
  for (final ch in ['zhongguo', 'guandian', 'gj']) {
    final json = await client.getJson('http://china.cankaoxiaoxi.com/json/channel/$ch/list.json');
    for (final raw in (json as Map)['list'] as List? ?? const []) {
      final data = (raw as Map)['data'] as Map? ?? const {};
      items.add(_item(source, '${data['id']}', '${data['title'] ?? ''}', '${data['url'] ?? ''}', pub: DateTime.tryParse('${data['publishTime'] ?? ''}')));
    }
  }
  return items.where((e) => e.title.isNotEmpty).toList();
}

Future<Map<String, String>> _clsQuery([Map<String, String>? extra]) async {
  final params = {
    'appName': 'CailianpressWeb',
    'os': 'web',
    'sv': '7.7.5',
    ...?extra,
  };
  final keys = params.keys.toList()..sort();
  final raw = [for (final k in keys) '$k=${params[k]}'].join('&');
  final sign = md5.convert(utf8.encode(sha1.convert(utf8.encode(raw)).toString())).toString();
  return {...params, 'sign': sign};
}

String _qs(Map<String, String> q) => q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');

Future<List<NewsItem>> _clsTelegraph(FetchClient client, SourceDef source) async {
  final q = await _clsQuery({
    'last_time': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    'refresh_type': '1',
    'rn': '30',
  });
  final json = await client.getJson('https://www.cls.cn/v1/roll/get_roll_list?${_qs(q)}', headers: {
    'Referer': 'https://www.cls.cn/telegraph',
  });
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['roll_data'] as List? ?? const [])
      if ((raw as Map)['is_ad'] != 1)
        _item(source, '${raw['id']}', '${raw['title'] ?? raw['brief'] ?? ''}', 'https://www.cls.cn/detail/${raw['id']}', pub: _ms(raw['ctime'])),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _clsDepth(FetchClient client, SourceDef source) async {
  final q = await _clsQuery();
  final json = await client.getJson('https://www.cls.cn/v3/depth/home/assembled/1000?${_qs(q)}');
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['depth_list'] as List? ?? const [])
      _item(source, '${(raw as Map)['id']}', '${raw['title'] ?? raw['brief'] ?? ''}', 'https://www.cls.cn/detail/${raw['id']}', pub: _ms(raw['ctime'])),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _clsHot(FetchClient client, SourceDef source) async {
  final q = await _clsQuery();
  final json = await client.getJson('https://www.cls.cn/v2/article/hot/list?${_qs(q)}');
  return [
    for (final raw in (json as Map)['data'] as List? ?? const [])
      _item(source, '${(raw as Map)['id']}', '${raw['title'] ?? raw['brief'] ?? ''}', 'https://www.cls.cn/detail/${raw['id']}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _xueqiu(FetchClient client, SourceDef source) async {
  final cookie = await client.cookieFrom('https://xueqiu.com/hq');
  final json = await client.getJson(
    'https://stock.xueqiu.com/v5/stock/hot_stock/list.json?size=30&_type=10&type=10',
    headers: {if (cookie.isNotEmpty) 'Cookie': cookie, 'Referer': 'https://xueqiu.com/'},
  );
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['items'] as List? ?? const [])
      if ((raw as Map)['ad'] != 1)
        _item(source, '${raw['code']}', '${raw['name'] ?? ''}', 'https://xueqiu.com/s/${raw['code']}', summary: '${raw['percent']}% ${raw['exchange'] ?? ''}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _gelonghui(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.gelonghui.com/news/');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.article-content')) {
    final a = el.querySelector('.detail-right > a');
    final href = a?.attributes['href'] ?? '';
    final title = a?.querySelector('h2')?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href.startsWith('http') ? href : 'https://www.gelonghui.com$href'));
  }
  return items;
}

Future<List<NewsItem>> _fastbullExpress(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.fastbull.com/cn/express-news');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.news-list')) {
    final href = el.querySelector('[data-href]')?.attributes['data-href'] ?? el.querySelector('[data-id]')?.attributes['data-id'] ?? '';
    final titleText = el.querySelector('.title_name')?.text.trim() ?? '';
    if (href.isEmpty || titleText.isEmpty) continue;
    final path = href.startsWith('/') ? href : '/cn/fastshort/$href';
    items.add(_item(source, href, titleText, 'https://www.fastbull.com$path'));
  }
  return items;
}

Future<List<NewsItem>> _fastbullNews(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.fastbull.com/cn/news');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final a in doc.querySelectorAll('.trending_type')) {
    final href = a.attributes['href'] ?? '';
    final title = a.querySelector('.title')?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href.startsWith('http') ? href : 'https://www.fastbull.com$href'));
  }
  return items;
}

Future<List<NewsItem>> _github(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://github.com/trending?spoken_language_code=');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('article')) {
    final a = el.querySelector('h2 a');
    final href = a?.attributes['href'] ?? '';
    final title = a?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, 'https://github.com$href', summary: el.querySelector('p')?.text.trim() ?? ''));
  }
  return items;
}

Future<List<NewsItem>> _biliSearch(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://s.search.bilibili.com/main/hotword?limit=30');
  return [
    for (final raw in (json as Map)['list'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['keyword']}',
        '${raw['show_name'] ?? raw['keyword'] ?? ''}',
        'https://search.bilibili.com/all?keyword=${Uri.encodeComponent('${raw['keyword'] ?? ''}')}',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _biliVideo(FetchClient client, SourceDef source, String url) async {
  final json = await client.getJson(url);
  return [
    for (final raw in ((json as Map)['data'] as Map?)?['list'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['bvid']}',
        '${raw['title'] ?? ''}',
        'https://www.bilibili.com/video/${raw['bvid']}',
        summary: '${raw['desc'] ?? ''}',
        pub: _ms(raw['pubdate']),
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _kuaishou(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.kuaishou.com/?isHome=1');
  final match = RegExp(r'window\.__APOLLO_STATE__\s*=\s*(\{.+?\});').firstMatch(html);
  if (match == null) throw Exception('kuaishou apollo missing');
  final data = jsonDecode(match.group(1)!) as Map;
  final root = (data['defaultClient'] as Map?)?['ROOT_QUERY'] as Map? ?? const {};
  final rank = root['visionHotRank({"page":"home"})'] as Map? ?? const {};
  final rankId = '${rank['id'] ?? ''}';
  final hot = (data['defaultClient'] as Map?)?[rankId] as Map? ?? const {};
  final items = <NewsItem>[];
  for (final raw in hot['items'] as List? ?? const []) {
    final id = '${(raw as Map)['id'] ?? ''}';
    final node = (data['defaultClient'] as Map?)?[id] as Map? ?? const {};
    if (node['tagType'] == '置顶') continue;
    final name = '${node['name'] ?? ''}';
    if (name.isEmpty) continue;
    items.add(_item(source, id.replaceFirst('VisionHotRankItem:', ''), name, 'https://www.kuaishou.com/search/video?searchKey=${Uri.encodeComponent(name)}'));
  }
  return items;
}

Future<List<NewsItem>> _jin10(FetchClient client, SourceDef source) async {
  final raw = await client.getText('https://www.jin10.com/flash_newest.js?t=${DateTime.now().millisecondsSinceEpoch}');
  final jsonStr = raw.replaceFirst(RegExp(r'^var\s+newest\s*=\s*'), '').replaceFirst(RegExp(r';*$'), '').trim();
  final list = jsonDecode(jsonStr) as List;
  final items = <NewsItem>[];
  for (final rawItem in list) {
    final m = rawItem as Map;
    final channel = m['channel'] as List? ?? const [];
    if (channel.contains(5)) continue;
    final data = m['data'] as Map? ?? const {};
    var text = '${data['title'] ?? data['content'] ?? ''}'.replaceAll(RegExp(r'</?b>'), '');
    if (text.isEmpty) continue;
    items.add(_item(source, '${m['id']}', text, 'https://flash.jin10.com/detail/${m['id']}'));
  }
  return items;
}

Future<List<NewsItem>> _baidu(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://top.baidu.com/board?tab=realtime');
  final match = RegExp(r'<!--s-data:(.*?)-->', dotAll: true).firstMatch(html);
  if (match == null) throw Exception('baidu s-data missing');
  final data = jsonDecode(match.group(1)!) as Map;
  final content = (((data['data'] as Map?)?['cards'] as List?)?.first as Map?)?['content'] as List? ?? const [];
  return [
    for (final raw in content)
      if ((raw as Map)['isTop'] != true)
        _item(source, '${raw['rawUrl']}', '${raw['word'] ?? ''}', '${raw['rawUrl'] ?? ''}', summary: '${raw['desc'] ?? ''}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _nowcoder(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://gw-c.nowcoder.com/api/sparta/hot-search/top-hot-pc?size=20&_=${DateTime.now().millisecondsSinceEpoch}&t=');
  final items = <NewsItem>[];
  for (final raw in ((json as Map)['data'] as Map?)?['result'] as List? ?? const []) {
    final m = raw as Map;
    final type = m['type'];
    final id = type == 74 ? '${m['uuid']}' : '${m['id']}';
    final url = type == 74 ? 'https://www.nowcoder.com/feed/main/detail/${m['uuid']}' : 'https://www.nowcoder.com/discuss/${m['id']}';
    items.add(_item(source, id, '${m['title'] ?? ''}', url));
  }
  return items.where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _ifeng(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.ifeng.com/');
  final match = RegExp(r'var\s+allData\s*=\s*(\{[\s\S]*?\});').firstMatch(html);
  if (match == null) throw Exception('ifeng allData missing');
  final data = jsonDecode(match.group(1)!) as Map;
  return [
    for (final raw in data['hotNews1'] as List? ?? const [])
      _item(source, '${(raw as Map)['url']}', '${raw['title'] ?? ''}', '${raw['url'] ?? ''}'),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _chongbuluoHot(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://www.chongbuluo.com/forum.php?mod=guide&view=hot');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final el in doc.querySelectorAll('.bmw table tr')) {
    final title = el.querySelector('.common .xst')?.text.trim() ?? '';
    final href = el.querySelector('.common a')?.attributes['href'] ?? '';
    if (title.isEmpty || href.isEmpty) continue;
    final url = href.startsWith('http') ? href : 'https://www.chongbuluo.com/$href';
    items.add(_item(source, url, title, url));
  }
  return items;
}

Future<List<NewsItem>> _douban(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://m.douban.com/rexxar/api/v2/subject/recent_hot/movie', headers: {
    'Referer': 'https://movie.douban.com/',
    'Accept': 'application/json, text/plain, */*',
  });
  return [
    for (final raw in (json as Map)['items'] as List? ?? const [])
      _item(
        source,
        '${(raw as Map)['id']}',
        '${raw['title'] ?? ''}',
        'https://movie.douban.com/subject/${raw['id']}',
        summary: '${raw['card_subtitle'] ?? ''}',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _steam(FetchClient client, SourceDef source) async {
  final html = await client.getText('https://store.steampowered.com/stats/stats/');
  final doc = html_parser.parse(html);
  final items = <NewsItem>[];
  for (final row in doc.querySelectorAll('#detailStats tr.player_count_row')) {
    final a = row.querySelector('a.gameLink');
    final href = a?.attributes['href'] ?? '';
    final title = a?.text.trim() ?? '';
    if (href.isEmpty || title.isEmpty) continue;
    items.add(_item(source, href, title, href, summary: row.querySelector('td .currentServers')?.text.trim() ?? ''));
  }
  return items;
}

Future<List<NewsItem>> _tencent(FetchClient client, SourceDef source) async {
  final json = await client.getJson('https://i.news.qq.com/web_backend/v2/getTagInfo?tagId=aEWqxLtdgmQ%3D', headers: {
    'Referer': 'https://news.qq.com/',
  });
  final tabs = ((json as Map)['data'] as Map?)?['tabs'] as List? ?? const [];
  final list = tabs.isEmpty ? const [] : (tabs.first as Map)['articleList'] as List? ?? const [];
  return [
    for (final raw in list)
      _item(
        source,
        '${(raw as Map)['id']}',
        '${raw['title'] ?? ''}',
        '${((raw['link_info'] as Map?)?['url']) ?? ''}',
        summary: '${raw['desc'] ?? ''}',
      ),
  ].where((e) => e.title.isNotEmpty && e.url.isNotEmpty).toList();
}

Future<List<NewsItem>> _qqvideo(FetchClient client, SourceDef source) async {
  final json = await client.postJson(
    'https://pbaccess.video.qq.com/trpc.vector_layout.page_view.PageService/getCard?video_appid=3000010&vversion_platform=2',
    {
      'page_params': {
        'rank_channel_id': '100113',
        'rank_name': 'HotSearch',
        'rank_page_size': '30',
        'tab_name': '热搜榜',
        'tab_type': 'hot_rank',
        'page_id': 'scms_shake',
        'page_type': 'scms_shake',
      },
      'page_context': {'page_index': '1'},
    },
    headers: {'Referer': 'https://v.qq.com/'},
  );
  final cards = (((((((json as Map)['data'] as Map?)?['card'] as Map?)?['children_list'] as Map?)?['list'] as Map?)?['cards']) as List?) ?? const [];
  return [
    for (final raw in cards)
      _item(
        source,
        '${(raw as Map)['id']}',
        '${(raw['params'] as Map?)?['title'] ?? ''}',
        'https://v.qq.com/x/cover/${raw['id']}.html',
        summary: '${(raw['params'] as Map?)?['sub_title'] ?? ''}',
      ),
  ].where((e) => e.title.isNotEmpty).toList();
}

Future<List<NewsItem>> _iqiyi(FetchClient client, SourceDef source) async {
  final json = await client.getJson(
    'https://mesh.if.iqiyi.com/portal/lw/v7/channel/card/videoTab?channelName=recommend&data_source=v7_rec_sec_hot_rank_list&tempId=85&count=30&block_id=hot_ranklist&device=14a4b5ba98e790dce6dc07482447cf48&from=webapp',
    headers: {'Referer': 'https://www.iqiyi.com'},
  );
  final videos = (((json as Map)['items'] as List?)?.first as Map?)?['video'] as List? ?? const [];
  final data = videos.isEmpty ? const [] : (videos.first as Map)['data'] as List? ?? const [];
  return [
    for (final raw in data)
      _item(
        source,
        '${(raw as Map)['entity_id']}',
        '${raw['title'] ?? ''}',
        '${raw['page_url'] ?? ''}',
        summary: '${raw['desc'] ?? raw['description'] ?? ''}',
      ),
  ].where((e) => e.title.isNotEmpty && e.url.isNotEmpty).toList();
}
