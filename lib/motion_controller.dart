import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

/// Motion controller that can be passed to [Joystick] to add support for gamepads.
/// Manual instantiation should be avoided as a [channelName] must be provided which is used
/// to get the method and event channels that need to be created beforehand.
/// Use [MotionController.getController] with a pair of axes to setup and get the controller.
class MotionController {
  MotionController({
    @required String channelName,
  }): _channel = MethodChannel(channelName),
      _eventChannel = EventChannel(channelName + '/stream');

  /// Base method channel for the plugin.
  static const _baseChannel = MethodChannel('joystick');

  /// Method channel for the specific controller.
  final MethodChannel _channel;

  /// Event channel that provides the motion events from the gamepad.
  final EventChannel _eventChannel;

  /// Internal variable for managing the MotionEvent stream provided by the event channel.
  Stream<MotionEvent> _eventStream;

  /// Getter a [Joystick] can use to listen for motion events.
  Stream<MotionEvent> get stream {
    if (_eventStream == null) _eventStream = _eventChannel
      .receiveBroadcastStream()
      .map((d) => MotionEvent(data: Offset(d[0], d[1])));
    return _eventStream;
  }

  /// Changes the axes the controller listens on.
  Future<bool> setSources(Tuple2<String, String> sources) =>
    _channel.invokeMethod('setSources', {'sources': sources.toList()});

  /// Checks if a gamepad is connected.
  static Future<bool> get isGamepadConnected async {
    return await _baseChannel.invokeMethod('isGamepadConnected');
  }

  /// Sets up the native channels based on the axes the controller wants to listen for.
  static Future<MotionController> getController([Tuple2<String, String> sources = MotionSources.joy1]) async {
    final channelName = await _baseChannel.invokeMethod<String>('getController', {'sources': sources.toList()});
    return MotionController(channelName: channelName);
  }
}

/// Possible axes to listen on.
class MotionAxes {
  static const String
    AXIS_HAT_X = 'AXIS_HAT_X',
    AXIS_HAT_Y = 'AXIS_HAT_Y',
    AXIS_X = 'AXIS_X',
    AXIS_Y = 'AXIS_Y',
    AXIS_Z = 'AXIS_Z',
    AXIS_RZ = 'AXIS_RZ';
}

/// Combinations of axes commonly found on gamepads
class MotionSources {
  static const Tuple2<String, String>
    dpad = Tuple2(MotionAxes.AXIS_HAT_X, MotionAxes.AXIS_HAT_Y),
    joy1 = Tuple2(MotionAxes.AXIS_X, MotionAxes.AXIS_Y),
    joy2 = Tuple2(MotionAxes.AXIS_Z, MotionAxes.AXIS_RZ);
}

/// Container event object that holds joystick motion data.
class MotionEvent {
  MotionEvent({this.data});
  final Offset data;
}
