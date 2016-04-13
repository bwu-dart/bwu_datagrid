@TestOn('vm')
library bwu_datagrid_examples.test.e03b_editing_with_undo_test;

import 'dart:async' show Future;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart' show Keyboard;
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/e03b_editing_with_undo.html';
  forEachBrowser(tests);
}

// TODO(zoechi)
// - accept with tab

void tests(WebBrowser browser) {
  group('e03b_editing_with_undo,', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    test('undo', () async {
      const By textEditorSelector = const By.cssSelector('input[type="text"]');
      const By dateEditorSelector = const By.cssSelector('input[type="date"]');
      const By checkboxEditorSelector =
          const By.cssSelector('input[type="checkbox"]');
      const By undoButtonSelector =
          const By.cssSelector('app-element::shadow .options-panel button');

      // prepare undo
      final WebElement undoButton =
          await driver.findElement(undoButtonSelector);
      expect(await undoButton.enabled, isFalse,
          reason: 'undo button should be disabled when no call was edited yet');

      // prepare scroll
      WebElement viewPort = await driver.findElement(viewPortSelector);
      expect(viewPort, isNotNull);
      final int maxYScroll =
          int.parse(await viewPort.attributes['scrollHeight']);
      expect(maxYScroll, greaterThan(12000));

      // title
      const int titleScrollTop = 0;
      const String titleTaskTitle = 'Task 12';
      await selectRowByTask(driver, titleTaskTitle, scrollTop: titleScrollTop);
      WebElement titleCell =
          await driver.findElement(titleCellActiveRowSelector);
      final String titleOldValue = await titleCell.text;

      await driver.mouse.moveTo(element: titleCell);
      await driver.mouse.doubleClick();

      final WebElement titleEditor =
          await titleCell.findElement(textEditorSelector);
      await titleEditor.clear();
      final String titleNewValue = 'New title';
      await titleEditor.sendKeys('${titleNewValue}${Keyboard.enter}');
      expect(await titleCell.elementExists(textEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(await titleCell.text, titleNewValue);

      expect(await undoButton.enabled, isTrue,
          reason:
              'undo button should be enabled after a cell value was changed');

      // description
      const int descriptionScrollTop = 0;
      const String descriptionTaskTitle = 'Task 3';
      await selectRowByTask(driver, descriptionTaskTitle,
          scrollTop: descriptionScrollTop);
      WebElement descriptionCell =
          await driver.findElement(descriptionCellActiveRowSelector);
      final String descriptionOldValue = await descriptionCell.text;
      const String descriptionNewValue =
          'Some other description\nwhich can also be multiline';
      await driver.mouse.moveTo(element: descriptionCell);
      await driver.mouse.doubleClick();
      const By descriptionEditorSelector =
          const By.cssSelector('body > div > textarea');
      final WebElement descriptionEditor =
          await driver.findElement(descriptionEditorSelector);
      await descriptionEditor.clear();
      await descriptionEditor.sendKeys(
          '${descriptionNewValue}${Keyboard.control}${Keyboard.enter}');
      expect(await driver.elementExists(descriptionEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(await descriptionCell.text,
          descriptionNewValue.replaceAll('\n', ' '));

      // duration'
      const int durationScrollTop = 0;
      const String durationTaskTitle = 'Task 8';
      await selectRowByTask(driver, durationTaskTitle,
          scrollTop: durationScrollTop);
      WebElement durationCell =
          await driver.findElement(durationCellActiveRowSelector);
      final String durationOldValue = await durationCell.text;
      await driver.mouse.moveTo(element: durationCell);
      await driver.mouse.doubleClick();
      final WebElement durationEditor =
          await durationCell.findElement(textEditorSelector);
      await durationEditor.clear();
      const String durationNewValue = '25 days';
      await durationEditor.sendKeys('${durationNewValue}${Keyboard.enter}');
      expect(await durationCell.elementExists(textEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(await durationCell.text, durationNewValue);

      //percent complete
      final int percentCompleteScrollTop = maxYScroll ~/ 2;
      const String percentCompleteTaskTitle = 'Task 250';
      await selectRowByTask(driver, percentCompleteTaskTitle,
          scrollTop: percentCompleteScrollTop);
      WebElement percentCompleteCell =
          await driver.findElement(percentCellActiveRowSelector);
      const By percentBarSelector =
          const By.cssSelector('span.percent-complete-bar');
      WebElement bar =
          await percentCompleteCell.findElement(percentBarSelector);
      final String percentCompleteOldValue = await bar.attributes['style'];
      await driver.mouse.moveTo(element: percentCompleteCell);
      await driver.mouse.doubleClick();
      final WebElement percentCompleteEditor =
          await percentCompleteCell.findElement(textEditorSelector);
      await percentCompleteEditor.clear();
      const String percentCompleteNewValue = '66';
      await percentCompleteEditor
          .sendKeys('${percentCompleteNewValue}${Keyboard.enter}');
      expect(
          await percentCompleteCell.elementExists(textEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      bar = await percentCompleteCell.findElement(percentBarSelector);
      expect(await bar.attributes['style'],
          matches('width: ${percentCompleteNewValue}%;'));

      // start
      final int startScrollTop = maxYScroll ~/ 2;
      const String startTaskTitle = 'Task 260';
      await selectRowByTask(driver, startTaskTitle, scrollTop: startScrollTop);
      WebElement startCell =
          await driver.findElement(startCellActiveRowSelector);
      final String startOldValue = await startCell.text;
      await driver.mouse.moveTo(element: startCell);
      await driver.mouse.doubleClick();
      final String startNewValue = '2016-08-19';
      final String startNewInput = '08192016';
      final WebElement startEditor =
          await startCell.findElement(dateEditorSelector);
      await startEditor.sendKeys('${startNewInput}${Keyboard.enter}');
      expect(await startCell.elementExists(dateEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(await startCell.text, startNewValue);

      // finish
      final int finishScrollTop = maxYScroll ~/ 4;
      const String finishTaskTitle = 'Task 127';
      await selectRowByTask(driver, finishTaskTitle,
          scrollTop: finishScrollTop);
      WebElement finishCell =
          await driver.findElement(finishCellActiveRowSelector);
      final String finishOldValue = await finishCell.text;
      await driver.mouse.moveTo(element: finishCell);
      await driver.mouse.doubleClick();
      final String finishNewValue = '2016-09-02';
      final String finishNewInput = '09022016';
      final WebElement finishEditor =
          await finishCell.findElement(dateEditorSelector);
      await finishEditor.sendKeys('${finishNewInput}${Keyboard.enter}');
      expect(await finishCell.elementExists(dateEditorSelector), isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(await finishCell.text, finishNewValue);

      // effort-driven
      const int effortDrivenScrollTop = 0;
      const String effortDrivenTaskTitle = 'Task 132';
      await selectRowByTask(driver, effortDrivenTaskTitle,
          scrollTop: effortDrivenScrollTop);
      WebElement effortDrivenCell =
          await driver.findElement(effortDrivenCellActiveRowSelector);
      final bool effortDrivenOldValue = await effortDrivenCell
          .elementExists(effortDrivenCheckedImageSelector);
      await driver.mouse.moveTo(element: effortDrivenCell);
      await driver.mouse.doubleClick();
      final WebElement effortDrivenEditor =
          await effortDrivenCell.findElement(checkboxEditorSelector);
      await effortDrivenEditor.click();
      await effortDrivenEditor.sendKeys(Keyboard.enter);
      expect(await effortDrivenCell.elementExists(checkboxEditorSelector),
          isFalse);
      await new Future<Null>.delayed(const Duration(milliseconds: 10));
      expect(
          await effortDrivenCell
              .elementExists(effortDrivenCheckedImageSelector),
          !effortDrivenOldValue);

      // exercise
      int undoCount = 0;
      while (await undoButton.enabled) {
        await undoButton.click();
        undoCount++;
      }
      expect(undoCount, 7,
          reason: '7 cells were changed, 7 should have been undone');

      await selectRowByTask(driver, titleTaskTitle, scrollTop: titleScrollTop);
      titleCell = await driver.findElement(titleCellActiveRowSelector);
      expect(await titleCell.text, titleOldValue);

      await selectRowByTask(driver, descriptionTaskTitle,
          scrollTop: descriptionScrollTop);
      descriptionCell =
          await driver.findElement(descriptionCellActiveRowSelector);
      expect(await descriptionCell.text, descriptionOldValue);

      await selectRowByTask(driver, durationTaskTitle,
          scrollTop: durationScrollTop);
      durationCell = await driver.findElement(durationCellActiveRowSelector);
      expect(await durationCell.text, durationOldValue);

      await selectRowByTask(driver, percentCompleteTaskTitle,
          scrollTop: percentCompleteScrollTop);
      percentCompleteCell =
          await driver.findElement(percentCellActiveRowSelector);
      bar = await percentCompleteCell.findElement(percentBarSelector);
      expect(await bar.attributes['style'], percentCompleteOldValue);

      await selectRowByTask(driver, startTaskTitle, scrollTop: startScrollTop);
      startCell = await driver.findElement(startCellActiveRowSelector);
      expect(await startCell.text, startOldValue);

      await selectRowByTask(driver, finishTaskTitle,
          scrollTop: finishScrollTop);
      finishCell = await driver.findElement(finishCellActiveRowSelector);
      expect(await finishCell.text, finishOldValue);

      await selectRowByTask(driver, effortDrivenTaskTitle,
          scrollTop: effortDrivenScrollTop);
      effortDrivenCell =
          await driver.findElement(effortDrivenCellActiveRowSelector);
      expect(
          await effortDrivenCell
              .elementExists(effortDrivenCheckedImageSelector),
          effortDrivenOldValue);
    } /*, skip: 'temporary'*/);
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

Future<Null> selectRowByTask(ExtendedWebDriver driver, String taskTitle,
    {int scrollTop}) async {
  if (scrollTop != null) {
    WebElement viewPort = await driver.findElement(viewPortSelector);
    await driver.scrollElementAbsolute(viewPort, y: scrollTop);
    await new Future<Null>.delayed(const Duration(milliseconds: 100));
  }

  final List<WebElement> cells = await (await driver
          .findElements(firstColumnSelector)
          .asyncMap(
              (WebElement e) async => {'element': e, 'text': await e.text})
          .where((Map<dynamic, dynamic> item) => item['text'] == taskTitle))
      .map((Map<dynamic, dynamic> item) => item['element'])
      .toList() as List<WebElement>;
  if (cells.length == 0) {
    throw 'No row with title "${taskTitle}" found.';
  } else if (cells.length > 1) {
    throw '${cells.length} rows with title "${taskTitle}" found.';
  }
  await cells.first.click();
}
