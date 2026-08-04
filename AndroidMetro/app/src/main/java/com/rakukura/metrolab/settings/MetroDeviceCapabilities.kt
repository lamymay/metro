package com.rakukura.metrolab.settings

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.camera2.CameraManager
import android.os.BatteryManager
import android.os.Build
import android.view.WindowManager

/**
 * The handful of Settings/Action Center toggles that a sandboxed app can *actually*
 * touch. WiFi, Bluetooth, airplane mode and rotation lock all require permissions an
 * ordinary app can never hold — those stay purely visual, like the rest of the lab.
 * Brightness, torch, battery status and keep-awake do not, so those are wired for real:
 * dragging the brightness tile here changes the actual screen brightness.
 */
class MetroDeviceCapabilities(private val activity: Activity) {

    private val listeners = ArrayList<() -> Unit>()

    fun addListener(l: () -> Unit) {
        listeners.add(l)
    }

    fun removeListener(l: () -> Unit) {
        listeners.remove(l)
    }

    private fun notifyChanged() {
        for (l in ArrayList(listeners)) l()
    }

    // ---- Brightness ----

    /** 0f..1f, mirrors the window's own `LayoutParams.screenBrightness`. */
    var brightness: Float = readWindowBrightness()
        private set

    fun setBrightness(value: Float) {
        brightness = value.coerceIn(0.01f, 1f)
        val params = activity.window.attributes
        params.screenBrightness = brightness
        activity.window.attributes = params
        notifyChanged()
    }

    private fun readWindowBrightness(): Float {
        val current = activity.window.attributes.screenBrightness
        return if (current in 0f..1f) current else 0.7f
    }

    // ---- Keep awake ----

    var keepAwake: Boolean = false
        set(value) {
            field = value
            if (value) {
                activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            notifyChanged()
        }

    // ---- Torch ----

    /** `CameraManager.setTorchMode` needs API 23; below that there is no public torch
     * API at all, so the control simply doesn't offer itself. */
    val torchAvailable: Boolean
        get() = Build.VERSION.SDK_INT >= 23 &&
            activity.packageManager.hasSystemFeature("android.hardware.camera.flash")

    var torchOn: Boolean = false
        set(value) {
            field = value
            applyTorch()
            notifyChanged()
        }

    private fun applyTorch() {
        if (Build.VERSION.SDK_INT < 23) return
        try {
            val manager = activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val id = manager.cameraIdList.firstOrNull {
                manager.getCameraCharacteristics(it)
                    .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return
            manager.setTorchMode(id, torchOn)
        } catch (_: Exception) {
            // No permission, or torch already claimed by the camera app — nothing to
            // usefully recover here.
        }
    }

    // ---- Battery ----

    var batteryLevel: Int = -1
        private set
    var batteryStateDescription: String = "unknown"
        private set

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
            batteryLevel = if (level >= 0 && scale > 0) (level * 100 / scale) else -1
            batteryStateDescription = when (intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
                BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                BatteryManager.BATTERY_STATUS_FULL -> "full"
                BatteryManager.BATTERY_STATUS_DISCHARGING, BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "on battery"
                else -> "unknown"
            }
            notifyChanged()
        }
    }

    fun startObservingBattery() {
        activity.registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    fun stopObservingBattery() {
        try {
            activity.unregisterReceiver(batteryReceiver)
        } catch (_: IllegalArgumentException) {
            // Already unregistered.
        }
    }
}
