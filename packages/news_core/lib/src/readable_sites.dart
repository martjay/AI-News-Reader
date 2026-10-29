/// Host-specific full-text extraction. Generic rules still run afterwards.
class ReadableSite {
  ReadableSite({
    required this.id,
    required this.hosts,
    this.selectors = const [],
    this.remove = const [],
    this.noise = const [],
    this.jinaFirst = false,
  });

  final String id;
  final List<String> hosts;
  final List<String> selectors;
  final List<String> remove;
  final List<RegExp> noise;
  final bool jinaFirst;
}

final kReadableSites = <ReadableSite>[
  ReadableSite(
    id: 'aihot',
    hosts: ['aihot.news'],
    selectors: ['.prose', '.article-content', 'article', 'main'],
    remove: ['.related', '.comments', 'aside'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'qbitai',
    hosts: ['qbitai.com'],
    selectors: ['.article', '.content-box', '.article-content', '#content'],
    remove: ['.share-box', '.related-posts', '.entry-meta', '.post-tags'],
    noise: [
      RegExp(r'量子位\s*[|｜]'),
      RegExp(r'关注量子位'),
      RegExp(r'转载请联系'),
    ],
  ),
  ReadableSite(
    id: 'jiqizhixin',
    hosts: ['jiqizhixin.com'],
    selectors: ['.article__content', '.js-article-content', '.article-content', 'article'],
    remove: ['.article__sidebar', '.recommended', '.follow-us'],
    noise: [RegExp(r'机器之心'), RegExp(r'点击星标')],
  ),
  ReadableSite(
    id: 'sspai',
    hosts: ['sspai.com'],
    selectors: ['.wangEditor-txt', '#article-content', '.article-body', '.content'],
    remove: ['.article-side', '.series-widget', '.ss-app-card'],
    noise: [RegExp(r'少数派'), RegExp(r'Matrix 精选'), RegExp(r'本作品采用')],
  ),
  ReadableSite(
    id: 'juejin',
    hosts: ['juejin.cn', 'juejin.im'],
    selectors: ['.article-content', '#article-root', '.markdown-body', '.article-viewer'],
    remove: ['.article-suspended-panel', '.sidebar-box', '.category-course-recommend'],
    noise: [RegExp(r'掘金'), RegExp(r'收藏成功'), RegExp(r'打开掘金')],
  ),
  ReadableSite(
    id: 'ithome',
    hosts: ['ithome.com'],
    selectors: ['#paragraph', '.post_content', '#content', '.content'],
    remove: ['.dajia', '.related_post', '.post_recommend', '.hot_tags', '#commentlist'],
    noise: [
      RegExp(r'IT之家'),
      RegExp(r'本文系'),
      RegExp(r'责编[：:]'),
      RegExp(r'欢迎前往IT之家'),
    ],
  ),
  ReadableSite(
    id: 'solidot',
    hosts: ['solidot.org'],
    selectors: ['.p_mainnew', '#news_content', '.p_content'],
    remove: ['.talk_item', '.sectioncomment'],
    noise: [RegExp(r'Solidot'), RegExp(r'来自[【\[]')],
  ),
  ReadableSite(
    id: 'kr36',
    hosts: ['36kr.com'],
    selectors: ['.articleDetailContent', '.kr-rich-text-wrapper', '.common-width.content', '.article-content'],
    remove: ['.article-footer', '.recommend-list', '.author-info'],
    noise: [RegExp(r'36氪'), RegExp(r'经授权转载'), RegExp(r'创业者服务')],
  ),
  ReadableSite(
    id: 'openai',
    hosts: ['openai.com'],
    selectors: ['article', '[class*="RichText"]', 'main article', '.prose'],
    remove: ['nav', 'footer', '[class*="Related"]'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'deepmind',
    hosts: ['deepmind.google', 'deepmind.com'],
    selectors: ['article', 'main article', '.blog-content'],
    remove: ['[class*="related"]', '[class*="footer"]'],
  ),
  ReadableSite(
    id: 'google_research',
    hosts: ['research.google', 'ai.googleblog.com', 'blog.google'],
    selectors: ['article', '.blog-content', '.post-body'],
    remove: ['.blog-sidebar'],
  ),
  ReadableSite(
    id: 'microsoft_ai',
    hosts: ['blogs.microsoft.com', 'microsoft.com'],
    selectors: ['.entry-content', 'article .content', '.c-paragraph'],
    remove: ['.related-posts', '.social-share-bar'],
  ),
  ReadableSite(
    id: 'nvidia',
    hosts: ['blogs.nvidia.com', 'nvidia.com'],
    selectors: ['.entry-content', 'article .content', '.article-body'],
    remove: ['.related-posts', '.social-share'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'hf_blog',
    hosts: ['huggingface.co'],
    selectors: ['.blog-content', 'article.blog', 'article', 'main'],
    remove: ['.blog-aside', '.hf-navbar'],
  ),
  ReadableSite(
    id: 'arxiv',
    hosts: ['arxiv.org'],
    selectors: ['blockquote.abstract', '#abs', '.abstract', 'body'],
    remove: ['#header', '#footer', '.extra-services', '#download-button'],
    noise: [RegExp(r'^arXiv:'), RegExp(r'Submitted on'), RegExp(r'view license')],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'techcrunch',
    hosts: ['techcrunch.com'],
    selectors: ['.entry-content', '.article-content', 'article .content'],
    remove: ['.wp-block-tc-related', '.ad-unit', '.wp-block-embed'],
    noise: [RegExp(r'TechCrunch'), RegExp(r'Image Credits'), RegExp(r'Read more:')],
  ),
  ReadableSite(
    id: 'venturebeat',
    hosts: ['venturebeat.com'],
    selectors: ['.article-content', '.entry-content', 'article'],
    remove: ['.vb-related', '.vb-newsletter'],
    noise: [RegExp(r'VentureBeat'), RegExp(r'Transform \d')],
  ),
  ReadableSite(
    id: 'mittr',
    hosts: ['technologyreview.com'],
    selectors: ['.gutenbergContent', '#content--body', '.contentBody', 'article'],
    remove: ['.c-related', '.c-newsletter'],
    noise: [RegExp(r'MIT Technology Review'), RegExp(r'This story is')],
  ),
  ReadableSite(
    id: 'marktechpost',
    hosts: ['marktechpost.com'],
    selectors: ['.td-post-content', '.entry-content', 'article'],
    remove: ['.td-post-source-tags', '.td-related'],
    noise: [RegExp(r'MarkTechPost'), RegExp(r'The post .+ appeared first')],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'v2ex',
    hosts: ['v2ex.com', 'www.v2ex.com'],
    selectors: ['.topic_content', '.markdown_body'],
    remove: ['#Top', '#Bottom', '#Rightbar', '.header', '.cell.flex-one-row'],
  ),
  ReadableSite(
    id: 'zhihu',
    hosts: ['zhihu.com', 'zhuanlan.zhihu.com'],
    jinaFirst: true,
    selectors: ['.Post-RichTextContainer', '.RichText', '.Post-RichText', '.QuestionRichText'],
    remove: ['.ContentItem-actions', '.Reward', '.Comments-container'],
    noise: [RegExp(r'打开知乎'), RegExp(r'下载知乎'), RegExp(r'查看全部 \d+ 条评论')],
  ),
  ReadableSite(
    id: 'zaobao',
    hosts: ['zaobao.com', 'zaobao.com.sg', 'zaochenbao.com'],
    jinaFirst: true,
    selectors: ['.article-content-rawhtml', '.article-content', '#article-body'],
    remove: ['.related-topics', '.paywall'],
    noise: [RegExp(r'联合早报'), RegExp(r'点此查看')],
  ),
  ReadableSite(
    id: 'wallstreetcn',
    hosts: ['wallstreetcn.com'],
    selectors: ['.RichText', '.article-content', '.live-content', '.livenews-detail'],
    remove: ['.article-toolbar', '.recommend-wrap', '.footer-download'],
    noise: [RegExp(r'华尔街见闻'), RegExp(r'打开APP'), RegExp(r'点击加载')],
  ),
  ReadableSite(
    id: 'thepaper',
    hosts: ['thepaper.cn'],
    selectors: ['.news_txt', '.index_contentwrap__', '#about_img', 'article'],
    remove: ['.news_phpto', '.relevant_news', '.comment_lanmu'],
    noise: [RegExp(r'澎湃新闻'), RegExp(r'责任编辑')],
  ),
  ReadableSite(
    id: 'cls',
    hosts: ['cls.cn'],
    selectors: ['.detail-content', '.m-content', '.telegraph-content', '.article-content'],
    remove: ['.recommend', '.comment-box'],
    noise: [RegExp(r'财联社'), RegExp(r'请注明出处')],
  ),
  ReadableSite(
    id: 'ifeng',
    hosts: ['ifeng.com'],
    selectors: ['#main_content', '.text-3nJMAD', '.article', 'article'],
    remove: ['.bottomShare', '.reference'],
    noise: [RegExp(r'凤凰网'), RegExp(r'责任编辑')],
  ),
  ReadableSite(
    id: 'cankaoxiaoxi',
    hosts: ['cankaoxiaoxi.com', 'ckxx.net', 'ckxxapp.ckxx.net'],
    selectors: ['.article-content', '#article-content', '.articleText'],
    noise: [RegExp(r'参考消息'), RegExp(r'来源[：:]')],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'freebuf',
    hosts: ['freebuf.com'],
    selectors: ['.article-content', '#content', '.article-body'],
    remove: ['.article-operate', '.relevant-article'],
    noise: [RegExp(r'FreeBuf'), RegExp(r'未经许可不得转载'), RegExp(r'客服小蜜蜂')],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'gelonghui',
    hosts: ['gelonghui.com'],
    selectors: ['.article-content', '.article-text', '.news-content'],
    noise: [RegExp(r'格隆汇'), RegExp(r'免责声明')],
  ),
  ReadableSite(
    id: 'hupu',
    hosts: ['hupu.com', 'bbs.hupu.com'],
    selectors: ['.quote-content', '.bbs-content', '.thread-content-detail'],
    remove: ['.floor-bottom', '.left-bar'],
  ),
  ReadableSite(
    id: 'pcbeta',
    hosts: ['pcbeta.com', 'bbs.pcbeta.com'],
    selectors: ['td.t_f', '.t_f', '#postlist .pcb'],
    remove: ['.sign', '.pstatus'],
  ),
  ReadableSite(
    id: 'chongbuluo',
    hosts: ['chongbuluo.com'],
    selectors: ['td.t_f', '.t_f'],
    remove: ['.sign'],
  ),
  ReadableSite(
    id: 'nowcoder',
    hosts: ['nowcoder.com'],
    selectors: ['.feed-content', '.post-content', '.nc-post-content'],
  ),
  ReadableSite(
    id: 'sputnik',
    hosts: ['sputniknews.cn', 'sputniknews.com'],
    selectors: ['.article__body', '.article__text', 'article'],
    noise: [RegExp(r'卫星通讯社')],
  ),
  ReadableSite(
    id: 'kaopu',
    hosts: ['kaopu.news', 'kaopunews.com'],
    selectors: ['article', '.post-content', 'main'],
  ),
  ReadableSite(
    id: 'github',
    hosts: ['github.com'],
    selectors: ['#readme', 'article.markdown-body', '.markdown-body'],
    remove: ['.Header', '.footer', '.js-header-wrapper'],
  ),
  ReadableSite(
    id: 'hn',
    hosts: ['news.ycombinator.com'],
    selectors: ['.toptext', '.comment', 'body'],
    remove: ['.pagetop', '#hnfooter'],
  ),
  ReadableSite(
    id: 'producthunt',
    hosts: ['producthunt.com'],
    selectors: ['[data-test="post-description"]', 'article', 'main'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'toutiao',
    hosts: ['toutiao.com'],
    jinaFirst: true,
    selectors: ['.article-content', '.syl-article-base', 'article'],
    noise: [RegExp(r'今日头条'), RegExp(r'打开头条')],
  ),
  ReadableSite(
    id: 'tencent-news',
    hosts: ['news.qq.com', 'new.qq.com', 'view.inews.qq.com', 'inews.qq.com'],
    selectors: ['.content-article', '#Cnt-Main-Article-QQ', 'article'],
    noise: [RegExp(r'腾讯新闻'), RegExp(r'打开腾讯新闻')],
  ),
  ReadableSite(
    id: 'bilibili',
    hosts: ['bilibili.com'],
    selectors: ['.desc-info-text', '.video-desc-container', '#v_desc'],
  ),
  ReadableSite(
    id: 'weibo',
    hosts: ['weibo.com', 's.weibo.com'],
    selectors: ['.Feed_body', '.weibo-text', '.card-wrap'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'baidu',
    hosts: ['baidu.com'],
    selectors: ['#content_left', 'article', 'main'],
  ),
  ReadableSite(
    id: 'tieba',
    hosts: ['tieba.baidu.com'],
    selectors: ['.d_post_content', '#j_p_postlist'],
  ),
  ReadableSite(
    id: 'douban',
    hosts: ['douban.com', 'movie.douban.com'],
    selectors: ['#link-report', '.review-content', '.indent'],
  ),
  ReadableSite(
    id: 'coolapk',
    hosts: ['coolapk.com'],
    selectors: ['.message', '.feed-message', 'article'],
  ),
  ReadableSite(
    id: 'mktnews',
    hosts: ['mktnews.net', 'mktnews.com'],
    selectors: ['.flash-content', '.article-content', 'article'],
  ),
  ReadableSite(
    id: 'xueqiu',
    hosts: ['xueqiu.com'],
    selectors: ['.article__bd', '.status-content', '.detail-content'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'fastbull',
    hosts: ['fastbull.cn', 'fastbull.com'],
    selectors: ['.news-content', '.article-content', 'article'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'jin10',
    hosts: ['jin10.com', 'flash.jin10.com'],
    selectors: ['.flash-content', '.article-content', 'article'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'dongqiudi',
    hosts: ['dongqiudi.com'],
    selectors: ['.article-content', '#article-content', 'article'],
  ),
  ReadableSite(
    id: 'kuaishou',
    hosts: ['kuaishou.com'],
    selectors: ['.video-info-title', 'article', 'main'],
    jinaFirst: true,
  ),
  ReadableSite(
    id: 'douyin',
    hosts: ['douyin.com'],
    selectors: ['[data-e2e="browse-video-desc"]', 'article', 'main'],
  ),
  ReadableSite(
    id: 'steam',
    hosts: ['steampowered.com', 'store.steampowered.com'],
    selectors: ['.game_description_snippet', '#game_area_description'],
  ),
];

ReadableSite? siteForUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return null;
  for (final site in kReadableSites) {
    for (final h in site.hosts) {
      if (host == h || host.endsWith('.$h')) return site;
    }
  }
  return null;
}
