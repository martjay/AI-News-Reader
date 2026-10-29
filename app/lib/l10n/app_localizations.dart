import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'新闻'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 新闻'**
  String get appSubtitle;

  /// No description provided for @navToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get navToday;

  /// No description provided for @navSources.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get navSources;

  /// No description provided for @navSaved.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get navSaved;

  /// No description provided for @navMe.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navMe;

  /// No description provided for @actionRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get actionRefresh;

  /// No description provided for @actionSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get actionSearch;

  /// No description provided for @actionSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get actionSettings;

  /// No description provided for @actionSave.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get actionSave;

  /// No description provided for @actionUnsave.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get actionUnsave;

  /// No description provided for @actionMarkRead.
  ///
  /// In zh, this message translates to:
  /// **'标为已读'**
  String get actionMarkRead;

  /// No description provided for @actionOpenOriginal.
  ///
  /// In zh, this message translates to:
  /// **'打开原文'**
  String get actionOpenOriginal;

  /// No description provided for @actionShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get actionShare;

  /// No description provided for @shareCopied.
  ///
  /// In zh, this message translates to:
  /// **'标题和链接已复制'**
  String get shareCopied;

  /// No description provided for @actionLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get actionLanguage;

  /// No description provided for @actionTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get actionTheme;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'正文字号'**
  String get fontSize;

  /// No description provided for @snapshotRepo.
  ///
  /// In zh, this message translates to:
  /// **'快照仓库（owner/repo）'**
  String get snapshotRepo;

  /// No description provided for @snapshotHint.
  ///
  /// In zh, this message translates to:
  /// **'电脑会尽量直连海外源。手机使用内置快照；填仓库后可通过 jsDelivr 自动更新。'**
  String get snapshotHint;

  /// No description provided for @snapshotUrl.
  ///
  /// In zh, this message translates to:
  /// **'自定义快照 URL'**
  String get snapshotUrl;

  /// No description provided for @sourcesManage.
  ///
  /// In zh, this message translates to:
  /// **'管理来源'**
  String get sourcesManage;

  /// No description provided for @sourcesEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get sourcesEnabled;

  /// No description provided for @emptyToday.
  ///
  /// In zh, this message translates to:
  /// **'还没有条目。下拉刷新试试。'**
  String get emptyToday;

  /// No description provided for @emptyFilter.
  ///
  /// In zh, this message translates to:
  /// **'这个源暂时没有内容。换一个源或下拉刷新。'**
  String get emptyFilter;

  /// No description provided for @feedAll.
  ///
  /// In zh, this message translates to:
  /// **'全部源'**
  String get feedAll;

  /// No description provided for @feedDomestic.
  ///
  /// In zh, this message translates to:
  /// **'国内'**
  String get feedDomestic;

  /// No description provided for @feedWorld.
  ///
  /// In zh, this message translates to:
  /// **'国际'**
  String get feedWorld;

  /// No description provided for @regionDomestic.
  ///
  /// In zh, this message translates to:
  /// **'国内新闻'**
  String get regionDomestic;

  /// No description provided for @regionWorld.
  ///
  /// In zh, this message translates to:
  /// **'国际新闻'**
  String get regionWorld;

  /// No description provided for @feedCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 篇'**
  String feedCount(int n);

  /// No description provided for @emptySaved.
  ///
  /// In zh, this message translates to:
  /// **'收藏的文章会出现在这里。'**
  String get emptySaved;

  /// No description provided for @emptySearch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的标题或摘要。'**
  String get emptySearch;

  /// No description provided for @emptyArticle.
  ///
  /// In zh, this message translates to:
  /// **'从左侧选一篇。默认只显示摘要，需要时再获取全文。'**
  String get emptyArticle;

  /// No description provided for @emptySource.
  ///
  /// In zh, this message translates to:
  /// **'这个源暂时没有内容。'**
  String get emptySource;

  /// No description provided for @errorPartial.
  ///
  /// In zh, this message translates to:
  /// **'部分来源未能更新，已显示缓存。'**
  String get errorPartial;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络不可达。已尽量使用本地缓存。'**
  String get errorNetwork;

  /// No description provided for @errorSnapshot.
  ///
  /// In zh, this message translates to:
  /// **'快照地址无效或下载失败，已使用本地缓存。'**
  String get errorSnapshot;

  /// No description provided for @errorTranslate.
  ///
  /// In zh, this message translates to:
  /// **'翻译暂时失败，可稍后重试。'**
  String get errorTranslate;

  /// No description provided for @errorBody.
  ///
  /// In zh, this message translates to:
  /// **'正文抓取失败，仍可打开原文。'**
  String get errorBody;

  /// No description provided for @refreshing.
  ///
  /// In zh, this message translates to:
  /// **'正在更新…'**
  String get refreshing;

  /// No description provided for @lastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'更新于 {time}'**
  String lastUpdated(String time);

  /// No description provided for @unreadDot.
  ///
  /// In zh, this message translates to:
  /// **'未读'**
  String get unreadDot;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索标题、摘要、正文'**
  String get searchHint;

  /// No description provided for @categoryLabs.
  ///
  /// In zh, this message translates to:
  /// **'实验室'**
  String get categoryLabs;

  /// No description provided for @categoryChina.
  ///
  /// In zh, this message translates to:
  /// **'国内媒体'**
  String get categoryChina;

  /// No description provided for @categoryPapers.
  ///
  /// In zh, this message translates to:
  /// **'论文'**
  String get categoryPapers;

  /// No description provided for @categoryIndustry.
  ///
  /// In zh, this message translates to:
  /// **'产业'**
  String get categoryIndustry;

  /// No description provided for @categoryGlobal.
  ///
  /// In zh, this message translates to:
  /// **'国际'**
  String get categoryGlobal;

  /// No description provided for @sourceFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get sourceFailed;

  /// No description provided for @sourceOk.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get sourceOk;

  /// No description provided for @aboutBody.
  ///
  /// In zh, this message translates to:
  /// **'把分散的 AI 资讯收成一份今日报。国内源直连 RSS，海外源在电脑上直连、在手机上走快照。点开先看摘要，需要时再手动获取全文或翻译。'**
  String get aboutBody;

  /// No description provided for @aboutTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get aboutTitle;

  /// No description provided for @authorQq.
  ///
  /// In zh, this message translates to:
  /// **'作者 QQ'**
  String get authorQq;

  /// No description provided for @qqCopied.
  ///
  /// In zh, this message translates to:
  /// **'QQ 号码已复制'**
  String get qqCopied;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @openInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'用浏览器打开'**
  String get openInBrowser;

  /// No description provided for @noExcerpt.
  ///
  /// In zh, this message translates to:
  /// **'这篇没有摘要，请打开原文阅读。'**
  String get noExcerpt;

  /// No description provided for @briefTitle.
  ///
  /// In zh, this message translates to:
  /// **'今日要点'**
  String get briefTitle;

  /// No description provided for @boardsTitle.
  ///
  /// In zh, this message translates to:
  /// **'热榜'**
  String get boardsTitle;

  /// No description provided for @bySource.
  ///
  /// In zh, this message translates to:
  /// **'按来源'**
  String get bySource;

  /// No description provided for @sourcesReorderHint.
  ///
  /// In zh, this message translates to:
  /// **'长按拖动调整顺序'**
  String get sourcesReorderHint;

  /// No description provided for @markAllRead.
  ///
  /// In zh, this message translates to:
  /// **'全部标为已读'**
  String get markAllRead;

  /// No description provided for @newBadge.
  ///
  /// In zh, this message translates to:
  /// **'新'**
  String get newBadge;

  /// No description provided for @readingBody.
  ///
  /// In zh, this message translates to:
  /// **'正在取正文…'**
  String get readingBody;

  /// No description provided for @fetchFullText.
  ///
  /// In zh, this message translates to:
  /// **'获取全文'**
  String get fetchFullText;

  /// No description provided for @refetchFullText.
  ///
  /// In zh, this message translates to:
  /// **'重新获取'**
  String get refetchFullText;

  /// No description provided for @showSummary.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get showSummary;

  /// No description provided for @showFullText.
  ///
  /// In zh, this message translates to:
  /// **'显示全文'**
  String get showFullText;

  /// No description provided for @translateArticle.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get translateArticle;

  /// No description provided for @translatingArticle.
  ///
  /// In zh, this message translates to:
  /// **'正在翻译…'**
  String get translatingArticle;

  /// No description provided for @copyArticle.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copyArticle;

  /// No description provided for @articleCopied.
  ///
  /// In zh, this message translates to:
  /// **'标题和正文已复制'**
  String get articleCopied;

  /// No description provided for @copyTranslation.
  ///
  /// In zh, this message translates to:
  /// **'复制译文'**
  String get copyTranslation;

  /// No description provided for @copyOriginalText.
  ///
  /// In zh, this message translates to:
  /// **'复制原文'**
  String get copyOriginalText;

  /// No description provided for @copyBilingual.
  ///
  /// In zh, this message translates to:
  /// **'复制双语'**
  String get copyBilingual;

  /// No description provided for @ttsVoicesZh.
  ///
  /// In zh, this message translates to:
  /// **'中文朗读人'**
  String get ttsVoicesZh;

  /// No description provided for @ttsVoicesEn.
  ///
  /// In zh, this message translates to:
  /// **'英文朗读人'**
  String get ttsVoicesEn;

  /// No description provided for @listenArticle.
  ///
  /// In zh, this message translates to:
  /// **'朗读'**
  String get listenArticle;

  /// No description provided for @stopListening.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stopListening;

  /// No description provided for @pauseSpeech.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pauseSpeech;

  /// No description provided for @resumeSpeech.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resumeSpeech;

  /// No description provided for @preparingSpeech.
  ///
  /// In zh, this message translates to:
  /// **'正在生成...'**
  String get preparingSpeech;

  /// No description provided for @ttsChunkLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {current}/{total} 段'**
  String ttsChunkLabel(int current, int total);

  /// No description provided for @ttsChunkRemaining.
  ///
  /// In zh, this message translates to:
  /// **'本段剩余 {time}'**
  String ttsChunkRemaining(String time);

  /// No description provided for @ttsPreparingChunk.
  ///
  /// In zh, this message translates to:
  /// **'正在生成第 {current}/{total} 段…'**
  String ttsPreparingChunk(int current, int total);

  /// No description provided for @listenFailed.
  ///
  /// In zh, this message translates to:
  /// **'朗读失败，请检查网络或代理。'**
  String get listenFailed;

  /// No description provided for @downloadSpeech.
  ///
  /// In zh, this message translates to:
  /// **'下载语音'**
  String get downloadSpeech;

  /// No description provided for @downloadingSpeech.
  ///
  /// In zh, this message translates to:
  /// **'正在合成 {done}/{total}…'**
  String downloadingSpeech(int done, int total);

  /// No description provided for @audioSaved.
  ///
  /// In zh, this message translates to:
  /// **'语音已保存'**
  String get audioSaved;

  /// No description provided for @audioSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存语音失败，请检查网络或代理。'**
  String get audioSaveFailed;

  /// No description provided for @nothingToListen.
  ///
  /// In zh, this message translates to:
  /// **'没有可朗读的内容。'**
  String get nothingToListen;

  /// No description provided for @translationCopied.
  ///
  /// In zh, this message translates to:
  /// **'译文已复制'**
  String get translationCopied;

  /// No description provided for @originalCopied.
  ///
  /// In zh, this message translates to:
  /// **'原文已复制'**
  String get originalCopied;

  /// No description provided for @bilingualCopied.
  ///
  /// In zh, this message translates to:
  /// **'双语已复制'**
  String get bilingualCopied;

  /// No description provided for @originalBody.
  ///
  /// In zh, this message translates to:
  /// **'原文'**
  String get originalBody;

  /// No description provided for @bodyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'正文暂时读不到，摘要如下。可打开原站。'**
  String get bodyUnavailable;

  /// No description provided for @bodyFetchFailed.
  ///
  /// In zh, this message translates to:
  /// **'未能获取全文。可打开原站。'**
  String get bodyFetchFailed;

  /// No description provided for @bodyExcerptOnly.
  ///
  /// In zh, this message translates to:
  /// **'只拿到摘要，不是完整正文。可打开原站。'**
  String get bodyExcerptOnly;

  /// No description provided for @imageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片无法加载'**
  String get imageLoadFailed;

  /// No description provided for @relatedSources.
  ///
  /// In zh, this message translates to:
  /// **'{n} 家来源'**
  String relatedSources(int n);

  /// No description provided for @unreadCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 未读'**
  String unreadCount(int n);

  /// No description provided for @sourceFragile.
  ///
  /// In zh, this message translates to:
  /// **'不稳定'**
  String get sourceFragile;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get settingsSectionNetwork;

  /// No description provided for @useSystemProxy.
  ///
  /// In zh, this message translates to:
  /// **'使用系统代理'**
  String get useSystemProxy;

  /// No description provided for @proxyUrl.
  ///
  /// In zh, this message translates to:
  /// **'手动代理（HTTP）'**
  String get proxyUrl;

  /// No description provided for @proxyHint.
  ///
  /// In zh, this message translates to:
  /// **'Dart 默认不读 Windows 系统代理，海外 RSS 会直连失败。开启后读取环境变量和 Windows 代理；也可填 Clash/V2Ray 的 HTTP 端口，例如 127.0.0.1:7890。不支持 SOCKS。'**
  String get proxyHint;

  /// No description provided for @settingsSectionData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionSources.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get settingsSectionSources;

  /// No description provided for @settingsSectionTranslate.
  ///
  /// In zh, this message translates to:
  /// **'中文翻译'**
  String get settingsSectionTranslate;

  /// No description provided for @autoTranslate.
  ///
  /// In zh, this message translates to:
  /// **'自动把海外标题和摘要译成中文'**
  String get autoTranslate;

  /// No description provided for @showOriginal.
  ///
  /// In zh, this message translates to:
  /// **'同时显示英文原文'**
  String get showOriginal;

  /// No description provided for @translationHint.
  ///
  /// In zh, this message translates to:
  /// **'默认用腾讯交互翻译（国内可直连，无需代理）。填写 DeepSeek 或通义 API Key 后，译文会更稳、更像新闻口吻。'**
  String get translationHint;

  /// No description provided for @translationApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key（可选）'**
  String get translationApiKey;

  /// No description provided for @translationBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'接口地址'**
  String get translationBaseUrl;

  /// No description provided for @translationModel.
  ///
  /// In zh, this message translates to:
  /// **'模型名'**
  String get translationModel;

  /// No description provided for @translating.
  ///
  /// In zh, this message translates to:
  /// **'正在把海外新闻译成中文…'**
  String get translating;

  /// No description provided for @relativeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get relativeJustNow;

  /// No description provided for @relativeMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前'**
  String relativeMinutes(int n);

  /// No description provided for @relativeHours.
  ///
  /// In zh, this message translates to:
  /// **'{n} 小时前'**
  String relativeHours(int n);

  /// No description provided for @relativeDays.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前'**
  String relativeDays(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
