# Chordior - 专业和弦与调式罗盘套件 (Music Theory & Chord Progression Suite)

> **AI-driven by: taketo**  
> 跨越 PC 桌面端与 Android 移动端的现代音乐理论探索、和弦声部诱导与和声编曲利器。

---
<img width="1200" height="2000" alt="ad4fa5ed5f3288cd013b53365d978a4c" src="https://github.com/user-attachments/assets/026dc719-24ce-4602-80aa-57785f61c9a7" />

<img width="2884" height="1767" alt="d9d00bc1b1c9ea8c4a914431aa032368" src="https://github.com/user-attachments/assets/109282e6-8f6b-442a-8611-627d677a4dc6" />

<img width="2636" height="1087" alt="image" src="https://github.com/user-attachments/assets/605888a9-4930-40f1-accf-43a6ffffc9df" />


## 📖 项目简介 (Overview)

**Chordior** 是一款面向音乐制作人、乐手、作曲家及音乐理论学习者的现代化音乐理论与和声探索套件。系统集成了**和弦与调式双向推导罗盘**、**吉他指板与钢琴键盘多视角实时联动**、**声部诱导和弦进行编曲工坊**，并搭载了**母带级多采样原声声学引擎**。

项目同时提供了两个独立而深度的平台版本：
- 🖥️ **PC 桌面端**：基于 Python 3 与 PyQt6 构建的专业音乐工作站级桌面客户端。
- 📱 **Android / 移动端**：基于 Flutter 3 与 Android 原生音频架构（SoundPool + AudioTrack）深度优化的现代高性能移动应用。

---

## 🌟 核心功能特性 (Core Features)

### 1. 调式罗盘与和弦智能探测 (Mode Compass & Theory Engine)
- **多维度和弦反查**：在键盘或指板上自由选取音符，智能识别和弦名称、和弦记号、和弦属性（大三、小三、属七、九和弦、挂四、减七等）与转位形式。
- **调式归属可能分析**：实时计算当前音符组合在自然大调、自然小调、多利亚 (Dorian)、弗里几亚 (Phrygian)、利底亚 (Lydian)、混合利底亚 (Mixolydian)、洛克里亚 (Locrian)、和声小调、旋律小调等各大调式中的归属概率。
- **调式主音与和弦根音高亮**：支持独立开关和弦根音、调式主音的高亮显示，并纳入柔和显色强度控制，层次分明，绝不混淆。

### 2. 双乐器键盘与指板联动 (Piano & Guitar Dual Visualization)
- **4 个八度全域钢琴键盘**：清晰展现和弦与调式音符分布，支持白键与黑键的高灵敏度触控交互。
- **21 品标准吉他指板**：完整模拟 6 弦 21 品吉他真实品格排布，支持音名标示、调式音级显示与根音强调色。
- **30% ~ 120% 自由极微缩放**：下限放宽至 30%，在极小屏幕尺寸的手机上亦可完整尽览 21 品全指板与全部琴键，且带有文字防挤压保底。

### 3. 和弦编曲工坊 (Progression Studio)
- **声部诱导 (Voice Leading)**：支持 Compact、Smooth 等多种声部平滑连接算法，避免和弦跳跃生硬。
- **演奏风格控制**：支持同时发声 (Simultaneous)、流行轻扫弦 (Pop Strum，35ms 弹性延迟)、上升琶音 (Arp Up) 与下降琶音 (Arp Down)。
- **和弦卡片管理**：和弦块拖拽排序、自由试听、插入与实时编辑。

### 4. 录音棚级母带多采样声学引擎 (Studio Master Audio Engine)
- **7 大真实乐器音色库**：
  1. `Concert Grand` (施坦威大三角钢琴 - 物理时长达 16 秒的饱满共鸣)
  2. `Acoustic Guitar` (真实钢弦民谣吉他原声)
  3. `Nylon Guitar` (古典尼龙弦吉他温润弹拨)
  4. `Warm Synth Pad` (温暖模拟合成器铺底，具备 160ms 慢起、三失谐立体声声场)
  5. `Church Organ` (宏大教堂管风琴风管气鸣)
  6. `Fender Rhodes` (经典复古电钢琴)
  7. `Celesta & Bells` (梦幻钢片琴与八音盒钟鸣)
