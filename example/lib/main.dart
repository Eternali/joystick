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
  String errorTxt = '';
  int debug = 0;

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
              alignment: Alignment.topRight,
              child: Text(errorTxt),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text('DEBUG PLUGIN: $debug'),
            ),
            Joystick(
              autoCenter: true,
              controller: _controller,
              onDrag: (pos) {
                setState(() {
                  debug += 1;
                  joy = pos;
                });
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.usb),
          onPressed: () async {
            if (await PhysicalMotion.isGamepadConnected) {
              PhysicalMotion.getController(MotionSources.dpad).then((controller) => setState(() {
                _controller = controller;
                errorTxt = 'Connected to controller.';
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
