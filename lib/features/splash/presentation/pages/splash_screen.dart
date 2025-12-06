import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String status;
  final String? error;
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    required this.status,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = error != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD), // Light Blue 50
              Color(0xFFBBDEFB), // Light Blue 100
              Color(0xFF90CAF9), // Light Blue 200
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative Elements (Android Studio style)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Illustrated Animal Logo (Dolphin)
                  _buildDolphinIllustration(),

                  const SizedBox(height: 48),

                  // App Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Stress Pilot',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1976D2),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'v1.0.0',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF64B5F6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Status/Error Section
                  if (isError) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Initialization Failed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: const Color(0xFFBBDEFB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1976D2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Footer
                  Text(
                    'Powered by Flutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64B5F6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDolphinIllustration() {
    return SizedBox(
      width: 280,
      height: 200,
      child: CustomPaint(painter: _DolphinPainter()),
    );
  }
}

class _DolphinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Ocean waves background
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.7);
    wavePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.65,
      size.width * 0.5,
      size.height * 0.7,
    );
    wavePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.75,
      size.width,
      size.height * 0.7,
    );
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    paint.color = const Color(0xFF4FC3F7);
    canvas.drawPath(wavePath, paint);

    // Dolphin body (main curve)
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.3, size.height * 0.5);
    bodyPath.cubicTo(
      size.width * 0.35,
      size.height * 0.35,
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.65,
      size.height * 0.35,
    );
    bodyPath.cubicTo(
      size.width * 0.75,
      size.height * 0.38,
      size.width * 0.8,
      size.height * 0.45,
      size.width * 0.75,
      size.height * 0.55,
    );
    bodyPath.cubicTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.65,
      size.width * 0.3,
      size.height * 0.5,
    );

    paint.color = const Color(0xFF1976D2);
    canvas.drawPath(bodyPath, paint);

    // Dolphin belly (lighter shade)
    final bellyPath = Path();
    bellyPath.moveTo(size.width * 0.35, size.height * 0.48);
    bellyPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4,
      size.width * 0.65,
      size.height * 0.42,
    );
    bellyPath.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.55,
      size.width * 0.35,
      size.height * 0.48,
    );

    paint.color = const Color(0xFF64B5F6);
    canvas.drawPath(bellyPath, paint);

    // Dorsal fin
    final finPath = Path();
    finPath.moveTo(size.width * 0.52, size.height * 0.32);
    finPath.quadraticBezierTo(
      size.width * 0.54,
      size.height * 0.22,
      size.width * 0.58,
      size.height * 0.28,
    );
    finPath.lineTo(size.width * 0.56, size.height * 0.34);
    finPath.close();

    paint.color = const Color(0xFF1565C0);
    canvas.drawPath(finPath, paint);

    // Tail
    final tailPath = Path();
    tailPath.moveTo(size.width * 0.75, size.height * 0.55);
    tailPath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.48,
      size.width * 0.85,
      size.height * 0.52,
    );
    tailPath.quadraticBezierTo(
      size.width * 0.83,
      size.height * 0.58,
      size.width * 0.78,
      size.height * 0.62,
    );
    tailPath.quadraticBezierTo(
      size.width * 0.76,
      size.height * 0.68,
      size.width * 0.78,
      size.height * 0.72,
    );
    tailPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.65,
      size.width * 0.75,
      size.height * 0.55,
    );

    paint.color = const Color(0xFF1976D2);
    canvas.drawPath(tailPath, paint);

    // Eye
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.42), 4, paint);
    paint.color = const Color(0xFF0D47A1);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.42), 2, paint);

    // Water splashes
    paint.color = Colors.white.withValues(alpha: 0.6);
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = size.width * 0.25 + (i * 15);
      final y = size.height * 0.7 + (i % 2 == 0 ? -5 : 5);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
