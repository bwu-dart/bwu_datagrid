@TestOn('vm')
library bwu_datagrid_examples.test.e03_editing_test;

import 'dart:async' show Future, Stream;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart' as wd;
import 'package:webdriver/io.dart' show Keyboard;
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/e03_editing.html';
  forEachBrowser(tests);
//  tests(WebBrowser.chrome);
}

// TODO(zoechi)
// - accept with tab

enum AutoEdit { enabled, disabled, }

void tests(WebBrowser browser) {
  testsWithEditMode(browser, AutoEdit.disabled);
  testsWithEditMode(browser, AutoEdit.enabled);
}

void testsWithEditMode(WebBrowser browser, AutoEdit autoEdit) {
  group('e03_editing,', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    group('${autoEdit},', () {
      group('title', () {
        const String titleOldValue = 'Task 7';
        const String titleNewValue = 'New Title';
        const By editorSelector = const By.cssSelector('input[type="text"]');

        WebElement titleCell;
        WebElement editor;

        setUp(() async {
          if (autoEdit == AutoEdit.enabled) {
            final WebElement autoEditEnableButton = await driver
                .findElements(const By.shadow(
                    'app-element::shadow div.options-panel button'))
                .first;
            autoEditEnableButton.click();
          }

          titleCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          expect(await titleCell.text, titleOldValue);

          await driver.mouse.moveTo(element: titleCell);
          await driver.mouse.doubleClick();

          editor = await titleCell.findElement(editorSelector);
          expect(await editor.attributes['value'], titleOldValue);
          await editor.clear();
        });

        test('accept with enter', () async {
          await editor.sendKeys('${titleNewValue}${Keyboard.enter}');
          expect(await titleCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleNewValue);
        });

        test('accept with click on other cell', () async {
          await editor.sendKeys('${titleNewValue}');
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await titleCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleNewValue);
        });

        test('cancel with Esc', () async {
          await editor.sendKeys('${titleNewValue}${Keyboard.escape}');
          expect(await titleCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleOldValue);
        });
      } /*, skip: 'temporary'*/);

      group('description', () {
        const String descriptionOldValue =
            'This is a sample task description.\n  It can be multiline';
        final String descriptionOldValueOneLine = descriptionOldValue
            .replaceAll('\n', ' ')
            .replaceAll('  ', ' ')
            .replaceAll('  ', ' ');

        const String descriptionNewValue =
            'Some other description\nwhich can also be multiline';
        const By editorSelector = const By.cssSelector('body > div > textarea');

        WebElement editor;
        WebElement titleCell;
        WebElement descriptionCell;

        setUp(() async {
          titleCell =
              await (driver.findElements(firstColumnSelector).skip(9).first);
          await titleCell.click();

          descriptionCell =
              await driver.findElement(descriptionCellActiveRowSelector);
          expect(await descriptionCell.text, descriptionOldValueOneLine);
          await driver.mouse.moveTo(element: descriptionCell);
          await driver.mouse.doubleClick();

          editor = await driver.findElement(editorSelector);
          expect(await editor.attributes['value'], descriptionOldValue);
          await editor.clear();
        });

        test('accept with Ctrl+Enter', () async {
          await editor.sendKeys(
              '${descriptionNewValue}${Keyboard.control}${Keyboard.enter}');

          if (autoEdit == AutoEdit.disabled) {
            expect(await driver.elementExists(editorSelector), isFalse);
          }

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionNewValue.replaceAll('\n', ' '));
        });

        test('accept with Save', () async {
          await editor.sendKeys(descriptionNewValue);
          final WebElement saveButton = await findSaveButton(driver);
          saveButton.click();

          if (autoEdit == AutoEdit.disabled) {
            expect(await driver.elementExists(editorSelector), isFalse);
          }

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionNewValue.replaceAll('\n', ' '));
        });

        test('cancel with Esc', () async {
          await editor.sendKeys('${descriptionNewValue}${Keyboard.escape}');
          expect(await driver.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text, descriptionOldValueOneLine);
        });

        test('cancel with Cancel', () async {
          await editor.sendKeys(descriptionNewValue);
          final WebElement cancelButton = await findCancelButton(driver);
          cancelButton.click();
          expect(await driver.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text, descriptionOldValueOneLine);
        });
      } /*, skip: 'temporary'*/);

      group('duration', () {
        const String durationOldValue = '5 days';
        const String durationNewValue = '25 days';
        const By editorSelector = const By.cssSelector('input[type="text"]');

        WebElement durationCell;
        WebElement editor;

        setUp(() async {
          final WebElement firstCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          await firstCell.click();
          durationCell =
              await driver.findElement(durationCellActiveRowSelector);
          expect(await durationCell.text, durationOldValue);

          await driver.mouse.moveTo(element: durationCell);
          await driver.mouse.doubleClick();

          editor = await durationCell.findElement(editorSelector);
          expect(await editor.attributes['value'], durationOldValue);
          await editor.clear();
        });

        test('accept with enter', () async {
          await editor.sendKeys('${durationNewValue}${Keyboard.enter}');
          expect(await durationCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await durationCell.text, durationNewValue);
        });

        test('accept with click on other cell', () async {
          await editor.sendKeys('${durationNewValue}');
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await durationCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await durationCell.text, durationNewValue);
        });

        test('cancel with Esc', () async {
          await editor.sendKeys('${durationNewValue}${Keyboard.escape}');
          expect(await durationCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await durationCell.text, durationOldValue);
        });
      } /*, skip: 'temporary'*/);

      group('percent complete', () {
//        const durationOldValue = '5 days';
        const int percentCompleteNewValue = 66;
        const By editorSelector = const By.cssSelector('input[type="text"]');
        const By editorPickerSelector =
            const By.cssSelector('div.editor-percentcomplete-picker');
        const By editorCompleteButtonSelector = const By.cssSelector(
            'div.editor-percentcomplete-picker div.editor-percentcomplete-buttons button[val="100"]');
        const By percentBarSelector =
            const By.cssSelector('span.percent-complete-bar');

        WebElement percentCompleteCell;
        WebElement editor;
        WebElement firstCell;
        int percentCompleteOldValue;

        setUp(() async {
          firstCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          await firstCell.click();
          percentCompleteCell =
              await driver.findElement(percentCellActiveRowSelector);
          final WebElement bar =
              await percentCompleteCell.findElement(percentBarSelector);
          expect(await bar.attributes['style'], matches(r'width: \d{1,3}%;'));

          await driver.mouse.moveTo(element: percentCompleteCell);
          await driver.mouse.doubleClick();

          editor = await percentCompleteCell.findElement(editorSelector);
          percentCompleteOldValue =
              await int.parse(await editor.attributes['value']);
          expect(percentCompleteOldValue, greaterThanOrEqualTo(0));
          expect(percentCompleteOldValue, lessThanOrEqualTo(100));
        });

        test('edit with picker, accept with clicking on another cell',
            () async {
          final WebElement editorPicker =
              await percentCompleteCell.findElement(editorPickerSelector);
          await driver.mouse.moveTo(element: editorPicker);
          await new Future.delayed(const Duration(milliseconds: 100));
          final WebElement editorCompleteButton = await percentCompleteCell
              .findElement(editorCompleteButtonSelector);
          await editorCompleteButton.click();
          expect(int.parse(await editor.attributes['value']), 100);

          await firstCell.click();
          final WebElement bar =
              await percentCompleteCell.findElement(percentBarSelector);
          expect(await bar.attributes['style'], matches('width: 100%;'));
        });

        test('edit with keyboard, accept with Enter', () async {
          await editor.clear();
          await editor.sendKeys('${percentCompleteNewValue}${Keyboard.enter}');
          expect(
              await percentCompleteCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          final WebElement bar =
              await percentCompleteCell.findElement(percentBarSelector);
          expect(await bar.attributes['style'],
              matches('width: ${percentCompleteNewValue}%;'));
        });

        test('edit with keyboard, accept with click on other cell', () async {
          await editor.clear();
          await editor.sendKeys('${percentCompleteNewValue}');
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(
              await percentCompleteCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          final WebElement bar =
              await percentCompleteCell.findElement(percentBarSelector);
          expect(await bar.attributes['style'],
              matches('width: ${percentCompleteNewValue}%;'));
        });

        test('cancel with Esc', () async {
          await editor.clear();
          await editor.sendKeys('${percentCompleteNewValue}${Keyboard.escape}');
          expect(
              await percentCompleteCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          final WebElement bar =
              await percentCompleteCell.findElement(percentBarSelector);
          expect(await bar.attributes['style'],
              matches('width: ${percentCompleteOldValue}%;'));
        });
      } /*, skip: 'temporary'*/);

      group('start', () {
        final String startOldValue = '2009-01-01';
        final String startNewValue = '2016-08-19';
        final String startNewInput = '08192016';
        const By editorSelector = const By.cssSelector('input[type="date"]');

        WebElement startCell;
        WebElement editor;

        setUp(() async {
          final WebElement firstCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          await firstCell.click();
          startCell = await driver.findElement(startCellActiveRowSelector);
          expect(await startCell.text, startOldValue);

          await driver.mouse.moveTo(element: startCell);
          await driver.mouse.doubleClick();

          editor = await startCell.findElement(editorSelector);
          expect(await editor.attributes['value'], startOldValue);
          //await editor.clear();
        });

        test('accept with enter', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys('${startNewValue}${Keyboard.enter}');
          } else {
            await editor.sendKeys('${startNewInput}${Keyboard.enter}');
          }
          expect(await startCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await startCell.text, startNewValue);
        });

        test('accept with click on other cell', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys(startNewValue);
          } else {
            await editor.sendKeys(startNewInput);
          }
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await startCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await startCell.text, startNewValue);
        });

        test('cancel with Esc', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys('${startNewValue}${Keyboard.escape}');
          } else {
            await editor.sendKeys('${startNewInput}${Keyboard.escape}');
          }
          expect(await startCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await startCell.text, startOldValue);
        });
      } /*, skip: 'temporary'*/);

      group('finish', () {
        final String finishOldValue = '2009-01-05';
        final String finishNewValue = '2016-09-02';
        final String finishNewInput = '09022016';
        const By editorSelector = const By.cssSelector('input[type="date"]');

        WebElement finishCell;
        WebElement editor;

        setUp(() async {
          final WebElement firstCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          await firstCell.click();
          finishCell = await driver.findElement(finishCellActiveRowSelector);
          expect(await finishCell.text, finishOldValue);

          await driver.mouse.moveTo(element: finishCell);
          await driver.mouse.doubleClick();

          editor = await finishCell.findElement(editorSelector);
          expect(await editor.attributes['value'], finishOldValue);
          //await editor.clear();
        });

        test('accept with enter', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys('${finishNewValue}${Keyboard.enter}');
          } else {
            await editor.sendKeys('${finishNewInput}${Keyboard.enter}');
          }
          expect(await finishCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await finishCell.text, finishNewValue);
        });

        test('accept with click on other cell', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys(finishNewValue);
          } else {
            await editor.sendKeys(finishNewInput);
          }
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await finishCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await finishCell.text, finishNewValue);
        });

        test('cancel with Esc', () async {
          if (browser == WebBrowser.firefox) {
            await editor.clear();
            await editor.sendKeys('${finishNewValue}${Keyboard.escape}');
          } else {
            await editor.sendKeys('${finishNewInput}${Keyboard.escape}');
          }
          expect(await finishCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await finishCell.text, finishOldValue);
        });
      } /*, skip: 'temporary'*/);

      group('effort-driven enabled to disabled', () {
        final String effortDrivenOldValue = 'true';
//        final effortDrivenNewValue = null;
        const By editorSelector =
            const By.cssSelector('input[type="checkbox"]');

        WebElement effortDrivenCell;
        WebElement editor;

        setUp(() async {
          final WebElement firstCell =
              await (driver.findElements(firstColumnSelector).skip(5).first);
          await firstCell.click();
          effortDrivenCell =
              await driver.findElement(effortDrivenCellActiveRowSelector);

          expect(effortDrivenCell.findElement(effortDrivenCheckedImageSelector),
              isNotNull);

          await driver.mouse.moveTo(element: effortDrivenCell);
          await driver.mouse.doubleClick();

          editor = await effortDrivenCell.findElement(editorSelector);
          expect(await editor.attributes['checked'], effortDrivenOldValue);
//          driver.execute('arguments[0].focus();', [editor]);
          await editor.click();
          // TODO(zoechi) Firefox might need space instead of click
//          await editor.sendKeys(Keyboard.space);
        });

        test('accept with enter', () async {
          await editor.sendKeys(Keyboard.enter);

          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(
              await effortDrivenCell
                  .elementExists(effortDrivenCheckedImageSelector),
              isFalse);
        });

        test('accept with click on other cell', () async {
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(
              await effortDrivenCell
                  .elementExists(effortDrivenCheckedImageSelector),
              isFalse);
        });

        test('cancel with Esc', () async {
          await editor.sendKeys(Keyboard.escape);
          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(effortDrivenCell.findElement(effortDrivenCheckedImageSelector),
              isNotNull);
        });
      } /*, skip: 'temporary'*/);

      group('effort-driven disabled to enabled', () {
        final String effortDrivenOldValue = null;
//        final effortDrivenNewValue = 'true';
        const By editorSelector =
            const By.cssSelector('input[type="checkbox"]');

        WebElement effortDrivenCell;
        WebElement editor;

        setUp(() async {
          final WebElement firstCell =
              await (driver.findElements(firstColumnSelector).skip(6).first);
          await firstCell.click();
          effortDrivenCell =
              await driver.findElement(effortDrivenCellActiveRowSelector);

          expect(
              await effortDrivenCell
                  .elementExists(effortDrivenCheckedImageSelector),
              isFalse);

          await driver.mouse.moveTo(element: effortDrivenCell);
          await driver.mouse.doubleClick();

          editor = await effortDrivenCell.findElement(editorSelector);
          expect(await editor.attributes['checked'], effortDrivenOldValue);
//          driver.execute('arguments[0].focus();', [editor]);
          await editor.click();
          // TODO(zoechi) Firefox might need space instead of click
//          await editor.sendKeys(Keyboard.space);
        });

        test('accept with enter', () async {
          await editor.sendKeys(Keyboard.enter);

          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(effortDrivenCell.findElement(effortDrivenCheckedImageSelector),
              isNotNull);
        });

        test('accept with click on other cell', () async {
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(effortDrivenCell.findElement(effortDrivenCheckedImageSelector),
              isNotNull);
        });

        test('cancel with Esc', () async {
          await editor.sendKeys(Keyboard.escape);
          expect(await effortDrivenCell.elementExists(editorSelector), isFalse);

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(
              await effortDrivenCell
                  .elementExists(effortDrivenCheckedImageSelector),
              isFalse);
        });
      } /*, skip: 'temporary'*/);
    } /*, skip: 'temporary'*/);
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

const By buttonsSelector = const By.cssSelector('body > div > div > button');

Future<WebElement> findSaveButton(wd.WebDriver driver) =>
    findButton(driver, 'Save');
Future<WebElement> findCancelButton(wd.WebDriver driver) =>
    findButton(driver, 'Cancel');

/// Find the buttons in the multiline text editor.
Future<WebElement> findButton(ExtendedWebDriver driver, String text) async {
  return driver
      .findElements(buttonsSelector)
      .asyncMap((wd.WebElement e) async => <String,dynamic>{'button': e, 'text': await e.text})
      .where((Map m) => m['text'] == text)
      .map/*<String>*/((Map m) => m['button'] as String)
      .first as WebElement;
}
