"""
Theory Engine - 现代乐理核心引擎
包含 12 平均律音名、全量调式音阶、基础与扩展和弦音计算、高精度和弦反向识别与结构解析。
"""

import itertools

NOTE_NAMES = ['C', 'C#/Db', 'D', 'D#/Eb', 'E', 'F', 'F#/Gb', 'G', 'G#/Ab', 'A', 'A#/Bb', 'B']
CIRCLE_OF_FIFTHS = ['C', 'G', 'D', 'A', 'E', 'B', 'Gb/F#', 'Db', 'Ab', 'Eb', 'Bb', 'F']
CIRCLE_RELATIVE_MINORS = ['A', 'E', 'B', 'F#', 'C#', 'G#', 'Eb/D#', 'Bb', 'F', 'C', 'G', 'D']

INTERVAL_NAMES = {
    0: "纯一度", 1: "小二度", 2: "大二度", 3: "小三度",
    4: "大三度", 5: "纯四度", 6: "减五/增四", 7: "纯五度",
    8: "小六度", 9: "大六度", 10: "小七度", 11: "大七度"
}

CHORD_CATEGORIES = {
    "基础三和弦": [
        ("Maj", [0, 4, 7], "大三和弦"),
        ("min", [0, 3, 7], "小三和弦"),
        ("dim", [0, 3, 6], "减三和弦"),
        ("aug", [0, 4, 8], "增三和弦"),
        ("sus2", [0, 2, 7], "挂二和弦"),
        ("sus4", [0, 5, 7], "挂四和弦"),
        ("5", [0, 7], "强力和弦 (Power Chord)")
    ],
    "流行与爵士七和弦": [
        ("7", [0, 4, 7, 10], "属七和弦"),
        ("Maj7", [0, 4, 7, 11], "大大七和弦"),
        ("m7", [0, 3, 7, 10], "小七和弦"),
        ("mMaj7", [0, 3, 7, 11], "小大七和弦"),
        ("dim7", [0, 3, 6, 9], "减七和弦"),
        ("m7b5", [0, 3, 6, 10], "半减七和弦"),
        ("7sus4", [0, 5, 7, 10], "属七挂四和弦"),
        ("aug7", [0, 4, 8, 10], "增七和弦"),
        ("augMaj7", [0, 4, 8, 11], "增大大七和弦")
    ],
    "高阶扩展和弦": [
        ("add9", [0, 4, 7, 14], "加九和弦"),
        ("madd9", [0, 3, 7, 14], "小加九和弦"),
        ("6", [0, 4, 7, 9], "大六和弦"),
        ("m6", [0, 3, 7, 9], "小六和弦"),
        ("6/9", [0, 4, 7, 9, 14], "六九和弦"),
        ("9", [0, 4, 7, 10, 14], "属九和弦"),
        ("Maj9", [0, 4, 7, 11, 14], "大九和弦"),
        ("m9", [0, 3, 7, 10, 14], "小九和弦"),
        ("m7(b9)", [0, 3, 7, 10, 13], "小七降九和弦"),
        ("m7b5(b9)", [0, 3, 6, 10, 13], "半减七降九和弦"),
        ("m9b5", [0, 3, 6, 10, 14], "半减九和弦"),
        ("7(b9)", [0, 4, 7, 10, 13], "属七降九和弦"),
        ("7(#9)", [0, 4, 7, 10, 15], "属七升九和弦"),
        ("Maj9(#11)", [0, 4, 7, 11, 14, 18], "大九升十一和弦"),
        ("mMaj9", [0, 3, 7, 11, 14], "小大九和弦"),
        ("11", [0, 4, 7, 10, 14, 17], "十一和弦"),
        ("13", [0, 4, 7, 10, 14, 21], "十三和弦"),
        ("7(b13)", [0, 4, 7, 10, 20], "属七降十三和弦"),
        ("7(b9,b13)", [0, 4, 7, 10, 13, 20], "属七降九降十三和弦"),
        ("7(#11)", [0, 4, 7, 10, 18], "属七升十一和弦 (利蒂亚属)"),
        ("m11", [0, 3, 7, 10, 14, 17], "小十一和弦 (So What四度和声)"),
        ("Maj13", [0, 4, 7, 11, 14, 21], "大大十三和弦"),
        ("m13", [0, 3, 7, 10, 14, 21], "小十三和弦"),
        ("m6/9", [0, 3, 7, 9, 14], "小六九和弦"),
        ("9sus4", [0, 5, 7, 10, 14], "属九挂四和弦"),
        ("13sus4", [0, 5, 7, 10, 14, 21], "属十三挂四和弦")
    ]
}

