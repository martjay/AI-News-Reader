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
