import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeader(title: 'Relatórios'),
          Expanded(child: Center(child: Text('Relatórios — Em desenvolvimento'))),
        ],
      ),
    );
  }
}
