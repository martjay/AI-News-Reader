import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'fetch_client.dart';
import 'readable_sites.dart';

class ReadableArticle {
  const ReadableArticle({
    required this.text,
    this.status = 'ok',
  });

  final String text;
  final String status;

  bool get ok => status == 'ok' && text.trim().length >= 80;

  static const empty = ReadableArticle(text: '', status: 'empty');
}

final _imageMarkdown = RegExp(r'^!\[[^\]]*\]\((https?:[^)\s]+)\)$');

String? readerImageUrl(String line) {
  final m = _imageMarkdown.firstMatch(line.trim());
  return m?.group(1);
}

bool isReaderImageLine(String line) => readerImageUrl(line) != null;

String plaintextFromHtml(String raw, {String url = ''}) {
  if (raw.trim().isEmpty) return '';
  final decoded = raw
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  return extractReadableHtml(decoded, url: url);
}

String extractReadableHtml(String html, {String url = ''}) {
  final site = siteForUrl(url);
  final extraNoise = site?.noise ?? const <RegExp>[];
  final document = html_parser.parse(html);
  for (final tag in ['script', 'style', 'noscript', 'iframe', 'svg', 'form', 'button', 'nav', 'footer', 'aside', 'header']) {
    document.querySelectorAll(tag).forEach((node) => node.remove());
  }
  final removeSel = [
    '[class*="footer"], [id*="footer"], [class*="copyright"], [class*="breadcrumb"], [class*="share"], [class*="icp"], [class*="sitemap"], [class*="comment"], '
        '#Bottom, #Rightbar, #Sidebar, #Top, [id*="rightbar"], [id*="sidebar"], [class*="sidebar"], [class*="site-nav"], '
        '[class*="recommend"], [class*="related"], [class*="subscribe"], [class*="newsletter"], [class*="hot-news"], '
        '[class*="hot_news"], [class*="advert"], [class*="ad-"], .ads, .ad, [class*="paywall"], [class*="cookie"]',
    if (site != null) ...site.remove,
  ].join(', ');
  for (final node in document.querySelectorAll(removeSel)) {
    node.remove();
  }

  const generic = [
    '.topic_content',
    '.markdown_body',
    '.markdown-body',
    'article',
    '[itemprop="articleBody"]',
    '.article-content',
    '.post-content',
    '.entry-content',
    '.post-body',
    '.article__content',
    '.news-content',
    '.article-detail',
    '.detail-content',
  ];
  final targets = [
    ...?site?.selectors,
    ...generic,
  ];

  String best = '';
  var usedSiteSelector = false;
  if (site != null) {
    for (final selector in site.selectors) {
      for (final node in document.querySelectorAll(selector)) {
        final text = _blocksFromElement(node, extraNoise: extraNoise, url: url);
        if (_readableScore(text, extraNoise: extraNoise) > _readableScore(best, extraNoise: extraNoise)) {
          best = text;
          usedSiteSelector = best.length >= 80;
        }
      }
    }
  }
  if (!usedSiteSelector || best.length < 160) {
    for (final selector in targets) {
      for (final node in document.querySelectorAll(selector)) {
        final text = _blocksFromElement(node, extraNoise: extraNoise, url: url);
        if (_readableScore(text, extraNoise: extraNoise) > _readableScore(best, extraNoise: extraNoise)) best = text;
      }
    }
  }

  if (best.length < 160) {
    for (final node in document.querySelectorAll('main')) {
      final text = _blocksFromElement(node, extraNoise: extraNoise, url: url);
      if (_readableScore(text, extraNoise: extraNoise) > _readableScore(best, extraNoise: extraNoise)) best = text;
    }
  }
  if (best.length < 120) {
    final fromP = _blocksFromElement(document.body, extraNoise: extraNoise, url: url);
    if (_readableScore(fromP, extraNoise: extraNoise) > _readableScore(best, extraNoise: extraNoise)) {
      best = fromP;
    }
  }

  return best.trim();
}