CHORD_TYPES = {}
for category, chord_list in CHORD_CATEGORIES.items():
    for name, intervals, _ in chord_list:
        CHORD_TYPES[name] = intervals

HIDDEN_CHORD_TYPES = {
    "7(no5)": [0, 4, 10],
    "Maj7(no5)": [0, 4, 11],
    "m7(no5)": [0, 3, 10],
    "mMaj7(no5)": [0, 3, 11],
    "7sus4(no5)": [0, 5, 10],
    "9(no5)": [0, 4, 10, 14],
    "Maj9(no5)": [0, 4, 11, 14],
    "m9(no5)": [0, 3, 10, 14],
    "m7(b9)(no5)": [0, 3, 10, 13],
    "7(b9)(no5)": [0, 4, 10, 13],
    "7(#9)(no5)": [0, 4, 10, 15],
    "7(b13)(no5)": [0, 4, 10, 20],
    "7(b9,b13)(no5)": [0, 4, 10, 13, 20],
    "7(#11)(no5)": [0, 4, 10, 18],
    "m11(no5)": [0, 3, 10, 14, 17],
    "Maj13(no5)": [0, 4, 11, 14, 21],
    "m13(no5)": [0, 3, 10, 14, 21],
    "13(no5)": [0, 4, 10, 14, 21],
    "9sus4(no5)": [0, 5, 10, 14],
    "13sus4(no5)": [0, 5, 10, 14, 21]
}

NO5_UI_MAP = {
    "7(no5)": "7",
    "Maj7(no5)": "Maj7",
    "m7(no5)": "m7",
    "mMaj7(no5)": "mMaj7",
    "7sus4(no5)": "7sus4",
    "9(no5)": "9",
    "Maj9(no5)": "Maj9",
    "m9(no5)": "m9",
    "m7(b9)(no5)": "m7(b9)",
    "7(b9)(no5)": "7(b9)",
    "7(#9)(no5)": "7(#9)",
    "7(b13)(no5)": "7(b13)",
    "7(b9,b13)(no5)": "7(b9,b13)",
    "7(#11)(no5)": "7(#11)",
    "m11(no5)": "m11",
    "Maj13(no5)": "Maj13",
    "m13(no5)": "m13",
    "13(no5)": "13",
    "9sus4(no5)": "9sus4",
    "13sus4(no5)": "13sus4"
}

MODES = {
    "Ionian (自然大调 Major)": [2, 2, 1, 2, 2, 2, 1],
    "Dorian (多利亚调式)": [2, 1, 2, 2, 2, 1, 2],
    "Phrygian (弗里吉亚调式)": [1, 2, 2, 2, 1, 2, 2],
    "Lydian (利蒂亚调式)": [2, 2, 2, 1, 2, 2, 1],
    "Mixolydian (混合利蒂亚调式)": [2, 2, 1, 2, 2, 1, 2],
    "Aeolian (自然小调 Minor)": [2, 1, 2, 2, 1, 2, 2],
    "Locrian (洛克里亚调式)": [1, 2, 2, 1, 2, 2, 2],
    "Harmonic Minor (和声小调)": [2, 1, 2, 2, 1, 3, 1],
    "Melodic Minor (旋律小调上行)": [2, 1, 2, 2, 2, 2, 1],
    "Major Pentatonic (大调五声 / ヨナ抜き长音阶)": [2, 2, 3, 2, 3],
    "Minor Pentatonic (小调五声 / 民谣音阶)": [3, 2, 2, 3, 2],
    "Miyako-bushi (都节音阶 / 阴音阶)": [1, 4, 2, 1, 4],
    "Ritsu (日本律音阶)": [2, 3, 2, 2, 3],
    "Ryukyu (琉球音阶 / ニロ抜き长音阶)": [4, 1, 2, 4, 1],
    "Yonanuki Minor (ヨナ抜き短音阶)": [2, 1, 4, 1, 4]
}

