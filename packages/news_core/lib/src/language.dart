bool isPrimarilyChinese(String text) {
  final chars = text.replaceAll(RegExp(r'\s+'), '');
  if (chars.isEmpty) return true;
  final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(chars).length;
  if (chars.length < 80) return cjk >= 4 || cjk / chars.length >= 0.28;
  return cjk / chars.length >= 0.55;
}

bool hasTranslatableLatin(String text) {
  return RegExp(r'[A-Za-z]').allMatches(text).length >= 24;
}