int _readableScore(String text, {List<RegExp> extraNoise = const []}) {
  if (text.isEmpty || looksUnreadable(text)) return 0;
  final lines = text.split(RegExp(r'\n+')).where((e) => e.trim().isNotEmpty).toList();
  var noise = 0;
  var content = 0;
  for (final line in lines) {
    if (_noiseLine(line, extraNoise: extraNoise)) {
      noise += line.length;
    } else {
      content += line.length;
    }
  }
  return content + lines.length * 40 - noise * 3;
}

String _imageSrc(Element img, String pageUrl) {
  final raw = (img.attributes['src'] ??
          img.attributes['data-src'] ??
          img.attributes['data-original'] ??
          '')
      .trim();
  var src = raw;
  final srcset = img.attributes['srcset'] ?? img.attributes['data-srcset'] ?? '';
  if (src.isEmpty && srcset.isNotEmpty) {
    src = srcset.split(',').map((e) => e.trim().split(' ').first).lastWhere((e) => e.isNotEmpty, orElse: () => '');
  }
  if (src.isEmpty || src.startsWith('data:')) return '';
  try {
    src = (pageUrl.isEmpty ? Uri.parse(src) : Uri.parse(pageUrl).resolve(src)).toString();
  } catch (_) {
    return '';
  }
  if (!src.startsWith('http')) return '';
  if (RegExp(r'(1x1|pixel|spacer|gravatar|emoji|favicon)', caseSensitive: false).hasMatch(src)) {
    return '';
  }
  final w = int.tryParse(img.attributes['width'] ?? '');
  final h = int.tryParse(img.attributes['height'] ?? '');
  if (w != null && h != null && w <= 8 && h <= 8) return '';
  return src;
}

String _blocksFromElement(Element? node, {List<RegExp> extraNoise = const [], String url = ''}) {
  if (node == null) return '';
  final buf = StringBuffer();
  var lastNl = true;
  void nl() {
    if (!lastNl) {
      buf.write('\n');
      lastNl = true;
    }
  }

  void walk(Node current) {
    if (current is Text) {
      final t = current.text;
      if (t.trim().isEmpty) {
        if (t.contains('\n')) nl();
        return;
      }
      buf.write(t);
      lastNl = t.endsWith('\n');
      return;
    }
    if (current is! Element) return;
    final tag = current.localName ?? '';
    if (const {'script', 'style', 'noscript', 'iframe', 'svg', 'form', 'button', 'nav', 'footer', 'aside', 'header'}.contains(tag)) {
      return;
    }
    if (tag == 'img') {
      final src = _imageSrc(current, url);
      if (src.isEmpty) return;
      nl();
      buf.write('![image]($src)');
      nl();
      return;
    }
    final isBlock = const {
      'p', 'div', 'section', 'article', 'li', 'blockquote', 'tr', 'br', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'figcaption', 'figure',
    }.contains(tag);
    if (isBlock) nl();
    for (final child in current.nodes) {
      walk(child);
    }
    if (isBlock) {
      nl();
    } else if (buf.isNotEmpty && !lastNl) {
      buf.write(' ');
    }
  }

  walk(node);
  return _blocks(buf.toString(), extraNoise: extraNoise);
}

String _blocks(String raw, {List<RegExp> extraNoise = const []}) {
  final lines = raw
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.replaceAll(RegExp(r'\s+'), ' ').trim())
      .map(_unwrapTitlePrefix)
      .expand(_breakReadOriginal)
      .map((e) => e.trim())
      .where((e) => e.length >= 12 || isReaderImageLine(e))
      .where((e) => !_noiseLine(e, extraNoise: extraNoise));
  return lines.join('\n\n');
}

