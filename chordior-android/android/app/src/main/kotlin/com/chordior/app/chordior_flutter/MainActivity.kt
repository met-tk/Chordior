package com.chordior.app.chordior_flutter

import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

data class NoteSample(val note: String, val midi: Int)
data class InstrumentBank(val dir: String, val notes: List<NoteSample>)

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.chordior.app/audio"
    private val executor = Executors.newCachedThreadPool()
    // 独立高优先级音频定时调度池：彻底脱离 Android UI 主线程，根治扫弦与琶音卡壳
    private val audioScheduler: ScheduledExecutorService = Executors.newScheduledThreadPool(2)

    private var soundPool: SoundPool? = null
    // key: "piano_36" -> soundId
    private val loadedSoundIds = ConcurrentHashMap<String, Int>()
    // 活跃播放音流追踪
    private val activeStreams = Collections.synchronizedList(mutableListOf<ActiveStreamInfo>())

    data class ActiveStreamInfo(val streamId: Int, val volume: Float)

    @Volatile
    private var lastTrack: AudioTrack? = null

    private val BANKS = mapOf(
        "Concert Grand" to InstrumentBank("piano", listOf(
            NoteSample("C2", 36), NoteSample("Ds2", 39), NoteSample("Fs2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Ds3", 51), NoteSample("Fs3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Ds4", 63), NoteSample("Fs4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Ds5", 75), NoteSample("Fs5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Acoustic Guitar" to InstrumentBank("guitar_steel", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Nylon Guitar" to InstrumentBank("guitar_nylon", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Fender Rhodes" to InstrumentBank("rhodes", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Church Organ" to InstrumentBank("organ", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Warm Synth Pad" to InstrumentBank("synth_pad", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        )),
        "Celesta & Bells" to InstrumentBank("celesta", listOf(
            NoteSample("C2", 36), NoteSample("Eb2", 39), NoteSample("Gb2", 42), NoteSample("A2", 45),
            NoteSample("C3", 48), NoteSample("Eb3", 51), NoteSample("Gb3", 54), NoteSample("A3", 57),
            NoteSample("C4", 60), NoteSample("Eb4", 63), NoteSample("Gb4", 66), NoteSample("A4", 69),
            NoteSample("C5", 72), NoteSample("Eb5", 75), NoteSample("Gb5", 78), NoteSample("A5", 81),
            NoteSample("C6", 84)
        ))
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initSoundPool()
        // 启动时在后台有序预热全部 6 种乐器采样（优先预热 Concert Grand 与 Warm Synth Pad）
        executor.execute {
            loadInstrumentSync("Concert Grand")
            loadInstrumentSync("Warm Synth Pad")
            loadInstrumentSync("Church Organ")
            loadInstrumentSync("Acoustic Guitar")
            loadInstrumentSync("Fender Rhodes")
            loadInstrumentSync("Celesta & Bells")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setTimbre" -> {
                    val timbre = call.argument<String>("timbre") ?: "Concert Grand"
                    executor.execute { loadInstrumentSync(timbre) }
                    result.success(true)
                }
                "playSamples" -> {
                    val pitches = call.argument<List<Int>>("pitches") ?: emptyList()
                    val timbre = call.argument<String>("timbre") ?: "Concert Grand"
                    val mode = call.argument<String>("mode") ?: "Simultaneous"
                    val speedMs = call.argument<Int>("speedMs") ?: 35
                    val volume = call.argument<Double>("volume") ?: 0.85
                    val sustainSec = call.argument<Double>("sustainSec") ?: 2.0
                    val dampPrevious = call.argument<Boolean>("dampPrevious") ?: true

                    playSamplesInternal(pitches, timbre, mode, speedMs, volume, sustainSec, dampPrevious)
                    result.success(true)
                }
                "playPcm" -> {
                    val pcmBytes = call.argument<ByteArray>("bytes")
                    val sampleRate = call.argument<Int>("sampleRate") ?: 44100
                    if (pcmBytes != null && pcmBytes.isNotEmpty()) {
                        playPcmInternal(pcmBytes, sampleRate)
                    }
                    result.success(true)
                }
                "stopAudio" -> {
                    stopAllAudio()
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
                .build()

            // 32 路流兼顾低配机型混音性能与多复音丰富度
            soundPool = SoundPool.Builder()
                .setMaxStreams(32)
                .setAudioAttributes(attributes)
                .build()
        }
    }

    private fun loadInstrumentSync(instName: String) {
        val bank = BANKS[instName] ?: return
        for (sample in bank.notes) {
            val key = "${bank.dir}_${sample.midi}"
            if (!loadedSoundIds.containsKey(key)) {
                try {
                    val path = "audio/${bank.dir}/${sample.note}.mp3"
                    val afd: AssetFileDescriptor = assets.openFd(path)
                    val soundId = soundPool?.load(afd, 1) ?: 0
                    if (soundId > 0) {
                        loadedSoundIds[key] = soundId
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun playPcmInternal(pcmBytes: ByteArray, sampleRate: Int) {
        executor.execute {
            try {
                val bufferSize = pcmBytes.size
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()

                track.write(pcmBytes, 0, bufferSize)
                track.play()
                lastTrack = track
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
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
        val bank = BANKS[timbre] ?: BANKS["Concert Grand"] ?: return

        // 换和弦平滑阻尼：降为 15% 微弱余音，65ms 后平滑释放
        if (dampPrevious) {
            smoothDampPreviousStreams()
        }

        // 音符排序
        val sortedPitches = ArrayList(pitches)
        if (mode == "Pop Strum" || mode == "Arp Up") {
            sortedPitches.sort()
        } else if (mode == "Arp Down") {
            sortedPitches.sortWith(Comparator { a, b -> b.compareTo(a) })
        }

        val pool = soundPool ?: return

        // 多音和弦动态头寸削波保护 (Headroom Limiter)
        val noteCount = Math.max(1, sortedPitches.size)
        val baseVol = (volume * (1.0 / Math.pow(noteCount.toDouble(), 0.55))).toFloat().coerceIn(0.08f, 0.88f)

        val baseSampleSec = if (bank.dir == "piano") 15.0 else if (bank.dir == "synth_pad") 3.8 else 3.129
        // 核心声学法则 1：计算当前和弦中物理发声时间最短的那个音符！
        var minPhysicalMs = Long.MAX_VALUE
        for (midi in sortedPitches) {
            var bestAnchor = bank.notes[0]
            var minDiff = Math.abs(midi - bestAnchor.midi)
            for (n in bank.notes) {
                val d = Math.abs(midi - n.midi)
                if (d < minDiff) {
                    minDiff = d
                    bestAnchor = n
                }
            }
            val semitoneDiff = (midi - bestAnchor.midi).toDouble()
            val rate = Math.pow(2.0, semitoneDiff / 12.0).coerceIn(0.5, 2.0)
            // 该音符在硬件 DAC 上实际物理能播放的总毫秒数
            val notePlayableMs = Math.floor((baseSampleSec / rate) * 1000).toLong()
            if (notePlayableMs < minPhysicalMs) {
                minPhysicalMs = notePlayableMs
            }
        }

        // 核心声学法则 2：全体音符的共同衰减终点，必须提前最短音符 220ms 彻底归零！
        // 钢琴采样超长无需提前，其余非无限持续乐器预留 220ms 裕度，绝不给任何音符触碰文件末端提前暴毙的机会！
        val safePhysicalMs = if (bank.dir == "piano") 15000L else Math.max(400L, minPhysicalMs - 220L)
        val commonDurationMs = Math.min((sustainSec * 1000).toLong(), safePhysicalMs).coerceIn(400L, 16000L)

        // 收集本次和弦启动的流，用于共同包络驱动
        val currentChordStreams = Collections.synchronizedList(mutableListOf<ActiveStreamInfo>())

        for (i in 0 until sortedPitches.size) {
            val targetMidi = sortedPitches[i]

            // 同时发声微交错调度 (Micro-Staggering，平摊 CPU 峰值，从根源消灭爆音)
            val delayMs = if (mode == "Simultaneous") (i * 2).toLong() else (i * speedMs).toLong()

            // 查找最近基准采样
            var bestAnchor = bank.notes[0]
            var minDiff = Math.abs(targetMidi - bestAnchor.midi)
            for (n in bank.notes) {
                val d = Math.abs(targetMidi - n.midi)
                if (d < minDiff) {
                    minDiff = d
                    bestAnchor = n
                }
            }

            val key = "${bank.dir}_${bestAnchor.midi}"
            val soundId = loadedSoundIds[key]

            if (soundId != null && soundId > 0) {
                // 计算半音变调速率
                val semitoneDiff = (targetMidi - bestAnchor.midi).toDouble()
                val rate = Math.pow(2.0, semitoneDiff / 12.0).toFloat().coerceIn(0.5f, 2.0f)

                val playRunnable = Runnable {
                    try {
                        val streamId = pool.play(soundId, baseVol, baseVol, 1, 0, rate)
                        if (streamId > 0) {
                            val info = ActiveStreamInfo(streamId, baseVol)
                            activeStreams.add(info)
                            currentChordStreams.add(info)
                        }
                    } catch (_: Exception) {}
                }

                // 专有高精度音频调度器异步执行
                if (delayMs > 0) {
                    audioScheduler.schedule(playRunnable, delayMs, TimeUnit.MILLISECONDS)
                } else {
                    audioScheduler.execute(playRunnable)
                }
            } else {
                executor.execute {
                    try {
                        val path = "audio/${bank.dir}/${bestAnchor.note}.mp3"
                        val afd = assets.openFd(path)
                        val sId = pool.load(afd, 1)
                        if (sId > 0) {
                            loadedSoundIds[key] = sId
                        }
                    } catch (_: Exception) {}
                }
            }
        }

        // 核心声学法则 3：前慢后快平滑余弦包络 (Cosine Rolloff Envelope)
        // 前 65% 时间保持 100% 满音量；后 35% 时间平滑余弦加速滚降，并在 commonDurationMs 瞬间全员共同停止
        val rolloffStartMs = (commonDurationMs * 0.65).toLong()
        val rolloffDurationMs = (commonDurationMs - rolloffStartMs).coerceAtLeast(120L)
        val steps = 12
        val stepIntervalMs = rolloffDurationMs / steps

        for (k in 1..steps) {
            val progress = k.toDouble() / steps.toDouble()
            // 余弦函数：cos(0)=1 开始下降极其平缓无感知，随后逐渐加快，最后 cos(pi/2)=0 绝对归零
            val factor = Math.cos(Math.PI * 0.5 * progress).toFloat()
            val stepTimeMs = rolloffStartMs + (k * stepIntervalMs)

            audioScheduler.schedule({
                synchronized(currentChordStreams) {
                    for (item in currentChordStreams) {
                        try {
                            val currentV = item.volume * factor
                            pool.setVolume(item.streamId, currentV, currentV)
                            if (k == steps) {
                                // 核心优化：在最后一步已完全降为 0 音量，延迟 45ms 零振幅静默停止，彻底杜绝切断杂音！
                                audioScheduler.schedule({
                                    try { pool.stop(item.streamId) } catch (_: Exception) {}
                                }, 45, TimeUnit.MILLISECONDS)
                            }
                        } catch (_: Exception) {}
                    }
                }
            }, stepTimeMs, TimeUnit.MILLISECONDS)
        }
    }

    /**
     * 极速无锁平滑阻尼：彻底消灭老旧手机上的高频锁阻塞与爆音
     */
    private fun smoothDampPreviousStreams() {
        val targets: List<ActiveStreamInfo>
        synchronized(activeStreams) {
            if (activeStreams.isEmpty()) return
            targets = ArrayList(activeStreams)
            activeStreams.clear()
        }

        val pool = soundPool ?: return
        // 瞬间将上一和弦降为 15% 微弱余音，为新和弦让出主声部，消除波形突变
        for (info in targets) {
            try {
                val lowVol = info.volume * 0.15f
                pool.setVolume(info.streamId, lowVol, lowVol)
            } catch (_: Exception) {}
        }

        // 65ms 后由后台任务静默释放旧音轨，零 CPU 争抢
        audioScheduler.schedule({
            for (info in targets) {
                try {
                    pool.stop(info.streamId)
                } catch (_: Exception) {}
            }
        }, 65, TimeUnit.MILLISECONDS)
    }

    private fun stopAllAudio() {
        synchronized(activeStreams) {
            val pool = soundPool
            if (pool != null) {
                for (info in activeStreams) {
                    try {
                        pool.stop(info.streamId)
                    } catch (_: Exception) {}
                }
            }
            activeStreams.clear()
        }
        lastTrack?.let {
            try {
                it.stop()
                it.release()
            } catch (_: Exception) {}
        }
        lastTrack = null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAllAudio()
        audioScheduler.shutdownNow()
        soundPool?.release()
        soundPool = null
    }
}


