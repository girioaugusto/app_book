import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'providers/tabs_controller.dart';

import 'root_shell.dart';
import 'screens/login_screen.dart';
// Se quiser abrir direto a HomeScreen (sem RootShell), descomente a linha abaixo
// import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _introCtrl;   // entrada do logo
  late final AnimationController _floatCtrl;   // flutuação
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _rotate;
  late final Animation<double> _float;

  // Texto
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Precarrega a imagem pra evitar hitch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('lib/assets/logo.png'), context);
    });

    // Entrada do logo
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeIn);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_introCtrl);

    _rotate = Tween<double>(begin: -0.06, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_introCtrl);

    _introCtrl.forward();

    // Flutuação contínua
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -10.0, end: 10.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_floatCtrl);

    // Texto: entra depois do logo (usar Interval)
    _textFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    ));

    // ✅ Decidir destino após ~2.6s
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      final auth = context.read<AuthService>();

      if (auth.currentUser != null) {
        // Já logado → abrir Home dentro do RootShell (aba 1 = home_screen.dart)
        context.read<TabsController>().setIndex(1);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootShell()),
        );

        // Se preferir abrir DIRETO a HomeScreen, troque por:
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => const HomeScreen()),
        // );
      } else {
        // Não logado → abrir Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const appGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: appGreen,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introCtrl, _floatCtrl]),
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _float.value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO
                  FadeTransition(
                    opacity: _fade,
                    child: Transform.rotate(
                      angle: _rotate.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Image.asset(
                          'lib/assets/logo.png',
                          width: 320,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // TEXTO "Entre Páginas"
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Text(
                        'Entre Páginas',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzelDecorative(
                          textStyle: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
