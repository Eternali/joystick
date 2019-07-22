import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joystick/joystick.dart';

void main() {
  const MethodChannel channel = MethodChannel('joystick');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Joystick.platformVersion, '42');
  });
}
