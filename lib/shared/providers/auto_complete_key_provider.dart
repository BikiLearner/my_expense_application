import 'package:flutter/cupertino.dart';

abstract class AutoCompleteProvider implements Listenable {
  TextEditingController get titleController;
  int get autoCompleteKey;
}