MODE_COLORS = {
    "Ionian (自然大调 Major)": "#f97316",
    "Dorian (多利亚调式)": "#38bdf8",
    "Phrygian (弗里吉亚调式)": "#a855f7",
    "Lydian (利蒂亚调式)": "#ec4899",
    "Mixolydian (混合利蒂亚调式)": "#eab308",
    "Aeolian (自然小调 Minor)": "#06b6d4",
    "Locrian (洛克里亚调式)": "#64748b",
    "Harmonic Minor (和声小调)": "#10b981",
    "Melodic Minor (旋律小调上行)": "#6366f1",
    "Major Pentatonic (大调五声 / ヨナ抜き长音阶)": "#f59e0b",
    "Minor Pentatonic (小调五声 / 民谣音阶)": "#14b8a6",
    "Miyako-bushi (都节音阶 / 阴音阶)": "#d946ef",
    "Ritsu (日本律音阶)": "#059669",
    "Ryukyu (琉球音阶 / ニロ抜き长音阶)": "#0284c7",
    "Yonanuki Minor (ヨナ抜き短音阶)": "#e11d48"
}

DEGREE_FUNCTIONS = {
    "Ionian (自然大调 Major)": [
        "主和弦 (Tonic - I)",
        "副特征上主和弦 (Supertonic - ii)",
        "代理主上中和弦 (Tonic Substitute / Mediant - iii)",
        "特征下属和弦 (Subdominant - IV)",
        "属和弦 (Dominant - V)",
        "代理主下中和弦 (Tonic Substitute / Submediant - vi)",
        "导和弦 (Leading-Tone - vii°)",
    ],
    "Aeolian (自然小调 Minor)": [
        "主和弦 (Modal Tonic - i)",
        "禁用和弦 (Avoid / Diminished Supertonic - ii°)",
        "平行大调主和弦 (Relative Major Tonic / Mediant - ♭III)",
        "特征下属和弦 (Subdominant - iv)",
        "小属和弦 (Minor Dominant - v)",
        "特征降六大和弦 (Characteristic Submediant - ♭VI)",
        "下主级进和弦 (Subtonic Cadence - ♭VII)",
    ],
    "Harmonic Minor (和声小调)": [
        "主和弦 (Tonic - i)",
        "下属减上主和弦 (Subdominant Function / Diminished Supertonic - ii°)",
        "色彩增和弦 (Coloristic Augmented Mediant - ♭III+)",
        "下属小和弦 (Subdominant Minor - iv)",
        "属和弦 (Dominant - V / V7)",
        "下中扩展和弦 (Extended Submediant - ♭VI)",
        "代理属和弦 (Dominant Substitute / Leading-Tone Diminished - vii°7)",
    ],
    "Dorian (多利亚调式)": [
        "主和弦 (Modal Tonic - i)",
        "特征弱终止和弦 (Weak Characteristic Cadence - ii)",
        "代理主和弦 (Tonic Substitute - ♭III)",
        "特征终止和弦 (Primary Characteristic Cadence - IV)",
        "弱属和弦 (Minor Dominant - v)",
        "禁用和弦 (Avoid / Tritone Diminished - vi°)",
        "下主级进和弦 (Subtonic Cadence - ♭VII)",
    ],
    "Phrygian (弗里吉亚调式)": [
        "主和弦 (Modal Tonic - i)",
        "特征终止和弦 (Characteristic Cadence / Neapolitan - ♭II)",
        "属七避免和弦 (Avoid Dominant-Type Mediant - ♭III7)",
        "副终止和弦 (Secondary Cadence / Subdominant - iv)",
        "禁用属和弦 (Avoid / Diminished Dominant - v°)",
        "代理主和弦 (Tonic Substitute - ♭VI)",
        "特征弱终止和弦 (Weak Cadence / Minor Subtonic - ♭vii)",
    ],
    "Lydian (利蒂亚调式)": [
        "主和弦 (Modal Tonic - I)",
        "特征终止和弦 (Characteristic Cadence - II)",
        "代理主和弦 (Tonic Substitute - iii)",
        "禁用减和弦 (Avoid / Tritone Diminished - ♯iv°)",
        "色彩属弱终止和弦 (Modal Dominant Cadence - V)",
        "代理主和弦 (Tonic Substitute - vi)",
        "特征弱终止和弦 (Weak Cadence / Minor Leading - vii)",
    ],
    "Mixolydian (混合利蒂亚调式)": [
        "挂留主和弦 (Dominant-Type Tonic - I7)",
        "连接下属和弦 (Connective Supertonic - ii)",
        "禁用和弦 (Avoid / Diminished Mediant - iii°)",
        "母下属和弦 (Primary Subdominant - IV)",
        "特征弱属和弦 (Minor Dominant - v)",
        "主代理和弦 (Tonic Substitute - vi)",
        "特征终止和弦 (Characteristic Cadence / Subtonic - ♭VII)",
    ],
}


