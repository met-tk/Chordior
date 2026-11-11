package com.chordior.vocal.vocal_master_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.SoundPool
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

data class NoteSample(val note: String, val midi: Int)
data class InstrumentBank(val dir: String, val notes: List<NoteSample>) {
    // 快速 O(1) 预计算缓存：MIDI -> 最近采样点及速率
    val midiLookup = Array(128) { midi ->
        var best = notes[0]
        var minDiff = Math.abs(midi - best.midi)
        for (n in notes) {
            val d = Math.abs(midi - n.midi)
            if (d < minDiff) {
                minDiff = d
                best = n
            }
        }
        val semitoneDiff = (midi - best.midi).toDouble()
        val rate = Math.pow(2.0, semitoneDiff / 12.0).coerceIn(0.5, 2.0).toFloat()
        Pair(best, rate)
    }
}

/// 麦克风硬件直流偏置滤除器 (零群延迟、零相位失真，纯净保留基波及泛音相对时域形态)
class DcBlocker(private val r: Double = 0.995) {
    private var x1 = 0.0
    private var y1 = 0.0

    fun process(x: Double): Double {
        val y = x - x1 + r * y1
        x1 = x
        y1 = y
        return y
    }

    fun reset() {
        x1 = 0.0
        y1 = 0.0
    }
}

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.chordior.vocal/audio"
    private var methodChannel: MethodChannel? = null
    private val executor = Executors.newCachedThreadPool()
    // 独立超低抖动纳秒级调度器，保障琶音节拍与连奏平滑
    private val audioScheduler: ScheduledExecutorService = Executors.newScheduledThreadPool(2)

    private var soundPool: SoundPool? = null
    // key: "piano_60" -> soundId
    private val loadedSoundIds = ConcurrentHashMap<String, Int>()
    // 标记已就绪（解码完成）的 soundId
    private val readySoundIds = Collections.newSetFromMap(ConcurrentHashMap<Int, Boolean>())
    // 正在播放的 streamId 追踪：midi -> List<StreamId>
    private val activeNoteStreams = ConcurrentHashMap<Int, MutableList<Int>>()
    private val activeStreams = Collections.synchronizedList(mutableListOf<ActiveStreamInfo>())

    // 音频焦点与切后台无感恢复管理
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var wasListeningBeforePause = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 申请屏幕物理最高刷新率 (120Hz/90Hz/144Hz)，彻底释放动画丝滑度
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val window = window
                val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                val modes = display?.supportedModes
                val maxRefreshMode = modes?.maxByOrNull { it.refreshRate }
                if (maxRefreshMode != null) {
                    window.attributes.preferredDisplayModeId = maxRefreshMode.modeId
                }
            } catch (_: Exception) {}
        }
        initAudio()
    }

    private fun initAudio() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    }

    private fun requestAppAudioFocus(): Boolean {
        val am = audioManager ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (audioFocusRequest == null) {
                    val playbackAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                    audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(playbackAttributes)
                        .setAcceptsDelayedFocusGain(true)
                        .setOnAudioFocusChangeListener { /* 音频焦点监听 */ }
                        .build()
                }
                audioFocusRequest?.let { am.requestAudioFocus(it) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED } ?: false
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun abandonAppAudioFocus() {
        val am = audioManager ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus(null)
            }
        } catch (_: Exception) {}
    }

    override fun onResume() {
        super.onResume()
        // 切回前台：立即抢占并打通音频焦点
        requestAppAudioFocus()
        // 恢复底层 SoundPool 播放通路
        soundPool?.autoResume()
        // 若在切后台前正在麦克风识音，则优雅无缝恢复识音
        if (wasListeningBeforePause) {
            wasListeningBeforePause = false
            startAudioPitchDetection()
        }
    }

    override fun onPause() {
        super.onPause()
        // 切到后台：若正在识音，记录状态并临时挂起释放 AudioRecord 硬件占用
        if (isListening) {
            wasListeningBeforePause = true
            stopAudioPitchDetection()
        }
        // 暂停 SoundPool 所有残留音频流，避免后台持续混音与系统通道竞争
        soundPool?.autoPause()
    }

    // 针对极速首次按键若未解码完成时的待决播放：soundId -> List<PendingPlay>
    data class PendingPlay(val volume: Float, val rate: Float, val midi: Int, val sustainSec: Double)
    private val pendingPlays = ConcurrentHashMap<Int, MutableList<PendingPlay>>()

    data class ActiveStreamInfo(val streamId: Int, val volume: Float)

    private val STANDARD_NOTES = listOf(
        NoteSample("C2", 36), NoteSample("Ds2", 39), NoteSample("Fs2", 42), NoteSample("A2", 45),
        NoteSample("C3", 48), NoteSample("Ds3", 51), NoteSample("Fs3", 54), NoteSample("A3", 57),
        NoteSample("C4", 60), NoteSample("Ds4", 63), NoteSample("Fs4", 66), NoteSample("A4", 69),
        NoteSample("C5", 72), NoteSample("Ds5", 75), NoteSample("Fs5", 78), NoteSample("A5", 81),
        NoteSample("C6", 84)
    )

    private val ORGAN_NOTES = listOf(
        NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
        NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
        NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
        NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
        NoteSample("C6", 84)
    )

    private val DIVA_NOTES = listOf(
        NoteSample("C1", 24), NoteSample("Db1", 25), NoteSample("D1", 26), NoteSample("Eb1", 27), NoteSample("E1", 28), NoteSample("F1", 29),
        NoteSample("Gb1", 30), NoteSample("G1", 31), NoteSample("Ab1", 32), NoteSample("A1", 33), NoteSample("Bb1", 34), NoteSample("B1", 35),
        NoteSample("C2", 36), NoteSample("Db2", 37), NoteSample("D2", 38), NoteSample("Eb2", 39), NoteSample("E2", 40), NoteSample("F2", 41),
        NoteSample("Gb2", 42), NoteSample("G2", 43), NoteSample("Ab2", 44), NoteSample("A2", 45), NoteSample("Bb2", 46), NoteSample("B2", 47),
        NoteSample("C3", 48), NoteSample("Db3", 49), NoteSample("D3", 50), NoteSample("Eb3", 51), NoteSample("E3", 52), NoteSample("F3", 53),
        NoteSample("Gb3", 54), NoteSample("G3", 55), NoteSample("Ab3", 56), NoteSample("A3", 57), NoteSample("Bb3", 58), NoteSample("B3", 59),
        NoteSample("C4", 60), NoteSample("Db4", 61), NoteSample("D4", 62), NoteSample("Eb4", 63), NoteSample("E4", 64), NoteSample("F4", 65),
        NoteSample("Gb4", 66), NoteSample("G4", 67), NoteSample("Ab4", 68), NoteSample("A4", 69), NoteSample("Bb4", 70), NoteSample("B4", 71),
        NoteSample("C5", 72), NoteSample("Db5", 73), NoteSample("D5", 74), NoteSample("Eb5", 75), NoteSample("E5", 76), NoteSample("F5", 77),
        NoteSample("Gb5", 78), NoteSample("G5", 79), NoteSample("Ab5", 80), NoteSample("A5", 81), NoteSample("Bb5", 82), NoteSample("B5", 83),
        NoteSample("C6", 84), NoteSample("Db6", 85), NoteSample("D6", 86), NoteSample("Eb6", 87), NoteSample("E6", 88), NoteSample("F6", 89),
        NoteSample("Gb6", 90), NoteSample("G6", 91), NoteSample("Ab6", 92), NoteSample("A6", 93), NoteSample("Bb6", 94), NoteSample("B6", 95),
        NoteSample("C7", 96)
    )

    private val FLUTE_NOTES = listOf(
        NoteSample("C4", 60), NoteSample("E4", 64), NoteSample("A4", 69),
        NoteSample("C5", 72), NoteSample("E5", 76), NoteSample("A5", 81),
        NoteSample("C6", 84), NoteSample("E6", 88), NoteSample("A6", 93),
        NoteSample("C7", 96)
    )

    private val VIOLIN_NOTES = listOf(
        NoteSample("G3", 55), NoteSample("A3", 57),
        NoteSample("C4", 60), NoteSample("E4", 64), NoteSample("G4", 67), NoteSample("A4", 69),
        NoteSample("C5", 72), NoteSample("E5", 76), NoteSample("G5", 79), NoteSample("A5", 81),
        NoteSample("C6", 84), NoteSample("E6", 88), NoteSample("G6", 91), NoteSample("A6", 93),
        NoteSample("C7", 96)
    )

    private val BANKS = mapOf(
        "Concert Grand" to InstrumentBank("piano", STANDARD_NOTES),
        "Virtual Singer" to InstrumentBank("diva_voice", DIVA_NOTES),
        "Church Organ" to InstrumentBank("organ", ORGAN_NOTES),
        "Concert Flute" to InstrumentBank("flute", FLUTE_NOTES),
        "Solo Violin" to InstrumentBank("violin", VIOLIN_NOTES),
        "Fender Rhodes" to InstrumentBank("rhodes", ORGAN_NOTES),
        "Acoustic Guitar" to InstrumentBank("guitar_steel", ORGAN_NOTES),
        "Celesta & Bells" to InstrumentBank("celesta", ORGAN_NOTES)
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initSoundPool()

        // 启动时优先极速加载主钢琴乐器（仅17个采样，毫秒级就绪，彻底避免堵塞 MediaCodec 队列）
        executor.execute {
            loadInstrumentSync("Concert Grand")
            // 次要乐器让出关键启动窗口，错峰预热
            try { Thread.sleep(1200) } catch (_: Exception) {}
            loadInstrumentSync("Virtual Singer")
            try { Thread.sleep(600) } catch (_: Exception) {}
            loadInstrumentSync("Concert Flute")
            loadInstrumentSync("Solo Violin")
            try { Thread.sleep(600) } catch (_: Exception) {}
            loadInstrumentSync("Church Organ")
            loadInstrumentSync("Fender Rhodes")
            loadInstrumentSync("Acoustic Guitar")
            loadInstrumentSync("Celesta & Bells")
        }

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setTimbre" -> {
                    val timbre = call.argument<String>("timbre") ?: "Concert Grand"
                    executor.execute { loadInstrumentSync(timbre) }
                    result.success(true)
                }
                // 极速单音播放通道：直通底层，耗时 < 1ms
                "playSingleNote" -> {
                    val midi = call.argument<Int>("midi") ?: 60
                    val timbre = call.argument<String>("timbre") ?: "Concert Grand"
                    val volume = call.argument<Double>("volume") ?: 0.85
                    val sustainSec = call.argument<Double>("sustainSec") ?: 3.0
                    val dampPrevious = call.argument<Boolean>("dampPrevious") ?: false
                    playSingleNoteInternal(midi, timbre, volume.toFloat(), sustainSec, dampPrevious)
                    result.success(true)
                }
                "stopSingleNote" -> {
                    val midi = call.argument<Int>("midi") ?: 60
                    stopSingleNoteInternal(midi)
                    result.success(true)
                }
                "playSamples" -> {
                    val pitches = call.argument<List<Int>>("pitches") ?: emptyList()
                    val timbre = call.argument<String>("timbre") ?: "Concert Grand"
                    val mode = call.argument<String>("mode") ?: "Simultaneous"
                    val speedMs = call.argument<Int>("speedMs") ?: 60
                    val volume = call.argument<Double>("volume") ?: 0.85
                    val sustainSec = call.argument<Double>("sustainSec") ?: 3.0
                    val dampPrevious = call.argument<Boolean>("dampPrevious") ?: false

                    playSamplesInternal(pitches, timbre, mode, speedMs, volume, sustainSec, dampPrevious)
                    result.success(true)
                }
                "stopAll" -> {
                    stopAllAudio()
                    result.success(true)
                }
                "startListening" -> {
                    checkAndStartListening(result)
                }
                "stopListening" -> {
                    stopAudioPitchDetection()
                    result.success(true)
                }
                "setPitchSensitivity" -> {
                    val sensitivity = call.argument<String>("sensitivity") ?: "balanced"
                    pitchRmsThreshold = when (sensitivity) {
                        "high" -> 150.0
                        "noiseResistant" -> 500.0
                        else -> 250.0
                    }
                    pitchYinThreshold = when (sensitivity) {
                        "high" -> 0.16
                        "noiseResistant" -> 0.08
                        else -> 0.12
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initSoundPool() {
        if (soundPool == null) {
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                .build()

            // 48 路高并发硬件混音通道，保障滑音连奏与和弦丰富度
            val pool = SoundPool.Builder()
                .setMaxStreams(48)
                .setAudioAttributes(attributes)
                .build()

            // 解码就绪监听：彻底解决 SoundPool 异步加载首按键无声问题
            pool.setOnLoadCompleteListener { _, sampleId, status ->
                if (status == 0) {
                    readySoundIds.add(sampleId)
                    val pending = pendingPlays.remove(sampleId)
                    if (pending != null) {
                        for (req in pending) {
                            val streamId = pool.play(sampleId, req.volume, req.volume, 1, 0, req.rate)
                            trackStream(req.midi, streamId, req.volume, req.sustainSec)
                        }
                    }
                }
            }
            soundPool = pool
        }
    }

    private fun loadInstrumentSync(instName: String) {
        val bank = BANKS[instName] ?: return
        val pool = soundPool ?: return
        for (sample in bank.notes) {
            val key = "${bank.dir}_${sample.midi}"
            if (!loadedSoundIds.containsKey(key)) {
                loadSampleFile(pool, bank.dir, sample.note, key)
            }
        }
    }

    private fun loadSampleFile(pool: SoundPool, dir: String, note: String, key: String): Int {
        var afd: AssetFileDescriptor? = null
        try {
            afd = assets.openFd("audio/$dir/$note.mp3")
        } catch (_: Exception) {
            try {
                afd = assets.openFd("flutter_assets/assets/audio/$dir/$note.mp3")
            } catch (_: Exception) {}
        }

        if (afd != null) {
            try {
                val soundId = pool.load(afd, 1)
                if (soundId > 0) {
                    loadedSoundIds[key] = soundId
                    return soundId
                }
            } catch (_: Exception) {
            } finally {
                try { afd.close() } catch (_: Exception) {}
            }
        }

        // 强保底：若 openFd 失败（如极端情况下资源被意外压缩），通过 InputStream 转存临时缓存文件加载
        try {
            val cacheFile = java.io.File(cacheDir, "snd_${dir}_${note}.mp3")
            if (!cacheFile.exists() || cacheFile.length() == 0L) {
                val paths = listOf("audio/$dir/$note.mp3", "flutter_assets/assets/audio/$dir/$note.mp3")
                var stream: java.io.InputStream? = null
                for (p in paths) {
                    try {
                        stream = assets.open(p)
                        if (stream != null) break
                    } catch (_: Exception) {}
                }
                if (stream != null) {
                    stream.use { input ->
                        cacheFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                }
            }
            if (cacheFile.exists() && cacheFile.length() > 0L) {
                val soundId = pool.load(cacheFile.absolutePath, 1)
                if (soundId > 0) {
                    loadedSoundIds[key] = soundId
                    return soundId
                }
            }
        } catch (_: Exception) {}

        return 0
    }

    private fun playSingleNoteInternal(midi: Int, timbre: String, volume: Float, sustainSec: Double, dampPrevious: Boolean = false) {
        val bank = BANKS[timbre] ?: BANKS["Concert Grand"] ?: return
        val pool = soundPool ?: return

        val clampedMidi = midi.coerceIn(0, 127)

        if (dampPrevious) {
            // 防浑浊快速平滑声学渐弱包络线到零：迅速衰减正在播放的前一个/其余音符，防止声音混叠浑浊
            smoothQuickDampPreviousStreams()
        } else {
            // 仅对相同 MIDI 音符进行平滑淡出，防止同频物理相位叠加，绝对不误伤其他琴键的自然延音
            dampSameMidiStreams(clampedMidi)
        }

        val (bestAnchor, rate) = bank.midiLookup[clampedMidi]

        val key = "${bank.dir}_${bestAnchor.midi}"
        var soundId = loadedSoundIds[key]
        if (soundId == null) {
            soundId = loadSampleFile(pool, bank.dir, bestAnchor.note, key)
            if (soundId == 0) return
        }

        if (readySoundIds.contains(soundId)) {
            val streamId = pool.play(soundId, volume, volume, 1, 0, rate)
            trackStream(clampedMidi, streamId, volume, sustainSec)
        } else {
            // 若还在异步解码中，加入待播队列，毫秒级就绪后立即触发，杜绝吞音
            pendingPlays.getOrPut(soundId) { Collections.synchronizedList(mutableListOf()) }
                .add(PendingPlay(volume, rate, clampedMidi, sustainSec))
        }
    }

    private fun trackStream(midi: Int, streamId: Int, volume: Float, sustainSec: Double) {
        if (streamId <= 0) return
        val list = activeNoteStreams.getOrPut(midi) { Collections.synchronizedList(mutableListOf()) }
        list.add(streamId)
        activeStreams.add(ActiveStreamInfo(streamId, volume))

        // 达到 sustainSec 后平滑释放，保障完整 3 秒自然钢琴泛音衰减
        val durationMs = (sustainSec * 1000).toLong()
        audioScheduler.schedule({
            smoothDampStream(streamId, volume)
            list.remove(streamId)
        }, durationMs, TimeUnit.MILLISECONDS)
    }

    private fun dampSameMidiStreams(midi: Int) {
        val streams = activeNoteStreams.remove(midi) ?: return
        for (sid in streams) {
            smoothDampStream(sid, 0.8f)
        }
    }

    private fun stopSingleNoteInternal(midi: Int) {
        dampSameMidiStreams(midi)
    }

    private fun playSamplesInternal(
        pitches: List<Int>,
        timbre: String,
        mode: String,
        speedMs: Int,
        volume: Double,
        sustainSec: Double,
        dampPrevious: Boolean
    ) {
        if (pitches.isEmpty()) return
        if (dampPrevious) {
            smoothQuickDampPreviousStreams()
        }

        val sortedPitches = ArrayList(pitches)
        if (mode == "Arp Up" || mode == "Ascending") {
            sortedPitches.sort()
        } else if (mode == "Arp Down" || mode == "Descending") {
            sortedPitches.sortWith(Comparator { a, b -> b.compareTo(a) })
        }

        val count = Math.max(1, sortedPitches.size)
        val perNoteVol = (volume * (1.0 / Math.pow(count.toDouble(), 0.5))).toFloat().coerceIn(0.15f, 0.95f)

        for (i in 0 until sortedPitches.size) {
            val midi = sortedPitches[i]
            val delayMs = if (mode == "Simultaneous") 0L else (i * speedMs).toLong()
            val shouldDamp = if (mode != "Simultaneous" && i > 0) dampPrevious else false
            if (delayMs == 0L) {
                playSingleNoteInternal(midi, timbre, perNoteVol, sustainSec, shouldDamp)
            } else {
                audioScheduler.schedule({
                    playSingleNoteInternal(midi, timbre, perNoteVol, sustainSec, shouldDamp)
                }, delayMs, TimeUnit.MILLISECONDS)
            }
        }
    }

    private fun smoothDampStream(streamId: Int, currentVol: Float) {
        val pool = soundPool ?: return
        executor.execute {
            try {
                // 优雅声学平滑渐隐衰减，消除机械骤停感与爆鸣
                pool.setVolume(streamId, currentVol * 0.6f, currentVol * 0.6f)
                Thread.sleep(60)
                pool.setVolume(streamId, currentVol * 0.25f, currentVol * 0.25f)
                Thread.sleep(80)
                pool.setVolume(streamId, currentVol * 0.05f, currentVol * 0.05f)
                Thread.sleep(80)
                pool.stop(streamId)
            } catch (_: Exception) {}
        }
    }

    // 琴键点击专用：快速声学平滑渐弱包络到零（约 80ms~90ms 快速平滑消除前音，杜绝浑浊且绝无爆破破音）
    private fun smoothQuickDampStream(streamId: Int, currentVol: Float) {
        val pool = soundPool ?: return
        executor.execute {
            try {
                pool.setVolume(streamId, currentVol * 0.40f, currentVol * 0.40f)
                Thread.sleep(35)
                pool.setVolume(streamId, currentVol * 0.10f, currentVol * 0.10f)
                Thread.sleep(45)
                pool.setVolume(streamId, 0f, 0f)
                pool.stop(streamId)
            } catch (_: Exception) {}
        }
    }

    private fun smoothQuickDampPreviousStreams() {
        val list = mutableListOf<ActiveStreamInfo>()
        synchronized(activeStreams) {
            list.addAll(activeStreams)
            activeStreams.clear()
        }
        activeNoteStreams.clear()
        for (info in list) {
            smoothQuickDampStream(info.streamId, info.volume)
        }
    }

    private fun smoothDampPreviousStreams() {
        synchronized(activeStreams) {
            for (info in activeStreams) {
                smoothDampStream(info.streamId, info.volume)
            }
            activeStreams.clear()
        }
    }

    private fun stopAllAudio() {
        soundPool?.autoPause()
        activeStreams.clear()
        activeNoteStreams.clear()
        pendingPlays.clear()
    }

    // ================= 实时人声聆听与音高识别引擎 =================
    private var isListening = false
    private var audioRecord: AudioRecord? = null
    private var listeningThread: Thread? = null
    private var lastReportedMidi: Int? = null
    private var silenceCounter = 0
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val RECORD_AUDIO_PERMISSION_CODE = 1001
    // 人声灵敏度门限 (Balanced 推荐默认: 250.0, High: 150.0, NoiseResistant: 500.0)
    @Volatile
    private var pitchRmsThreshold = 250.0
    @Volatile
    private var pitchYinThreshold = 0.12
    @Volatile
    private var lastContinuousMidi: Int? = null
    @Volatile
    private var lastContinuousTau = 0.0
    @Volatile
    private var octaveJumpCandidateMidi: Int? = null
    @Volatile
    private var octaveJumpFrameCount = 0

    private fun checkAndStartListening(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingPermissionResult = result
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_PERMISSION_CODE)
            return
        }
        val success = startAudioPitchDetection()
        result.success(success)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                val success = startAudioPitchDetection()
                pendingPermissionResult?.success(success)
            } else {
                pendingPermissionResult?.success(false)
            }
            pendingPermissionResult = null
        }
    }

    private fun startAudioPitchDetection(): Boolean {
        if (isListening) return true
        isListening = true
        lastReportedMidi = null
        silenceCounter = 0

        // 采用 Android CDD 全设备 100% 硬件保证支持的标准采样率 44100Hz
        val requestedSampleRate = 44100
        val windowSize = 2048 // 约 46.4ms 分析窗口 (保障最低基频 C2~65Hz 具有充足分析周期)
        val hopSize = 512    // 约 11.6ms 刷新步长 (刷新率 ~86Hz，高精度超低延迟捕获人声转音)

        val minBuf = AudioRecord.getMinBufferSize(requestedSampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val actualBufSize = Math.max(minBuf, hopSize * 4)

        var record: AudioRecord? = null
        try {
            record = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                requestedSampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                actualBufSize
            )
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                record = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    requestedSampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    actualBufSize
                )
            }
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                isListening = false
                return false
            }
            record.startRecording()
            audioRecord = record
        } catch (_: Exception) {
            isListening = false
            return false
        }

        listeningThread = Thread {
            // 严谨读取 Android 硬件实际运行采样率 (杜绝由于底层采样率重采样不一致引起的音高八度缩放)
            val sampleRate = record.sampleRate
            // 人声与高音乐器基频范围: 60Hz (B1) ~ 2400Hz (D7)，全量覆盖 C2~C7 (61 键)
            val minTau = (sampleRate / 2400.0).toInt().coerceAtLeast(4)
            val maxTau = (sampleRate / 60.0).toInt().coerceAtMost(windowSize - 1)
            val totalBufferLen = windowSize + maxTau + 16

            val circularBuffer = DoubleArray(totalBufferLen)
            val dcBlocker = DcBlocker(0.995)
            val hopShorts = ShortArray(hopSize)
            var samplesFilled = 0

            while (isListening) {
                val readCount = record.read(hopShorts, 0, hopSize)
                if (readCount < hopSize) {
                    try { Thread.sleep(5) } catch (_: Exception) {}
                    continue
                }

                // 滑动窗口：前移并载入最新采样点
                System.arraycopy(circularBuffer, readCount, circularBuffer, 0, totalBufferLen - readCount)
                var sumSquare = 0.0
                val offset = totalBufferLen - readCount
                for (i in 0 until readCount) {
                    val s = hopShorts[i].toDouble()
                    val cleaned = dcBlocker.process(s)
                    circularBuffer[offset + i] = cleaned
                    sumSquare += cleaned * cleaned
                }
                samplesFilled = Math.min(totalBufferLen, samplesFilled + readCount)
                if (samplesFilled < totalBufferLen) {
                    continue
                }

                val rms = Math.sqrt(sumSquare / readCount)

                // 静音门限检验
                if (rms < pitchRmsThreshold) {
                    silenceCounter++
                    if (silenceCounter >= 3 && lastReportedMidi != null) {
                        lastReportedMidi = null
                        lastContinuousMidi = null
                        lastContinuousTau = 0.0
                        octaveJumpCandidateMidi = null
                        octaveJumpFrameCount = 0
                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onPitchDetected",
                                mapOf("active" to false, "midi" to null, "freq" to 0.0, "volume" to 0.0)
                            )
                        }
                    }
                    continue
                }

                // ================= 工业级标准纯正 YIN 算法 =================
                // 1. 差分函数 (Difference Function)
                val d = DoubleArray(maxTau + 1)
                for (tau in minTau..maxTau) {
                    var diffSum = 0.0
                    for (i in 0 until windowSize) {
                        val delta = circularBuffer[i] - circularBuffer[i + tau]
                        diffSum += delta * delta
                    }
                    d[tau] = diffSum
                }

                // 2. 累积均值归一化差分函数 (Cumulative Mean Normalized Difference Function)
                val dPrime = DoubleArray(maxTau + 1)
                dPrime[0] = 1.0
                var runningSum = 0.0
                for (tau in 1..maxTau) {
                    runningSum += d[tau]
                    dPrime[tau] = if (runningSum > 0.0) {
                        (d[tau] * tau) / runningSum
                    } else {
                        1.0
                    }
                }

                // 3. 严格遵循 YIN 论文绝对阈值第一极小值准则 (First Local Minimum Below Threshold)
                // 核心准则：从 minTau 开始扫描，一旦找到第一个跌破阈值且开始回升的局部波谷，立即确认为基频周期！
                // 严禁向后跳入 2*tau 或 4*tau，彻底从根源消除低一个或两个八度误判！
                var tauFound = -1
                var scanTau = minTau
                while (scanTau < maxTau) {
                    if (dPrime[scanTau] < pitchYinThreshold) {
                        while (scanTau + 1 < maxTau && dPrime[scanTau + 1] < dPrime[scanTau]) {
                            scanTau++
                        }
                        tauFound = scanTau
                        break
                    }
                    scanTau++
                }

                // 若未跌破阈值，寻找全局极小波谷，但要求全局极小值 < 0.35 确保音质调性
                if (tauFound < 0) {
                    var globalMinTau = minTau
                    var globalMinVal = Double.MAX_VALUE
                    for (t in minTau until maxTau) {
                        if (dPrime[t] < globalMinVal) {
                            globalMinVal = dPrime[t]
                            globalMinTau = t
                        }
                    }
                    if (globalMinVal < 0.35) {
                        tauFound = globalMinTau
                    }
                }

                if (tauFound < 0) {
                    silenceCounter++
                    if (silenceCounter >= 3 && lastReportedMidi != null) {
                        lastReportedMidi = null
                        lastContinuousMidi = null
                        lastContinuousTau = 0.0
                        octaveJumpCandidateMidi = null
                        octaveJumpFrameCount = 0
                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onPitchDetected",
                                mapOf("active" to false, "midi" to null, "freq" to 0.0, "volume" to 0.0)
                            )
                        }
                    }
                    continue
                }

                var bestTau = tauFound

                // 4. 连续性八度跳变平滑 (消除吟唱时的双八度交替闪烁)
                if (bestTau > 0 && lastContinuousMidi != null && lastContinuousTau > 0) {
                    val lastMidi = lastContinuousMidi!!
                    val tentativeFreq = sampleRate.toDouble() / bestTau
                    val tentativeMidi = (69.0 + 12.0 * (Math.log(tentativeFreq / 440.0) / Math.log(2.0))).roundToInt()
                    val diffMidi = Math.abs(tentativeMidi - lastMidi)

                    if (diffMidi in 11..13) {
                        val histTau = lastContinuousTau.toInt().coerceIn(minTau, maxTau)
                        if (dPrime[histTau] < 0.28) {
                            if (octaveJumpCandidateMidi == tentativeMidi) {
                                octaveJumpFrameCount++
                                if (octaveJumpFrameCount < 3) {
                                    bestTau = histTau
                                }
                            } else {
                                octaveJumpCandidateMidi = tentativeMidi
                                octaveJumpFrameCount = 1
                                bestTau = histTau
                            }
                        } else {
                            octaveJumpCandidateMidi = null
                            octaveJumpFrameCount = 0
                        }
                    } else {
                        octaveJumpCandidateMidi = null
                        octaveJumpFrameCount = 0
                    }
                }

                // 5. 抛物线二次插值精确定位 (Parabolic Interpolation)
                if (bestTau in (minTau + 1) until maxTau) {
                    val s0 = dPrime[bestTau - 1]
                    val s1 = dPrime[bestTau]
                    val s2 = dPrime[bestTau + 1]
                    val denom = 2.0 * (2.0 * s1 - s0 - s2)
                    val delta = if (denom != 0.0) (s0 - s2) / denom else 0.0
                    val refinedTau = (bestTau.toDouble() + delta).coerceIn(minTau.toDouble(), maxTau.toDouble())

                    val freq = sampleRate.toDouble() / refinedTau
                    if (freq in 60.0..2400.0) {
                        val midi = (69.0 + 12.0 * (Math.log(freq / 440.0) / Math.log(2.0))).roundToInt().coerceIn(21, 108)

                        silenceCounter = 0
                        lastReportedMidi = midi
                        lastContinuousTau = refinedTau
                        lastContinuousMidi = midi

                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onPitchDetected",
                                mapOf("active" to true, "midi" to midi, "freq" to freq, "volume" to rms)
                            )
                        }
                    }
                } else {
                    silenceCounter++
                    if (silenceCounter >= 3 && lastReportedMidi != null) {
                        lastReportedMidi = null
                        lastContinuousMidi = null
                        lastContinuousTau = 0.0
                        octaveJumpCandidateMidi = null
                        octaveJumpFrameCount = 0
                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onPitchDetected",
                                mapOf("active" to false, "midi" to null, "freq" to 0.0, "volume" to 0.0)
                            )
                        }
                    }
                }
            }
        }.apply {
            priority = Thread.MAX_PRIORITY - 1
            start()
        }

        return true
    }

    private fun stopAudioPitchDetection() {
        isListening = false
        lastReportedMidi = null
        lastContinuousMidi = null
        lastContinuousTau = 0.0
        octaveJumpCandidateMidi = null
        octaveJumpFrameCount = 0
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (_: Exception) {}
        audioRecord = null
        listeningThread = null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAudioPitchDetection()
        abandonAppAudioFocus()
        audioScheduler.shutdownNow()
        executor.shutdownNow()
        soundPool?.release()
        soundPool = null
    }
}
