import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_toast.dart';

const _kLastSyncKey = 'last_sync_at';

/// Sincronização real: o Firestore grava offline e envia quando há conexão;
/// "Sincronizar" aguarda o envio das gravações pendentes deste aparelho.
class SyncCard extends StatefulWidget {
  const SyncCard({super.key});

  @override
  State<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<SyncCard> {
  static const _timeout = Duration(seconds: 15);

  bool _syncing = false;
  DateTime? _lastSync;
  bool? _pending;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLastSync());
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kLastSyncKey);
    if (!mounted) return;
    setState(() => _lastSync = iso == null ? null : DateTime.tryParse(iso));
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await FirebaseFirestore.instance.waitForPendingWrites().timeout(_timeout);
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSyncKey, now.toIso8601String());
      if (!mounted) return;
      setState(() {
        _lastSync = now;
        _pending  = false;
      });
      AppToast.success(context, 'Tudo sincronizado com a nuvem.');
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _pending = true);
      AppToast.info(
        context,
        'Sem conexão: as alterações ficam salvas no aparelho e serão '
        'enviadas automaticamente quando a internet voltar.',
      );
    } on FirebaseException {
      if (mounted) AppToast.error(context, 'Falha ao sincronizar.');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String get _status {
    final when = _lastSync == null
        ? 'Nunca sincronizado manualmente'
        : 'Última: ${_lastSync!.toBrDateTime}';
    return switch (_pending) {
      true  => '$when · alterações aguardando conexão',
      false => '$when · nada pendente',
      null  => when,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical:   AppSpacing.xs,
      ),
      child: Container(
        padding:    const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:        isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
          ),
        ),
        child: Row(
          children: [
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: _pending ?? false
                    ? AppColors.amberLight
                    : AppColors.brandLight,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(
                _pending ?? false
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_outlined,
                color: _pending ?? false ? AppColors.amber : AppColors.brandGreen,
                size:  20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sincronização',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width:  56,
              height: 32,
              child: _syncing
                  ? const Center(
                      child: SizedBox(
                        width:  18,
                        height: 18,
                        child:  CircularProgressIndicator(
                          strokeWidth: 2,
                          color:       AppColors.brandGreen,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: _sync,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandGreen,
                        side:    const BorderSide(color: AppColors.brandGreen),
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: const Text('Sync', style: TextStyle(fontSize: 12)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
