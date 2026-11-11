# Chordior Android 移动端与 Web 工作站 (`chordior-android`)

Chordior 主项目的 Flutter 客户端实现，主要面向 **Android 平台（保留定制 `web/` PWA 与 WebAudio 工作站构建能力）**。内置 7 组跨八度原生采样音色、声部诱导（Voice-Leading）进行编曲与高自由度键盘/指板缩放交互。

返回总览：[仓库根 README](../README.md) | 查看 [音频管线图](../docs/images/audio-dsp-architecture.png)

---

## 运行截图

<p align="center">
  <img width="320" alt="Chordior Android Portrait UI" src="https://github.com/user-attachments/assets/026dc719-24ce-4602-80aa-57785f61c9a7" />
</p>

---

## 核心特性

1. **调式罗盘与顺阶分析 (`compass_screen.dart`)**
   - 实时匹配常见教会调式、和声小调、旋律小调与五声音阶，支持三和弦 / 七和弦 / 九和弦深度切换。
   - 右上角内置五度圈视图、根音与主音独立高亮逻辑，支持一键循环切换仅钢琴 / 仅吉他 / 双乐器视图。
2. **和弦工坊与声部诱导 (`studio_screen.dart`, `harmonic_presets.dart`)**
   - 支持 `Voice-Leading Compact` 等声部平滑连接排列策略、拍数与八度移调调节、拖拽排序和弦卡片。
   - 支持齐奏 (`Simultaneous`)、流行吉他扫弦 (`Pop Strum`)、上行琶音 (`Arp Up`)、下行琶音 (`Arp Down`) 四种演奏模式。
3. **Android 原生与 Web 双音频架构 (`audio_synth.dart`, `MainActivity.kt`)**
   - **Android 原生端**：通过 MethodChannel 调用 Kotlin `SoundPool` 多通道加载 `android/app/src/main/assets/audio/` 下 7 套乐器采样（`celesta`、`guitar_nylon`、`guitar_steel`、`organ`、`piano`、`rhodes`、`synth_pad` 共 119 份音频资源），实现低延迟平滑消音与复音回放。
   - **Web 端**：保留 `web/` 目录中的离线二进制采样（`.bin`）与 WebAudio DSP 播放逻辑，支持桌面浏览器独立构建与运行。
4. **移动端自适应极微缩放与设置中心 (`settings_screen.dart`)**
   - 钢琴与 21 品吉他指板均支持 `30% - 120%` 高精度缩放及字号自适应防挤压保底，兼顾单手操作与小屏全指板浏览。

---

## 目录结构

```text
chordior-android/
├── lib/
│   ├── main.dart                     # 应用入口与 3 标签页主导航 (调式罗盘 / 和弦工坊 / 设置中心)
│   ├── core/                         # 乐理引擎 (theory_engine.dart) 与进行预设 (harmonic_presets.dart)
│   ├── audio/                        # 跨端音频调度 (audio_synth.dart / web_synth_helper*)
│   ├── state/                        # Provider 全局状态管理与声音控制
│   ├── services/                     # 本地持久化存储服务 (shared_preferences)
│   ├── screens/                      # 调式罗盘屏 / 和弦工坊屏 / 设置中心屏
│   └── widgets/                      # 48 键钢琴 / 21 品吉他指板 / 五度圈卡片组件
├── android/
│   └── app/src/main/assets/audio/    # 7 套原生采样音色资源库
├── web/                              # 定制 Web PWA 与音频资源目录
├── test/                             # 乐理单元测试与 Widget 冒烟测试
├── pubspec.yaml                      # 独立 Flutter 包清单 (v1.0.0+1)
└── analysis_options.yaml             # 静态分析规则
```

---

## 独立构建与测试

### 1. 获取依赖、静态检查与测试

```bash
cd chordior-android
flutter pub get
flutter analyze
flutter test
```

### 2. 构建 Android Release APK

```bash
cd chordior-android
flutter build apk --release
```

生成产物位于 `chordior-android/build/app/outputs/flutter-apk/app-release.apk`。

### 3. 可选：构建 Web 工作站版本

```bash
cd chordior-android
flutter build web --release
```
