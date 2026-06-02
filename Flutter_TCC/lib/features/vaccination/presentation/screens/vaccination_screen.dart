import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({required this.animalId, super.key});
  final String animalId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Registrar Vacinação', showBack: true),
          Expanded(child: Center(child: Text('Vacinação #$animalId — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
