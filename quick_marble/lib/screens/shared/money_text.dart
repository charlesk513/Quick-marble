import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _ugxFormat =
    NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  const MoneyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(_ugxFormat.format(amount), style: style);
  }
}

String formatUgx(double amount) => _ugxFormat.format(amount);
