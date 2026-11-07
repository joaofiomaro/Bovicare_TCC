import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/tutorial_provider.dart';

/// Boas-vindas na primeira abertura do app: o usuário escolhe entre conhecer
/// as funções em poucos passos ou pular direto para o uso. Também abre pelo
/// Perfil (Ajuda e tutoriais › Rever apresentação).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _tips = true;

  static const _features = [
    _Feature(
      icon:  Icons.pets_rounded,
      title: 'Seu rebanho na palma da mão',
      body:  'Cadastre cada animal com brinco, raça, peso e tag RFID. Na ficha '
          'ficam as vacinas, pesagens, saúde e reprodução.',
    ),
    _Feature(
      icon:  Icons.vaccines_rounded,
      title: 'Vacinas e alertas em dia',
      body:  'Registre vacinas e o app calcula a carência. Alertas avisam de '
          'vacinas a vencer, partos previstos e animais em carência.',
    ),
    _Feature(
      icon:  Icons.sensor_door_rounded,
      title: 'Brete eletrônico',
      body:  'Conecte pelo Bluetooth para abrir e fechar as portas, ler a tag '
          'do animal e acionar a parada de emergência.',
    ),
    _Feature(
      icon:  Icons.medical_services_rounded,
      title: 'Veterinários por perto',
      body:  'Encontre veterinários da sua região e abra um chamado. Quem é '
          'veterinário recebe os chamados e organiza a agenda.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _features.length;

  Future<void> _finish({required bool tips}) async {
    await ref.read(tutorialProvider.notifier).finishIntro(tips: tips);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else if (FirebaseAuth.instance.currentUser != null) {
      context.goNamed(AppRoutes.dashboard);
    } else {
      context.goNamed(AppRoutes.login);
    }
  }

  void _next() => _pages.nextPage(duration: AppDurations.normal, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandGreen,
      body: SafeArea(
        child: Column(
          children: [
            // "Pular" leva à última página, onde se decide sobre as dicas.
            SizedBox(
              height: 56,
              child: _page > 0 && !_isLast
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _pages.animateToPage(
                          _features.length,
                          duration: AppDurations.normal,
                          curve:    Curves.easeOutCubic,
                        ),
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('Pular'),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: PageView(
                controller:    _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Intro(onTour: _next, onSkip: () => _finish(tips: false)),
                  for (final f in _features) _FeaturePage(feature: f),
                ],
              ),
            ),
            if (_page > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _Dots(index: _page - 1, total: _features.length),
                    const SizedBox(height: AppSpacing.xl),
                    if (_isLast) ...[
                      _TipsSwitch(
                        value:     _tips,
                        onChanged: (v) => setState(() => _tips = v),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                    _WhiteButton(
                      label:     _isLast ? 'Começar a usar' : 'Próximo',
                      onPressed: _isLast ? () => _finish(tips: _tips) : _next,
                    ),
                  ],
                ),
              ),
            if (_page == 0) const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

/// Primeira página: apresentação e a escolha entre ver o tutorial ou pular.
class _Intro extends StatelessWidget {
  const _Intro({required this.onTour, required this.onSkip});
  final VoidCallback onTour;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.x2l),
          Image.asset('assets/images/bovicare_logo.png', width: 104, height: 104)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Bem-vindo ao BoviCare',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color:      Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Quer conhecer as principais funções do app? Leva menos de um minuto.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x3l),
          _WhiteButton(label: 'Ver como funciona', icon: Icons.play_arrow_rounded, onPressed: onTour),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side:            BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                minimumSize:     const Size.fromHeight(52),
                shape:           const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
              child: const Text('Pular e começar a usar'),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.x2l),
          Container(
            width:  120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color:      Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            feature.body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color:  Colors.white.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsSwitch extends StatelessWidget {
  const _TipsSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.12),
          borderRadius: AppRadius.mdAll,
        ),
        child: SwitchListTile(
          value:     value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.brandDeep,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          title: const Text(
            'Mostrar o passo a passo na primeira vez em cada tela',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Dá para mudar depois em Perfil.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      );
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brandGreen,
            minimumSize: const Size.fromHeight(52),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Página ${index + 1} de $total',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: AppDurations.fast,
                margin:   const EdgeInsets.symmetric(horizontal: 3),
                width:    i == index ? 20 : 8,
                height:   8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == index ? 1 : 0.4),
                  borderRadius: AppRadius.fullAll,
                ),
              ),
          ],
        ),
      );
}