def normalize_note_name(name):
    if not name:
        return ""
    name = name.strip()
    for standard in NOTE_NAMES:
        parts = [p.upper() for p in standard.split('/')]
        if name in parts or name == standard.upper():
            return standard
    flat_to_standard = {'DB': 'C#/Db', 'EB': 'D#/Eb', 'GB': 'F#/Gb', 'AB': 'G#/Ab', 'BB': 'A#/Bb'}
    sharp_to_standard = {'C#': 'C#/Db', 'D#': 'D#/Eb', 'F#': 'F#/Gb', 'G#': 'G#/Ab', 'A#': 'A#/Bb'}
    if name.upper() in flat_to_standard:
        return flat_to_standard[name.upper()]
    if name.upper() in sharp_to_standard:
        return sharp_to_standard[name.upper()]
    return name


def note_name_to_pitch_class(note_str):
    norm = normalize_note_name(note_str)
    if norm in NOTE_NAMES:
        return NOTE_NAMES.index(norm)
    return None


def get_chord_notes(root_note, chord_type):
    """根据根音与和弦类型返回音名列表 (原位音程公式)"""
    norm_root = normalize_note_name(root_note)
    if norm_root not in NOTE_NAMES:
        return []
    root_idx = NOTE_NAMES.index(norm_root)
    formula = CHORD_TYPES.get(chord_type) or HIDDEN_CHORD_TYPES.get(chord_type)
    if not formula:
        return []
    return [NOTE_NAMES[(root_idx + i) % 12] for i in formula]


def get_all_scales():
    scales = {}
    for root in NOTE_NAMES:
        for mode_name, intervals in MODES.items():
            current_scale = []
            curr_idx = NOTE_NAMES.index(root)
            for step in intervals:
                current_scale.append(NOTE_NAMES[curr_idx % 12])
                curr_idx += step
            scales[f"{root} {mode_name}"] = current_scale
    return scales


def analyze_chord_structure(p_indices):
    """
    根据绝对琴键索引精确解析和弦结构（根音、类型、转位、最低音、是否有效）。
    """
    if not p_indices:
        return {'name': 'None', 'root': '', 'type': '', 'inv': 0, 'bass': '', 'is_valid': False}

    sorted_indices = sorted(p_indices)
    bass_val = sorted_indices[0]
    bass_name = NOTE_NAMES[bass_val % 12]

    unique_pitch_classes = []
    seen = set()
    for idx in sorted_indices:
        pc = idx % 12
        if pc not in seen:
            unique_pitch_classes.append(pc)
            seen.add(pc)

    if len(unique_pitch_classes) == 1:
        return {
            'name': f"{bass_name} (单音)",
            'root': bass_name,
            'type': '单音',
            'inv': 0,
            'bass': bass_name,
            'is_valid': False
        }

    if len(unique_pitch_classes) == 2:
        span = abs(sorted_indices[1] - sorted_indices[0]) % 12
        interval_desc = INTERVAL_NAMES.get(span, f"{span}半音")
        note2 = NOTE_NAMES[unique_pitch_classes[1]]
        return {
            'name': f"{bass_name} - {note2} : {interval_desc}",
            'root': bass_name,
            'type': interval_desc,
            'inv': 0,
            'bass': bass_name,
            'is_valid': False
        }

    results = []
    for cand_pc in unique_pitch_classes:
        root_name = NOTE_NAMES[cand_pc]
        curr_intervals = set([(pc - cand_pc) % 12 for pc in unique_pitch_classes])

        for lib in [CHORD_TYPES, HIDDEN_CHORD_TYPES]:
            for type_name, formula in lib.items():
                formula_mod_set = set([f % 12 for f in formula])
                if curr_intervals == formula_mod_set:
                    bass_offset = (bass_val % 12 - cand_pc) % 12
                    inv_index = -1
                    bass_interval = -1
                    for i, f_val in enumerate(formula):
                        if f_val % 12 == bass_offset:
                            inv_index = i
                            bass_interval = f_val
                            break

                    if inv_index != -1:
                        # 原位得分最高（inv_index == 0 得大加分）
                        score = len(formula) * 10 - (inv_index * 8)
                        results.append({
                            'root': root_name,
                            'type': type_name,
                            'inv': inv_index,
                            'interval': bass_interval,
                            'score': score
                        })

    if not results:
        return {
            'name': '未知和弦 (Unknown)',
            'root': '',
            'type': '',
            'inv': 0,
            'bass': bass_name,
            'is_valid': False
        }

    best = sorted(results, key=lambda x: -x['score'])[0]
    r_n = best['root']
    t_n = NO5_UI_MAP.get(best['type'], best['type'])
    i_idx = best['inv']

    if i_idx == 0:
        full_name = f"{r_n} {t_n}"
    elif i_idx == 1:
        full_name = f"{r_n} {t_n}/1转位 ({bass_name})"
    elif i_idx == 2:
        full_name = f"{r_n} {t_n}/2转位 ({bass_name})"
    elif i_idx == 3:
        full_name = f"{r_n} {t_n}/3转位 ({bass_name})"
    else:
        full_name = f"{r_n} {t_n}/{bass_name}"

    return {
        'name': full_name,
        'root': r_n,
        'type': t_n,
        'inv': i_idx,
        'bass': bass_name,
        'is_valid': True
    }


