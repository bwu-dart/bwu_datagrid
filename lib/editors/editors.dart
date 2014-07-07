library bwu_dart.bwu_datagrid.editors;

import 'dart:html' as dom;

import 'package:bwu_utils_browser/math/parse_num.dart' as tools;
import 'package:bwu_utils_browser/html/html.dart' as dom_tools;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

/***
 * Contains basic BwuDatagrid editors.
 * @module Editors
 */

abstract class Editor {
  //void call(EditorArgs args);
  Editor newInstance(EditorArgs args);
  BwuDatagrid grid;
  NodeBox gridPosition;
  dom.HtmlElement container;
  Column column;
  DataItem item;
  Function commitChanges;
  Function cancelChanges;

  void destroy();
  void loadValue(DataItem item);
  /**
   * Normally returns [String] but for example for
   * compound editors it may return [Map]
   */
  dynamic serializeValue();
  bool get isValueChanged;
  void applyValue(DataItem item, dynamic value);
  void focus();
  void show() {}
  void hide() {}
  void position(NodeBox position){}

  ValidationResult validate();
}

class ValidationResult {
  bool isValid = false;
  String message;
  List<ValidationErrorSource> errors;

  ValidationResult(this.isValid, [this.message, this.errors]);
}

class ValidationErrorSource {
  int index;
  Editor editor;
  dom.HtmlElement container;
  String message;

  ValidationErrorSource({this.index, this.editor, this.container, this.message});
}

abstract class Validator  {
  ValidationResult call(dynamic value);
}

typedef void CommitChangesFn();

typedef void CancelChangesFn();

class EditorArgs {
  BwuDatagrid grid;
  NodeBox gridPosition;
  NodeBox position;
  dom.HtmlElement container;
  Column column;
  DataItem item;

  CommitChangesFn commitChanges;
  CancelChangesFn cancelChanges;

  EditorArgs({this.grid, this.gridPosition, this.position, this.container, this.column, this.item, this.commitChanges, this.cancelChanges});

//  void extend(EditorArgs c) {
//      if(c.grid != null) grid = c.grid;
//      if(c.gridPosition != null) gridPosition = c.gridPosition;
//      if(c.position != null) position = c.position;
//      if(c.container != null) container = c.container;
//      if(c.column != null) column = c.column;
//      if(c.item != null) item = c.item;
//      if(c.commitChanges != null) commitChanges = c.commitChanges;
//      if(c.cancelChanges != null) cancelChanges = c.cancelChanges;
//  }
}

class TextEditor extends Editor {
  EditorArgs args;

  TextEditor newInstance(EditorArgs args) {
    return new TextEditor._(args);
  }

  TextEditor();

  TextEditor._(this.args) {
    $input = new dom.TextInputElement()..classes.add('editor-text');
    args.container.append($input);
    $input
        ..onKeyDown.listen((dom.KeyboardEvent e) {
          if (e.keyCode == dom.KeyCode.LEFT || e.keyCode == dom.KeyCode.RIGHT) {
            e.stopImmediatePropagation();
          }
        })
        ..focus()
        ..select();
  }

  dom.InputElement $input;
  String defaultValue;

  @override
  void destroy() {
    $input.remove();
  }

  @override
  void focus() {
    $input.focus();
  }

//  @override
  String get value => $input.value;

//  @override
  set value(val) => $input.value = val;

  @override
  void loadValue(DataItem item) {
    defaultValue = item[args.column.field] != null ? item[args.column.field] : "";
    $input.value =  defaultValue;
    $input.defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () => $input.value;

  @override
  void applyValue(DataItem item, String state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.value == "" && defaultValue == null)) && ($input.value != defaultValue);
  }

  @override
  ValidationResult validate () {
    if (args.column.validator != null) {
      var validationResults = args.column.validator($input.value);
      if (!validationResults.isValid) {
        return validationResults;
      }
    }

    return new ValidationResult(true);
  }
}

class IntegerEditor extends Editor {
  EditorArgs args;
  dom.InputElement $input;
  var defaultValue;

  IntegerEditor newInstance(EditorArgs args) {
    return new IntegerEditor._(args);
  }

  IntegerEditor();

  IntegerEditor._(this.args) {
    $input = new dom.TextInputElement()..classes.add('editor-text');

    $input.onKeyDown.listen((dom.KeyboardEvent e) {
      if (e.keyCode == dom.KeyCode.LEFT || e.keyCode == dom.KeyCode.RIGHT) {
        e.stopImmediatePropagation();
      }
    });

    args.container.append($input);
    $input..focus()..select();
  }

