library bwu_datagrid.example.e03a_compund_editors.numeric_range_editor;

import 'dart:html' as dom;
import 'package:bwu_datagrid/editors/editors.dart';
import 'package:bwu_utils_browser/math/parse_num.dart' as tools;

class NumericRangeEditor extends Editor {
  EditorArgs args;
  dom.TextInputElement $from, $to;

  NumericRangeEditor newInstance(EditorArgs args) {
    return new NumericRangeEditor._(args);
  }

  NumericRangeEditor();

  NumericRangeEditor._(this.args) {
    args.container.children.clear();
    $from = new dom.TextInputElement()
        ..style.width = '40px'
        ..onKeyDown.listen(handleKeyDown);
    args.container.append($from);

    args.container.appendHtml("&nbsp; to &nbsp;");

    $to = new dom.TextInputElement()
        ..style.width='40px'
        ..onKeyDown.listen(handleKeyDown);
    args.container.append($to);

    focus();
  }

  void handleKeyDown (dom.KeyboardEvent e) {
    if (e.keyCode == dom.KeyCode.LEFT || e.keyCode == dom.KeyCode.RIGHT || e.keyCode == dom.KeyCode.TAB) {
      e.stopImmediatePropagation();
    }
  }


  @override
  void applyValue(/*Map/Item*/ item, Map value) {
    item['from'] = value['from'];
    item['to'] = value['to'];
  }

  @override
  void destroy() {
    args.container.children.clear();
  }

  @override
  void focus() {
    $from.focus();
  }


  @override
  bool get isValueChanged {
    return args.item['from'] != tools.parseInt($from.value, onErrorDefault: 0) || args.item['to'] != tools.parseInt($from.value, onErrorDefault: 0);
  }

  @override
  void loadValue(item) {
    $from.value = item['from'].toString();
    $to.value = item['to'].toString();
  }

  @override
  Map serializeValue() {
    return {'from': tools.parseInt($from.value, onErrorDefault: 0), 'to': tools.parseInt($to.value, onErrorDefault: 0)};
  }

  @override
  ValidationResult validate() {
    if (!tools.isInt($from.value) || !tools.isInt($to.value)) {
      return new ValidationResult(false, 'Please type in valid numbers.');
    }

    if (tools.parseInt($from.value) > tools.parseInt($to.value)) {
      return new ValidationResult(false, '"from" cannot be greater than "to"');
    }

    return new ValidationResult(true);
  }
}