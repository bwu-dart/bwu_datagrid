@HtmlImport(
    'package:bwu_datagrid_examples/checkbox_row_select/app_element.html')
@TestOn('browser')
library bwu_datagrid_examples.test.example_elements;

export 'package:polymer/init.dart';

import 'dart:async' show Future;
import 'dart:html' as dom;
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;
import 'package:test/test.dart';
import 'package:bwu_datagrid_examples/checkbox_row_select/app_element.dart';

dom.CheckboxInputElement getSelectAllCheckBox() {
  return dom
      .querySelector('* /deep/ bwu-datagrid-header-column#_checkbox_selector')
      .childNodes[0] as dom.CheckboxInputElement;
  // grid.querySelector('* /deep/ bwu-datagrid-header-column#_checkbox_selector') ...
  // didn't work in FireFox
}

// TODO(zoechi) fails when run with `pub run test -pchrome` works with `-pdartium`
// and when `checkbox_row_select_testx.html` is run from Chrome.
// Seems to be caused by running within a iframe

dynamic main() async {
  await initPolymer();

  group('checkbox_row_select', () {
    BwuDatagrid grid;
    dom.Element appElement;

    setUp(() async {
      appElement = new AppElement();
      dom.document.body.append(appElement);
      // allow the grid finish initialization
      await new Future<Null>(() {});

      grid = dom.querySelector('app-element /deep/ #myGrid') as BwuDatagrid;
      expect(grid, new isInstanceOf<BwuDatagrid>());
    });

    tearDown(() {
      appElement.remove();
      grid = null;
      appElement = null;
    });

    test('select row', () {
      // set up
      const int sampleRow = 3;
      const int checkBoxCol = 0;
      final dom.CheckboxInputElement checkBox = grid
          .getCellNode(sampleRow, checkBoxCol)
          .childNodes[0] as dom.CheckboxInputElement;
      expect(checkBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(checkBox.checked, isFalse);
      expect(grid.getGridOptions.selectedCellCssClass, isNotEmpty);

      // exercise
      checkBox.click();

      // verification
      expect(checkBox.checked, isTrue);
      for (int i = 0; i < grid.columns.length; i++) {
        final dom.Element node = grid.getCellNode(sampleRow, i);
        expect(
            node.classes, contains(grid.getGridOptions.selectedCellCssClass));
      }
      // tear down
    });

    test('unselect row', () async {
      // set up
      const int sampleRow = 3;
      const int checkBoxCol = 0;
      dom.CheckboxInputElement checkBox = grid
          .getCellNode(sampleRow, checkBoxCol)
          .childNodes[0] as dom.CheckboxInputElement;
      expect(checkBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(checkBox.checked, isFalse);
      expect(grid.getGridOptions.selectedCellCssClass, isNotEmpty);

      // exercise
      checkBox.click();
      expect(checkBox.checked, isTrue);

      // get checkBox again because the grid recreates it when it is rendered
      checkBox = grid.getCellNode(sampleRow, checkBoxCol).childNodes[0]
          as dom.CheckboxInputElement;

      checkBox.click();

      // verification
      expect(checkBox.checked, isFalse);
      for (int i = 0; i < grid.columns.length; i++) {
        final dom.Element node = grid.getCellNode(sampleRow, i);
        expect(node.classes,
            isNot(contains(grid.getGridOptions.selectedCellCssClass)));
      }
      // tear down
    });

    test('select all rows', () {
      // set up
      dom.CheckboxInputElement checkBox = getSelectAllCheckBox();
      expect(checkBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(checkBox.checked, isFalse);
      expect(grid.getGridOptions.selectedCellCssClass, isNotEmpty);

      // exercise
      checkBox.click();

      // verification
      expect(checkBox.checked, isTrue);

      // check all rendered rows
      for (int row = grid.getRenderedRange().top;
          row < grid.getRenderedRange().bottom;
          row++) {
        for (int col = 0; col < grid.columns.length; col++) {
          final dom.Element node = grid.getCellNode(row, col);
          if (col == 0) {
            final dom.CheckboxInputElement rowCheckBox =
                node.childNodes[0] as dom.CheckboxInputElement;
            expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
            expect(rowCheckBox.checked, isTrue);
          }

          expect(
              node.classes, contains(grid.getGridOptions.selectedCellCssClass));
        }
      }

      // ensure all rows are selected
      expect(grid.dataProvider.length, grid.getSelectedRows().length);

      // tear down
    });

    test('select all rows and unselect one row', () {
      // set up
      dom.CheckboxInputElement checkBox = getSelectAllCheckBox();

      expect(checkBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(checkBox.checked, isFalse);
      expect(grid.getGridOptions.selectedCellCssClass, isNotEmpty);
      checkBox.click();
      const int sampleRow = 3;
      const int checkBoxCol = 0;
      dom.CheckboxInputElement rowCheckBox = grid
          .getCellNode(sampleRow, checkBoxCol)
          .childNodes[0] as dom.CheckboxInputElement;
      expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(rowCheckBox.checked, isTrue);

      // exercise
      rowCheckBox.click();

      // verification
      checkBox = getSelectAllCheckBox();
      expect(checkBox.checked, isFalse);

      // check all rendered rows
      for (int row = grid.getRenderedRange().top;
          row < grid.getRenderedRange().bottom;
          row++) {
        // deselected row
        if (row == sampleRow) {
          for (int col = 0; col < grid.columns.length; col++) {
            final dom.Element node = grid.getCellNode(row, col);
            if (col == 0) {
              final dom.CheckboxInputElement rowCheckBox =
                  node.childNodes[0] as dom.CheckboxInputElement;
              expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
              expect(rowCheckBox.checked, isFalse);
            }

            expect(node.classes,
                isNot(contains(grid.getGridOptions.selectedCellCssClass)));
          }
          // remaining selected rows
        } else {
          for (int col = 0; col < grid.columns.length; col++) {
            final dom.Element node = grid.getCellNode(row, col);
            if (col == 0) {
              final dom.CheckboxInputElement rowCheckBox =
                  node.childNodes[0] as dom.CheckboxInputElement;
              expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
              expect(rowCheckBox.checked, isTrue);
            }

            expect(node.classes,
                contains(grid.getGridOptions.selectedCellCssClass));
          }
        }
      }

      // check if all but one row are selected
      expect(grid.dataProvider.length, grid.getSelectedRows().length + 1);

      // tear down
    });

    test('select all rows then unselect one ane re-select it', () {
      // set up
      dom.CheckboxInputElement checkBox = getSelectAllCheckBox();

      expect(checkBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(checkBox.checked, isFalse);
      expect(grid.getGridOptions.selectedCellCssClass, isNotEmpty);
      // select all rows
      checkBox.click();
      const int sampleRow = 3;
      const int checkBoxCol = 0;
      dom.CheckboxInputElement rowCheckBox = grid
          .getCellNode(sampleRow, checkBoxCol)
          .childNodes[0] as dom.CheckboxInputElement;
      expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
      expect(rowCheckBox.checked, isTrue);
      // unselect one row
      rowCheckBox.click();
      expect(rowCheckBox.checked, isFalse);
      checkBox = getSelectAllCheckBox();
      expect(checkBox.checked, isFalse);

      rowCheckBox = grid.getCellNode(sampleRow, checkBoxCol).childNodes[0]
          as dom.CheckboxInputElement;

      // exercise
      // reselect unselected row
      rowCheckBox.click();

      // verification
      checkBox = getSelectAllCheckBox();
      rowCheckBox = grid.getCellNode(sampleRow, checkBoxCol).childNodes[0]
          as dom.CheckboxInputElement;
      expect(rowCheckBox.checked, isTrue);
      checkBox = getSelectAllCheckBox();
      expect(checkBox.checked, isTrue);

      // check all rendered rows
      for (int row = grid.getRenderedRange().top;
          row < grid.getRenderedRange().bottom;
          row++) {
        for (int col = 0; col < grid.columns.length; col++) {
          final dom.Element node = grid.getCellNode(row, col);
          if (col == 0) {
            final dom.CheckboxInputElement rowCheckBox =
                node.childNodes[0] as dom.CheckboxInputElement;
            expect(rowCheckBox, new isInstanceOf<dom.CheckboxInputElement>());
            expect(rowCheckBox.checked, isTrue);
          }

          expect(
              node.classes, contains(grid.getGridOptions.selectedCellCssClass));
        }
      }

      // check if all rows are selected again
      expect(grid.dataProvider.length, grid.getSelectedRows().length);

      // tear down
    });
  }, timeout: const Timeout(const Duration(seconds: 120)));
}