def identify_chord_name(p_indices):
    """兼容旧接口"""
    info = analyze_chord_structure(p_indices)
    return info['name']


def get_mode_harmonics(root_name, mode_name, depth='Triad'):
    norm_root = normalize_note_name(root_name)
    all_scales = get_all_scales()
    scale_key = f"{norm_root} {mode_name}"
    if scale_key not in all_scales:
        for k in all_scales.keys():
            if k.startswith(norm_root + " ") and (mode_name in k or k.endswith(mode_name)):
                scale_key = k
                break

    if scale_key not in all_scales:
        return []

    scale_notes = all_scales[scale_key]
    num_degrees = len(scale_notes)
    if num_degrees < 3:
        return []

    roman_numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'][:num_degrees]
    harmonics = []

    for degree_idx in range(num_degrees):
        indices = [degree_idx, (degree_idx + 2) % num_degrees, (degree_idx + 4) % num_degrees]
        if depth in ['7th', '9th'] and num_degrees >= 4:
            indices.append((degree_idx + 1) % num_degrees if num_degrees == 5 else (degree_idx + 6) % num_degrees)
        if depth == '9th' and num_degrees >= 5:
            indices.append((degree_idx + 3) % num_degrees if num_degrees == 5 else (degree_idx + 8) % num_degrees)

        chord_notes = [scale_notes[i] for i in indices]
        
        # 严格原位单调递增映射（不受琴键上限截断限制，确保全部音符完整参与判定）
        piano_indices = []
        root_pc = note_name_to_pitch_class(chord_notes[0])
        cur_val = root_pc
        piano_indices.append(cur_val)
        for n in chord_notes[1:]:
            pc = note_name_to_pitch_class(n)
            next_val = cur_val + 1
            while next_val % 12 != pc:
                next_val += 1
            piano_indices.append(next_val)
            cur_val = next_val

        chord_struct = analyze_chord_structure(piano_indices)
        r_clean = chord_struct['root'].split('/')[0] if chord_struct.get('root') else ""
        t_clean = chord_struct['type']
        if r_clean:
            clean_name = f"{r_clean} {t_clean}" if t_clean else r_clean
        else:
            root_note = chord_notes[0].split('/')[0]
            clean_name = f"{root_note} 和声"

        funcs = DEGREE_FUNCTIONS.get(mode_name, ["", "", "", "", "", "", ""])
        func_tag = funcs[degree_idx] if degree_idx < len(funcs) else ""

        harmonics.append({
            'roman': roman_numerals[degree_idx],
            'name': clean_name,
            'notes': chord_notes,
            'function': func_tag
        })

    return harmonics