  @override
  void destroy () {
    $input.remove();
  }

  @override
  void focus () {
    $input.focus();
  }

  @override
  void loadValue (DataItem item) {
    defaultValue = item[args.column.field].toString();
    $input.value = defaultValue;
    $input.defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () {
    return tools.parseInt($input.value).toString(); // || 0; // TODO default 0
  }

  @override
  void applyValue (DataItem item, dynamic state) {
    int val;
    if(state is int) {
      val = state;
    } else if (state is String) {
      val = tools.parseInt(state, onErrorDefault: 0);
    } else if (state == null){
      val = 0;
    } else {
      throw 'not supported data type for "state" (${state})';
    }
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.value == '' && defaultValue == null)) && ($input.value != defaultValue);
  }

  @override
  ValidationResult validate () {
    if (!tools.isInt($input.value)) {
      return new ValidationResult(false, "Please enter a valid integer");
    }

    return new ValidationResult(true);
  }
}

class DateEditor extends Editor  {
  dom.InputElement $input;
  String defaultValue;
  bool calendarOpen = false;
  EditorArgs args;

  DateEditor newInstance(EditorArgs args) {
    return new DateEditor._(args);
  }

  DateEditor();

  DateEditor._(this.args) {
    $input = new dom.DateInputElement()..classes.add('editor-text');
    args.container.append($input);
    $input..focus(); //..select();
//    $input.datepicker({
//      'showOn': "button",
//      'buttonImageOnly': true,
//      'buttonImage': "../images/calendar.gif",
//      'beforeShow': () {
//        var calendarOpen = true;
//      },
//      'onClose': () {
//        var calendarOpen = false;
//      }
//    });
    $input.width = $input.offsetWidth.round() - 18;
  }

  @override
  void destroy () {
//    datepicker.dpDiv.stop(true, true);
//    $input.datepicker("hide");
//    $input.datepicker("destroy");
    $input.remove();
  }

  @override
  void show () {
    if (calendarOpen) {
//      print('show, calendarOpen');
//      datepicker.dpDiv.stop(true, true).show();
    }
  }

  @override
  void hide () {
    if (calendarOpen) {
//      print('hide, calendarOpen');
//      datepicker.dpDiv.stop(true, true).hide();
    }
  }

  @override
  void position (NodeBox position) {
    if (!calendarOpen) {
      return null;
    }
//    datepicker.dpDiv
//        .css("top", position.top + 30)
//        .css("left", position.left);
  }

  @override
  void focus () {
    $input.focus();
  }

  @override
  void loadValue (DataItem item) {
    defaultValue = item[args.column.field] != null ? item[args.column.field].toString() : '';
    $input.value = defaultValue;
    $input.defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () {
    return $input.value;
  }

  @override
  void applyValue (DataItem item, String state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.value == "" && defaultValue == null)) && ($input.value != defaultValue);
  }

  @override
  ValidationResult validate () {
    return new ValidationResult(true);
  }
}

class YesNoSelectEditor extends Editor{
  dom.SelectElement $select;
  String defaultValue;
  EditorArgs args;

  YesNoSelectEditor newInstance(EditorArgs args) {
    return new YesNoSelectEditor._(args);
  }

  YesNoSelectEditor();

  YesNoSelectEditor._(this.args) {
    $select = new dom.SelectElement()
      ..tabIndex=0
      ..classes.add('editor-yesno')
      ..append(new dom.OptionElement()
          ..value='yes'
          ..text ='Yes')
      ..append(new dom.OptionElement()
          ..value='no'
          ..text='No');
    args.container.append($select);
    $select..focus();
  }

  @override
  void destroy () {
    $select.remove();
  }

  @override
  void focus () {
    $select.focus();
  }

  @override
  void loadValue (DataItem item) {
    defaultValue = item[args.column.field];
    $select.value = defaultValue != null ? "yes" : "no";
    //$select.select();
  }

  @override
  String serializeValue () {
    return ($select.value == "yes").toString();
  }

  @override
  void applyValue (/*Map/Item*/ dynamic item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return ($select.value != defaultValue);
  }

  @override
  ValidationResult validate () {
    return new ValidationResult(true);
  }
}

class CheckboxEditor extends Editor {
  dom.InputElement $select;
  bool defaultValue;
  EditorArgs args;

  CheckboxEditor newInstance(EditorArgs args) {
    return new CheckboxEditor._(args);
  }

