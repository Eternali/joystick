import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

class MotionController {
  MotionController({
    @required String channelName,
  }): _channel = MethodChannel(channelName),
      _eventChannel = EventChannel(channelName + '/stream');

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  Stream<MotionEvent> _eventStream;

  Stream<MotionEvent> get stream {
    if (_eventStream == null) _eventStream = _eventChannel
      .receiveBroadcastStream()
      .map((d) {
        return MotionEvent(data: Offset(d[0], d[1]));
      });
    return _eventStream;
  }

  Future<bool> setSources(Tuple2<String, String> sources) =>
    _channel.invokeMethod('setSources', {'sources': sources.toList()});
}

class MotionAxes {
  static const String
    AXIS_HAT_X = 'AXIS_HAT_X',
    AXIS_HAT_Y = 'AXIS_HAT_Y',
    AXIS_X = 'AXIS_X',
    AXIS_Y = 'AXIS_Y',
    AXIS_Z = 'AXIS_Z',
    AXIS_RZ = 'AXIS_RZ';
}

class MotionSources {
  static const Tuple2<String, String>
    dpad = Tuple2(MotionAxes.AXIS_HAT_X, MotionAxes.AXIS_HAT_Y),
    joy1 = Tuple2(MotionAxes.AXIS_X, MotionAxes.AXIS_Y),
    joy2 = Tuple2(MotionAxes.AXIS_Z, MotionAxes.AXIS_RZ);
}

class MotionEvent {
  MotionEvent({this.data});
  final Offset data;
}

class PhysicalMotion {
  static const _channel = MethodChannel('joystick');

  static Future<bool> get isGamepadConnected async {
    return await _channel.invokeMethod('isGamepadConnected');
  }

  static Future<MotionController> getController([Tuple2<String, String> sources = MotionSources.joy1]) async {
    final channelName = await _channel.invokeMethod<String>('getController', {'sources': sources.toList()});
    return MotionController(channelName: channelName);
  }
}