Iterable<String> _breakReadOriginal(String line) {
  var t = line.trim();
  if (t.isEmpty) return const [];
  final hasSource = RegExp(
    r'阅读原文|查看原文|原文链接|Read original|via\s+\S+',
    caseSensitive: false,
  ).hasMatch(t);
  String? href;
  if (hasSource) {
    final url = RegExp(r'(https?://\S+)\s*$', caseSensitive: false).firstMatch(t);
    if (url != null) {
      href = url.group(1);
      t = t.substring(0, url.start).trim();
      t = t.replaceFirst(RegExp(r'[·•|]\s*$'), '').trim();
    }
  }
  t = t.replaceAll(RegExp('[🔗📎]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  t = t.replaceAll(
    RegExp(r'\s+(?=(阅读原文|查看原文|原文链接|Read original))', caseSensitive: false),
    '\n\n',
  );
  final out = t
      .split(RegExp(r'\n+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (href != null) out.add('🔗 $href');
  return out;
}

String _unwrapTitlePrefix(String line) {
  final m = RegExp(r'^Title:\s+(.+)$', caseSensitive: false).firstMatch(line);
  return m == null ? line : m.group(1)!.trim();
}

bool _markdownNavLine(String t) {
  if (RegExp(r'^\[\]\([^)]+\)\s*$').hasMatch(t)) return true;
  if (RegExp(r'^\*+\s*\[[^\]]*]\([^)]+\)\s*$').hasMatch(t)) return true;
  if (RegExp(r'^\[[^\]]{1,20}]\(https?:[^)]+\)\s*$').hasMatch(t)) return true;
  return false;
}

String cleanReadableMarkdown(String md, {List<RegExp> extraNoise = const []}) {
  final stripped = md.replaceAllMapped(
    RegExp(r'!\[[^\]]*]\(([^)]+)\)'),
    (m) {
      final src = m.group(1)!.trim();
      if (src.startsWith('http')) return '![image]($src)';
      return '';
    },
  );
  final titleBits = <String>[];
  final bodyBits = <String>[];
  for (final raw in stripped.split(RegExp(r'\r?\n'))) {
    final t = raw.trim();
    if (t.isEmpty) continue;
    final title = RegExp(r'^Title:\s*(.+)$', caseSensitive: false).firstMatch(t);
    if (title != null) {
      final value = title.group(1)!.trim();
      if (value.isNotEmpty) titleBits.add(value);
      continue;
    }
    if (RegExp(
      r'^(URL Source|Published Time|Markdown Content|Warning)\s*:',
      caseSensitive: false,
    ).hasMatch(t)) {
      continue;
    }
    if (_markdownNavLine(t)) continue;
    bodyBits.add(t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1)!));
  }
  final body = _blocks(bodyBits.join('\n'), extraNoise: extraNoise);
  if (body.length >= 80) return body;
  final fromTitle = _blocks(titleBits.join('\n'), extraNoise: extraNoise);
  return fromTitle.length >= body.length ? fromTitle : body;
}

bool _noiseLine(String line, {List<RegExp> extraNoise = const []}) {
  final t = line.trim();
  if (isReaderImageLine(t)) return false;
  if (t.length < 12) return true;
  for (final re in extraNoise) {
    if (re.hasMatch(t) && t.length < 72) return true;
  }
  if (RegExp(r'^(分享|关注|登录|注册|导读|AI评分|相关阅读|打开原站|评论|收藏|展开全文|点击加载)').hasMatch(t)) return true;
  if (RegExp(r'扫描二维码|下载.*APP|打开APP|未经授权不得转载|责任编辑[：:]|获授权转载|观点归原作者所有').hasMatch(t) &&
      t.length < 200) {
    return true;
  }
  if (RegExp(r'增值电信业务').hasMatch(t)) return true;
  if (RegExp(r'^首页\s*[>›]|Back to Articles|Collections mentioned|News from Google collection').hasMatch(t) &&
      t.length < 160) {
    return true;
  }
  if (RegExp(r'(^|\s)#[^\s#]{1,24}').allMatches(t).length >= 2 && t.length < 80) return true;
  if (RegExp(r'^\d{1,2}月\d{1,2}日').hasMatch(t) && t.length < 40) return true;
  if (RegExp(
    r'^(Subscribe|Sign up|Read more|Also Read|Related (Stories|Articles)|Follow us|Cookie)\b',
    caseSensitive: false,
  ).hasMatch(t)) {
    return true;
  }
  if (RegExp(r'The post .+ appeared first on', caseSensitive: false).hasMatch(t)) return true;
  if (RegExp(r'关于我们|网站声明|联系方式|用户反馈|网站地图|友情链接|帮助中心').hasMatch(t)) return true;
  if (RegExp(r'举报电话|举报邮箱|版权所有|著作权|备案号|ICP备|公网安备|互联网新闻信息服务').hasMatch(t)) return true;
  if (RegExp(r'京ICP|沪ICP|粤ICP|浙ICP|苏ICP|京公网安备|沪公网').hasMatch(t)) return true;
  if (RegExp(r'本文已被查看|常见问题|点击这里|新浪微博分享|微信扫一扫').hasMatch(t)) return true;
  if (RegExp(r'请不要在回答技术问题|复制粘贴 AI|AI 生成的内容').hasMatch(t)) return true;
  if (RegExp(r'^(URL Source|Published Time|Markdown Content|Warning)\s*:', caseSensitive: false).hasMatch(t)) {
    return true;
  }
  if (_markdownNavLine(t)) return true;
  if (RegExp(
    r'No Comments Yet|powered by|Select Language|Online Highest|Do have faith',
    caseSensitive: false,
  ).hasMatch(t)) {
    return true;
  }
  if (RegExp(r'^VERSION\s*:', caseSensitive: false).hasMatch(t)) return true;
  if (RegExp(r'\bUTC\s+\d{1,2}:\d{2}\b').hasMatch(t) && t.length < 160) return true;
  if (RegExp(r'(Just Now|\d+\s*(views|replies|comments))\b', caseSensitive: false).hasMatch(t) && t.length < 80) {
    return true;
  }
  if (RegExp(
    r'\b(About|Help|Advertise|Privacy|FAQ|Terms|API|Blog)\b.*\b(About|Help|Advertise|Privacy|FAQ|Terms|API|Blog)\b',
    caseSensitive: false,
  ).hasMatch(t)) {
    return true;
  }
  if (RegExp(r'^https?://\S+$').hasMatch(t)) return true;
  if (RegExp(r'^\d{4}[-年/]\d{1,2}[-月/]\d{1,2}').hasMatch(t) && t.length < 48) return true;
  if (RegExp(r'editor@|copyright|©|All rights reserved', caseSensitive: false).hasMatch(t) && t.length < 180) {
    return true;
  }
  if ('|'.allMatches(t).length >= 3) return true;
  if ('·'.allMatches(t).length >= 3 && t.length < 280) return true;
  return false;
}

List<String> splitReaderParagraphs(String text) {
  var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (!normalized.contains('\n') && normalized.length > 240) {
    normalized = normalized.replaceAll(RegExp(r'。\s*'), '。\n');
  }
  return normalized
      .split(RegExp(r'\n+'))
      .expand(_breakReadOriginal)
      .expand(_splitImageLines)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

Iterable<String> _splitImageLines(String line) {
  final re = RegExp(r'!\[[^\]]*\]\(https?:[^)]+\)');
  if (!re.hasMatch(line)) return [line];
  final out = <String>[];
  var start = 0;
  for (final m in re.allMatches(line)) {
    final before = line.substring(start, m.start).trim();
    if (before.isNotEmpty) out.add(before);
    out.add('![image](${RegExp(r'\((https?:[^)]+)\)').firstMatch(m.group(0)!)?.group(1) ?? ''})');
    start = m.end;
  }
  final after = line.substring(start).trim();
  if (after.isNotEmpty) out.add(after);
  return out.where((e) => e != '![image]()');
}

bool looksUnreadable(String text) {
  final t = text.trim();
  if (t.isEmpty) return true;
  if (t.contains('_waf_') || t.contains('"waf"')) return true;
  if (t.startsWith('{') && t.contains('"')) return true;
  if (t.startsWith('[') && t.contains('{')) return true;
  if (t.length > 2000 && '{'.allMatches(t).length > 20 && '"'.allMatches(t).length > 40) {
    return true;
  }
  if (RegExp(r'\uFFFD\uFFFD').hasMatch(t)) return true;
  if (RegExp(
        r'Just a moment|Attention Required!|cf-browser-verification|Enable JavaScript and cookies|人机验证|访问触发保护|请完成验证',
        caseSensitive: false,
      ).hasMatch(t) &&
      t.length < 2000) {
    return true;
  }
  return false;
}

enum ReaderBlockKind { paragraph, heading, bullet, quote, code, image }

class ReaderSpan {
  const ReaderSpan(this.text, {this.bold = false, this.italic = false, this.code = false});

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
}

class ReaderBlock {
  const ReaderBlock({
    required this.plain,
    required this.spans,
    this.kind = ReaderBlockKind.paragraph,
    this.headingLevel = 0,
    this.imageUrl,
  });

  final String plain;
  final List<ReaderSpan> spans;
  final ReaderBlockKind kind;
  final int headingLevel;
  final String? imageUrl;
}

List<ReaderBlock> readerBlocks(String text) {
  final lines = splitReaderParagraphs(text);
  final out = <ReaderBlock>[];
  var inFence = false;
  final code = StringBuffer();
  for (final line in lines) {
    final fence = line.trim();
    if (fence == '```' || fence.startsWith('```')) {
      if (inFence) {
        final body = code.toString().trim();
        code.clear();
        inFence = false;
        if (body.isNotEmpty) {
          out.add(ReaderBlock(
            plain: body,
            spans: [ReaderSpan(body, code: true)],
            kind: ReaderBlockKind.code,
          ));
        }
      } else {
        inFence = true;
      }
      continue;
    }
    if (inFence) {
      if (code.isNotEmpty) code.writeln();
      code.write(line);
      continue;
    }
    final block = readerBlock(line);
    if (block.kind == ReaderBlockKind.image || block.plain.trim().isNotEmpty) out.add(block);
  }
  if (inFence && code.toString().trim().isNotEmpty) {
    final body = code.toString().trim();
    out.add(ReaderBlock(plain: body, spans: [ReaderSpan(body, code: true)], kind: ReaderBlockKind.code));
  }
  return out;
}

ReaderBlock readerBlock(String line) {
  final image = readerImageUrl(line);
  if (image != null) {
    return ReaderBlock(
      plain: line.trim(),
      spans: [ReaderSpan(line.trim())],
      kind: ReaderBlockKind.image,
      imageUrl: image,
    );
  }
  var raw = _repairReaderLine(line);
  if (raw == '---' || raw == '***' || raw == '___') {
    return const ReaderBlock(plain: '', spans: []);
  }
  var kind = ReaderBlockKind.paragraph;
  var heading = 0;
  final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(raw);
  if (headingMatch != null) {
    kind = ReaderBlockKind.heading;
    final level = headingMatch.group(1)!.length;
    heading = level > 3 ? 3 : level;
    raw = headingMatch.group(2)!.trim();
  } else {
    final bullet = RegExp(r'^(?:[-*+]|\d+\.)\s+(.+)$').firstMatch(raw);
    if (bullet != null) {
      kind = ReaderBlockKind.bullet;
      raw = bullet.group(1)!.trim();
    } else if (raw.startsWith('> ')) {
      kind = ReaderBlockKind.quote;
      raw = raw.substring(2).trim();
    }
  }
  final spans = parseInlineMarkdown(raw);
  final plain = spans.map((span) => span.text).join().trim();
  return ReaderBlock(plain: plain, spans: spans, kind: kind, headingLevel: heading);
}

String _repairReaderLine(String line) {
  var raw = line.trim();
  raw = raw.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!);
  raw = raw.replaceAll(RegExp(r'(?<![\w\\])\$1(?![\w])'), '');
  raw = raw.replaceAll(RegExp(r'：\s*[·•∙]\s*'), '：');
  raw = raw.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return raw.trim();
}

