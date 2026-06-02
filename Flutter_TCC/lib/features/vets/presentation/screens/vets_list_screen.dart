import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class VetsListScreen extends StatelessWidget {
  const VetsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeader(title: 'Veterinários'),
          Expanded(child: Center(child: Text('Veterinários — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
