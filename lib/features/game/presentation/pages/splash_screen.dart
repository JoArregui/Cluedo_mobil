import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controladores de animación ──────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final AnimationController _titleController;
  late final AnimationController _scanlineController;
  late final AnimationController _glowController;

  // Fade-in de la imagen de fondo
  late final Animation<double> _bgFade;

  // Vignette (oscurece bordes) aparece después del fondo
  late final Animation<double> _vignetteFade;

  // Título principal: desliza desde abajo y aparece
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;

  // Subtítulo: aparece después del título
  late final Animation<double> _subtitleFade;

  // Línea decorativa debajo del título
  late final Animation<double> _lineWidth;

  // Brillo pulsante del título
  late final Animation<double> _glowAnim;

  // Scanlines (efecto gráfico)
  late final Animation<double> _scanlineOpacity;

  @override
  void initState() {
    super.initState();

    // ── Controlador principal de fondo (2.5 s) ──────────────────────────────
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _bgFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _vignetteFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _scanlineOpacity = CurvedAnimation(
      parent: _scanlineController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    // ── Controlador de título (1.2 s, arranca con 600 ms de retraso) ─────────
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _subtitleFade = CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    );

    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // ── Glow pulsante (loop) ─────────────────────────────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // ── Secuencia de arranque ─────────────────────────────────────────────────
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    _fadeController.forward();
    _scanlineController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _titleController.forward();

    // Navegar a la siguiente pantalla
    await Future.delayed(const Duration(milliseconds: 8000));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => widget.nextScreen,
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _scanlineController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Imagen de fondo: Mansión ───────────────────────────────────
          FadeTransition(
            opacity: _bgFade,
            child: Image.asset(
              'assets/images/Extras/Mansion.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ── 2. Overlay oscuro con gradiente (novela gráfica) ──────────────
          FadeTransition(
            opacity: _vignetteFade,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55000000), // sutil en la parte superior
                    Color(0xAA0A0005), // semiopaco a la mitad
                    Color(0xF0050008), // casi opaco en la parte inferior
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. Vignette radial (oscurece las esquinas) ────────────────────
          FadeTransition(
            opacity: _vignetteFade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),

          // ── 4. Scanlines (efecto gráfico noir) ───────────────────────────
          FadeTransition(
            opacity: _scanlineOpacity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ScanlinePainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // ── 5. Contenido central: título + subtítulo ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.18,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _titleController,
                _glowController,
              ]),
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtítulo superior
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: const Text(
                        '— UN MISTERIO EN LA MANSIÓN —',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11.5,
                          letterSpacing: 4.5,
                          color: Color(0xFFB8955A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Título principal con glow
                    Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: Opacity(
                        opacity: _titleFade.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(
                                const Color(0xFFE8D5B0),
                                const Color(0xFFFFF3D0),
                                _glowAnim.value,
                              )!,
                              const Color(0xFFB8955A),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CLUEDO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                              color: Colors.white, // reemplazado por ShaderMask
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Línea decorativa dorada
                    Opacity(
                      opacity: _titleFade.value,
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: _lineWidth.value * 0.55,
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFB8955A)
                                      .withValues(alpha: _glowAnim.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tagline inferior
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: Text(
                        '¿QUIÉN LO HIZO?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 13,
                          letterSpacing: 6,
                          color: const Color(0xFF9B7E52)
                              .withValues(alpha: 0.85),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── 6. Logo / versión en la esquina inferior ──────────────────────
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: const Text(
                'v1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: Color(0x88B8955A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter para el efecto de scanlines ────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lineGap = 4.0;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}