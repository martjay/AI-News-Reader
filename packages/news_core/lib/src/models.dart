enum SourceCategory { labs, china, papers, industry, global }

enum SourceAccess { direct, snapshot }

enum SourceType { rss, sspai, juejin, hfPapers, kr36, hot }

class SourceDef {
  const SourceDef({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.access,
    required this.type,
    required this.url,
    required this.home,
    required this.intervalMinutes,
    this.fallbackUrl = '',
    this.fragile = false,
    this.enabled = true,
    this.board = false,
  });

  final String id;
  final String name;
  final String nameEn;
  final SourceCategory category;
  final SourceAccess access;
  final SourceType type;
  final String url;
  final String home;
  final int intervalMinutes;
  final String fallbackUrl;
  final bool fragile;
  final bool enabled;
  final bool board;

  String displayName(bool chinese) => chinese ? name : nameEn;

  factory SourceDef.fromYaml(Map<dynamic, dynamic> map) {
    return SourceDef(
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['nameEn'] as String? ?? map['name'] as String,
      category: SourceCategory.values.byName(map['category'] as String),
      access: SourceAccess.values.byName(map['access'] as String),
      type: parseSourceType(map['type'] as String),
      url: map['url'] as String,
      home: map['home'] as String,
      intervalMinutes: map['intervalMinutes'] as int? ?? 30,
      fallbackUrl: map['fallbackUrl'] as String? ?? '',
      fragile: map['fragile'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? true,
      board: map['board'] as bool? ?? defaultBoardIds.contains(map['id']),
    );
  }
}

const defaultBoardIds = {
  'zhihu',
  'weibo',
  'douyin',
  'hupu',
  'tieba',
  'toutiao',
  'thepaper',
  'coolapk',
  'xueqiu-hotstock',
  'xueqiu',
  'github-trending-today',
  'github',
  'bilibili-hot-search',
  'bilibili-hot-video',
  'bilibili-ranking',
  'bilibili',
  'kuaishou',
  'baidu',
  'nowcoder',
  'douban',
  'steam',
  'qqvideo-tv-hotsearch',
  'qqvideo',
  'iqiyi-hot-ranklist',
  'iqiyi',
  '36kr-renqi',
};

SourceType parseSourceType(String raw) {
  switch (raw) {
    case 'rss':
      return SourceType.rss;
    case 'sspai':
      return SourceType.sspai;
    case 'juejin':
      return SourceType.juejin;
    case 'hf_papers':
      return SourceType.hfPapers;
    case 'kr36':
      return SourceType.kr36;
    case 'hot':
      return SourceType.hot;
    default:
      throw ArgumentError('Unknown source type: $raw');
  }
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.url,
    this.summary = '',
    this.pubDate,
    this.extraSourceIds = const [],
  });

  final String id;
  final String sourceId;
  final String title;
  final String url;
  final String summary;
  final DateTime? pubDate;
  final List<String> extraSourceIds;

  List<String> get allSourceIds => [sourceId, ...extraSourceIds];

  NewsItem copyWith({
    String? id,
    String? sourceId,
    String? title,
    String? url,
    String? summary,
    DateTime? pubDate,
    List<String>? extraSourceIds,
  }) {
    return NewsItem(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      url: url ?? this.url,
      summary: summary ?? this.summary,
      pubDate: pubDate ?? this.pubDate,
      extraSourceIds: extraSourceIds ?? this.extraSourceIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'title': title,
        'url': url,
        'summary': summary,
        'pubDate': pubDate?.toUtc().toIso8601String(),
        'extraSourceIds': extraSourceIds,
      };

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      pubDate: json['pubDate'] == null
          ? null
          : DateTime.tryParse(json['pubDate'] as String)?.toLocal(),
      extraSourceIds: (json['extraSourceIds'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class SourceFetchResult {
  const SourceFetchResult({
    required this.sourceId,
    required this.status,
    required this.updatedAt,
    this.items = const [],
    this.error,
  });

  final String sourceId;
  final String status;
  final DateTime updatedAt;
  final List<NewsItem> items;
  final String? error;

  bool get ok => status == 'ok';

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'status': status,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'error': error,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory SourceFetchResult.fromJson(Map<String, dynamic> json) {
    return SourceFetchResult(
      sourceId: json['sourceId'] as String? ?? '',
      status: json['status'] as String? ?? 'error',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      error: json['error'] as String?,
      items: (json['items'] as List? ?? [])
          .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
