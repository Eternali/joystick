package com.example.joystick

import android.os.Handler
import android.os.Looper
import android.util.Log
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

// Map of strings dart plugin sends to MotionEvent integer values.
val motionSources = mapOf(
        "AXIS_HAT_X" to MotionEvent.AXIS_HAT_X,
        "AXIS_HAT_Y" to MotionEvent.AXIS_HAT_Y,
        "AXIS_X" to MotionEvent.AXIS_X,
        "AXIS_Y" to MotionEvent.AXIS_Y,
        "AXIS_Z" to MotionEvent.AXIS_Z,
        "AXIS_RZ" to MotionEvent.AXIS_RZ
)

// Motion Controller
// searchForAxis determines whether or not we are strict in terms of what axes we are interested in.
// If true, it will go through the axes on joystick 1, then the dpad, and then joystick 2 and will
// return the first non zero value it finds.
class MotionControllerAdapter(
        val registrar: Registrar,
        var sources: Pair<String, String>,
        val searchForAxis: Boolean = false
): MethodCallHandler, EventChannel.StreamHandler {
    var axes = Pair(
            motionSources[sources.first] ?: MotionEvent.AXIS_X,
            motionSources[sources.second] ?: MotionEvent.AXIS_Y
    )
    // The method channel name is based on the axes it is interested in.
    val methodChannelName: String = "joystick/${sources.first}/${sources.second}"
    // Handler so we can send calls to the main thread.
    private val _handler = Handler(Looper.getMainLooper())
    // MethodChannel for this specific motion controller.
    private val _channel = MethodChannel(registrar.messenger(), methodChannelName)
    // EventChannel to manage motion events.
    private val _eventChannel = EventChannel(registrar.messenger(), "$methodChannelName/stream")
    // EventSink to publish motion events on for the plugin to listen to.
    private var _eventSink: EventChannel.EventSink? = null
    // Motion event callback so for the main plugin to register in its handler.
    val motionListener: (View, MotionEvent?) -> Boolean = ml@{ view, event ->
        if (_eventSink != null && event != null) {
            // Motion events contain a list of historical events that have occurred since the
            // callback was last triggered.
            (0 until event.historySize).forEach {
                // Send to the event sink in the main handler thread.
                _handler.post {
                    _eventSink?.success(processInput(event, axes, searchForAxis, it).toList())
                }
            }
            // Handle the latest event last.
            _handler.post {
                _eventSink?.success(processInput(event, axes, searchForAxis, -1).toList())
            }
            return@ml true
        }
        false
    }

    init {
        // Send plugin method calls here
        _channel.setMethodCallHandler(this)
        // Send plugin event stream calls here
        _eventChannel.setStreamHandler(this)
    }

    // Center the event axis value. Often joysticks have a set of values that they consider to be
    // centered and use this to check if it is zeroed.
    private fun getCenteredAxis(
            event: MotionEvent,
            axis: Int,
            device: InputDevice,
            histPos: Int
    ): Float {
        val range = device.getMotionRange(axis)
        range?.apply {
            try {
                Log.w("Flutter", event.getAxisValue(axis).toString())
                val value =
                        if (histPos < 0) event.getAxisValue(axis)
                        else event.getHistoricalAxisValue(axis, histPos)
                if (value.absoluteValue > range.flat) return value
            } catch (e: IllegalArgumentException) {
                Log.w(
                        "Flutter Joystick Plugin",
                        "An error occurred attempting to center a motion event."
                )
            }
        }
        return 0f
    }

    // Process a historical motion event.
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
}
