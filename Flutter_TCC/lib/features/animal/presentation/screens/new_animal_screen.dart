import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class NewAnimalScreen extends StatelessWidget {
  const NewAnimalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeader(title: 'Novo Animal', showBack: true),
          Expanded(child: Center(child: Text('Novo Animal — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
