# Vox Vocal Master 声乐训练工作台 (`vox-android`)

<p align="left">
  <img src="./Vox.png" width="76" alt="Vox App Icon" />
</p>

**Vox (`v1.4.0`)** 是独立剥离自原混杂仓库的附属项目，聚焦于**科学音域测量、声区色带可视化、实时麦克风音高纠偏与练声辅助**。本工程严格限定为 **仅面向 Android 平台**，已移除无用的 `web/`、`ios/`、`macos/`、`linux/`、`windows/` 模板空壳及冗余缓存。

返回总览：[仓库根 README](../README.md) | 查看 [音频管线图](../docs/images/audio-dsp-architecture.png)

---

## 核心功能与技术亮点

1. **多维度分组音域谱带 (`multi_range_ribbon.dart`, `vocal_range_model.dart`)**
   - 在钢琴黑键/白键两侧可视化叠加分组音域色带，对比女声、男声、流行与美声各声部区（例如女高音 Soprano、女中音 Mezzo、男高音 Tenor、男低音 Bass、混声/哨音扩展区等）。
   - 支持音域色带跨边拖拽调序、自定义分组颜色与实时叠加显示。
2. **88 键全音域交互钢琴 (`horizontal_piano.dart`, `vertical_piano.dart`)**
   - 支持竖屏横向钢琴与全屏双排自由切换，支持键位滑奏（Glissando）连贯发声与双指独立调整布局缩放。
   - 支持科学音高记法（**SPN**，如 `C4`）与日式雅马哈记法（**Yamaha**，如 `C3` = 中央 C）一键切换，并内置 **简/繁中、英、日** 三语界面切换 (`app_strings.dart`)。
3. **Android 48 复音采样与 Yin 实时基频提取 (`MainActivity.kt`, `real_audio_engine.dart`)**
   - **原生 48 复音发声引擎**：通过 Kotlin `SoundPool`（最大 48 并发流 + 节拍/音高采样池）直读原生音频，内置 **Piano (`piano`)、Diva Voice (`diva_voice`)、Organ (`organ`)、Flute (`flute`)、Violin (`violin`)、Rhodes (`rhodes`)、Nylon/Steel Guitar (`guitar_nylon` / `guitar_steel`)、Celesta (`celesta`)、Synth Pad (`synth_pad`)** 共 10 组多音色采样，支持按键瞬态发声与持续共鸣回响。
   - **实时麦克风音高识别**：基于 Kotlin 原生 `AudioRecord` (16kHz PCM) 与 **Yin 基频检测算法**，配合实时降噪灵敏度滑块与沉默防抖状态机 (`vocal_master_state.dart`)，精确回显演唱音名、八度定位、实时音分（Cents）偏差与五线谱高光指示。
4. **专业五线谱渲染与盲听训练 (`music_theory.dart`, `assets/fonts/Leland.otf`)**
   - 内嵌开源音乐制谱字体 `Leland.otf`，支持调号切换（升降记号偏好）、高低音谱表定位以及音程/听音盲测训练模式。

---

## 目录结构

```text
vox-android/
├── lib/
│   ├── main.dart                     # 应用入口与 VocalMasterStudioScreen
│   ├── core/                         # 三语本地化字典 (app_strings.dart) 与乐理音阶计算 (music_theory.dart)
│   ├── models/                       # 音域分级与声部分组数据模型
│   ├── state/                        # 核心状态机、录音音高防抖与 Persistence 存储
│   ├── audio/                        # 原生音频通道桥接 (real_audio_engine.dart)
│   └── widgets/
│       ├── header/                   # 实时音分仪表与调号状态顶栏
│       ├── piano/                    # 横向/竖向钢琴键盘与分组音域谱带
│       └── bottom/                   # 音域管理弹窗与 v1.4.0 设置面板
├── android/
│   ├── app/src/main/kotlin/          # MainActivity.kt (48 复音 SoundPool + AudioRecord Yin Pitch)
│   └── app/src/main/assets/audio/    # 原生多乐器采样音频库
├── assets/
│   ├── audio/                        # 参考采样音频 (diva_voice, flute, violin, organ, piano 等)
│   └── fonts/Leland.otf              # 专业五线谱符号字体
├── test/                             # 音域分组调序、持久化、音高防抖与窄屏无溢出测试 (70 项用例)
├── Vox.png                           # Vox 专属透明高分辨率应用标识
├── pubspec.yaml                      # 独立清单 (version: 1.4.0)
└── analysis_options.yaml             # 静态分析配置
```

---

## 独立构建与测试

> 权限说明：本应用包含实时跟唱音高监测模块，`AndroidManifest.xml` 声明了 `android.permission.RECORD_AUDIO` 权限（仅在开启麦克风监听模式时请求）。

### 1. 安装依赖、静态分析与全部 70 项测试

```bash
cd vox-android
flutter pub get
flutter analyze
flutter test
```

### 2. 构建 Android Release APK

```bash
cd vox-android
flutter build apk --release
```

生成产物位于 `vox-android/build/app/outputs/flutter-apk/app-release.apk`。
