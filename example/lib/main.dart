import 'package:flutter/material.dart';

import 'package:joystick/joystick.dart';
import 'package:joystick/physical_motion.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Offset joy = Offset.zero;
  MotionController _controller;
  String errorTxt;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Joystick example app'),
        ),
        body: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: Text('JOY: (${joy.dx}, ${joy.dy})'),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Text(errorTxt),
            ),
            Expanded(
              child: Joystick(
                autoCenter: true,
                controller: _controller,
                onDrag: (pos) {
                  setState(() {
                    joy = pos;
                  });
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.usb),
          onPressed: () async {
            if (await PhysicalMotion.isGamepadConnected) {
              PhysicalMotion.getController(MotionSources.joy1).then((controller) => setState(() {
                _controller = controller;
              }));
            } else {
              setState(() {
                errorTxt = 'Failed to detect gamepad.';
              });
            }
          },
        ),
      ),
    );
  }
}