- **多音防爆音削波保护 (Headroom Limiter)**：根据和弦音数自适应对数压低单音增益，杜绝 6~8 音密集和弦在 16-bit DAC 上的硬件削波破音。
- **微交错平摊调度 (Micro-Staggering)**：在密集并发时错开 2ms 调度，平摊 CPU 瞬时调用峰值，消除低配机型的 Audio Underrun 杂音。
- **前慢后快平滑余弦衰减包络 (Cosine Rolloff Envelope)**：
  - 前 65% 时间保持 100% 饱满发声；
  - 后 35% 时间沿余弦曲线平滑滚降；
  - 终点提前 220ms 归零，所有音符在同一瞬间同步静默停止，彻底杜绝长短脚与硬切杂音。

---

## 🖥️ PC 桌面端指南 (Desktop Version)

### 技术栈 (Tech Stack)
- **语言**：Python 3.10+
- **GUI 框架**：PyQt6
- **音频架构**：Pygame Mixer / NumPy 浮点混音 / Mido (MIDI 支持)

### 快速启动 (Quick Start)
1. **安装依赖**：
   ```bash
   pip install PyQt6 pygame numpy mido
   ```
2. **运行主程序**：
   ```bash
   python chord_finder.py
   ```
3. **独立工具模块**：
   - 运行和弦工坊独立窗口：`python progression_studio.py`
   - 运行五度圈工具：`python circle_of_fifths.py`

### 独立可执行文件打包 (PyInstaller Build)
项目根目录下已包含预配置好的 PyInstaller 规范文件：
```bash
pyinstaller Chordior.spec
```
构建成功后，将在 `dist/Chordior/` 下生成免安装绿色版 Windows 桌面可执行程序。

---

## 📱 Android 移动端指南 (Android Mobile Version)

### 技术栈 (Tech Stack)
- **跨平台框架**：Flutter 3.x (Dart)
- **底层音频桥接**：Kotlin + Android 原生 `SoundPool` + `AudioTrack` (通过 `MethodChannel` 高速通信)
- **状态管理**：Provider / ChangeNotifier 全局响应式架构
- **数据持久化**：SharedPreferences (断电保存调式音、和弦音、配色、缩放等配置)

### 安装包直接体验 (Pre-built APK)
根目录下已提供预编译打包的正式版 APK，支持直接传至手机安装：
- **文件路径**：`Chordior-v1.0.0.apk`
- **应用名称**：Chordior
- **图标适配**：已适配标准方形与圆形自适应图标（LANCZOS 高保真重采样）。

### 源码编译与调试 (Build from Source)
1. **进入 Flutter 工程目录**：
   ```bash
   cd chordior_flutter
   ```
2. **配置 Android 与 Java 环境变量 (PowerShell 示例)**：
   ```powershell
   $env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
   $env:ANDROID_HOME = "X:\AI project\AndroidSdk"
   $env:Path = "X:\AI project\Flutter\bin;C:\Program Files\Java\jdk-21\bin;X:\AI project\AndroidSdk\platform-tools;" + $env:Path
   ```
3. **代码静态检查**：
   ```powershell
   flutter analyze lib/
   ```
4. **编译 Release APK**：
   ```powershell
   flutter build apk --release
   ```
   产物位于：`build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Web 预览端指南 (Web Version)

Android 端的 Flutter 工程同样完整支持直接编译为现代 Web 单页应用：
1. **编译 Web 端产物**：
   ```powershell
   flutter build web --release
   ```
2. **本地 HTTP 预览**：
   ```powershell
   python -m http.server 8080 --bind 127.0.0.1
   ```
3. 打开浏览器访问：`http://127.0.0.1:8080` 即可实时体验与移动端高度一致的交互。

---

## 📂 项目目录架构 (Directory Structure)

