// ...existing code...
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ).drive(Tween(begin: 0.6, end: 1.0));
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // start animations
    _logoController.forward();
    _shimmerController.repeat(reverse: false);

    // navigate after a short delay
    Timer(const Duration(seconds: 3), () {
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFf6d365), Color(0xFFfda085)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative blurred circles
          Positioned(
            top: -size.width * .25,
            left: -size.width * .2,
            child: _BlurCircle(
              size: size.width * .7,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -size.width * .3,
            right: -size.width * .2,
            child: _BlurCircle(
              size: size.width * .85,
              color: Colors.white.withOpacity(0.06),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with scale + fade
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.delivery_dining,
                              size: 56,
                              color: Color(0xFFf76b1c),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Feastly",
                              style: TextStyle(
                                color: Color(0xFFf76b1c),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Shimmering app title
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return _ShimmerText(
                        text: "Delivery Partner",
                        shimmerPercent: _shimmerController.value,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      "Faster deliveries. Better earnings.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Small footer
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.85,
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Powered by ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextSpan(
                        text: "Feastly",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// small blurred circle used for background decoration
class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // subtle gradient to create depth
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.01)],
          center: Alignment.center,
          radius: 0.8,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox(),
      ),
    );
  }
}

/// Simple shimmer text using a sliding gradient
class _ShimmerText extends StatelessWidget {
  final String text;
  final double shimmerPercent;
  const _ShimmerText({required this.text, required this.shimmerPercent});

  @override
  Widget build(BuildContext context) {
    // gradient slides from left (-1) to right (1)
    final slide = (shimmerPercent * 2) - 1;
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: const [Colors.white70, Colors.white, Colors.white70],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + slide, 0),
          end: Alignment(1.0 + slide, 0),
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white, // base color will be masked by shader
        ),
      ),
    );
  }
}
