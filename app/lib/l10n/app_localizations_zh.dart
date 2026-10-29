// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '新闻';

  @override
  String get appSubtitle => 'AI 新闻';

  @override
  String get navToday => '今日';

  @override
  String get navSources => '来源';

  @override
  String get navSaved => '收藏';

  @override
  String get navMe => '我的';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionSettings => '设置';

  @override
  String get actionSave => '收藏';

  @override
  String get actionUnsave => '取消收藏';

  @override
  String get actionMarkRead => '标为已读';

  @override
  String get actionOpenOriginal => '打开原文';

  @override
  String get actionShare => '分享';

  @override
  String get shareCopied => '标题和链接已复制';

  @override
  String get actionLanguage => '语言';

  @override
  String get actionTheme => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get fontSize => '正文字号';

  @override
  String get snapshotRepo => '快照仓库（owner/repo）';

  @override
  String get snapshotHint => '电脑会尽量直连海外源。手机使用内置快照；填仓库后可通过 jsDelivr 自动更新。';

  @override
  String get snapshotUrl => '自定义快照 URL';

  @override
  String get sourcesManage => '管理来源';

  @override
  String get sourcesEnabled => '已开启';

  @override
  String get emptyToday => '还没有条目。下拉刷新试试。';

  @override
  String get emptyFilter => '这个源暂时没有内容。换一个源或下拉刷新。';

  @override
  String get feedAll => '全部源';

  @override
  String get feedDomestic => '国内';

  @override
  String get feedWorld => '国际';

  @override
  String get regionDomestic => '国内新闻';

  @override
  String get regionWorld => '国际新闻';

  @override
  String feedCount(int n) {
    return '$n 篇';
  }

  @override
  String get emptySaved => '收藏的文章会出现在这里。';

  @override
  String get emptySearch => '没有匹配的标题或摘要。';

  @override
  String get emptyArticle => '从左侧选一篇。默认只显示摘要，需要时再获取全文。';

  @override
  String get emptySource => '这个源暂时没有内容。';

  @override
  String get errorPartial => '部分来源未能更新，已显示缓存。';

  @override
  String get errorNetwork => '网络不可达。已尽量使用本地缓存。';

  @override
  String get errorSnapshot => '快照地址无效或下载失败，已使用本地缓存。';

  @override
  String get errorTranslate => '翻译暂时失败，可稍后重试。';

  @override
  String get errorBody => '正文抓取失败，仍可打开原文。';

  @override
  String get refreshing => '正在更新…';

  @override
  String lastUpdated(String time) {
    return '更新于 $time';
  }

  @override
  String get unreadDot => '未读';

  @override
  String get searchHint => '搜索标题、摘要、正文';

  @override
  String get categoryLabs => '实验室';

  @override
  String get categoryChina => '国内媒体';

  @override
  String get categoryPapers => '论文';

  @override
  String get categoryIndustry => '产业';

  @override
  String get categoryGlobal => '国际';

  @override
  String get sourceFailed => '失败';

  @override
  String get sourceOk => '正常';

  @override
  String get aboutBody =>
      '把分散的 AI 资讯收成一份今日报。国内源直连 RSS，海外源在电脑上直连、在手机上走快照。点开先看摘要，需要时再手动获取全文或翻译。';

  @override
  String get aboutTitle => '关于';

  @override
  String get authorQq => '作者 QQ';

  @override
  String get qqCopied => 'QQ 号码已复制';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get openInBrowser => '用浏览器打开';

  @override
  String get noExcerpt => '这篇没有摘要，请打开原文阅读。';

  @override
  String get briefTitle => '今日要点';

  @override
  String get boardsTitle => '热榜';

  @override
  String get bySource => '按来源';

  @override
  String get sourcesReorderHint => '长按拖动调整顺序';

  @override
  String get markAllRead => '全部标为已读';

  @override
  String get newBadge => '新';

  @override
  String get readingBody => '正在取正文…';

  @override
  String get fetchFullText => '获取全文';

  @override
  String get refetchFullText => '重新获取';

  @override
  String get showSummary => '简介';

  @override
  String get showFullText => '显示全文';

  @override
  String get translateArticle => '翻译';

  @override
  String get translatingArticle => '正在翻译…';

  @override
  String get copyArticle => '复制';

  @override
  String get articleCopied => '标题和正文已复制';

  @override
  String get copyTranslation => '复制译文';

  @override
  String get copyOriginalText => '复制原文';

  @override
  String get copyBilingual => '复制双语';

  @override
  String get ttsVoicesZh => '中文朗读人';

  @override
  String get ttsVoicesEn => '英文朗读人';

  @override
  String get listenArticle => '朗读';

  @override
  String get stopListening => '停止';

  @override
  String get pauseSpeech => '暂停';

  @override
  String get resumeSpeech => '继续';

  @override
  String get preparingSpeech => '正在生成...';

  @override
  String ttsChunkLabel(int current, int total) {
    return '第 $current/$total 段';
  }

  @override
  String ttsChunkRemaining(String time) {
    return '本段剩余 $time';
  }

  @override
  String ttsPreparingChunk(int current, int total) {
    return '正在生成第 $current/$total 段…';
  }

  @override
  String get listenFailed => '朗读失败，请检查网络或代理。';

  @override
  String get downloadSpeech => '下载语音';

  @override
  String downloadingSpeech(int done, int total) {
    return '正在合成 $done/$total…';
  }

  @override
  String get audioSaved => '语音已保存';

  @override
  String get audioSaveFailed => '保存语音失败，请检查网络或代理。';

  @override
  String get nothingToListen => '没有可朗读的内容。';

  @override
  String get translationCopied => '译文已复制';

  @override
  String get originalCopied => '原文已复制';

  @override
  String get bilingualCopied => '双语已复制';

  @override
  String get originalBody => '原文';

  @override
  String get bodyUnavailable => '正文暂时读不到，摘要如下。可打开原站。';

  @override
  String get bodyFetchFailed => '未能获取全文。可打开原站。';

  @override
  String get bodyExcerptOnly => '只拿到摘要，不是完整正文。可打开原站。';

  @override
  String get imageLoadFailed => '图片无法加载';

  @override
  String relatedSources(int n) {
    return '$n 家来源';
  }

  @override
  String unreadCount(int n) {
    return '$n 未读';
  }

  @override
  String get sourceFragile => '不稳定';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionNetwork => '网络';

  @override
  String get useSystemProxy => '使用系统代理';

  @override
  String get proxyUrl => '手动代理（HTTP）';

  @override
  String get proxyHint =>
      'Dart 默认不读 Windows 系统代理，海外 RSS 会直连失败。开启后读取环境变量和 Windows 代理；也可填 Clash/V2Ray 的 HTTP 端口，例如 127.0.0.1:7890。不支持 SOCKS。';

  @override
  String get settingsSectionData => '数据';

  @override
  String get settingsSectionSources => '来源';

  @override
  String get settingsSectionTranslate => '中文翻译';

  @override
  String get autoTranslate => '自动把海外标题和摘要译成中文';

  @override
  String get showOriginal => '同时显示英文原文';

  @override
  String get translationHint =>
      '默认用腾讯交互翻译（国内可直连，无需代理）。填写 DeepSeek 或通义 API Key 后，译文会更稳、更像新闻口吻。';

  @override
  String get translationApiKey => 'API Key（可选）';

  @override
  String get translationBaseUrl => '接口地址';

  @override
  String get translationModel => '模型名';

  @override
  String get translating => '正在把海外新闻译成中文…';

  @override
  String get relativeJustNow => '刚刚';

  @override
  String relativeMinutes(int n) {
    return '$n 分钟前';
  }

  @override
  String relativeHours(int n) {
    return '$n 小时前';
  }

  @override
  String relativeDays(int n) {
    return '$n 天前';
  }
}
