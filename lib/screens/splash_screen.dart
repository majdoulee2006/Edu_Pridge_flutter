import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding/onboarding_one.dart';
import 'student/nav_bar/student_home_screen.dart';
import 'teacher/teacher_home.dart';
import 'parents/nav_bar/parent_home.dart';
import 'Head of department/nav_bar/boss_home.dart';
import 'Affairs_Officer/nav_bar/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── controllers ──────────────────────────────────────
  late final AnimationController _masterCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _particleCtrl;

  // ── animations ────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _scale;
  late final Animation<double> _rotY;
  late final Animation<double> _glow;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _dotsSlide;
  late final Animation<double> _pulse;

  final _rng = Random();
  final List<_Particle> _particles = [];
  bool _logoExists = true;

  // ── colours ───────────────────────────────────────────
  static const _gold    = Color(0xFFD4A017);
  static const _navy    = Color(0xFF1A3A6B);
  static const _bgLight = Color(0xFFF5EDDA);

  @override
  void initState() {
    super.initState();
    _spawnParticles();
    _buildAnimations();
    _runSequence();
  }

  // ── particles ─────────────────────────────────────────
  void _spawnParticles() {
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x:     _rng.nextDouble(),
        y:     _rng.nextDouble(),
        size:  _rng.nextDouble() * 4 + 2,
        speed: _rng.nextDouble() * 0.18 + 0.06,
        color: switch (i % 4) {
          0 => _gold.withValues(alpha: 0.55),
          1 => _navy.withValues(alpha: 0.30),
          2 => Colors.white.withValues(alpha: 0.45),
          _ => _gold.withValues(alpha: 0.25),
        },
      ));
    }
  }

  // ── animation setup ───────────────────────────────────
  void _buildAnimations() {
    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    );
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.00, 0.12, curve: Curves.easeIn)));

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.06, 0.22, curve: Curves.easeIn)));

    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.15, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.00)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 25),
    ]).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.08, 0.72)));

    // 1.5 full Y-axis rotations (3π rad)
    _rotY = Tween<double>(begin: 0, end: pi * 3).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.08, 0.65, curve: Curves.easeInOutCubic)));

    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.58, 0.88, curve: Curves.easeOut)));

    _dotsSlide = Tween<double>(begin: 38, end: 0).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.66, 0.84, curve: Curves.easeOut)));
    _dotsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterCtrl,
          curve: const Interval(0.66, 0.90, curve: Curves.easeIn)));

    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  // ── sequence ──────────────────────────────────────────
  Future<void> _runSequence() async {
    // lock orientation during splash
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _masterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 3900));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final role  = prefs.getString('role')  ?? '';
    if (!mounted) return;

    Widget dest;
    if (token.isEmpty) {
      dest = const OnboardingOne();
    } else {
      dest = switch (role) {
        'student'                      => const StudentHomeScreen(),
        'teacher'                      => const TeacherHomeScreen(),
        'parent'                       => const ParentsHomeScreen(),
        'head'  || 'department_head'   => const DeptHeadHomeScreen(),
        'affairs' || 'affairs_officer' => const AffairsOfficerHomeScreen(),
        _                              => const OnboardingOne(),
      };
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context2, a, b) => dest,
        transitionsBuilder: (context2, anim, b, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_masterCtrl, _pulseCtrl, _particleCtrl]),
        builder: (ctx, _) {
          return Scaffold(
            backgroundColor: _bgLight,
            body: Stack(
                children: [
                  // ── animated background gradient ──────
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.4,
                        colors: [
                          Color.fromRGBO(255, 250, 240,
                              _bgFade.value.clamp(0.0, 1.0)),
                          Color.fromRGBO(237, 225, 196,
                              _bgFade.value.clamp(0.0, 1.0)),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),

                  // ── floating particles ────────────────
                  CustomPaint(
                    size: Size(size.width, size.height),
                    painter: _ParticlePainter(
                        _particles, _particleCtrl.value,
                        opacity: _bgFade.value),
                  ),

                  // ── centre content ───────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // glow ring behind logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_glow.value > 0.05)
                              _GlowRing(
                                radius: 155 * _pulse.value,
                                opacity: _glow.value * 0.35 * _pulse.value,
                              ),
                            if (_glow.value > 0.2)
                              _GlowRing(
                                radius: 120 * _pulse.value,
                                opacity: _glow.value * 0.22 * _pulse.value,
                                color: _navy,
                              ),

                            // ── 3-D rotating logo ──────
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014)
                                  ..rotateY(_rotY.value),
                                child: Transform.scale(
                                  // counter-flip when showing "back face" so logo stays correct
                                  scaleX: cos(_rotY.value) < 0 ? -1.0 : 1.0,
                                  scaleY: 1.0,
                                  child: Transform.scale(
                                    scale: _scale.value,
                                    child: _logoWidget(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // ── bouncing dots ──────────────
                        if (_dotsOpacity.value > 0.05)
                          Opacity(
                            opacity: _dotsOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _dotsSlide.value),
                              child: _BouncingDots(
                                  progress: _particleCtrl.value),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── bottom brand line ─────────────────
                  if (_dotsOpacity.value > 0.3)
                    Positioned(
                      bottom: 42,
                      left: 0, right: 0,
                      child: Opacity(
                        opacity: _dotsOpacity.value,
                        child: const Text(
                          'EduBridge © 2025',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E8C6A),
                            letterSpacing: 1.4,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          );
        },
      ),
    );
  }

  Widget _logoWidget() {
    if (!_logoExists) {
      // fallback when image not yet added to assets
      return Container(
        width: 210, height: 210,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgLight,
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: _glow.value * 0.6),
              blurRadius: 35, spreadRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24, offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.school_rounded,
            size: 90, color: _gold),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: _glow.value * 0.55),
            blurRadius: 40, spreadRadius: 8,
          ),
          BoxShadow(
            color: _navy.withValues(alpha: _glow.value * 0.18),
            blurRadius: 20, spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 26, offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        width: 210, height: 210,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, st) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _logoExists = false));
          return const SizedBox(width: 210, height: 210);
        },
      ),
    );
  }
}

// ── Glow ring widget ─────────────────────────────────────────
class _GlowRing extends StatelessWidget {
  final double radius;
  final double opacity;
  final Color color;
  const _GlowRing(
      {required this.radius,
      required this.opacity,
      this.color = const Color(0xFFD4A017)});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 60,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouncing dots ────────────────────────────────────────────
class _BouncingDots extends StatelessWidget {
  final double progress;
  const _BouncingDots({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (progress * 2 * pi) + (i * pi * 2 / 3);
        final dy = -sin(phase) * 7;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 9, height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 1
                  ? const Color(0xFF1A3A6B)
                  : const Color(0xFFD4A017),
              boxShadow: [
                BoxShadow(
                  color: (i == 1
                          ? const Color(0xFF1A3A6B)
                          : const Color(0xFFD4A017))
                      .withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Particle model ───────────────────────────────────────────
class _Particle {
  final double x, y, size, speed;
  final Color color;
  const _Particle(
      {required this.x,
      required this.y,
      required this.size,
      required this.speed,
      required this.color});
}

// ── Particle painter ─────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double opacity;
  const _ParticlePainter(this.particles, this.progress,
      {this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.y - progress * p.speed) % 1.0 + 1.0) % 1.0;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * opacity);
      // draw small blurred circle
      canvas.drawCircle(
          Offset(p.x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
