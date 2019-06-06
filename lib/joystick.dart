library joystick;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

typedef BuildJoyPainter = JoyPainter Function(Offset pos, double size);

/// Creates a configurable virtual joystick control.
class Joystick extends StatefulWidget {

  Joystick({
    Key key,
    this.pointerSize = 20,
    this.autoCenter = false,
    this.mustDrag = false,
    this.showGuides = true,
    this.guideLines = 3,
    this.onTap,
    this.onDrag,
    this.painter,
    this.joyColor = Colors.purple,
    this.lineColor = Colors.grey,
  }) : super(key: key);

  /// Radius of the default joystick indicator.
  final double pointerSize;

  /// Reset position of joystick to the center when released.
  final bool autoCenter;

  /// If [true] the joystick can only be controlled by dragging on the joystick
  /// itself, otherwise it can be controlled by dragging anywhere on the touch
  /// area and the joystick will snap to that location.
  final bool mustDrag;

  /// Whether or not to show grid lines for guidance.
  /// 
  /// Defaults to [true].
  final bool showGuides;

  /// Number of lines to display per quadrant of touch area.
  /// For example, setting this to [3] will divide each axis into 8 sections.
  /// 
  /// Defaults to [3].
  final int guideLines;

  /// Function to call if the joystick is tapped and not dragged.
  final Function onTap;

  /// Function to call when the joystick is dragged. It is passed an [Offset] of
  /// the joystick's regularized position whose dimensions are all between
  /// [-1] and [1] (using the same strategy as the flutter [Alignment] class).
  final Function onDrag;

  /// Override the default joystick painter.
  final BuildJoyPainter painter;

  /// Color palette of the joystick.
  final MaterialColor joyColor;

  /// Color palette of the grid lines.
  final MaterialColor lineColor;

  _JoystickState createState() => _JoystickState();

}

class _JoystickState extends State<Joystick> {

  /// Raw position of the joystick.
  Offset pointerPos;

  /// Controls ability to drag the joystick.
  bool draggable = true;

  /// clamp the [pointerPos] to a set of [constraints].
  Offset clampToBox(RenderBox constraints) {
    double x = pointerPos.dx;
    double y = pointerPos.dy;

    if (x > constraints.size.width) x = constraints.size.width;
    else if (x < 0) x = 0;

    if (y > constraints.size.height) y = constraints.size.height;
    else if (y < 0) y = 0;

    return Offset(x, y);
  }

  /// Center the [pointerPos] in a box specified by [constraints].
  void center(BoxConstraints constraints) {
    pointerPos = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
  }

  /// Map a raw [pos] to a set of dimensions specified by [constraints].
  Offset regularize(Offset pos, RenderBox constraints) {
    return Offset(
      2 * pos.dx / constraints.size.width - 1,
      2 * pos.dy / constraints.size.height - 1,
    );
  }

  /// Check if the drag [details] is over the joystick.
  bool isOver(DragDownDetails details) {
    final pos = Vector3(pointerPos.dx, pointerPos.dy, 0);
    final fOff = (context.findRenderObject() as RenderBox).globalToLocal(details.globalPosition);
    final fpos = Vector3(fOff.dx, fOff.dy, 0);
    return pos.distanceTo(fpos) <= widget.pointerSize;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (pointerPos == null) center(constraints);
        final joy = CustomPaint(
          painter: widget.painter != null
            ? widget.painter(pointerPos, widget.pointerSize)
            : JoyPainter(
              pos: pointerPos,
              radius: widget.pointerSize,
              color: widget.joyColor,
            ),
        );
        return ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: GestureDetector(
            onTap: widget.onTap,
            onPanDown: (details) {
              if (widget.mustDrag && !isOver(details)) {
                draggable = false;
                return;
              } else draggable = true;
              final RenderBox rbox = context.findRenderObject();
              pointerPos = rbox.globalToLocal(details.globalPosition);
              setState(() {
                pointerPos = clampToBox(rbox);
              });
              widget.onDrag(regularize(pointerPos, rbox));
            },
            onPanEnd: (details) {
              if (widget.autoCenter && draggable) {
                setState(() { center(constraints); });
                widget.onDrag(regularize(pointerPos, context.findRenderObject()));
              }
            },
            onPanUpdate: (details) {
              if (!draggable) return;
              pointerPos = pointerPos.translate(details.delta.dx, details.delta.dy);
              setState(() {
                pointerPos = clampToBox(context.findRenderObject());
              });
              widget.onDrag(regularize(pointerPos, context.findRenderObject()));
            },
            child: widget.showGuides ? CustomPaint(
              painter: GridPainter(color: widget.lineColor, quadrantLines: widget.guideLines),
              child: joy,
            ) : joy,
          ),
        );
      }
    );
  }

}

/// Paint a grid of major and minor lines.
class GridPainter extends CustomPainter {

  GridPainter({ this.pos = const Offset(0, 0), this.quadrantLines, this.color });

  /// Position to center the grid about.
  final Offset pos;

  /// Number of lines in a dimention of each quadrant.
  final int quadrantLines;

  /// Color palette of the lines.
  final MaterialColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = color[600].withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final subPaint = Paint()
      ..color = color[600].withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

      // Subdivide and draw
      final dx = size.width / (quadrantLines * 2 + 2);
      final dy = size.height / (quadrantLines * 2 + 2);
      for (int i in List.generate(quadrantLines * 2 + 3, (i) => i)) {
        canvas.drawLine(Offset(0, i * dy), Offset(size.width, i * dy), subPaint);
        canvas.drawLine(Offset(i * dx, 0), Offset(i * dx, size.height), subPaint);
      }
      
      // Draw x and y axes
      canvas.drawLine(size.centerLeft(pos), size.centerRight(pos), mainPaint);
      canvas.drawLine(size.topCenter(pos), size.bottomCenter(pos), mainPaint);      
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate != this;
  }

}

/// Default joystick painter.
class JoyPainter extends CustomPainter {

  JoyPainter({ this.pos, this.radius, this.color });

  /// Position to paint at.
  final Offset pos;

  /// Radius of the joystick.
  final double radius;

  /// Color palette of the joystick.
  final MaterialColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = Paint()
      ..color = color[300]
      ..style = PaintingStyle.fill;
    final outer = Paint()
      ..color = color[900]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

      canvas.drawCircle(pos, radius, inner);
      canvas.drawCircle(pos, radius, outer);
  }

  @override
  bool shouldRepaint(JoyPainter oldDelegate) {
    return oldDelegate != this;
  }

}
