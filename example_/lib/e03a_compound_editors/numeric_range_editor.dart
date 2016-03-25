library bwu_datagrid_examples.e03a_compund_editors.numeric_range_editor;

import 'dart:html' as dom;
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_utils/bwu_utils_browser.dart' as tools;
import 'package:bwu_datagrid/datagrid/helpers.dart';

class NumericRangeEditor extends Editor {
  EditorArgs args;
  dom.TextInputElement fromInput, toInput;

  NumericRangeEditor newInstance(EditorArgs args) {
    return new NumericRangeEditor._(args);
  }

  NumericRangeEditor();

  NumericRangeEditor._(this.args) {
    args.container.children.clear();
    fromInput = new dom.TextInputElement()
      ..style.width = '40px'
      ..onKeyDown.listen(handleKeyDown);
    args.container.append(fromInput);

    args.container.appendHtml("&nbsp; to &nbsp;");

    toInput = new dom.TextInputElement()
      ..style.width = '40px'
      ..onKeyDown.listen(handleKeyDown);
    args.container.append(toInput);

    focus();
  }

  void handleKeyDown(dom.KeyboardEvent e) {
    if (e.keyCode == dom.KeyCode.LEFT ||
        e.keyCode == dom.KeyCode.RIGHT ||
        e.keyCode == dom.KeyCode.TAB) {
      e.stopImmediatePropagation();
    }
  }

  @override
  void applyValue(
      DataItem<dynamic, dynamic> item, Map<dynamic, dynamic> value) {
    item['from'] = value['from'];
    item['to'] = value['to'];
  }

  @override
  void destroy() {
    args.container.children.clear();
  }

  @override
  void focus() {
    fromInput.focus();
  }

  @override
  bool get isValueChanged {
    return args.item['from'] !=
            tools.parseInt(fromInput.value, onErrorDefault: 0) ||
        args.item['to'] != tools.parseInt(fromInput.value, onErrorDefault: 0);
  }

  @override
  void loadValue(DataItem<dynamic, dynamic> item) {
    fromInput.value = '${item['from']}';
    toInput.value = '${item['to']}';
  }

  @override
  Map<String, int> serializeValue() {
    return {
      'from': tools.parseInt(fromInput.value, onErrorDefault: 0),
      'to': tools.parseInt(toInput.value, onErrorDefault: 0)
    };
  }

  @override
  ValidationResult validate() {
    if (!tools.isInt(fromInput.value) || !tools.isInt(toInput.value)) {
      return new ValidationResult(false, 'Please type in valid numbers.');
    }

    if (tools.parseInt(fromInput.value) > tools.parseInt(toInput.value)) {
      return new ValidationResult(false, '"from" cannot be greater than "to"');
    }

    return new ValidationResult(true);
  }
}