```text
Chordior/
├── Chordior-v1.0.0.apk           # 最新编译的 Android 正式版安装包
├── README.md                     # 本项目全景文档
├── Chordior.spec                 # PC 端 PyInstaller 打包配置文件
│
├── chord_finder.py               # PC 端主窗口：调式罗盘、和弦识别与交互中心
├── progression_studio.py         # PC 端和弦进行编曲工坊
├── theory_engine.py              # PC 端音乐理论计算引擎
├── guitar_widget.py              # PC 端吉他指板组件
├── piano_widget.py               # PC 端钢琴键盘组件
├── audio_synth.py                # PC 端音频合成引擎
├── circle_of_fifths.py           # PC 端五度圈可视化组件
├── color_picker_dialog.py        # PC 端调色板与配色方案
│
├── icon_concepts/                # 应用图标设计母带
│   ├── icon_saishuu.png          # 最终版高清应用图标 (1254x1254)
│   └── icon_master_square.png    # 正方形矢量图标
│
└── chordior_flutter/             # Flutter 移动端 & Web 端完整项目
    ├── lib/
    │   ├── main.dart             # 移动端入口、底部导航与全局主题
    │   ├── state/
    │   │   └── app_state.dart    # 全局响应式状态机与配置持久化
    │   ├── screens/
    │   │   ├── compass_screen.dart # 调式罗盘主页面
    │   │   ├── studio_screen.dart  # 和弦工坊页面
    │   │   └── settings_screen.dart# 综合设置中心 (含 taketo 署名)
    │   ├── widgets/
    │   │   ├── piano_view.dart   # 触摸优化钢琴视图 (支持 30% 缩放)
    │   │   ├── guitar_view.dart  # 触摸优化吉他指板 (支持 30% 缩放)
    │   │   └── circle_of_fifths_dialog.dart # 五度圈弹窗
    │   ├── audio/
    │   │   └── audio_synth.dart  # 原生 SoundPool / Web Audio 桥接通道
    │   └── services/
    │       └── storage_service.dart # 本地配置存取持久化服务
    │
    ├── android/                  # Android 原生平台工程
    │   └── app/src/main/
    │       ├── AndroidManifest.xml # 应用清单 (配置 Chordior 名称与图标)
    │       ├── kotlin/.../MainActivity.kt # 专有音频调度引擎与混音削波保护
    │       └── assets/audio/     # 打包进 APK 的 6 大乐器共 102 个专业采样
    │           ├── piano/        # 施坦威钢琴长录音采样
    │           ├── organ/        # 管风琴母带淡出切片
    │           ├── synth_pad/    # 立体声温润合成器采样
    │           ├── guitar_steel/ # 钢弦吉他采样
    │           ├── guitar_nylon/ # 尼龙吉他采样
    │           ├── rhodes/       # 电钢琴采样
    │           └── celesta/      # 钢片琴采样
    └── web/                      # Web 端托管与 PWA 资产配置
```

---

## 🎨 配色与视觉设计哲学 (Visual Design)

Chordior 强调**“功能与美学共生”**：
- **深色模式 (Dark Mode)**：深邃的炭黑背景 (`#121216`) 搭配高对比度的发光和弦音符，适合舞台与昏暗录音室环境。
- **明亮模式 (Light Mode)**：柔和护眼的纸白灰质感，适合日间排练与理论教学。
- **色彩层级映射**：
  - 和弦组成音：明亮高饱和主强调色，指板一目了然；
  - 调式从属音：次级柔和色，支持独立调节显色透明度；
  - 根音标记：专属轮廓与标识符，强化调性骨架感知。

---

## 🤝 贡献与反馈 (Contribution)

本项目核心音乐算法、声学包络引擎与跨平台交互由 **taketo** 驱动架构。如果您在使用过程中遇到任何关于声学计算、调式识别或指板布局的问题，欢迎提交 Issue 或提供改进建议。

> *“Let the harmonies speak, and the compass lead.”*  
> **Chordior - AI-driven by: taketo**
