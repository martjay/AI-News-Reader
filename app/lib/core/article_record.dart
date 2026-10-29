import 'package:news_core/news_core.dart';

class ArticleRecord {
  const ArticleRecord({
    required this.item,
    this.saved = false,
    this.read = false,
    this.titleZh = '',
    this.summaryZh = '',
    this.body = '',
    this.bodyZh = '',
    this.bodyStatus = '',
  });

  final NewsItem item;
  final bool saved;
  final bool read;
  final String titleZh;
  final String summaryZh;
  final String body;
  final String bodyZh;
  final String bodyStatus;

  String displayTitle(bool chinese) => chinese && titleZh.isNotEmpty ? titleZh : item.title;

  String displaySummary(bool chinese) => chinese && summaryZh.isNotEmpty ? summaryZh : item.summary;

  bool get needsTranslation {
    if (item.title.isNotEmpty && titleZh.isEmpty && !isPrimarilyChinese(item.title)) return true;
    if (item.summary.isNotEmpty && summaryZh.isEmpty && !isPrimarilyChinese(item.summary)) return true;
    return false;
  }

  ArticleRecord copyWith({
    NewsItem? item,
    bool? saved,
    bool? read,
    String? titleZh,
    String? summaryZh,
    String? body,
    String? bodyZh,
    String? bodyStatus,
  }) {
    return ArticleRecord(
      item: item ?? this.item,
      saved: saved ?? this.saved,
      read: read ?? this.read,
      titleZh: titleZh ?? this.titleZh,
      summaryZh: summaryZh ?? this.summaryZh,
      body: body ?? this.body,
      bodyZh: bodyZh ?? this.bodyZh,
      bodyStatus: bodyStatus ?? this.bodyStatus,
    );
  }

  String displayBody(bool chinese) => chinese && bodyZh.isNotEmpty ? bodyZh : body;
}