List<ReaderSpan> parseInlineMarkdown(String input) {
  final spans = <ReaderSpan>[];
  final buf = StringBuffer();
  var bold = false;
  var italic = false;
  var code = false;
  var i = 0;

  void flush() {
    if (buf.isEmpty) return;
    spans.add(ReaderSpan(buf.toString(), bold: bold, italic: italic, code: code));
    buf.clear();
  }

  while (i < input.length) {
    if (!code && (input.startsWith('**', i) || input.startsWith('__', i))) {
      final marker = input.substring(i, i + 2);
      if (bold || input.indexOf(marker, i + 2) >= 0) {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
    }
    if (!bold && input[i] == '`') {
      if (code) {
        flush();
        code = false;
        i++;
        continue;
      }
      final close = input.indexOf('`', i + 1);
      if (close > i + 1) {
        flush();
        code = true;
        i++;
        continue;
      }
    }
    if (!code && (input[i] == '*' || input[i] == '_')) {
      final mark = input[i];
      if (italic || _hasItalicCloser(input, i, mark)) {
        flush();
        italic = !italic;
        i++;
        continue;
      }
    }
    if (!code && input[i] == '[') {
      final link = _linkAt(input, i);
      if (link != null) {
        flush();
        buf.write(link.$1);
        i = link.$2;
        continue;
      }
    }
    buf.write(input[i]);
    i++;
  }
  flush();
  if (spans.isEmpty) return const [ReaderSpan('')];
  return spans;
}

bool _hasItalicCloser(String input, int opener, String mark) {
  if (opener + 1 >= input.length) return false;
  if (input[opener + 1] == mark || input[opener + 1] == ' ' || input[opener + 1] == '\n') return false;
  for (var j = opener + 2; j < input.length; j++) {
    if (input[j] != mark) continue;
    if (j + 1 < input.length && input[j + 1] == mark) {
      j++;
      continue;
    }
    if (input[j - 1] == ' ' || input[j - 1] == '\n') continue;
    return true;
  }
  return false;
}

(String, int)? _linkAt(String input, int start) {
  final match = RegExp(r'^\[([^\]]+)\]\([^)]*\)').matchAsPrefix(input, start);
  if (match == null) return null;
  final label = match.group(1)!.trim();
  if (label.isEmpty) return null;
  return (label, match.end);
}

String readerPlainText(String text) {
  return readerBlocks(text).map((block) => block.plain.trim()).where((line) => line.isNotEmpty).join('\n\n');
}

String speechPlaintext(String text) {
  return readerBlocks(text).where((block) {
    if (block.kind == ReaderBlockKind.image) return false;
    final t = block.plain.trim();
    if (t.isEmpty) return false;
    if (t.startsWith('🔗')) return false;
    if (RegExp(r'^https?://\S+$').hasMatch(t)) return false;
    if (RegExp(r'^(阅读原文|查看原文|原文链接)', caseSensitive: false).hasMatch(t)) return false;
    if (RegExp(r'^read original', caseSensitive: false).hasMatch(t)) return false;
    return true;
  }).map((block) => block.plain.trim()).join('\n\n');
}

bool looksUnstructured(String text) {
  if (text.length < 240) return false;
  return RegExp(r'\n').allMatches(text).length < 2;
}

Future<ReadableArticle> fetchReadable(
  FetchClient client,
  String url, {
  String seedHtml = '',
  bool preferRemote = false,
}) async {
  final seed = plaintextFromHtml(seedHtml, url: url);
  if (!preferRemote && seed.length >= 360 && !looksUnreadable(seed)) {
    return ReadableArticle(text: seed);
  }

  final site = siteForUrl(url);
  final extraNoise = site?.noise ?? const <RegExp>[];

  Future<String> fromJina() async {
    final prefixed = url.startsWith('http') ? url : 'https://$url';
    final md = await client.getText('https://r.jina.ai/$prefixed');
    return cleanReadableMarkdown(md, extraNoise: extraNoise);
  }

  String remote = '';
  if (site?.jinaFirst == true) {
    try {
      remote = await fromJina();
    } catch (_) {}
  }
  if (looksUnreadable(remote)) {
    try {
      final html = await client.getText(url);
      remote = extractReadableHtml(html, url: url);
    } catch (_) {}
  }

  if (looksUnreadable(remote) || looksUnstructured(remote) || remote.length < 120) {
    try {
      final text = await fromJina();
      if (_readableScore(text, extraNoise: extraNoise) > _readableScore(remote, extraNoise: extraNoise)) {
        remote = text;
      }
    } catch (_) {}
  }

  remote = cleanReadableMarkdown(remote, extraNoise: extraNoise);
  if (looksUnreadable(remote)) remote = '';

  ReadableArticle result;
  if (remote.length >= 120 && !looksUnreadable(remote)) {
    result = ReadableArticle(text: remote);
  } else if (seed.length >= 80 && !looksUnreadable(seed)) {
    result = ReadableArticle(text: seed, status: 'excerpt');
  } else if (seed.isNotEmpty && !looksUnreadable(seed)) {
    result = ReadableArticle(text: seed, status: 'excerpt');
  } else {
    result = ReadableArticle.empty;
  }
  return result;
}
