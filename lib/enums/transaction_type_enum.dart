import 'package:flutter/material.dart';

enum TransactionTypeEnum{
  credit,
  cash
}
extension TransactionTypeX on TransactionTypeEnum {
  String get label {
    switch (this) {
      case TransactionTypeEnum.cash:
        return 'Cash';
      case TransactionTypeEnum.credit:
        return 'Credit';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionTypeEnum.cash:
        return Icons.attach_money_sharp;
      case TransactionTypeEnum.credit:
        return Icons.credit_card_rounded;
    }
  }
}