  CheckboxEditor();

  CheckboxEditor._(this.args) {
    $select = new dom.CheckboxInputElement()
      ..value='true'
      ..classes.add('editor-checkbox')
      ..attributes['hidefocus'] = 'true';
    args.container.append($select);
    $select.focus();
  }

  @override
  void destroy () {
    $select.remove();
  }

  @override
  void focus () {
    $select.focus();
  }

  @override
  void loadValue (DataItem item) {
    var val = item[args.column.field];
    defaultValue =  (val is bool && val) || (val is String && (val.toLowerCase() == 'true' || val.toLowerCase() == 'yes')) || (val is int && val != 0) ;
    if (defaultValue) {
      $select.checked = true;
    } else {
      $select.checked = false;
    }
  }

  @override
  String serializeValue () {
    return $select.checked.toString();
  }

  @override
  void applyValue (DataItem item, String state) {
    item[args.column.field] = state.toLowerCase() == 'true' ? true : false;
  }

  @override
  bool get isValueChanged {
    return (this.serializeValue() != defaultValue);
  }

  @override
  ValidationResult validate () {
    return new ValidationResult(true);
  }
}

class PercentCompleteEditor extends Editor {
  dom.InputElement $input;
  dom.HtmlElement $picker;
  dom.RangeInputElement $slider;
  int defaultValue;
  EditorArgs args;

  PercentCompleteEditor newInstance(EditorArgs args) {
    return new PercentCompleteEditor._(args);
  }

  PercentCompleteEditor();

  PercentCompleteEditor._(this.args) {
    $input = new dom.TextInputElement()..classes.add('editor-percentcomplete');
    $input.style.width = '${dom_tools.innerWidth(args.container) - 25}px';
    args.container.append($input);

    $picker = new dom.DivElement()
        ..classes.add('editor-percentcomplete-picker');
        // TODO ..style.zIndex = '10000'; it seems it needs to be added to the body to make it display above the elements border
        // workaround would be to show it above the field when it is near the border
    args.container.append($picker);
    $picker.append(new dom.DivElement()
        ..classes.add('editor-percentcomplete-helper')
        ..append(new dom.DivElement()
            ..classes.add('editor-percentcomplete-wrapper')
            ..append(new dom.DivElement()
                ..classes.add('editor-percentcomplete-slider')
                ..append(new dom.DivElement()
                      ..classes.add('editor-percentcomplete-buttons')))));

    $picker.querySelector(".editor-percentcomplete-buttons")
        ..append(new dom.ButtonElement()
            ..attributes['val']='0'
            ..text= 'Not started')
        ..append(new dom.BRElement())
        ..append(new dom.ButtonElement()
            ..attributes['val']='50'
            ..text='In Progress')
        ..append(new dom.BRElement())
        ..append(new dom.ButtonElement()
            ..attributes['val']='100'
            ..text='Complete');

    $input
        ..focus()
        ..select();


    var $sliderWrapper = $picker.querySelector(".editor-percentcomplete-slider");
    $slider = new dom.RangeInputElement();
    $slider
        ..min = '0'
        ..max = '100'
        ..step = '1'
        ..value = _invertedRangeValueInt(defaultValue)
        ..style.width = '25px'
        ..style.height = '100px'
        ..attributes['orient'] = 'vertical' // http://stackoverflow.com/questions/15935837
        ..attributes['writing-mode'] = 'bt-lr'
        ..style.appearance = 'slider-vertical'
        ..onChange.listen((e) {
          $input.value = _invertedRangeValue($slider.value);
        });
    $sliderWrapper.append($slider);
//    $picker.querySelector(".editor-percentcomplete-slider").slider({
//      'orientation': "vertical",
//      'range': "min",
//      'value': defaultValue,
//      'slide': (dom.MouseEvent event, dom.HtmlElement ui) {
//        $input.value = ui.attributes['val'];
//      }
//    });

    $picker.querySelectorAll(".editor-percentcomplete-buttons button").forEach((e) => e.onClick.listen((e) {
      $input.value = (e.target.attributes['val']);
      $slider.value = _invertedRangeValue($input.value);
      //$picker.querySelector(".editor-percentcomplete-slider").slider("value", e.target.attributes['val']);
    }));
  }


  @override
  void destroy () {
    $input.remove();
    $picker.remove();
  }

  @override
  void focus () {
    $input.focus();
  }

