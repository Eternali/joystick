package com.example.joystick

import android.view.InputDevice

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class JoystickPlugin(val registrar: Registrar): MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "joystick")
            channel.setMethodCallHandler(JoystickPlugin(registrar))
        }

        val adapters: MutableList<MotionControllerAdapter> = mutableListOf()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isGamepadConnected" -> {
                val ids = InputDevice.getDeviceIds()
                for (id in ids) {
                    val device: InputDevice = InputDevice.getDevice(id)
                    if ((device.sources and InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD) {
                        result.success(true)
                        return
                    }
                }
                result.success(false)
            }
            "getController" -> {
                val sources = call.argument<List<String>>("sources") ?: return
                val searchForAxis = call.argument<Boolean>("searchForAxis") ?: false
                adapters.add(MotionControllerAdapter(
                        registrar,
                        Pair(sources[0], sources[1]),
                        searchForAxis
                ))
                // Get the containing FlutterView and set the generic motion listener to the listeners
                // of all adapters registered. The listener must be set on this view because in order
                // for gamepad events to be visible and the callback triggered the view must be in focus.
                registrar.view().setOnGenericMotionListener { view, motionEvent ->
                    adapters.fold(true, { acc, adapter ->
                        acc && adapter.motionListener(view, motionEvent)
                    })
                }
                result.success(adapters.last().methodChannelName)
            }
            else -> result.notImplemented()
        }
    }
}
