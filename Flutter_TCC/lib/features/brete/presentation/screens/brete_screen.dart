import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class BreteScreen extends StatelessWidget {
  const BreteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeader(title: 'Painel Brete', subtitle: 'Controle ESP32'),
          Expanded(child: Center(child: Text('Brete — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
