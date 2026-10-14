package com.lifeos.lifeos_kupler

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "lifeos_kupler/display": lets the game ask for the screen's highest
        // refresh rate (90/120/144 Hz). Android keeps most apps at 60 Hz
        // unless they pick a display mode themselves.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifeos_kupler/display").setMethodCallHandler { call, result ->
            when (call.method) {
                "setHighRefreshRate" -> result.success(setHighRefreshRate(call.arguments as? Boolean ?: false))
                "maxRefreshRate" -> result.success(maxRefreshRate())
                else -> result.notImplemented()
            }
        }
        // "lifeos_kupler/haptics": game vibration straight through the
        // Vibrator service, tagged as media/game vibration. (The vibration
        // plugin tags it as an alarm, which some phones silence.)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifeos_kupler/haptics").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasVibrator" -> result.success(vibrator()?.hasVibrator() == true)
                "vibrate" -> {
                    val args = call.arguments as? List<*>
                    val timings = args?.getOrNull(0) as? List<*>
                    val amplitudes = args?.getOrNull(1) as? List<*>
                    vibrate(
                        timings?.mapNotNull { (it as? Number)?.toLong() } ?: emptyList(),
                        amplitudes?.mapNotNull { (it as? Number)?.toInt() } ?: emptyList(),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    /** [timings]: off/on durations in ms (starting with a pause); [amplitudes]: 0..255 per step. */
    @Suppress("DEPRECATION")
    private fun vibrate(timings: List<Long>, amplitudes: List<Int>) {
        val v = vibrator() ?: return
        if (!v.hasVibrator() || timings.isEmpty()) return
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                v.vibrate(timings.toLongArray(), -1)
                return
            }
            val useAmplitude = v.hasAmplitudeControl() && amplitudes.size == timings.size
            val effect = if (useAmplitude) {
                VibrationEffect.createWaveform(timings.toLongArray(), amplitudes.map { it.coerceIn(0, 255) }.toIntArray(), -1)
            } else {
                VibrationEffect.createWaveform(timings.toLongArray(), -1)
            }
            when {
                Build.VERSION.SDK_INT >= 33 ->
                    v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
                else ->
                    v.vibrate(effect, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).build())
            }
        } catch (e: Exception) {
            // Never let a vibration problem break the game.
        }
    }

    @Suppress("DEPRECATION")
    private fun currentDisplay(): Display? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display else windowManager.defaultDisplay

    /** Display modes with the current resolution (only the refresh rate differs). */
    private fun sameSizeModes(display: Display): List<Display.Mode> {
        val current = display.mode
        return display.supportedModes.filter {
            it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight
        }
    }

    private fun maxRefreshRate(): Double {
        val display = currentDisplay() ?: return 60.0
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return display.refreshRate.toDouble()
        return (sameSizeModes(display).maxOfOrNull { it.refreshRate } ?: display.refreshRate).toDouble()
    }

    /** Picks the fastest mode, or the one closest to 60 Hz. Returns its rate. */
    private fun setHighRefreshRate(on: Boolean): Double {
        val display = currentDisplay() ?: return 60.0
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return display.refreshRate.toDouble()
        val modes = sameSizeModes(display)
        val target = if (on) modes.maxByOrNull { it.refreshRate } else modes.minByOrNull { abs(it.refreshRate - 60f) }
        val params = window.attributes
        params.preferredDisplayModeId = target?.modeId ?: 0
        window.attributes = params
        return (target?.refreshRate ?: display.refreshRate).toDouble()
    }
}
