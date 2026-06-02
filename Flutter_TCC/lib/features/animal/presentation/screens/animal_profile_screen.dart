import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class AnimalProfileScreen extends StatelessWidget {
  const AnimalProfileScreen({required this.animalId, super.key});
  final String animalId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Ficha Animal', showBack: true),
          Expanded(child: Center(child: Text('Animal #$animalId — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
