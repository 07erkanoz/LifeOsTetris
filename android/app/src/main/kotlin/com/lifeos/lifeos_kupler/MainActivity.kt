package com.lifeos.lifeos_kupler

import android.os.Build
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
