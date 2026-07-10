import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/expence_provider.dart';

class TitleAutoCompleteField extends StatelessWidget {
  final TextEditingController controller;

  const TitleAutoCompleteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, int>(
      selector: (_, p) => p.autoCompleteKey,
      builder: (context, autoKey, _) {
        return Selector<ExpenseProvider, List<String>>(
          selector: (_, p) => p.cachedCategories,
          builder: (context, cachedCategories, __) {
            return Autocomplete<String>(
              key: ValueKey(autoKey),
              initialValue: TextEditingValue(text: controller.text),

              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }

                return cachedCategories.where(
                  (option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },

              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                    // Sync with main controller
                    textController.text = controller.text;
                    textController.selection = TextSelection.fromPosition(
                      TextPosition(offset: textController.text.length),
                    );

                    textController.addListener(() {
                      if (controller.text != textController.text) {
                        controller.text = textController.text;
                      }
                    });

                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Groceries, Fuel',
                        labelStyle: TextStyle(color: Colors.grey[500]),
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: const Icon(
                          Icons.title,
                          color: Color(0xFF64FFDA),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3C3C3C),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF64FFDA),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    );
                  },

              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 8,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 300,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: options.length,
                        itemBuilder: (_, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
