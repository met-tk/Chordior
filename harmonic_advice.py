"""
Harmonic Advice Database - 调式顺阶和声实战使用建议与声部解构知识库 (工业级事务参考手册版)
面向现代编曲、爵士/流行及电影配乐的高严谨度调式和声理论参考字典。
规范格式：
- 功能归属 (func)
- 顺阶原型 (prototype)
- 常用选型 (common_form)
- 声部与配置说明 (theory)
- 规范连接 (progressions)
"""

DEGREE_ADVICE_DATABASE = {
    "Ionian (自然大调 Major)": [
        {
            "degree": "I",
            "func": "主功能组 (Tonic Group)",
            "prototype": "I / Imaj7 (如 C / Cmaj7，构成音：1 - 3 - 5 - 7)",
            "common_form": "I, Imaj7, Iadd9, I6/9",
            "theory": "调式稳定基准。三音与七音构成纯正大调色彩。实务中常加入 9 音 (add9) 或 6 音 (6/9) 以柔化大七度尖锐摩擦，并避免 11 音 (4 音为避用音 Avoid Note)。",
            "progressions": "• I → IV → V → I\n• I → vi → ii → V",
        },
        {
            "degree": "ii",
            "func": "下属功能组 (Subdominant Group)",
            "prototype": "ii / iim7 (如 Dm / Dm7，构成音：2 - 4 - 6 - 1)",
            "common_form": "iim7, iim9, iim11",
            "theory": "弱下属属性。与 IV 级共享两个音 (4, 6)，常作为 IV 级平滑替代。在功能和声中担当 V 级属和弦的前置准备级数，扩展至 m7 或 m9 可提升声部平稳度。",
            "progressions": "• ii7 → V7 → Imaj7\n• I → ii7 → V7",
        },
        {
            "degree": "iii",
            "func": "主功能代理 (Tonic Substitute / Mediant)",
            "prototype": "iii / iiim7 (如 Em / Em7，构成音：3 - 5 - 7 - 2)",
            "common_form": "iiim7, iii7",
            "theory": "与主和弦 I 共享三个音 (3, 5, 7)，属弱主功能代用。因包含导音 (7)，调性倾向性较弱，实务多用作 I 级至 IV 级之间的下行级进过渡或挂留中继。",
            "progressions": "• I → iii → IV → V\n• iii7 → vi7 → ii7 → V7",
        },
        {
            "degree": "IV",
            "func": "下属功能组 (Subdominant Group)",
            "prototype": "IV / IVmaj7 (如 F / Fmaj7，构成音：4 - 6 - 1 - 3)",
            "common_form": "IV, IVmaj7, IVadd9, IV6",
            "theory": "纯正下属功能核心。和弦根音为全调下属音 (4)，引入适度张力并开展声部运动。可自由连接回 I 级（变格进行）或推进至 V 级。",
            "progressions": "• IV → V → I\n• IV → I (变格终止)",
        },
        {
            "degree": "V",
            "func": "属功能组 (Dominant Group)",
            "prototype": "V / V7 (如 G / G7，构成音：5 - 7 - 2 - 4)",
            "common_form": "V, V7, V9, V13, Vsus4",
            "theory": "调性引力核心。三音 (导音 7) 与七音 (4) 构成减五度三全音，具备向主和弦 I 解决的强驱动力。实务可采用 Vsus4 延缓解决或加入 9/13 扩展声部。",
            "progressions": "• V7 → I\n• ii7 → V7 → Imaj7",
        },
        {
            "degree": "vi",
            "func": "主功能代理 (Tonic Substitute / Submediant)",
            "prototype": "vi / vim7 (如 Am / Am7，构成音：6 - 1 - 3 - 5)",
            "common_form": "vim, vim7, vim9",
            "theory": "关系小调主和弦。与 I 共享三个音 (1, 3, 5)，具强主功能代用属性。用于阻碍终止（V → vi）吸收属张力，或作为现代流行循环的起点。",
            "progressions": "• V7 → vi (阻碍终止)\n• vi → IV → I → V",
        },
        {
            "degree": "vii°",
            "func": "导功能组 (Leading-Tone Group / Dominant Substitute)",
            "prototype": "vii° / viim7b5 (如 Bdim / Bm7b5，构成音：7 - 2 - 4 - 6)",
            "common_form": "viim7b5 (半减七); 流行实务常以 V7/3 代替",
            "theory": "包含导音 (7) 与三全音 (7-4)，属于无根音属和弦 (Rootless V7)。由于根音支撑弱且五度为减五度，实务中常由 V7 第一转位 (V6 或 V7/3) 替代。",
            "progressions": "• vii° → I\n• ii → viim7b5 → I",
        },
    ],

    "Aeolian (自然小调 Minor)": [
        {
            "degree": "i",
            "func": "调式主和弦 (Modal Tonic)",
            "prototype": "i / im7 (如 Am / Am7，构成音：1 - ♭3 - 5 - ♭7)",
            "common_form": "im, im7, im9, im11",
            "theory": "小调稳定基准。三音为小三度 (♭3)。实务中常用 im9 或 im11 保持织体开阔感，避免使用大七度音以免偏离自然小调。",
            "progressions": "• i → ♭VI → ♭VII → i\n• i → iv → v → i",
        },
        {
            "degree": "ii°",
            "func": "下属功能组 / 减上主和弦 (Supertonic Diminished)",
            "prototype": "ii° / iim7b5 (如 Bdim / Bm7b5，构成音：2 - 4 - ♭6 - 1)",
            "common_form": "iim7b5 (半减七)",
            "theory": "小调专属预备级数。包含减五度 (2-♭6)，但因 ♭6 音为小调下属特征音，故具有明确的下属功能，是小调 ii-V-i 进程的标准起始和弦。",
            "progressions": "• iim7b5 → V7 → im7\n• iim7b5 → ♭VII → i",
        },
        {
            "degree": "♭III",
            "func": "关系大调主和弦 (Relative Major Tonic / Mediant)",
            "prototype": "♭III / ♭IIImaj7 (如 C / Cmaj7，构成音：♭3 - 5 - ♭7 - 2)",
            "common_form": "♭III, ♭IIImaj7, ♭IIIadd9",
            "theory": "与关系大调主和弦重合。共享 i 级多数和弦音，提供大调色彩转换，常作为小调离调或声部舒展的中继点。",
            "progressions": "• i → ♭III → ♭VII → ♭VI\n• ♭III → ♭VI → ♭VII → i",
        },
        {
            "degree": "iv",
            "func": "下属功能组 (Subdominant Group)",
            "prototype": "iv / ivm7 (如 Dm / Dm7，构成音：4 - ♭6 - 1 - ♭3)",
            "common_form": "iv, ivm7, ivm9, iv6",
            "theory": "纯正小调下属核心。和弦三音为小调特征色彩音 (♭6)。因其不含大三度与三全音，音响暗淡稳定，为小调终止式提供坚实支撑。",
            "progressions": "• iv → v → i\n• i → iv → ♭VII → ♭III",
        },
        {
            "degree": "v",
            "func": "小属功能组 (Minor Dominant Group)",
            "prototype": "v / vm7 (如 Em / Em7，构成音：5 - ♭7 - 2 - 4)",
            "common_form": "vm7; 若需强调调性解决则借用和声小调 V7",
            "theory": "自然小调属和弦三音为降导音 (♭7)，不含导音，因此无传统大属和弦的尖锐张力。若需严格保持 Aeolian 调式纯度使用 vm7；若需强功能解决则转用和声小调 V7。",
            "progressions": "• vm7 → im7 (纯正调式进行)\n• ♭VI → ♭VII → vm7 → i",
        },
        {
            "degree": "♭VI",
            "func": "下中和弦 (Submediant / Subdominant Substitute)",
            "prototype": "♭VI / ♭VImaj7 (如 F / Fmaj7，构成音：♭6 - 1 - ♭3 - 5)",
            "common_form": "♭VI, ♭VImaj7, ♭VIadd9",
            "theory": "根音为小调特征色彩音 (♭6)。大三和弦结构。与 iv 级共享两个音，充当下属功能替代；在全音级进终止式中充当 ♭VII 的前置和弦。",
            "progressions": "• ♭VI → ♭VII → i (级进终止式)\n• i → ♭VI → ♭III → ♭VII",
        },
        {
            "degree": "♭VII",
            "func": "下导调式终止和弦 (Subtonic Cadence)",
            "prototype": "♭VII / ♭VII7 (如 G / G7，构成音：♭7 - 2 - 4 - 6)",
            "common_form": "♭VII, ♭VIIadd9, ♭VII6",
            "theory": "调式标志性级数。由于缺失导音 (7)，通过全音大步下行至主音 (♭7 → 1)，构成现代流行、摇滚与配乐中最典型的小调全音终止式。",
            "progressions": "• ♭VII → i\n• ♭VI → ♭VII → i",
        },
    ],

    "Harmonic Minor (和声小调)": [
        {
            "degree": "i",
            "func": "主功能组 (Tonic Group)",
            "prototype": "i / im(maj7) (如 Am / Am(maj7)，构成音：1 - ♭3 - 5 - 7)",
            "common_form": "im, im6, im(add9); 谨慎使用 im(maj7)",
            "theory": "七度音升高为自然导音 (7)。顺阶七和弦 im(maj7) 内部小三度与大七度形成不协和摩擦，实务常精简为纯小三和弦 im 或 im6，导音仅在属和弦中显现。",
            "progressions": "• i → iv → V7 → i\n• i → iim7b5 → V7 → i",
        },
        {
            "degree": "ii°",
            "func": "下属功能组 (Subdominant Group)",
            "prototype": "ii° / iim7b5 (如 Bdim / Bm7b5，构成音：2 - 4 - ♭6 - 1)",
            "common_form": "iim7b5 (半减七)",
            "theory": "构成与自然小调一致。五音 ♭6 向属和弦五音 5 的半音倾向极强，是通往大属七和弦 V7 的最标准下属预备级数。",
            "progressions": "• iim7b5 → V7 → im\n• iim7b5 → V7(♭9) → im",
        },
        {
            "degree": "♭III+",
            "func": "增中和弦 (Augmented Mediant / Dominant Function)",
            "prototype": "♭III+ / ♭IIImaj7#5 (如 C+ / Cmaj7#5，构成音：♭3 - 5# - 7 - 2)",
            "common_form": "避免直接使用；实务多视为 V7/♭3 或转位处理",
            "theory": "包含增五度 (♭3-7) 与大七度，声部张力极高且极不稳定。在实务中极少独立停留，通常作为主和弦向属和弦过渡的经过和声。",
            "progressions": "• i → ♭III+ → iv → V7\n• ♭III+ → V7",
        },
        {
            "degree": "iv",
            "func": "下属功能组 (Subdominant Group)",
            "prototype": "iv / ivm7 (如 Dm / Dm7，构成音：4 - ♭6 - 1 - ♭3)",
            "common_form": "iv, ivm7, iv6",
            "theory": "纯正小调下属核心。不含导音，保持了深暗的下属质感。与 V7 连接构成小调中最严整的传统和声终止准备。",
            "progressions": "• iv → V7 → i\n• i → iv → V7",
        },
        {
            "degree": "V",
            "func": "大属功能组 (Major Dominant Group)",
            "prototype": "V / V7 (如 E / E7，构成音：5 - 7 - 2 - 4)",
            "common_form": "V7, V7(♭9), V7(♭13)",
            "theory": "和声小调存在的核心目的所在。将五级和弦三音人工升高半音形成自然导音 (7)，与七音 (4) 构成三全音，具备无可替代的向小主和弦 (im) 的解决引力。",
            "progressions": "• V7 → i\n• V7(♭9) → i",
        },
        {
            "degree": "♭VI",
            "func": "阻碍终止中继和弦 (Submediant / Deceptive Resolution)",
            "prototype": "♭VI / ♭VImaj7 (如 F / Fmaj7，构成音：♭6 - 1 - ♭3 - 5)",
            "common_form": "♭VI, ♭VImaj7",
            "theory": "用于阻碍终止（V7 → ♭VI）。导音 (7) 上行解决至主音 (1)，而根音进行至 ♭6，形成意外中断效果，随后再重新导入 ii°-V7 解决。",
            "progressions": "• V7 → ♭VI (阻碍终止)\n• ♭VI → iim7b5 → V7 → i",
        },
        {
            "degree": "vii°",
            "func": "减七导和弦 (Diminished 7th Leading-Tone Group)",
            "prototype": "vii° / vii°7 (如 G#dim / G#dim7，构成音：7 - 2 - 4 - ♭6)",
            "common_form": "vii°7 (全减七和弦)",
            "theory": "全减七结构，由三个小三度叠置构成。四个音中任意一个均可作为导音向四个不同调性解决，是古典与现代和声中对称性最高的转调与导和弦工具。",
            "progressions": "• vii°7 → i\n• iv → vii°7 → i",
        },
    ],

    "Dorian (多利亚调式)": [
        {
            "degree": "i",
            "func": "调式主和弦 (Modal Tonic)",
            "prototype": "i / im7 (如 Dm / Dm7，构成音：1 - ♭3 - 5 - ♭7)",
            "common_form": "im7, im9, im11 (推荐四度叠置 Quartal Voicing)",
            "theory": "小调式中心。实务中推荐使用包含 9 音或 11 音的四度叠置形态，避免过多强调纯三度，以营造爵士与现代音乐特有的悬浮织体。",
            "progressions": "• im7 → IV7 → im7\n• im7 → ♭VII → IV7 → im7",
        },
        {
            "degree": "ii",
            "func": "上主和弦 / 弱终止中继 (Supertonic Cadence)",
            "prototype": "ii / iim7 (如 Em / Em7，构成音：2 - 4 - 6 - 1)",
            "common_form": "iim7",
            "theory": "五音包含 Dorian 特征色彩音 (♮6)。不同于自然小调的减和弦 (ii°)，Dorian 的 ii 级为稳定的小七和弦，可作为副特征和弦连接至 i 级。",
            "progressions": "• iim7 → im7\n• im7 → iim7 → IV7 → im7",
        },
        {
            "degree": "♭III",
            "func": "大调中音和弦 (Mediant / Avoid Focus)",
            "prototype": "♭III / ♭IIImaj7 (如 F / Fmaj7，构成音：♭3 - 5 - ♭7 - 2)",
            "common_form": "♭IIImaj7",
            "theory": "关系大调主和弦。四音包含调式特征音 ♮6，若停留过久容易将听觉中心偏转为关系大调 I 级，实务多用作声部快速经过和弦。",
            "progressions": "• im7 → ♭IIImaj7 → IV7\n• ♭IIImaj7 → ♭VII → im7",
        },
        {
            "degree": "IV",
            "func": "调式特征终止和弦 (Primary Characteristic Cadence)",
            "prototype": "IV / IV7 (如 G / G7，构成音：4 - 6 - 1 - ♭3)",
            "common_form": "IV, IV7, IV6, IV9 (推荐包含 6 音或 9 音)",
            "theory": "和弦三音为 Dorian 调式的特征大六度音 (♮6)。相较于自然小调的小四级 (iv)，大三度结构使其成为确立 Dorian 调式色彩的核心级数。直接连接回 i 级构成调式终止式。",
            "progressions": "• IV7 → im7 / im9\n• im7 → IV7 → ♭VII → im7",
        },
        {
            "degree": "v",
            "func": "小属和弦 (Minor Dominant)",
            "prototype": "v / vm7 (如 Am / Am7，构成音：5 - ♭7 - 2 - 4)",
            "common_form": "vm7",
            "theory": "属位小和弦。缺乏自然导音，调性吸引力弱，实务中主要作为声部平稳下行的副中继级数，避免与自然大调属和弦混淆。",
            "progressions": "• im7 → vm7 → IV7 → im7\n• vm7 → im7",
        },
        {
            "degree": "vi°",
            "func": "调式避免和弦 (Avoid Chord / Tritone Diminished)",
            "prototype": "vi° / vim7b5 (如 Bdim / Bm7b5，构成音：6 - 1 - ♭3 - 5)",
            "common_form": "避免作为主支点使用；常用 ♭VII 级或 ii 级替代",
            "theory": "和弦根音虽为特征音 ♮6，但内部包含减五度三全音 (6-♭3)，且直接指向关系大调主和弦，易破坏 Dorian 调性平衡，实务中避免长音停留。",
            "progressions": "• 仅作顺阶声部快速级进过渡\n• 尽量由 IV 级或 iim7 代替",
        },
        {
            "degree": "♭VII",
            "func": "副特征终止和弦 (Secondary Cadence)",
            "prototype": "♭VII / ♭VIImaj7 (如 C / Cmaj7，构成音：♭7 - 2 - 4 - 6)",
            "common_form": "♭VII, ♭VIImaj7",
            "theory": "和弦大七音包含调式特征音 ♮6。大三/大七结构，常与 IV 级交替使用，作为推回 i 级的主力支持级数。",
            "progressions": "• ♭VII → IV → im7\n• im7 → ♭VII → im7",
        },
    ],

    "Phrygian (弗里吉亚调式)": [
        {
            "degree": "i",
            "func": "调式主和弦 (Modal Tonic)",
            "prototype": "i / im7 (如 Em / Em7，构成音：1 - ♭3 - 5 - ♭7)",
            "common_form": "im, im7, im11 (弗拉门戈实务中常使用 I 大三和弦借音)",
            "theory": "弗里吉亚调式中心。上二度紧邻小二度特征音 (♭2)，形成极强音程压迫感。实务中应避免加入 9 音 (避免与 ♭2 冲突)。西班牙风格中常临时变格为 I 大和弦。",
            "progressions": "• ♭IImaj7 → im\n• im → ♭II → ♭VII → im",
        },
        {
            "degree": "♭II",
            "func": "调式绝对特征和弦 (Primary Characteristic Cadence / Neapolitan)",
            "prototype": "♭II / ♭IImaj7 (如 F / Fmaj7，构成音：♭2 - 4 - ♭6 - 1)",
            "common_form": "♭II, ♭IImaj7",
            "theory": "和弦根音为 Phrygian 灵魂特征音 ♭2。大三/大七和弦结构。通过半音向下紧扣主和弦根音 (♭2 → 1)，构成弗里吉亚最具辨识度的半音下行终止式。",
            "progressions": "• ♭IImaj7 → im7\n• im → ♭IImaj7 → ♭III → ♭IImaj7",
        },
        {
            "degree": "♭III",
            "func": "副属/大调中介和弦 (Mediant Cadence)",
            "prototype": "♭III / ♭III7 (如 G / G7，构成音：♭3 - 5 - ♭7 - 2)",
            "common_form": "♭III, ♭III7",
            "theory": "包含特征音 ♭2 作为和弦五音。属七和弦结构，常作为推动至 ♭II 级的动力支点，构成古典与弗拉门戈著名的安达卢西亚下行进行。",
            "progressions": "• ♭IV(iv) → ♭III → ♭II → im\n• ♭III7 → ♭IImaj7",
        },
        {
            "degree": "iv",
            "func": "下属功能和弦 (Subdominant Group)",
            "prototype": "iv / ivm7 (如 Am / Am7，构成音：4 - ♭6 - 1 - ♭3)",
            "common_form": "ivm, ivm7",
            "theory": "纯正小下属形态。和弦三音为 ♭6，与 ♭2 形成稳定支撑。常作为展开段落中的中继和弦，向 ♭III 或 ♭II 递进。",
            "progressions": "• im → ivm → ♭II → im\n• ivm7 → ♭III → ♭II",
        },
        {
            "degree": "v°",
            "func": "减属避免和弦 (Avoid Tritone Dominant)",
            "prototype": "v° / vm7b5 (如 Bdim / Bm7b5，构成音：5 - ♭7 - 2 - 4)",
            "common_form": "避免使用；属位功能完全由 ♭II 或 ♭VII 承担",
            "theory": "根音为五音 (5)，但由于五度音为 ♭2，构成减三和弦，无属和弦支撑力。调式和声中严禁在此停留，其功能被 ♭II 彻底接管。",
            "progressions": "• 避免在调式进行中作为结构和弦使用",
        },
        {
            "degree": "♭VI",
            "func": "下中音色彩和弦 (Submediant)",
            "prototype": "♭VI / ♭VImaj7 (如 C / Cmaj7，构成音：♭6 - 1 - ♭3 - 5)",
            "common_form": "♭VI, ♭VImaj7",
            "theory": "大三和弦结构，与主和弦 im 共享三个音。提供开阔的大调质感缓冲，常接 ♭VII 或下行至 ♭II。",
            "progressions": "• im → ♭VI → ♭VII → im\n• ♭VI → ♭II → im",
        },
        {
            "degree": "♭vii",
            "func": "小下导和弦 (Subtonic Cadence)",
            "prototype": "♭vii / ♭viim7 (如 Dm / Dm7，构成音：♭7 - 2 - 4 - ♭6)",
            "common_form": "♭viim, ♭viim7",
            "theory": "包含特征音 ♭2 作为和弦三音。小七和弦结构，常作为反向下行至 ♭VI 或推向 ♭II 的关键过渡级数。",
            "progressions": "• im → ♭vii → ♭VI → ♭II\n• ♭viim7 → ♭IImaj7 → im",
        },
    ],

    "Lydian (利蒂亚调式)": [
        {
            "degree": "I",
            "func": "调式主和弦 (Modal Tonic)",
            "prototype": "I / Imaj7 (如 F / Fmaj7，构成音：1 - 3 - 5 - 7)",
            "common_form": "I, Imaj7, Imaj7(#11), Iadd9",
            "theory": "大调式中心。由于包含特征增四度音 (♯4)，此音与三音为大二度，不构成传统回避音。实务中首选加入 ♯11 音 (Imaj7#11)，直接确立 Lydian 标志性升四度开阔织体。",
            "progressions": "• Imaj7(#11) ↔ II\n• Imaj7 → II/I → Imaj7",
        },
        {
            "degree": "II",
            "func": "调式核心特征和弦 (Primary Characteristic Cadence)",
            "prototype": "II / II7 (如 G / G7，构成音：2 - #4 - 6 - 1)",
            "common_form": "II (大三和弦), II/I (复合和弦), II7",
            "theory": "和弦三音即为调式灵魂特征音 ♯4。相较于自然大调的小二级 (ii)，大三和弦 II 是利蒂亚最强烈的调式辨识标记。实务中 II/I（主音上方弹大二度大三和弦）是影视与爵士的标准利蒂亚配置。",
            "progressions": "• II → Imaj7\n• II/I → Imaj7\n• I → II → vi → I",
        },
        {
            "degree": "iii",
            "func": "副特征中音和弦 (Secondary Cadence / Mediant)",
            "prototype": "iii / iiim7 (如 Am / Am7，构成音：3 - 5 - 7 - 2)",
            "common_form": "iiim7",
            "theory": "虽不含 ♯4 音，但与主和弦共享 3, 5, 7 三个音。可充当 I 级平滑延长，亦常作为 II 级下行回 I 级的中继缓冲。",
            "progressions": "• Imaj7 → II → iiim7 → Imaj7\n• iiim7 → II → I",
        },
        {
            "degree": "#iv°",
            "func": "调式避免和弦 (Avoid Tritone Diminished)",
            "prototype": "#iv° / #ivm7b5 (如 Bdim / Bm7b5，构成音：#4 - 6 - 1 - 3)",
            "common_form": "避免使用；实务多以 II 级代替",
            "theory": "根音虽为特征音 ♯4，但构成减三和弦，且其减五度三全音倾向于向主大调的 V 级解决，易破坏利蒂亚主导地位，实务中不作为骨干和弦。",
            "progressions": "• 避免停留；实务直接采用 II 级",
        },
        {
            "degree": "V",
            "func": "大七型属和弦 (Major Dominant)",
            "prototype": "V / Vmaj7 (如 C / Cmaj7，构成音：5 - 7 - 2 - #4)",
            "common_form": "V, Vmaj7",
            "theory": "和弦大七音为 ♯4 音。在 Lydian 中五级是大七和弦 (Vmaj7) 而非属七 (V7)，因此完全没有传统属功能的下行解决压力，音响通透稳定。",
            "progressions": "• Imaj7 → Vmaj7 → II → Imaj7\n• Vmaj7 → Imaj7",
        },
        {
            "degree": "vi",
            "func": "下中小和弦 (Submediant)",
            "prototype": "vi / vim7 (如 Dm / Dm7，构成音：6 - 1 - 3 - 5)",
            "common_form": "vim, vim7, vim9",
            "theory": "纯正小调色彩和弦。与主和弦共享主音 (1) 与中音 (3)，用作利蒂亚和声进程中的暗色对比中继，避免全曲明度过度饱和。",
            "progressions": "• Imaj7 → II → vi → I\n• vi → II → Imaj7",
        },
        {
            "degree": "vii",
            "func": "小导和弦 (Minor Leading)",
            "prototype": "vii / viim7 (如 Em / Em7，构成音：7 - 2 - #4 - 6)",
            "common_form": "viim, viim7",
            "theory": "和弦五音为特征音 ♯4。因不含减五度且为小三和弦，导音功能极度弱化，通常作为从上方平滑级进回归主音的上行阶梯。",
            "progressions": "• viim7 → Imaj7\n• vi → viim7 → Imaj7",
        },
    ],

    "Mixolydian (混合利蒂亚调式)": [
        {
            "degree": "I",
            "func": "调式主和弦 (Modal Tonic)",
            "prototype": "I7 (如 G7，构成音：1 - 3 - 5 - ♭7)",
            "common_form": "Isus4, I7sus4, I9sus4; Iadd9 (省略三音)",
            "theory": "顺阶原型 I7 内部 3 音与 ♭7 音构成减五度三全音，具备向 IV 级进行正格解决的倾向性，易削弱本位调式的独立性。实务常采用 sus4 结构挂留四度音、悬置大三度音，以此消除三全音倾向，稳定调式主音地位。",
            "progressions": "• I7sus4 → ♭VII → IV → I7sus4\n• I7sus4 ↔ ♭VII",
        },
        {
            "degree": "ii",
            "func": "上主功能和弦 (Supertonic Group)",
            "prototype": "ii / iim7 (如 Am / Am7，构成音：2 - 4 - 6 - 1)",
            "common_form": "iim7, iim11",
            "theory": "不含 ♭7 特征音，但提供标准小调质感。常与 v 级或 IV 级搭配，作为循环声部中的平稳过渡桥梁。",
            "progressions": "• I7sus4 → iim7 → ♭VII → I7sus4\n• iim7 → v → I",
        },
        {
            "degree": "iii°",
            "func": "调式避免和弦 (Avoid Tritone Diminished)",
            "prototype": "iii° / iiim7b5 (如 Bdim / Bm7b5，构成音：3 - 5 - ♭7 - 2)",
            "common_form": "避免独立使用；多由 I 级或 ♭VII 级代替",
            "theory": "根音为 3 音，五音为 ♭7 音，构成三全音减和弦，具有强烈的大调主和弦倾向，易导致听觉中心偏转回自然大调，实务中避用。",
            "progressions": "• 调式和声中避免长音停留",
        },
        {
            "degree": "IV",
            "func": "副特征终止和弦 (Subdominant Cadence)",
            "prototype": "IV / IVmaj7 (如 C / Cmaj7，构成音：4 - 6 - 1 - 3)",
            "common_form": "IV, IVadd9, IV6 (实务中常省略大七度 7 音)",
            "theory": "下属大三和弦。和弦音不含导向音，与 ♭VII 级并列为支持 Mixolydian 循环的核心和弦，常用作 ♭VII 与 I 级之间的过渡。",
            "progressions": "• I → ♭VII → IV → I\n• IV → ♭VII → I",
        },
        {
            "degree": "v",
            "func": "小属功能和弦 (Minor Dominant)",
            "prototype": "v / vm7 (如 Dm / Dm7，构成音：5 - ♭7 - 2 - 4)",
            "common_form": "vm, vm7",
            "theory": "根音为属音 (5)，三音为调式特征音 ♭7。因缺乏导音 (7)，无传统属七张力，表现为温和的灰色小调质感，确立调式平稳属性。",
            "progressions": "• vm7 → IV → I\n• I → vm7 → ♭VII → I",
        },
        {
            "degree": "vi",
            "func": "下中音色彩和弦 (Submediant)",
            "prototype": "vi / vim7 (如 Em / Em7，构成音：6 - 1 - 3 - 5)",
            "common_form": "vim, vim7",
            "theory": "自然小三和弦。与主和弦共享主音 (1) 与大三音 (3)，用作调式行进中的对比转折点。",
            "progressions": "• I → vi → ♭VII → I\n• vi → ♭VII → I",
        },
        {
            "degree": "♭VII",
            "func": "调式绝对核心特征和弦 (Primary Characteristic Cadence)",
            "prototype": "♭VII / ♭VII7 (如 F / Fmaj7，构成音：♭7 - 2 - 4 - 6)",
            "common_form": "♭VII (纯大三和弦), ♭VIIadd9, ♭VII/I (复合和弦)",
            "theory": "和弦根音即为 Mixolydian 调式的灵魂特征音 ♭7。大三和弦结构。向 I 级做全音下行解决是该调式最权威的终止式形态，也是摇滚、放克与后门进行的核心基石。",
            "progressions": "• ♭VII → I\n• ♭VII → IV → I\n• I → ♭VII/I → I",
        },
    ]
}


def get_chord_advice_data(mode_name, degree_idx):
    """
    根据调式全名和级数索引（0-6）检索规范化事务级和声建议
    """
    if not mode_name or degree_idx < 0 or degree_idx > 6:
        return None

    # 模糊匹配当前选中的调式
    target_key = None
    for key in DEGREE_ADVICE_DATABASE:
        prefix = key.split(' ')[0]
        if prefix in mode_name or mode_name in key:
            target_key = key
            break

    if not target_key:
        return {
            "degree": ["I", "ii", "iii", "IV", "V", "vi", "vii"][degree_idx],
            "func": "调式顺阶和弦",
            "prototype": "顺阶三度堆叠形态",
            "common_form": "视织体需求采用纯三和弦、七和弦或加音形式",
            "theory": "根据调式音阶内各声部音程关系进行声部连接，注意避开具有破坏调心倾向的三全音与避免音。",
            "progressions": "• 顺阶级进进行\n• 回归调式主音进行",
        }

    advice_list = DEGREE_ADVICE_DATABASE[target_key]
    if degree_idx < len(advice_list):
        return advice_list[degree_idx]

    return None
