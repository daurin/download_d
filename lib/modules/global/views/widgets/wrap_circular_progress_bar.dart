import 'package:flutter/material.dart';

class WrapCircularProgressBar extends StatelessWidget {
  
  final Widget child;
  final double value;
  final bool enable;
  final double strokeWidth;
  final Color backgroundColor;
  final Animation<Color> color;


  const WrapCircularProgressBar({
    Key key,
    this.child,
    this.value,
    this.enable=true,
    this.strokeWidth=4,
    this.backgroundColor,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!enable) return child;
        return Stack(
          children: [
            SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                value: value,
                valueColor: color,
                backgroundColor: backgroundColor,
              ),
            ),
            if (child != null)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    height: constraints.maxHeight - strokeWidth + 0.5,
                    width: constraints.maxWidth - strokeWidth + 0.5,
                    child: child,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