  @override
  void loadValue (DataItem item) {
    var val = item[args.column.field];
    if(val == null) val = 0;
    $input.value = (defaultValue = val).toString();
    $slider.value = _invertedRangeValueInt(defaultValue);
    $input.select();
  }

  String _invertedRangeValue(String val) {
    return '${100-tools.parseInt(val)}';
  }

  String _invertedRangeValueInt(int val) {
    if(val == null)  {
      val = 0;
    }
    return '${100-val}';
  }

  @override
  String serializeValue () {
    return tools.parseInt($input.value, onErrorDefault: 0).toString(); // || 0; // todo default 0
  }

  @override
  void applyValue (DataItem item, String state) {
    item[args.column.field] = tools.parseInt(state);
  }

  @override
  bool get isValueChanged {
    return (!($input.value == '' && defaultValue == null)) && (tools.parseInt($input.value, onErrorDefault: 0) != defaultValue);
  }

  @override
  ValidationResult validate() {
    if (!tools.isInt($input.value)) {
      return new ValidationResult(false, "Please enter a valid positive number");
    }

    return new ValidationResult(true);
  }
}

// TODO make Polymer element
/*
 * An example of a "detached" editor.
 * The UI is added onto document BODY and .position(), .show() and .hide() are implemented.
 * KeyDown events are also handled to provide handling for Tab, Shift-Tab, Esc and Ctrl-Enter.
 */
class LongTextEditor extends Editor {
  dom.TextAreaElement $input;
  dom.HtmlElement $wrapper;
  String defaultValue;
  EditorArgs args;

  LongTextEditor newInstance(EditorArgs args) {
    return new LongTextEditor._(args);
  }

  LongTextEditor();

  LongTextEditor._(this.args) {
    var $container = dom.document.body;

    $wrapper = new dom.DivElement()
      ..style.zIndex = '10000'
      ..style.position='absolute'
      ..style.background='white'
      ..style.padding='5px'
      ..style.border='3px solid gray'
      ..style.borderRadius ='10px';
    $container.append($wrapper);

    $input = new dom.TextAreaElement()
      ..attributes['hidefocus'] = 'true'
      ..rows=5
      ..style.background ='white'
      ..style.width ='250px'
      ..style.height='80px'
      ..style.border ='0'
      ..style.outline='0';
    $wrapper.append($input);

    $wrapper.append(new dom.DivElement()
      ..style.textAlign='right'
      ..append(new dom.ButtonElement()
          ..text = 'Save')
      ..append(new dom.ButtonElement()
          ..text = 'Cancel'));

    $wrapper.querySelectorAll("button").first.onClick.listen(this.save);
    $wrapper.querySelectorAll("button").last.onClick.listen(this.cancel);
    $input.onKeyDown.listen(this.handleKeyDown);

    position(args.position);
    $input
        ..focus()
        ..select();
  }

  void handleKeyDown (dom.KeyboardEvent e) {
    if (e.which == dom.KeyCode.ENTER && e.ctrlKey) {
      save();
    } else if (e.which == dom.KeyCode.ESC) {
      e.preventDefault();
      cancel();
    } else if (e.which == dom.KeyCode.TAB && e.shiftKey) {
      e.preventDefault();
      args.grid.navigatePrev();
    } else if (e.which == dom.KeyCode.TAB) {
      e.preventDefault();
      args.grid.navigateNext();
    }
  }

  void save ([dom.Event e]) {
    args.commitChanges();
  }

  void cancel ([dom.Event e]) {
    $input.value = defaultValue;
    args.cancelChanges();
  }

  String _defaultDisplay = 'auto';
  @override
  void hide () {
    _defaultDisplay = $wrapper.style.display;
    $wrapper.style.display = 'none'; //.hide();
  }

  @override
  void show () {
    $wrapper.style.display = _defaultDisplay;
  }

  @override
  void position (NodeBox position) {
    $wrapper
        ..style.top = '${position.top - 5}px'
        ..style.left = '${position.left - 5}px';
  }

  @override
  void destroy () {
    $wrapper.remove();
  }

  @override
  void focus () {
    $input.focus();
  }

  @override
  void loadValue (DataItem item) {
    $input.value = (defaultValue = item[args.column.field]);
    $input.select();
  }

  @override
  String serializeValue () {
    return $input.value;
  }

  @override
  void applyValue (DataItem item, String state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.value == '' && defaultValue == null)) && ($input.value != defaultValue);
  }

  @override
  ValidationResult validate () {
    return new ValidationResult(true);
  }
}
