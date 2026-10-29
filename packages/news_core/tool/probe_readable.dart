import 'dart:io';

import 'package:news_core/news_core.dart';

Future<void> main(List<String> args) async {
  final proxy = await applyFetchProxy(useSystem: true, manual: '');
  stdout.writeln('proxy=$proxy');
  if (args.isNotEmpty && args.first.startsWith('http')) {
    final client = FetchClient(timeout: const Duration(seconds: 20));
    for (final url in args) {
      stdout.writeln('\n== $url ==');
      try {
        final article = await fetchReadable(client, url, preferRemote: true);
        stdout.writeln('status=${article.status} chars=${article.text.length}');
      } catch (e) {
        stdout.writeln('ERR $e');
      }
    }
    client.close();
    return;
  }
  if (args.isNotEmpty) {
    final yaml = await File('../../config/sources.yaml').readAsString();
    final catalog = SourceCatalog.parse(yaml);
    final fetcher = SourceFetcher(client: FetchClient(timeout: const Duration(seconds: 20)));
    for (final id in args) {
      SourceDef? source;
      for (final item in catalog.enabled) {
        if (item.id == id) {
          source = item;
          break;
        }
      }
      if (source == null) {
        stdout.writeln('NO_SOURCE $id');
        continue;
      }
      final feed = await fetcher.fetch(source);
      stdout.writeln('\n== ${source.id} feed=${feed.status} n=${feed.items.length} ==');
      if (feed.items.isEmpty) continue;
      final pick = feed.items.firstWhere((e) => e.url.startsWith('http'), orElse: () => feed.items.first);
      stdout.writeln('url ${pick.url} seed=${pick.summary.length}');
      final article = await fetchReadable(
        fetcher.client,
        pick.url,
        seedHtml: pick.summary,
        preferRemote: true,
      );
      stdout.writeln('status=${article.status} chars=${article.text.length}');
    }
    fetcher.client.close();
    return;
  }
  final yaml = await File('../../config/sources.yaml').readAsString();
  final catalog = SourceCatalog.parse(yaml);
  final fetcher = SourceFetcher(client: FetchClient(timeout: const Duration(seconds: 12)));

  for (final source in catalog.enabled) {
    stdout.writeln('\n== ${source.id} (${source.type.name}) ==');
    final feed = await fetcher.fetch(source);
    if (feed.status != 'ok' || feed.items.isEmpty) {
      stdout.writeln('FEED ${feed.status} ${feed.error ?? ''}');
      continue;
    }
    NewsItem? pick;
    for (final item in feed.items) {
      if (item.url.startsWith('http')) {
        pick = item;
        break;
      }
    }
    if (pick == null) {
      stdout.writeln('NO_URL');
      continue;
    }
    stdout.writeln('item ${pick.title.replaceAll('\n', ' ')}');
    stdout.writeln('url  ${pick.url}');
    try {
      final article = await fetchReadable(
        fetcher.client,
        pick.url,
        seedHtml: pick.summary,
        preferRemote: true,
      );
      final text = article.text.trim();
      final paras = splitReaderParagraphs(text);
      stdout.writeln('status=${article.status} chars=${text.length} paras=${paras.length} site=${siteForUrl(pick.url)?.id}');
      final preview = paras.take(3).join(' | ').replaceAll('\n', ' ');
      stdout.writeln('head ${preview.length > 280 ? preview.substring(0, 280) : preview}');
      if (paras.length > 3) {
        final tail = paras.last.replaceAll('\n', ' ');
        stdout.writeln('tail ${tail.length > 160 ? tail.substring(0, 160) : tail}');
      }
    } catch (e) {
      stdout.writeln('ERR $e');
    }
  }
  fetcher.client.close();
}
