import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final int umbral; // a partir de cuántos caracteres se activa el marquee
  final double velocity;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.height = 20,
    this.umbral = 22,
    this.velocity = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (text.length <= umbral) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return SizedBox(
      height: height,
      child: Marquee(
        text: text,
        style: style,
        velocity: velocity,
        blankSpace: 40,
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}