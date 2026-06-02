import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class VetDetailScreen extends StatelessWidget {
  const VetDetailScreen({required this.vetId, super.key});
  final String vetId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Veterinário', showBack: true),
          Expanded(child: Center(child: Text('Vet #$vetId — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
