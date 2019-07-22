package com.example.joystick

import android.os.Handler
import android.os.Looper
import android.view.InputDevice
import android.view.MotionEvent
import android.view.View
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlin.math.absoluteValue

val motionSources = mapOf(
        "AXIS_HAT_X" to MotionEvent.AXIS_HAT_X,
        "AXIS_HAT_Y" to MotionEvent.AXIS_HAT_Y,
        "AXIS_X" to MotionEvent.AXIS_X,
        "AXIS_Y" to MotionEvent.AXIS_Y,
        "AXIS_Z" to MotionEvent.AXIS_Z,
        "AXIS_RZ" to MotionEvent.AXIS_RZ
)

class MotionControllerAdapter(
        val registrar: Registrar,
        var sources: Pair<String, String>,
        val searchForAxis: Boolean = false
): MethodCallHandler, EventChannel.StreamHandler, View(registrar.context()) {
    var axes = Pair(
            motionSources[sources.first] ?: MotionEvent.AXIS_X,
            motionSources[sources.second] ?: MotionEvent.AXIS_Y
    )
    val methodChannelName: String = "joystick/${sources.first}/${sources.second}"
    private val _handler = Handler(Looper.getMainLooper())
    private val _channel = MethodChannel(registrar.messenger(), methodChannelName)
    private val _eventChannel = EventChannel(registrar.messenger(), "$methodChannelName/stream")
    private var _eventSink: EventChannel.EventSink? = null

    init {
        _channel.setMethodCallHandler(this)
        _eventChannel.setStreamHandler(this)
    }

    private fun getCenteredAxis(
            event: MotionEvent,
            axis: Int,
            device: InputDevice,
            histPos: Int
    ): Float {
        val range = device.getMotionRange(axis)
        range?.apply {
            val value =
                    if (histPos < 0) event.getAxisValue(axis)
                    else event.getHistoricalAxisValue(axis, histPos)
            if (value.absoluteValue > range.flat) return value
        }
        return 0f
    }

    private fun processInput(
            event: MotionEvent,
            axes: Pair<Int, Int>,
            searchForAxis: Boolean,
            histPos: Int
    ): Pair<Float, Float> {
        var x = 0f
        if (axes.first == MotionEvent.AXIS_X || searchForAxis)
            x = getCenteredAxis(event, MotionEvent.AXIS_X, event.device, histPos)
        if (axes.first == MotionEvent.AXIS_HAT_X || (x == 0f && searchForAxis))
            x = getCenteredAxis(event, MotionEvent.AXIS_HAT_X, event.device, histPos)
        if (axes.first == MotionEvent.AXIS_Z || (x == 0f && searchForAxis))
            x = getCenteredAxis(event, MotionEvent.AXIS_Z, event.device, histPos)

        var y = 0f
        if (axes.second == MotionEvent.AXIS_Y || searchForAxis)
            y = getCenteredAxis(event, MotionEvent.AXIS_Y, event.device, histPos)
        if (axes.second == MotionEvent.AXIS_HAT_Y || (y == 0f && searchForAxis))
            y = getCenteredAxis(event, MotionEvent.AXIS_HAT_Y, event.device, histPos)
        if (axes.second == MotionEvent.AXIS_RZ || (y == 0f && searchForAxis))
            y = getCenteredAxis(event, MotionEvent.AXIS_RZ, event.device, histPos)

        return Pair(x, y)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setSources" -> {
                val newSources = call.argument<List<String>>("sources") ?: return
                sources = Pair(newSources[0], newSources[1])
                axes =  Pair(
                        motionSources[sources.first] ?: MotionEvent.AXIS_X,
                        motionSources[sources.second] ?: MotionEvent.AXIS_Y
                )
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(o: Any?, sink: EventChannel.EventSink?) {
        _eventSink = sink
    }

    override fun onCancel(o: Any?) {
        _eventSink = null
    }

    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        if (_eventSink != null && event != null) {
            (0 until event.historySize).forEach {
                _handler.post {
                    _eventSink?.success(processInput(event, axes, searchForAxis, it).toList())
                }
            }
            _handler.post {
                _eventSink?.success(processInput(event, axes, searchForAxis, -1).toList())
            }
            return true
        }
        return super.onGenericMotionEvent(event)
    }
}
