class TtsVoice {
  const TtsVoice({
    required this.id,
    required this.locale,
    required this.nameZh,
    required this.nameEn,
    required this.female,
  });

  final String id;
  final String locale;
  final String nameZh;
  final String nameEn;
  final bool female;

  String label(bool chinese) {
    final name = chinese ? nameZh : nameEn;
    final gender = chinese ? (female ? '女' : '男') : (female ? 'Female' : 'Male');
    return '$name · $gender';
  }
}

const kDefaultZhVoice = 'zh-CN-XiaoxiaoNeural';
const kDefaultEnVoice = 'en-US-AriaNeural';

/// Voices confirmed against the live Edge Read Aloud endpoint.
/// Extra Azure names (晓辰/晓涵/晓梦/Davis 等) still appear in old lists but return 403.
const kTtsVoices = <TtsVoice>[
  TtsVoice(id: 'zh-CN-XiaoxiaoNeural', locale: 'zh-CN', nameZh: '晓晓', nameEn: 'Xiaoxiao', female: true),
  TtsVoice(id: 'zh-CN-XiaoyiNeural', locale: 'zh-CN', nameZh: '晓伊', nameEn: 'Xiaoyi', female: true),
  TtsVoice(id: 'zh-CN-XiaoxuanNeural', locale: 'zh-CN', nameZh: '晓萱', nameEn: 'Xiaoxuan', female: true),
  TtsVoice(id: 'zh-CN-YunxiNeural', locale: 'zh-CN', nameZh: '云希', nameEn: 'Yunxi', female: false),
  TtsVoice(id: 'zh-CN-YunyangNeural', locale: 'zh-CN', nameZh: '云扬', nameEn: 'Yunyang', female: false),
  TtsVoice(id: 'zh-CN-YunjianNeural', locale: 'zh-CN', nameZh: '云健', nameEn: 'Yunjian', female: false),
  TtsVoice(id: 'zh-CN-YunxiaNeural', locale: 'zh-CN', nameZh: '云夏', nameEn: 'Yunxia', female: false),
  TtsVoice(id: 'en-US-AriaNeural', locale: 'en-US', nameZh: 'Aria', nameEn: 'Aria', female: true),
  TtsVoice(id: 'en-US-JennyNeural', locale: 'en-US', nameZh: 'Jenny', nameEn: 'Jenny', female: true),
  TtsVoice(id: 'en-US-EmmaNeural', locale: 'en-US', nameZh: 'Emma', nameEn: 'Emma', female: true),
  TtsVoice(id: 'en-US-AvaNeural', locale: 'en-US', nameZh: 'Ava', nameEn: 'Ava', female: true),
  TtsVoice(id: 'en-US-GuyNeural', locale: 'en-US', nameZh: 'Guy', nameEn: 'Guy', female: false),
  TtsVoice(id: 'en-US-AndrewNeural', locale: 'en-US', nameZh: 'Andrew', nameEn: 'Andrew', female: false),
  TtsVoice(id: 'en-US-BrianNeural', locale: 'en-US', nameZh: 'Brian', nameEn: 'Brian', female: false),
];

List<TtsVoice> voicesForLocale(String locale) =>
    kTtsVoices.where((v) => v.locale == locale).toList(growable: false);

TtsVoice voiceById(String id) {
  for (final voice in kTtsVoices) {
    if (voice.id == id) return voice;
  }
  return kTtsVoices.first;
}
