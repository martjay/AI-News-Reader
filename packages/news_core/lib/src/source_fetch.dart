import 'package:xml/xml.dart';

import 'article_id.dart';
import 'fetch_client.dart';
import 'models.dart';
import 'newsnow_fetch.dart';

class SourceFetcher {
  SourceFetcher({FetchClient? client}) : client = client ?? FetchClient();

  final FetchClient client;

  Future<SourceFetchResult> fetch(SourceDef source) async {
    final started = DateTime.now();
    try {
      List<NewsItem> items;
      switch (source.type) {
        case SourceType.rss:
          items = await _rss(source);
        case SourceType.sspai:
          items = await _sspai(source);
        case SourceType.juejin:
          items = await _juejin(source);
        case SourceType.hfPapers:
          items = await _hfPapers(source);
        case SourceType.kr36:
          items = await _kr36(source);
        case SourceType.hot:
          items = await fetchNewsnow(client, source);
      }
      final capped = items.take(40).toList();
      return SourceFetchResult(
        sourceId: source.id,
        status: capped.isEmpty ? 'empty' : 'ok',
        updatedAt: started,
        items: capped,
        error: capped.isEmpty ? 'No items' : null,
      );
    } catch (e) {
      return SourceFetchResult(
        sourceId: source.id,
        status: 'error',
        updatedAt: started,
        error: e.toString(),
      );
    }
  }

  Future<List<NewsItem>> _rss(SourceDef source) async {
    final urls = [
      source.url,
      if (source.fallbackUrl.trim().isNotEmpty) source.fallbackUrl.trim(),
    ];
    Object? last;
    for (final url in urls) {
      try {
        return await _rssFromUrl(source, url);
      } catch (e) {
        last = e;
      }
    }
    throw last ?? Exception('RSS failed for ${source.id}');
  }

  Future<List<NewsItem>> _rssFromUrl(SourceDef source, String feedUrl) async {
    final xmlText = await client.getText(feedUrl);
    final lead = xmlText.trimLeft();
    if (lead.startsWith('<!DOCTYPE') || lead.toLowerCase().startsWith('<html')) {
      throw Exception('Expected RSS, got HTML from $feedUrl');
    }
    final doc = XmlDocument.parse(xmlText);
    final items = <NewsItem>[];
    final rssItems = doc.findAllElements('item');
    if (rssItems.isNotEmpty) {
      for (final node in rssItems) {
        final title = _text(node, 'title');
        final link = _text(node, 'link');
        if (title.isEmpty || link.isEmpty) continue;
        items.add(makeItem(
          sourceId: source.id,
          title: _strip(title),
          url: link.trim(),
          summary: _strip(_text(node, 'description')),
          pubDate: _date(_text(node, 'pubDate')),
        ));
      }
      return items;
    }
    for (final node in doc.findAllElements('entry')) {
      final title = _text(node, 'title');
      var link = '';
      for (final l in node.findElements('link')) {
        link = l.getAttribute('href') ?? l.innerText;
        if (link.isNotEmpty) break;
      }
      if (title.isEmpty || link.isEmpty) continue;
      items.add(makeItem(
        sourceId: source.id,
        title: _strip(title),
        url: link.trim(),
        summary: _strip(_text(node, 'summary').isEmpty ? _text(node, 'content') : _text(node, 'summary')),
        pubDate: _date(_text(node, 'updated').isEmpty ? _text(node, 'published') : _text(node, 'updated')),
      ));
    }
    return items;
  }

  Future<List<NewsItem>> _sspai(SourceDef source) async {
    final url = source.url.contains('created_at=')
        ? source.url
        : '${source.url}${source.url.contains('?') ? '&' : '?'}created_at=${DateTime.now().millisecondsSinceEpoch}';
    final json = await client.getJson(url);
    final data = (json as Map)['data'] as List? ?? const [];
    return [
      for (final raw in data)
        makeItem(
          sourceId: source.id,
          title: (raw as Map)['title'] as String? ?? '',
          url: 'https://sspai.com/post/${raw['id']}',
          summary: (raw['summary'] as String?) ?? '',
          pubDate: raw['released_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch((raw['released_time'] as num).toInt() * 1000)
              : null,
        ),
    ].where((e) => e.title.isNotEmpty).toList();
  }

  Future<List<NewsItem>> _juejin(SourceDef source) async {
    final json = await client.getJson(source.url);
    final data = (json as Map)['data'] as List? ?? const [];
    return [
      for (final raw in data)
        makeItem(
          sourceId: source.id,
          title: ((raw as Map)['content'] as Map?)?['title'] as String? ?? '',
          url: 'https://juejin.cn/post/${(raw['content'] as Map?)?['content_id']}',
        ),
    ].where((e) => e.title.isNotEmpty && e.url.contains('/post/') && !e.url.endsWith('/post/')).toList();
  }

  Future<List<NewsItem>> _kr36(SourceDef source) async {
    final json = await client.postJson(source.url, {
      'partner_id': 'wap',
      'param': {'siteId': 1, 'platformId': 2},
    });
    final list = (((json as Map)['data'] as Map?)?['hotRankList'] as List?) ?? const [];
    final items = <NewsItem>[];
    for (final raw in list) {
      final map = raw as Map;
      final id = '${map['itemId'] ?? ''}';
      final material = map['templateMaterial'] as Map? ?? const {};
      final title = '${material['widgetTitle'] ?? ''}';
      if (id.isEmpty || title.isEmpty) continue;
      final ms = map['publishTime'] ?? material['publishTime'];
      items.add(makeItem(
        sourceId: source.id,
        title: title,
        url: 'https://www.36kr.com/p/$id',
        summary: '${material['widgetContent'] ?? ''}',
        pubDate: ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null,
      ));
    }
    return items;
  }

  Future<List<NewsItem>> _hfPapers(SourceDef source) async {
    final json = await client.getJson(source.url);
    final list = json as List? ?? const [];
    final items = <NewsItem>[];
    for (final raw in list) {
      final map = raw as Map;
      final paper = map['paper'] as Map? ?? map;
      final id = '${paper['id'] ?? map['paperId'] ?? ''}';
      final title = '${paper['title'] ?? ''}';
      if (id.isEmpty || title.isEmpty) continue;
      items.add(makeItem(
        sourceId: source.id,
        title: title,
        url: 'https://huggingface.co/papers/$id',
        summary: '${paper['summary'] ?? ''}',
        pubDate: DateTime.tryParse('${map['publishedAt'] ?? paper['publishedAt'] ?? ''}'),
      ));
    }
    return items;
  }

  String _text(XmlElement node, String name) {
    final els = node.findElements(name);
    if (els.isEmpty) return '';
    return els.first.innerText;
  }

  String _strip(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _date(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toLocal();
    return parseRssDate(raw);
  }
}

DateTime? parseRssDate(String raw) {
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  final re = RegExp(
    r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?',
  );
  final m = re.firstMatch(raw);
  if (m == null) return null;
  final month = months[m.group(2)!.toLowerCase()];
  if (month == null) return null;
  return DateTime.utc(
    int.parse(m.group(3)!),
    month,
    int.parse(m.group(1)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
    int.parse(m.group(6) ?? '0'),
  ).toLocal();
}

