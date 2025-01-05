import 'package:flutter/material.dart';
import '../theme.dart';

class DateSeparator extends StatelessWidget {
  final String date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          date,
          style: TextStyle(
            color: customColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
