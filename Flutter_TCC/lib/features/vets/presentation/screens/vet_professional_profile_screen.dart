import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/vet_entity.dart';
import '../providers/vets_provider.dart';

/// Especialidades sugeridas no cadastro do perfil profissional.
const List<String> kVetSpecialties = [
  'Clínica geral',
  'Reprodução',
  'Sanidade animal',
  'Cirurgia',
  'Nutrição animal',
  'Bovinocultura de leite',
  'Bovinocultura de corte',
];

/// Veterinário publica (ou retira) o próprio perfil no diretório consultado
/// pelos produtores — nome, CRMV, contatos, área de atendimento e posição.
class VetProfessionalProfileScreen extends ConsumerWidget {
  const VetProfessionalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myVetProfileProvider);
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Perfil profissional',
            subtitle: 'Visível para produtores na aba Vets',
            showBack: true,
          ),
          Expanded(
            child: profile.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brandGreen),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
              data:  (current) => _ProfileForm(initial: current),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.initial});
  final VetEntity? initial;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _crmv;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _radius;

  late Set<String> _specialties;
  late bool _available;
  double? _lat;
  double? _lng;
  bool _locating = false;

  bool get _isPublished => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p    = widget.initial;
    final user = ref.read(authProvider).valueOrNull;
    _name     = TextEditingController(text: p?.name ?? user?.name ?? '');
    _crmv     = TextEditingController(text: p?.crmv ?? '');
    _phone    = TextEditingController(text: p?.phone ?? '');
    _whatsapp = TextEditingController(text: p?.whatsapp ?? '');
    _email    = TextEditingController(text: p?.email ?? user?.email ?? '');
    _city     = TextEditingController(text: p?.city ?? '');
    _state    = TextEditingController(text: p?.state ?? '');
    _radius   = TextEditingController(
      text: p != null ? '${p.coverageRadiusKm}' : '50',
    );
    _specialties = {...?p?.specialties};
    _available   = p?.isAvailable ?? true;
    _lat = p?.lat;
    _lng = p?.lng;
  }

  @override
  void dispose() {
    for (final c in [_name, _crmv, _phone, _whatsapp, _email, _city, _state, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    ref.invalidate(userLocationProvider);
    final loc = await ref.read(userLocationProvider.future);
    if (!mounted) return;
    setState(() => _locating = false);
    if (loc.isFallback) {
      AppToast.error(
        context,
        'Localização indisponível. Ative o GPS e o consentimento de '
        'localização em Perfil › Meus consentimentos.',
      );
      return;
    }
    setState(() {
      _lat = loc.lat;
      _lng = loc.lng;
    });
    AppToast.success(context, 'Localização da base registrada.');
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Informe seu nome.';
    if (_crmv.text.trim().length < 4) return 'Informe o CRMV (ex.: CRMV-SP 12345).';
    if (_specialties.isEmpty) return 'Escolha ao menos uma especialidade.';
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 10) {
      return 'Informe um telefone com DDD.';
    }
    if (_city.text.trim().isEmpty) return 'Informe a cidade base.';
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(_state.text.trim())) {
      return 'Informe a UF com 2 letras.';
    }
    final radius = int.tryParse(_radius.text.trim());
    if (radius == null || radius < 1 || radius > 500) {
      return 'Raio de atendimento entre 1 e 500 km.';
    }
    if (_lat == null || _lng == null) {
      return 'Toque em "Usar minha localização" para marcar sua base no mapa.';
    }
    return null;
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    final uid = ref.read(authProvider).valueOrNull?.id;
    if (uid == null) return;

    final profile = VetEntity(
      id:               uid,
      name:             _name.text.trim(),
      crmv:             _crmv.text.trim(),
      specialties:      _specialties.toList(),
      phone:            _phone.text.trim(),
      whatsapp:         _opt(_whatsapp),
      email:            _opt(_email),
      city:             _city.text.trim(),
      state:            _state.text.trim().toUpperCase(),
      lat:              _lat!,
      lng:              _lng!,
      isAvailable:      _available,
      coverageRadiusKm: int.parse(_radius.text.trim()),
    );
    final ok = await ref.read(vetProfileActionsProvider.notifier).publish(profile);
    if (!mounted) return;
    ok
        ? AppToast.success(context, 'Perfil publicado para os produtores.')
        : AppToast.error(context, 'Não foi possível publicar. Tente novamente.');
  }

  Future<void> _unpublish() async {
    final confirmed = await AppBottomSheet.show(
      context,
      title:          'Retirar perfil do diretório?',
      message:        'Produtores deixam de ver seus dados e contatos na aba Vets. '
          'Os chamados que você já atendeu continuam no histórico.',
      confirmLabel:   'Retirar',
      confirmVariant: AppButtonVariant.danger,
      icon:           Icons.visibility_off_outlined,
      iconColor:      AppColors.danger,
    );
    if (confirmed != true || !mounted) return;
    final uid = ref.read(authProvider).valueOrNull?.id;
    if (uid == null) return;
    final ok = await ref.read(vetProfileActionsProvider.notifier).unpublish(uid);
    if (!mounted) return;
    ok
        ? AppToast.success(context, 'Perfil retirado do diretório.')
        : AppToast.error(context, 'Não foi possível retirar. Tente novamente.');
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(vetProfileActionsProvider).isLoading;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _StatusBanner(published: _isPublished),
        const SizedBox(height: AppSpacing.base),
        AppTextField(label: 'Nome profissional *', controller: _name, prefixIcon: Icons.person_outline),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'CRMV *', hint: 'CRMV-SP 12345', controller: _crmv, prefixIcon: Icons.badge_outlined),
        const SizedBox(height: AppSpacing.base),
        Text('Especialidades *', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing:    6,
          runSpacing: 6,
          children: [
            for (final s in kVetSpecialties)
              FilterChip(
                label:    Text(s),
                selected: _specialties.contains(s),
                selectedColor: AppColors.brandLight,
                checkmarkColor: AppColors.brandGreen,
                onSelected: (sel) => setState(
                  () => sel ? _specialties.add(s) : _specialties.remove(s),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        AppTextField(label: 'Telefone *', hint: '+55 19 99999-0000', controller: _phone, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'WhatsApp', controller: _whatsapp, prefixIcon: Icons.chat_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'E-mail de contato', controller: _email, prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(flex: 3, child: AppTextField(label: 'Cidade base *', controller: _city)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppTextField(label: 'UF *', controller: _state)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Raio de atendimento (km) *', controller: _radius, prefixIcon: Icons.radar_rounded, keyboardType: TextInputType.number),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label:     _lat == null
              ? 'Usar minha localização'
              : 'Base marcada (${_lat!.toStringAsFixed(3)}, ${_lng!.toStringAsFixed(3)}) — atualizar',
          icon:      Icons.my_location_rounded,
          variant:   AppButtonVariant.outline,
          isLoading: _locating,
          onPressed: _useMyLocation,
        ),
        SwitchListTile(
          contentPadding:   EdgeInsets.zero,
          value:            _available,
          activeThumbColor: AppColors.brandGreen,
          title:            const Text('Disponível para novos atendimentos'),
          onChanged:        (v) => setState(() => _available = v),
        ),
        const SizedBox(height: AppSpacing.base),
        AppButton(
          label:     _isPublished ? 'Salvar alterações' : 'Publicar perfil',
          icon:      Icons.public_rounded,
          isLoading: busy,
          onPressed: _publish,
        ),
        if (_isPublished) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label:     'Retirar do diretório',
            icon:      Icons.visibility_off_outlined,
            variant:   AppButtonVariant.ghost,
            onPressed: busy ? null : _unpublish,
          ),
        ],
        const SizedBox(height: AppSpacing.x2l),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, text) = published
        ? (AppColors.brandLight, AppColors.brandGreen, Icons.check_circle_outline,
            'Seu perfil está publicado e aparece para os produtores.')
        : (AppColors.amberLight, AppColors.amber, Icons.info_outline,
            'Seu perfil ainda não está publicado. Ao publicar, você consente '
            'que nome, CRMV, contatos e área de atendimento sejam exibidos aos '
            'produtores (LGPD). Pode retirar quando quiser.');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: fg, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
