import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    child: const Text(
                      'L&J Doces e Salgados',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.92, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: safeOpacity,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 168,
                      height: 168,
                      padding: const EdgeInsets.all(18),
                      // decoration: BoxDecoration(
                        // color: Colors.white.withOpacity(0.22),
                        // shape: BoxShape.circle,
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.black.withOpacity(0.10),
                        //     blurRadius: 30,
                        //     offset: const Offset(0, 16),
                        //   ),
                        // ],
                      // ),
                      child: Image.asset(
                        'lib/assets/images/app_splash.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // const SizedBox(height: 28),
                // const Text(
                //   'Pedido rápido, sabor caseiro e experiência leve.',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.w800,
                //     color: Color(0xFF2C2C2C),
                //     height: 1.15,
                //   ),
                // ),
                // const SizedBox(height: 75),
                // Text(
                //   'Descubra produtos, monte seu pedido e acompanhe tudo em um fluxo mais agradável desde a abertura do app.',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     fontSize: 14,
                //     height: 1.45,
                //     color: Colors.black.withOpacity(0.70),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(height: 22),
                // const Wrap(
                //   alignment: WrapAlignment.center,
                //   spacing: 10,
                //   runSpacing: 10,
                //   children: [
                //     _FeatureChip(label: 'Catálogo rápido'),
                //     _FeatureChip(label: 'Favoritos salvos'),
                //     _FeatureChip(label: 'Pedidos em tempo real'),
                //   ],
                // ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.35, end: 1),
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: const Column(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB35B00)),
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Preparando sua vitrine...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 255, 115, 0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
