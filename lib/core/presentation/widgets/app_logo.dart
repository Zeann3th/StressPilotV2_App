import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 48, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF84FFFF), // Cyan Accent 100
                Color(0xFF00BCD4), // Cyan
                Color(0xFF006064), // Cyan 900
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
              child: Center(
                child: Text(
                  'SP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.35,
                    fontFamily: 'JetBrains Mono',
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Stress',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Pilot',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
