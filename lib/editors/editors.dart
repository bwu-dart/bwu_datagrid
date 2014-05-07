library bwu_dart.bwu_datagrid.editors;

import 'dart:html' as dom;

import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/datagrid/helpers.dart';

/***
 * Contains basic SlickGrid editors.
 * @module Editors
 * @namespace Slick
 */

class Editor {
  BwuDatagrid grid;
  NodeBox gridPosition;
  NodeBox position;
  dom.HtmlElement container;
  Column column;
  Item item;
  Function commitChanges;
  Function cancelChanges;

  void destroy() {}
  void loadValue(Item item) {}
  String serializeValue() {}
  bool get isValueChanged => false;
  void applyValue(Item item, String value) {}
  void focus() {}
  void show() {}
  void hide() {}

  //void position(NodeBox cellBox) {}
  ValidationResults validate() {}
}

//(function ($) {
//  // register namespace
//  $.extend(true, window, {
//    "Slick": {
//      "Editors": {
//        "Text": TextEditor,
//        "Integer": IntegerEditor,
//        "Date": DateEditor,
//        "YesNoSelect": YesNoSelectEditor,
//        "Checkbox": CheckboxEditor,
//        "PercentComplete": PercentCompleteEditor,
//        "LongText": LongTextEditor
//      }
//    }
//  });

class ValidationResult {
  bool isValid = false;
  String message;

  ValidationResult(this.isValid, [this.message]);
}

class EditorArgs {
  dom.HtmlElement container;
  Column column;

  Map position;
  BwuDatagrid grid;
  void commitChanges();
  void cancelChanges();
}

