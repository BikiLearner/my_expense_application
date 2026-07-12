// import 'package:expence_app/features/expense/presentation/widgets/type_button.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../shared/enums/expense_type.dart';
// import '../provider/expence_provider.dart';
//
//
//
// class ExpenseTypeSelectorOld extends StatelessWidget {
//   const ExpenseTypeSelectorOld({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Selector<ExpenseProvider, ExpenseType>(
//       selector: (_, provider) => provider.selectedType,
//       builder: (context, selectedType, _) {
//         return Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             TypeButton(
//               type: ExpenseType.saving,
//               selected: selectedType == ExpenseType.saving,
//             ),
//             TypeButton(
//               type: ExpenseType.needed,
//               selected: selectedType == ExpenseType.needed,
//             ),
//             TypeButton(
//               type: ExpenseType.luxury,
//               selected: selectedType == ExpenseType.luxury,
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
