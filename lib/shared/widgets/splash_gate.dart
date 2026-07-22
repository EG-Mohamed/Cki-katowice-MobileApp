import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand_colors.dart';
import '../../state/theme_controller.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.ready, required this.child});

  final Future<void> ready;
  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    widget.ready
        .timeout(const Duration(seconds: 8))
        .catchError((_) {})
        .whenComplete(() {
          if (mounted) setState(() => _done = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          const Positioned.fill(child: _Splash()),
        ],
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return ColoredBox(
      color: BrandColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Image.asset('icons/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
