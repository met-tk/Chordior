"""
Chord Theory Module - 保持向后兼容的乐理接口模块
直接重定向至 theory_engine 模块以实现最强乐理算法与全量和弦扩展。
"""

from theory_engine import (
    NOTE_NAMES,
    SHARP_NAMES,
    FLAT_NAMES,
    INTERVAL_NAMES,
    CHORD_CATEGORIES,
    CHORD_TYPES,
    HIDDEN_CHORD_TYPES,
    NO5_UI_MAP,
    MODES,
    MODE_COLORS,
    SHORT_MODE_NAMES,
    DEGREE_FUNCTIONS,
    CIRCLE_OF_FIFTHS,
    CIRCLE_RELATIVE_MINORS,
    normalize_note_name,
    note_name_to_pitch_class,
    get_chord_notes,
    get_all_scales,
    identify_chord_name,
    get_mode_harmonics
)