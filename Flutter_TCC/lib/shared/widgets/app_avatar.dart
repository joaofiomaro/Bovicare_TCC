import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Avatar circular com imagem de rede e fallback de iniciais.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.imageUrl,
    this.radius = 24,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final fontSize = radius * 0.45;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.brandLight,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _Initials(initials: initials, fontSize: fontSize),
            placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brandLight,
      child: _Initials(initials: initials, fontSize: fontSize),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.fontSize});

  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        color: AppColors.brandGreen,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
