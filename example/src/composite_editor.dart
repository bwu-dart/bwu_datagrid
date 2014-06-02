library bwu_datagrid.example.composite_editor;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/editors/editors.dart';

class CompositeEditorOptions {
  String validationFailedMsg;
  Function show ;
  Function hide;
  Function position;
  Function destroy;

  CompositeEditorOptions({this.validationFailedMsg : 'Some of the fields have failed validation',
      this.show, this.hide, this.position, this.destroy});
}

/***
 * A composite Bwu Datagrid editor factory.
 * Generates an editor that is composed of multiple editors for given columns.
 * Individual editors are provided given containers instead of the original cell.
 * Validation will be performed on all editors individually and the results will be aggregated into one
 * validation result.
 *
 *
 * The returned editor will have its prototype set to CompositeEditor, so you can use the "instanceof" check.
 *
 * NOTE:  This doesn't work for detached editors since they will be created and positioned relative to the
 *        active cell and not the provided container.
 *
 * @param columns {Array} Column definitions from which editors will be pulled.
 * @param containers {Array} Container HTMLElements in which editors will be placed.
 * @param options {Object} Options hash:
 *  validationFailedMsg     -   A generic failed validation message set on the aggregated validation resuls.
 *  hide                    -   A function to be called when the grid asks the editor to hide itself.
 *  show                    -   A function to be called when the grid asks the editor to show itself.
 *  position                -   A function to be called when the grid asks the editor to reposition itself.
 *  destroy                 -   A function to be called when the editor is destroyed.
 */
class CompositeEditor extends Editor {
  List<Column> columns;
  CompositeEditorOptions options;
  Map<String,dom.HtmlElement> containers;

  CompositeEditor.prepare(this.columns, this.containers, this.options);
  CompositeEditor(this.args);

  Editor firstInvalidEditor;

  EditorArgs args;
  List<Editor> editors;

  NodeBox getContainerBox(String id) {
      var c = containers[id];
      math.Rectangle<int> offset = c.offset;
      var w = c.offsetWidth.round();
      var h = c.offsetHeight.round();

      return new NodeBox(
        top: offset.top.round(),
        left: offset.left.round(),
        bottom: offset.top.round() + h,
        right: offset.left.round() + w,
        width: w,
        height: h,
        visible: true
      );
    }

  void init() {
    var idx = columns.length;
    editors = new List<Editor>(columns.length);
    EditorArgs newArgs;
    while (idx-- > 0) {
      if (columns[idx].editor != null) {
        //newArgs = $.extend({}, args);
        newArgs = new EditorArgs(
          container : containers[columns[idx].id],
          column : columns[idx],
          position : getContainerBox(columns[idx].id)
        );

        editors[idx] = columns[idx].editor.newInstance(newArgs);
      }
    }
  }

  void destroy () {
    var idx = editors.length;
    while (idx-- > 0) {
      editors[idx].destroy();
    }

    if(options.destroy != null) options.destroy();
  }

  void focus () {
    // if validation has failed, set the focus to the first invalid editor
    if(firstInvalidEditor != null) {
      firstInvalidEditor.focus();
    } else {
      editors[0].focus();
    }
  }

  bool get isValueChanged {
    var idx = editors.length;
    while (idx-- > 0) {
      if (editors[idx].isValueChanged) {
        return true;
      }
    }
    return false;
  }

  dynamic serializeValue () {
    var serializedValue = new List(columns.length);
    var idx = editors.length;
    while (idx-- > 0) {
      serializedValue[idx] = editors[idx].serializeValue();
    }
    return serializedValue;
  }

  void applyValue (/*Item/Map*/item, state) {
    var idx = editors.length;
    while (idx-- > 0) {
      editors[idx].applyValue(item, state[idx]);
    }
  }

  void loadValue (/*Item/Map*/item) {
    var idx = editors.length;
    while (idx-- > 0) {
      editors[idx].loadValue(item);
    }
  }

  ValidationResult validate() {
    var validationResults;
    List<ValidationErrorSource> errors = [];

    firstInvalidEditor = null;

    var idx = editors.length;
    while (idx-- > 0) {
      validationResults = editors[idx].validate();
      if (!validationResults.isValid) {
        firstInvalidEditor = editors[idx];
        errors.add(new ValidationErrorSource(
          index: idx,
          editor: editors[idx],
          container: containers[idx],
          message: validationResults.message
        ));
      }
    }

    if (errors.length > 0) {
      return new ValidationResult(
        false,
        options.validationFailedMsg,
        errors
      );
    } else {
      return new ValidationResult(true);
    }
  }

  void hide () {
    var idx = editors.length;
    while (idx-- > 0) {
      if(editors[idx].hide != null) editors[idx].hide();
    }
    if(options.hide != null) options.hide();
  }

  void show () {
    var idx = editors.length;
    while (idx-- > 0) {
      if(editors[idx].show != null) editors[idx].show();
    }
    if(options.show != null) options.show();
  }

  void position (NodeBox box) {
    if(options.position != null) options.position(box);
  }

  @override
  Editor newInstance(EditorArgs args) {
    return this;
  }
}
