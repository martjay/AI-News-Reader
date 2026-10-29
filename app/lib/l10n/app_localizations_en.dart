// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'News';

  @override
  String get appSubtitle => 'AI news';

  @override
  String get navToday => 'Today';

  @override
  String get navSources => 'Sources';

  @override
  String get navSaved => 'Saved';

  @override
  String get navMe => 'Me';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionSave => 'Save';

  @override
  String get actionUnsave => 'Unsave';

  @override
  String get actionMarkRead => 'Mark read';

  @override
  String get actionOpenOriginal => 'Open original';

  @override
  String get actionShare => 'Share';

  @override
  String get shareCopied => 'Title and link copied';

  @override
  String get actionLanguage => 'Language';

  @override
  String get actionTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get fontSize => 'Body size';

  @override
  String get snapshotRepo => 'Snapshot repo (owner/repo)';

  @override
  String get snapshotHint =>
      'On desktop, overseas feeds are fetched live. On phones, the bundled snapshot is used; set a repo to refresh via jsDelivr.';

  @override
  String get snapshotUrl => 'Custom snapshot URL';

  @override
  String get sourcesManage => 'Manage sources';

  @override
  String get sourcesEnabled => 'Enabled';

  @override
  String get emptyToday => 'Nothing yet. Pull to refresh.';

  @override
  String get emptyFilter =>
      'Nothing from this source. Pick another, or pull to refresh.';

  @override
  String get feedAll => 'All sources';

  @override
  String get feedDomestic => 'China';

  @override
  String get feedWorld => 'World';

  @override
  String get regionDomestic => 'China';

  @override
  String get regionWorld => 'World';

  @override
  String feedCount(int n) {
    return '$n stories';
  }

  @override
  String get emptySaved => 'Saved stories will land here.';

  @override
  String get emptySearch => 'No titles or summaries matched.';

  @override
  String get emptyArticle =>
      'Pick a story on the left. You\'ll see the excerpt until you fetch the full article.';

  @override
  String get emptySource => 'This source has no items right now.';

  @override
  String get errorPartial => 'Some sources failed. Cached items are shown.';

  @override
  String get errorNetwork =>
      'Network unreachable. Showing local cache when possible.';

  @override
  String get errorSnapshot =>
      'Snapshot URL was rejected or failed. Using the local cache.';

  @override
  String get errorTranslate => 'Translation failed. Try again in a moment.';

  @override
  String get errorBody =>
      'Could not fetch the article body. The original site is still available.';

  @override
  String get refreshing => 'Updating…';

  @override
  String lastUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get unreadDot => 'Unread';

  @override
  String get searchHint => 'Search titles, summaries, and bodies';

  @override
  String get categoryLabs => 'Labs';

  @override
  String get categoryChina => 'China press';

  @override
  String get categoryPapers => 'Papers';

  @override
  String get categoryIndustry => 'Industry';

  @override
  String get categoryGlobal => 'World';

  @override
  String get sourceFailed => 'Failed';

  @override
  String get sourceOk => 'OK';

  @override
  String get aboutBody =>
      'A daily AI brief. Domestic RSS is fetched on-device; overseas feeds are live on desktop and snapshotted on phones. Open a story for the excerpt, then fetch the full article or translate when you need it.';

  @override
  String get aboutTitle => 'About';

  @override
  String get authorQq => 'Author QQ';

  @override
  String get qqCopied => 'QQ number copied';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get noExcerpt => 'No excerpt. Open the original article.';

  @override
  String get briefTitle => 'Today\'s brief';

  @override
  String get boardsTitle => 'Hot lists';

  @override
  String get bySource => 'By source';

  @override
  String get sourcesReorderHint => 'Hold and drag to reorder';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get newBadge => 'New';

  @override
  String get readingBody => 'Loading article…';

  @override
  String get fetchFullText => 'Fetch full text';

  @override
  String get refetchFullText => 'Fetch again';

  @override
  String get showSummary => 'Summary';

  @override
  String get showFullText => 'Show full text';

  @override
  String get translateArticle => 'Translate';

  @override
  String get translatingArticle => 'Translating…';

  @override
  String get copyArticle => 'Copy';

  @override
  String get articleCopied => 'Title and article copied';

  @override
  String get copyTranslation => 'Copy translation';

  @override
  String get copyOriginalText => 'Copy original';

  @override
  String get copyBilingual => 'Copy bilingual';

  @override
  String get ttsVoicesZh => 'Chinese voices';

  @override
  String get ttsVoicesEn => 'English voices';

  @override
  String get listenArticle => 'Listen';

  @override
  String get stopListening => 'Stop';

  @override
  String get pauseSpeech => 'Pause';

  @override
  String get resumeSpeech => 'Resume';

  @override
  String get preparingSpeech => 'Generating...';

  @override
  String ttsChunkLabel(int current, int total) {
    return '$current/$total';
  }

  @override
  String ttsChunkRemaining(String time) {
    return '$time left in this segment';
  }

  @override
  String ttsPreparingChunk(int current, int total) {
    return 'Preparing $current/$total…';
  }

  @override
  String get listenFailed =>
      'Couldn\'t read this aloud. Check the network or proxy.';

  @override
  String get downloadSpeech => 'Download audio';

  @override
  String downloadingSpeech(int done, int total) {
    return 'Synthesizing $done/$total…';
  }

  @override
  String get audioSaved => 'Audio saved';

  @override
  String get audioSaveFailed =>
      'Couldn\'t save the audio. Check the network or proxy.';

  @override
  String get nothingToListen => 'Nothing to read aloud.';

  @override
  String get translationCopied => 'Translation copied';

  @override
  String get originalCopied => 'Original copied';

  @override
  String get bilingualCopied => 'Bilingual copy copied';

  @override
  String get originalBody => 'Original';

  @override
  String get bodyUnavailable =>
      'Couldn\'t load the article. Summary below — or open the original.';

  @override
  String get bodyFetchFailed =>
      'Couldn\'t fetch the full article. The original site is still available.';

  @override
  String get bodyExcerptOnly =>
      'Only the summary is available, not the full article. Open the original if you need more.';

  @override
  String get imageLoadFailed => 'Image couldn\'t load';

  @override
  String relatedSources(int n) {
    return '$n sources';
  }

  @override
  String unreadCount(int n) {
    return '$n unread';
  }

  @override
  String get sourceFragile => 'Fragile';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionNetwork => 'Network';

  @override
  String get useSystemProxy => 'Use system proxy';

  @override
  String get proxyUrl => 'HTTP proxy';

  @override
  String get proxyHint =>
      'This app does not pick up Windows system proxy by default, which often breaks overseas RSS. Enable to read env vars and Windows proxy, or set Clash/V2Ray HTTP port such as 127.0.0.1:7890. SOCKS is not supported.';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionSources => 'Sources';

  @override
  String get settingsSectionTranslate => 'Chinese translation';

  @override
  String get autoTranslate =>
      'Translate overseas titles and excerpts into Chinese';

  @override
  String get showOriginal => 'Also show the English original';

  @override
  String get translationHint =>
      'Uses Tencent Transmart by default (reachable in mainland China, no VPN). Add a DeepSeek or Qwen API key for more stable news-style wording.';

  @override
  String get translationApiKey => 'API key (optional)';

  @override
  String get translationBaseUrl => 'API base URL';

  @override
  String get translationModel => 'Model';

  @override
  String get translating => 'Translating overseas stories into Chinese…';

  @override
  String get relativeJustNow => 'Just now';

  @override
  String relativeMinutes(int n) {
    return '$n min ago';
  }

  @override
  String relativeHours(int n) {
    return '$n hr ago';
  }

  @override
  String relativeDays(int n) {
    return '$n days ago';
  }
}
