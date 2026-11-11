enum AppLanguage {
  zh, // 简体中文
  en, // English
  ja, // 日本語
}

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  static AppStrings of(AppLanguage language) => AppStrings(language);

  // 软件名称
  String get appName => 'Vox';

  // 顶部与基础
  String get settingsTitle {
    switch (language) {
      case AppLanguage.zh:
        return '设置';
      case AppLanguage.en:
        return 'Settings';
      case AppLanguage.ja:
        return '設定';
    }
  }

  String get languageTitle {
    switch (language) {
      case AppLanguage.zh:
        return '界面语言';
      case AppLanguage.en:
        return 'Language';
      case AppLanguage.ja:
        return '言語設定';
    }
  }

  String get themeModeTitle {
    switch (language) {
      case AppLanguage.zh:
        return '外观主题';
      case AppLanguage.en:
        return 'Theme';
      case AppLanguage.ja:
        return 'テーマ';
    }
  }

  String get themeDark {
    switch (language) {
      case AppLanguage.zh:
        return '暗黑科技';
      case AppLanguage.en:
        return 'Dark Mode';
      case AppLanguage.ja:
        return 'ダークモード';
    }
  }

  String get themeLight {
    switch (language) {
      case AppLanguage.zh:
        return '典雅明亮';
      case AppLanguage.en:
        return 'Light Mode';
      case AppLanguage.ja:
        return 'ライトモード';
    }
  }

  String get instrumentTitle {
    switch (language) {
      case AppLanguage.zh:
        return '原声音源';
      case AppLanguage.en:
        return 'Instrument';
      case AppLanguage.ja:
        return '音色選択';
    }
  }

  // 乐器名称国际化 (精确匹配 Concert Grand, Church Organ 等真实 ID 及常见别名)
  String instrumentName(String id, String defaultName) {
    final lower = id.toLowerCase();
    switch (language) {
      case AppLanguage.zh:
        if (lower.contains('diva') || lower.contains('virtual')) return '虚拟歌姬';
        if (lower.contains('female') || lower.contains('soprano')) return '柔美女声';
        if (lower.contains('male') || lower.contains('tenor') || lower.contains('baritone')) return '磁性男声';
        if (lower.contains('choir')) return '圣洁合唱';
        if (lower.contains('grand') || lower.contains('piano')) return '大三角钢琴';
        if (lower.contains('rhodes')) return '电钢琴 (Rhodes)';
        if (lower.contains('organ')) return '教堂管风琴';
        if (lower.contains('celesta') || lower.contains('bell')) return '钢片琴 / 钟琴';
        if (lower.contains('flute')) return '音乐会长笛';
        if (lower.contains('violin')) return '独奏小提琴';
        if (lower.contains('steel') || (lower.contains('guitar') && !lower.contains('nylon'))) return '民谣钢弦吉他';
        if (lower.contains('nylon')) return '古典尼龙吉他';
        return defaultName;
      case AppLanguage.en:
        if (lower.contains('diva') || lower.contains('virtual')) return 'Virtual Singer';
        if (lower.contains('female') || lower.contains('soprano')) return 'Female Voice';
        if (lower.contains('male') || lower.contains('tenor') || lower.contains('baritone')) return 'Male Voice';
        if (lower.contains('choir')) return 'Choir Aahs';
        if (lower.contains('grand') || lower.contains('piano')) return 'Concert Grand Piano';
        if (lower.contains('rhodes')) return 'Electric Piano (Rhodes)';
        if (lower.contains('organ')) return 'Church Pipe Organ';
        if (lower.contains('celesta') || lower.contains('bell')) return 'Celesta & Bells';
        if (lower.contains('flute')) return 'Concert Flute';
        if (lower.contains('violin')) return 'Solo Violin';
        if (lower.contains('steel') || (lower.contains('guitar') && !lower.contains('nylon'))) return 'Acoustic Guitar';
        if (lower.contains('nylon')) return 'Classical Guitar';
        return defaultName;
      case AppLanguage.ja:
        if (lower.contains('diva') || lower.contains('virtual')) return 'バーチャルシンガー';
        if (lower.contains('female') || lower.contains('soprano')) return '女性ボイス';
        if (lower.contains('male') || lower.contains('tenor') || lower.contains('baritone')) return '男性ボイス';
        if (lower.contains('choir')) return 'コーラス合唱';
        if (lower.contains('grand') || lower.contains('piano')) return 'グランドピアノ';
        if (lower.contains('rhodes')) return 'エレクトリックピアノ';
        if (lower.contains('organ')) return 'パイプオルガン';
        if (lower.contains('celesta') || lower.contains('bell')) return 'チェレスタ＆ベル';
        if (lower.contains('flute')) return 'コンサートフルート';
        if (lower.contains('violin')) return 'ソロバイオリン';
        if (lower.contains('steel') || (lower.contains('guitar') && !lower.contains('nylon'))) return 'アコースティックギター';
        if (lower.contains('nylon')) return 'クラシックギター';
        return defaultName;
    }
  }

  // 琴键点击防音符混叠/快速渐弱包络 (Voice Damping)
  String get voiceDampingTitle {
    switch (language) {
      case AppLanguage.zh:
        return '音符防浑浊渐弱';
      case AppLanguage.en:
        return 'Voice Damping';
      case AppLanguage.ja:
        return 'ノート減衰（濁り防止）';
    }
  }

  String get voiceDampingDesc {
    switch (language) {
      case AppLanguage.zh:
        return '弹奏新音符时平滑弱化旧音符，防止声音混叠浑浊';
      case AppLanguage.en:
        return 'Smoothly fade out previous notes to prevent muddy overlapping';
      case AppLanguage.ja:
        return '新しい音を弾く際に前の音を滑らかに減衰し濁りを防止';
    }
  }

  // 键盘外观与缩放
  String get keyboardSectionTitle {
    switch (language) {
      case AppLanguage.zh:
        return '键盘外观与缩放';
      case AppLanguage.en:
        return 'Keyboard Layout';
      case AppLanguage.ja:
        return '鍵盤表示設定';
    }
  }

  String get horizontalScale {
    switch (language) {
      case AppLanguage.zh:
        return '琴键横向缩放 (宽幅)';
      case AppLanguage.en:
        return 'Key Width (Scale)';
      case AppLanguage.ja:
        return '鍵盤の幅 (拡大縮小)';
    }
  }

  String get keyLength {
    switch (language) {
      case AppLanguage.zh:
        return '琴键纵向比例 (长薄)';
      case AppLanguage.en:
        return 'Key Length Ratio';
      case AppLanguage.ja:
        return '鍵盤の長さ比率';
    }
  }

  String get rangeManagerHeightTitle {
    switch (language) {
      case AppLanguage.zh:
        return '音区窗口纵向长度';
      case AppLanguage.en:
        return 'Range Sheet Height';
      case AppLanguage.ja:
        return '音域画面の高さ';
    }
  }

  String get autoFit {
    switch (language) {
      case AppLanguage.zh:
        return '自动贴合';
      case AppLanguage.en:
        return 'Auto Fit';
      case AppLanguage.ja:
        return '自動吸着';
    }
  }

  String get customHeight {
    switch (language) {
      case AppLanguage.zh:
        return '自定义';
      case AppLanguage.en:
        return 'Custom';
      case AppLanguage.ja:
        return 'カスタム';
    }
  }

  String get offsetFineTune {
    switch (language) {
      case AppLanguage.zh:
        return '贴合微调偏移';
      case AppLanguage.en:
        return 'Offset Fine-tune';
      case AppLanguage.ja:
        return '微調整オフセット';
    }
  }

  String get screenHeightRatio {
    switch (language) {
      case AppLanguage.zh:
        return '占屏幕高度比例';
      case AppLanguage.en:
        return 'Screen Height Ratio';
      case AppLanguage.ja:
        return '画面高さの割合';
    }
  }

  String get trackGroupingSection {
    switch (language) {
      case AppLanguage.zh:
        return '分轨排布设置';
      case AppLanguage.en:
        return 'Track Layout';
      case AppLanguage.ja:
        return 'トラック配置設定';
    }
  }

  String get separateRangeTracks {
    switch (language) {
      case AppLanguage.zh:
        return '冲突换行 (无重叠音区同排合并)';
      case AppLanguage.en:
        return 'Auto Multi-track on Conflict';
      case AppLanguage.ja:
        return '重なり防止トラック自動分離';
    }
  }

  String get defaultIndicatorSide {
    switch (language) {
      case AppLanguage.zh:
        return '新增音区默认方位';
      case AppLanguage.en:
        return 'Default Side for New Ranges';
      case AppLanguage.ja:
        return '新規音域の既定配置側';
    }
  }

  String get blackKeySide {
    switch (language) {
      case AppLanguage.zh:
        return '黑键侧';
      case AppLanguage.en:
        return 'Black Key Side';
      case AppLanguage.ja:
        return '黒鍵側';
    }
  }

  String get whiteKeySide {
    switch (language) {
      case AppLanguage.zh:
        return '白键侧';
      case AppLanguage.en:
        return 'White Key Side';
      case AppLanguage.ja:
        return '白鍵側';
    }
  }

  String get octaveNotationTitle {
    switch (language) {
      case AppLanguage.zh:
        return '八度记谱法标准';
      case AppLanguage.en:
        return 'Octave Notation';
      case AppLanguage.ja:
        return 'オクターブ記譜基準';
    }
  }

  String get octaveNotationSpn {
    switch (language) {
      case AppLanguage.zh:
        return '国际标准 SPN (中央C=C4)';
      case AppLanguage.en:
        return 'SPN (Middle C=C4)';
      case AppLanguage.ja:
        return '国際標準 SPN (中央C=C4)';
    }
  }

  String get octaveNotationYamaha {
    switch (language) {
      case AppLanguage.zh:
        return '雅马哈 Yamaha (中央C=C3)';
      case AppLanguage.en:
        return 'Yamaha (Middle C=C3)';
      case AppLanguage.ja:
        return 'ヤマハ Yamaha (中央C=C3)';
    }
  }

  String get octaveNotationDesc {
    switch (language) {
      case AppLanguage.zh:
        return 'SPN 适用于国际声乐与调音器；Yamaha 适用于 VOCALOID、UTAU 及部分音乐制作宿主。';
      case AppLanguage.en:
        return 'SPN is standard for vocalists and tuners; Yamaha is common in VOCALOID and UTAU.';
      case AppLanguage.ja:
        return 'SPN は声楽・調律の国際基準、ヤマハは VOCALOID や UTAU 制作の標準表記です。';
    }
  }

  String get resetAllDefaults {
    switch (language) {
      case AppLanguage.zh:
        return '恢复默认设置';
      case AppLanguage.en:
        return 'Restore Defaults';
      case AppLanguage.ja:
        return '初期設定に戻す';
    }
  }

  String get resetSuccess {
    switch (language) {
      case AppLanguage.zh:
        return '已恢复默认设置';
      case AppLanguage.en:
        return 'Settings restored to defaults';
      case AppLanguage.ja:
        return '初期設定に戻しました';
    }
  }

  String get resetTrackGroups {
    switch (language) {
      case AppLanguage.zh:
        return '重置分轨';
      case AppLanguage.en:
        return 'Reset Tracks';
      case AppLanguage.ja:
        return 'トラック再配置';
    }
  }

  String get resetTrackSuccess {
    switch (language) {
      case AppLanguage.zh:
        return '已恢复智能贪心分轨';
      case AppLanguage.en:
        return 'Tracks reset to smart layout';
      case AppLanguage.ja:
        return 'スマート配置にリセットしました';
    }
  }

  String get reset {
    switch (language) {
      case AppLanguage.zh:
        return '重置';
      case AppLanguage.en:
        return 'Reset';
      case AppLanguage.ja:
        return 'リセット';
    }
  }

  // ================= 核心模式与主控制栏 =================
  String get rangeSelectMode {
    switch (language) {
      case AppLanguage.zh:
        return '音区划选';
      case AppLanguage.en:
        return 'Select Range';
      case AppLanguage.ja:
        return '音域選択';
    }
  }

  String get arpeggioPractice {
    switch (language) {
      case AppLanguage.zh:
        return '琶音练习';
      case AppLanguage.en:
        return 'Arpeggio Practice';
      case AppLanguage.ja:
        return 'アルペジオ練習';
    }
  }

  String get listenPitch {
    switch (language) {
      case AppLanguage.zh:
        return '实时聆听';
      case AppLanguage.en:
        return 'Listen Pitch';
      case AppLanguage.ja:
        return 'ピッチ検出';
    }
  }

  String get listeningActive {
    switch (language) {
      case AppLanguage.zh:
        return '正在聆听...';
      case AppLanguage.en:
        return 'Listening...';
      case AppLanguage.ja:
        return '検出中...';
    }
  }

  String get play {
    switch (language) {
      case AppLanguage.zh:
        return '播放';
      case AppLanguage.en:
        return 'Play';
      case AppLanguage.ja:
        return '再生';
    }
  }

  String get pause {
    switch (language) {
      case AppLanguage.zh:
        return '暂停';
      case AppLanguage.en:
        return 'Pause';
      case AppLanguage.ja:
        return '一時停止';
    }
  }

  String get rootNote {
    switch (language) {
      case AppLanguage.zh:
        return '基音';
      case AppLanguage.en:
        return 'Root';
      case AppLanguage.ja:
        return '基音';
    }
  }

  String get suggestedVowel {
    switch (language) {
      case AppLanguage.zh:
        return '建议母音';
      case AppLanguage.en:
        return 'Vowel';
      case AppLanguage.ja:
        return '推奨母音';
    }
  }

  String get horizontal {
    switch (language) {
      case AppLanguage.zh:
        return '横向';
      case AppLanguage.en:
        return 'Horizontal';
      case AppLanguage.ja:
        return '横型';
    }
  }

  String get vertical {
    switch (language) {
      case AppLanguage.zh:
        return '竖排';
      case AppLanguage.en:
        return 'Vertical';
      case AppLanguage.ja:
        return '縦型';
    }
  }

  String get rangeManagerBtn {
    switch (language) {
      case AppLanguage.zh:
        return '音区';
      case AppLanguage.en:
        return 'Ranges';
      case AppLanguage.ja:
        return '音域';
    }
  }

  String get settingsBtn {
    switch (language) {
      case AppLanguage.zh:
        return '设置';
      case AppLanguage.en:
        return 'Settings';
      case AppLanguage.ja:
        return '設定';
    }
  }

  String get listenPermissionDenied {
    switch (language) {
      case AppLanguage.zh:
        return '未获得麦克风录音权限';
      case AppLanguage.en:
        return 'Microphone permission denied';
      case AppLanguage.ja:
        return 'マイクのアクセスが許可されていません';
    }
  }

  String trainerPatternTitle(String id, String defaultTitle) {
    switch (language) {
      case AppLanguage.zh:
        switch (id) {
          case 'five_tone':
            return '五度琶音 (1-3-5-3-1)';
          case 'octave_jump':
            return '八度跳跃 (1-5-8-5-1)';
          case 'triad_arpeggio':
            return '大三和弦 (1-3-5-8)';
          case 'sustained_tone':
            return '稳态长音 (Sustained)';
          default:
            return defaultTitle;
        }
      case AppLanguage.en:
        switch (id) {
          case 'five_tone':
            return '5-Tone Arpeggio (1-3-5-3-1)';
          case 'octave_jump':
            return 'Octave Jump (1-5-8-5-1)';
          case 'triad_arpeggio':
            return 'Major Triad (1-3-5-8)';
          case 'sustained_tone':
            return 'Sustained Tone';
          default:
            return defaultTitle;
        }
      case AppLanguage.ja:
        switch (id) {
          case 'five_tone':
            return '5音アルペジオ (1-3-5-3-1)';
          case 'octave_jump':
            return 'オクターブ跳躍 (1-5-8-5-1)';
          case 'triad_arpeggio':
            return '長三和音 (1-3-5-8)';
          case 'sustained_tone':
            return 'ロングトーン';
          default:
            return defaultTitle;
        }
    }
  }

  String get switchToLightMode {
    switch (language) {
      case AppLanguage.zh:
        return '切换到明亮模式';
      case AppLanguage.en:
        return 'Switch to Light Mode';
      case AppLanguage.ja:
        return 'ライトモードへ';
    }
  }

  String get switchToDarkMode {
    switch (language) {
      case AppLanguage.zh:
        return '切换到暗黑模式';
      case AppLanguage.en:
        return 'Switch to Dark Mode';
      case AppLanguage.ja:
        return 'ダークモードへ';
    }
  }

  String get settingsTooltip {
    switch (language) {
      case AppLanguage.zh:
        return '设置';
      case AppLanguage.en:
        return 'Settings';
      case AppLanguage.ja:
        return '設定';
    }
  }

  String get clickOrDragToSelectRange {
    switch (language) {
      case AppLanguage.zh:
        return '在键盘上点击或划选以选择音区';
      case AppLanguage.en:
        return 'Click or drag on piano to select range';
      case AppLanguage.ja:
        return '鍵盤をタップまたはドラッグして音域を選択';
    }
  }

  String get semitonesUnit {
    switch (language) {
      case AppLanguage.zh:
        return '半音';
      case AppLanguage.en:
        return 'st';
      case AppLanguage.ja:
        return '半音';
    }
  }

  String get previewRange {
    switch (language) {
      case AppLanguage.zh:
        return '试听';
      case AppLanguage.en:
        return 'Preview';
      case AppLanguage.ja:
        return '試聴';
    }
  }

  String get preferSharpLabel {
    switch (language) {
      case AppLanguage.zh:
        return '♯优先';
      case AppLanguage.en:
        return '♯ Prior';
      case AppLanguage.ja:
        return '♯優先';
    }
  }

  String get preferFlatLabel {
    switch (language) {
      case AppLanguage.zh:
        return '♭优先';
      case AppLanguage.en:
        return '♭ Prior';
      case AppLanguage.ja:
        return '♭優先';
    }
  }

  // 聆听灵敏度多语言
  String get listeningSensitivityTitle {
    switch (language) {
      case AppLanguage.zh:
        return '人声聆听灵敏度';
      case AppLanguage.en:
        return 'Pitch Sensitivity';
      case AppLanguage.ja:
        return 'ピッチ検出感度';
    }
  }

  String get sensitivityHigh {
    switch (language) {
      case AppLanguage.zh:
        return '高灵敏 (微弱声/哼鸣)';
      case AppLanguage.en:
        return 'High (Soft Voice)';
      case AppLanguage.ja:
        return '高感度 (弱音・ハミング)';
    }
  }

  String get sensitivityBalanced {
    switch (language) {
      case AppLanguage.zh:
        return '标准平衡 (推荐)';
      case AppLanguage.en:
        return 'Balanced (Recommended)';
      case AppLanguage.ja:
        return '標準バランス (推奨)';
    }
  }

  String get sensitivityNoiseResistant {
    switch (language) {
      case AppLanguage.zh:
        return '抗噪稳健 (强音)';
      case AppLanguage.en:
        return 'Noise-Resistant';
      case AppLanguage.ja:
        return 'ノイズ耐性 (強音)';
    }
  }

  // 琴键发光余晖效果多语言
  String get pianoGlowModeTitle {
    switch (language) {
      case AppLanguage.zh:
        return '琴键发光与余晖效果';
      case AppLanguage.en:
        return 'Key Glow Effect';
      case AppLanguage.ja:
        return '鍵盤グロー・残光効果';
    }
  }

  String get glowModeInstant {
    switch (language) {
      case AppLanguage.zh:
        return '即时响应';
      case AppLanguage.en:
        return 'Instant';
      case AppLanguage.ja:
        return '即時応答';
    }
  }

  String get glowModeFadeOut {
    switch (language) {
      case AppLanguage.zh:
        return '余晖渐隐 (推荐)';
      case AppLanguage.en:
        return 'Smooth Glow';
      case AppLanguage.ja:
        return '残光フェード (推奨)';
    }
  }

  String get glowModeTrail {
    switch (language) {
      case AppLanguage.zh:
        return '多音留痕';
      case AppLanguage.en:
        return 'Trail Trace';
      case AppLanguage.ja:
        return '軌跡トレース';
    }
  }

  // 全局界面与字体比例多语言
  String get uiScaleTitle {
    switch (language) {
      case AppLanguage.zh:
        return '全局界面比例';
      case AppLanguage.en:
        return 'UI Scale';
      case AppLanguage.ja:
        return 'UI表示倍率';
    }
  }

  String get uiScaleReset {
    switch (language) {
      case AppLanguage.zh:
        return '重置';
      case AppLanguage.en:
        return 'Reset';
      case AppLanguage.ja:
        return 'リセット';
    }
  }

  String get uiScaleHint {
    switch (language) {
      case AppLanguage.zh:
        return '在窄屏手机上调小比例可容纳更多内容并优化排版';
      case AppLanguage.en:
        return 'Scale down on narrow screens to fit more content';
      case AppLanguage.ja:
        return '狭い画面では縮小して表示崩れを防げます';
    }
  }
}
