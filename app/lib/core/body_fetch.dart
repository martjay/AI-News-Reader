import 'article_record.dart';

class StoredBody {
  const StoredBody({
    required this.body,
    required this.bodyZh,
    required this.status,
  });

  final String body;
  final String bodyZh;
  final String status;
}

bool shouldAutoFetchBody(String body, String bodyStatus) {
  return body.trim().isEmpty && bodyStatus.isEmpty;
}

bool isFullBodyStatus(String status) => status == 'ok';

bool hasUsableFullBody(String body, String status) {
  final text = body.trim();
  if (text.isEmpty) return false;
  if (status == 'ok') return true;
  if (status == 'fail' && text.length >= 80) return true;
  return false;
}

bool isWeakBodyStatus(String status) =>
    status == 'fail' || status == 'empty' || status == 'excerpt';

/// Keeps a body fetched while a refresh or title translation was in flight.
/// Those updates rebuild the article list from an older copy, which would
/// otherwise put the reader back on the summary.
ArticleRecord preserveFetchedBody(ArticleRecord incoming, ArticleRecord? live) {
  if (live == null) return incoming;
  var next = incoming;
  final incomingFull = hasUsableFullBody(incoming.body, incoming.bodyStatus);
  final liveFull = hasUsableFullBody(live.body, live.bodyStatus);
  if (liveFull && !incomingFull) {
    next = next.copyWith(
      body: live.body,
      bodyZh: live.bodyZh,
      bodyStatus: live.bodyStatus,
    );
  } else if (next.body.trim() == live.body.trim() && next.bodyZh.isEmpty && live.bodyZh.isNotEmpty) {
    next = next.copyWith(bodyZh: live.bodyZh);
  }
  if (next.titleZh.isEmpty && live.titleZh.isNotEmpty) {
    next = next.copyWith(titleZh: live.titleZh);
  }
  if (next.summaryZh.isEmpty && live.summaryZh.isNotEmpty) {
    next = next.copyWith(summaryZh: live.summaryZh);
  }
  return next;
}

/// Body-fetch failures replace a quiet banner. A network banner stays visible.
/// A successful or excerpt fetch clears a stale body error.
String? bannerAfterBodyFetch({
  required String? current,
  required String status,
  required bool selected,
}) {
  final failed = selected && status == 'fail';
  if (failed) {
    if (current == 'network' || current == 'snapshot' || current == 'partial') return current;
    return 'body';
  }
  if (current == 'body') return null;
  return current;
}

StoredBody applyFetchedBody({
  required String previousBody,
  required String previousBodyZh,
  required String fetchedText,
  required String fetchedStatus,
  required String summaryFallback,
}) {
  var body = fetchedText.trim();
  var status = fetchedStatus;
  if (status == 'ok' && body.length < 80) {
    status = body.isEmpty ? 'empty' : 'excerpt';
  }
  if (body.isEmpty) {
    body = summaryFallback.trim();
    status = body.isEmpty ? 'empty' : 'excerpt';
  }
  final keepZh = body == previousBody.trim() ? previousBodyZh : '';
  return StoredBody(body: body, bodyZh: keepZh, status: status);
}

StoredBody applyFailedBody({
  required String previousBody,
  required String previousBodyZh,
  required String summaryFallback,
}) {
  final body = previousBody.trim().isNotEmpty ? previousBody : summaryFallback.trim();
  return StoredBody(
    body: body,
    bodyZh: previousBodyZh,
    status: 'fail',
  );
}
