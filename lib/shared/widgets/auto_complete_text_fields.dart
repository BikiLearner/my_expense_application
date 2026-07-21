import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';

class TitleAutoCompleteField extends StatefulWidget {
  const TitleAutoCompleteField({
    super.key,
    this.initialValue = '',
    this.focusNode,
    this.onChanged,
    this.onSelected,
    this.decoration,
    this.textStyle,
    this.dropdownColor = const Color(0xFF2C2C2C),
    this.suggestionTextStyle = const TextStyle(color: Colors.white),
    this.maxHeight = 200,
    this.maxWidth = 350,
    this.borderRadius = 12,
    this.elevation = 8,
    this.caseSensitive = false,
    this.autofocus = false,
  });

  final String initialValue;

  final FocusNode? focusNode;

  final ValueChanged<String>? onChanged;

  final ValueChanged<String>? onSelected;

  final InputDecoration? decoration;

  final TextStyle? textStyle;

  final TextStyle suggestionTextStyle;

  final Color dropdownColor;

  final double maxHeight;

  final double maxWidth;

  final double borderRadius;

  final double elevation;

  final bool caseSensitive;

  final bool autofocus;

  @override
  State<TitleAutoCompleteField> createState() =>
      _TitleAutoCompleteFieldState();
}

class _TitleAutoCompleteFieldState extends State<TitleAutoCompleteField> {
  late final TextEditingController _controller;

  late final FocusNode _focusNode;

  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void didUpdateWidget(covariant TitleAutoCompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;

      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    if (_ownsFocusNode) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<CategoryProvider, List<String>>(
      selector: (_, provider) => provider.categories,
      builder: (context, categories, _) {
        return RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,

          optionsBuilder: (value) {
            final text = value.text.trim();

            if (text.isEmpty) {
              return const Iterable<String>.empty();
            }

            final query = widget.caseSensitive
                ? text
                : text.toLowerCase();

            return categories.where((category) {
              final source = widget.caseSensitive
                  ? category
                  : category.toLowerCase();

              return source.contains(query);
            });
          },

          onSelected: (value) {
            _controller.text = value;

            _controller.selection = TextSelection.collapsed(
              offset: value.length,
            );

            widget.onSelected?.call(value);

            _focusNode.unfocus();
          },

          fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
              ) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              style: widget.textStyle,
              decoration: widget.decoration,
              onChanged: widget.onChanged,
            );
          },

          optionsViewBuilder: (
              context,
              onSelected,
              options,
              ) {
            final list = options.toList();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: widget.dropdownColor,
                elevation: widget.elevation,
                borderRadius:
                BorderRadius.circular(widget.borderRadius),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: widget.maxHeight,
                    maxWidth: widget.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    itemBuilder: (_, index) {
                      final option = list[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            option,
                            style: widget.suggestionTextStyle,
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
  }
}