class TextEditor extends Editor {
  EditorArgs args;
  TextEditor(this.args) {
    $input = new dom.Element.html("<INPUT type=text class='editor-text' />");
    args.container.append($input);
    $input
        ..onKeyDown.listen((dom.KeyboardEvent e) {
        //.bind("keydown.nav", function (e) {
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

  @override
  String get value => $input.val();

  @override
  void  set value(val) => $input.val(val);

  @override
  void loadValue(Item item) {
    defaultValue = item[args.column.field] != null ? item[args.column.field] : "";
    $input.val(defaultValue);
    $input.children[0].defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () => $input.val();

  @override
  void applyValue(Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
  }

  @override
  ValidationResult validate () {
    if (args.column.validator) {
      var validationResults = args.column.validator($input.val());
      if (!validationResults.valid) {
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

  IntegerEditor(this.args) {
    $input = new dom.Element.html("<INPUT type=text class='editor-text' />");

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
  void loadValue (Item item) {
    defaultValue = item[args.column.field];
    $input.val(defaultValue);
    $input.children[0].defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () {
    return int.parse($input.val(), radix: 10); // || 0; // TODO default 0
  }

  @override
  void applyValue (Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
  }

  @override
  ValidationResult validate () {
    if (isNaN($input.val())) {
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

  DateEditor(this.args) {
    $input = new dom.Element.html("<INPUT type=text class='editor-text' />");
    args.container.append($input);
    $input..focus()..select();
    $input.datepicker({
      'showOn': "button",
      'buttonImageOnly': true,
      'buttonImage': "../images/calendar.gif",
      'beforeShow': () {
        var calendarOpen = true;
      },
      'onClose': () {
        var calendarOpen = false;
      }
    });
    $input.width = $input.width - 18;
  }

  @override
  void destroy () {
    datepicker.dpDiv.stop(true, true);
    $input.datepicker("hide");
    $input.datepicker("destroy");
    $input.remove();
  }

  @override
  void show () {
    if (calendarOpen) {
      datepicker.dpDiv.stop(true, true).show();
    }
  }

  @override
  void hide () {
    if (calendarOpen) {
      datepicker.dpDiv.stop(true, true).hide();
    }
  }

  @override
  void position (Map position) {
    if (!calendarOpen) {
      return null;
    }
    datepicker.dpDiv
        .css("top", position['top'] + 30)
        .css("left", position['left']);
  }

  @override
  void focus () {
    $input.focus();
  }

  @override
  void loadValue (Item item) {
    defaultValue = item[args.column.field];
    $input.val(defaultValue);
    $input.children[0].defaultValue = defaultValue;
    $input.select();
  }

  @override
  String serializeValue () {
    return $input.val();
  }

  @override
  void applyValue (Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
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

  YesNoSelectEditor(this.args) {
    $select = new dom.Element.html("<SELECT tabIndex='0' class='editor-yesno'><OPTION value='yes'>Yes</OPTION><OPTION value='no'>No</OPTION></SELECT>");
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
  void loadValue (Item item) {
    $select.val((defaultValue = item[args.column.field]) ? "yes" : "no");
    $select.select();
  }

  @override
  String serializeValue () {
    return ($select.val() == "yes");
  }

  @override
  void applyValue (Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return ($select.val() != defaultValue);
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

  CheckboxEditor(this.args) {
    $select = new dom.Element.html("<INPUT type=checkbox value='true' class='editor-checkbox' hideFocus>");
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
  void loadValue (Item item) {
    defaultValue = item[args.column.field] != null;
    if (defaultValue) {
      $select.prop('checked', true);
    } else {
      $select.prop('checked', false);
    }
  }

  @override
  String serializeValue () {
    return $select.prop('checked');
  }

  @override
  void applyValue (Item item, int state) {
    item[args.column.field] = state;
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
  String defaultValue;
  EditorArgs args;

  PercentCompleteEditor(this.args)  {
    $input = new dom.Element.html("<INPUT type=text class='editor-percentcomplete' />");
    $input.width = args.container.innerWidth - 25;
    args.container.append($input);

    $picker = new dom.Element.html("<div class='editor-percentcomplete-picker' />");
    args.container.append($picker);
    $picker.append(new dom.Element.html("<div class='editor-percentcomplete-helper'><div class='editor-percentcomplete-wrapper'><div class='editor-percentcomplete-slider' /><div class='editor-percentcomplete-buttons' /></div></div>"));

    $picker.find(".editor-percentcomplete-buttons").append("<button val=0>Not started</button><br/><button val=50>In Progress</button><br/><button val=100>Complete</button>");

    $input..focus()..select();

    $picker.find(".editor-percentcomplete-slider").slider({
      'orientation': "vertical",
      'range': "min",
      'value': defaultValue,
      'slide': (dom.MouseEvent event, dom.HtmlElement ui) {
        $input.val(ui.value);
      }
    });

    $picker.find(".editor-percentcomplete-buttons button").onClick.listen((e) {
      $input.val($(this).attr("val"));
      $picker.find(".editor-percentcomplete-slider").slider("value", $(this).attr("val"));
    });
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
  void loadValue (Item item) {
    $input.val(defaultValue = item[args.column.field]);
    $input.select();
  }

  @override
  String serializeValue () {
    return int.parse($input.val(), radix: 10); // || 0; // todo default 0
  }

  @override
  void applyValue (Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.val() == "" && defaultValue == null)) && ((int.parse($input.val(), radix: 10) || 0) != defaultValue);
  }

  @override
  ValidationResult validate() {
    if (isNaN(parseInt($input.val(), 10))) {
      return new ValidationResult(false, "Please enter a valid positive number");
    }

    return new ValidationResult(true);
  }
}

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

  LongTextEditor(this.args) {
    var $container = dom.document.body;

    $wrapper = new dom.Element.html("<DIV style='z-index:10000;position:absolute;background:white;padding:5px;border:3px solid gray; -moz-border-radius:10px; border-radius:10px;'/>");
    $container.append($wrapper);

    $input = new dom.Element.html("<TEXTAREA hidefocus rows=5 style='backround:white;width:250px;height:80px;border:0;outline:0'>");
    $wrapper.append($input);

    $wrapper.append(new dom.Element.html("<DIV style='text-align:right'><BUTTON>Save</BUTTON><BUTTON>Cancel</BUTTON></DIV>"));

    $wrapper.find("button:first").bind("click", this.save);
    $wrapper.find("button:last").bind("click", this.cancel);
    $input.bind("keydown", this.handleKeyDown);

    position(args.position);
    $input..focus()..select();
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
    } else if (e.which == $.ui.keyCode.TAB) {
      e.preventDefault();
      args.grid.navigateNext();
    }
  }

  void save () {
    args.commitChanges();
  }

  void cancel () {
    $input.val(defaultValue);
    args.cancelChanges();
  }

  @override
  void hide () {
    $wrapper.hide();
  }

  @override
  void show () {
    $wrapper.show();
  }

  @override
  void position (Map position) {
    $wrapper
        ..style.top = position['top'] - 5
        ..style.left = position['left'] - 5;
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
  void loadValue (Item item) {
    $input.val(defaultValue = item[args.column.field]);
    $input.select();
  }

  @override
  String serializeValue () {
    return $input.val();
  }

  @override
  voidapplyValue (Item item, int state) {
    item[args.column.field] = state;
  }

  @override
  bool get isValueChanged {
    return (!($input.val() == "" && defaultValue == null)) && ($input.val() != defaultValue);
  }

  @override
  ValidationResult validate () {
    return new ValidationResult(true);
  }
}
