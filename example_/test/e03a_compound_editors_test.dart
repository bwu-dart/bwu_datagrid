@TestOn('vm')
library bwu_datagrid_examples.test.e03a_compound_editors_test;

import 'dart:async' show Future, Stream;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart' show Keyboard;
import 'common.dart';

const pageUrl = '${server}/e03a_compound_editors.html';

main() {
  group('Chrome,',
      () => testsWithBrowser(WebBrowser.chrome) /*, skip: 'temporary'*/);
  group('Firefox,', () => testsWithBrowser(WebBrowser.firefox),
      skip: 'blocked by FirefoxDriver issue - s');
  group('Edge,', () => testsWithBrowser(WebBrowser.edge),
      skip: 'blocked by FirefoxDriver issue - s');
  group('IE,', () => testsWithBrowser(WebBrowser.ie),
      skip: 'blocked by FirefoxDriver issue - s');

// https://github.com/SeleniumHQ/selenium/issues/939
// https://github.com/SeleniumHQ/selenium/issues/940
}

// TODO(zoechi)
// - accept with tab

void testsWithBrowser(WebBrowser browser) {
  group('e03a_compound_editors,', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.close();
    });

    group('range', () {
//      const titleOldValue = 'Task 7';
      const rangeNewValues = const [37, 70];
      const editorsSelector = const By.cssSelector('input[type="text"]');
      List<int> rangeOldValues;

      WebElement titleCell;
      WebElement rangeCell;
      List<WebElement> editors;

      setUp(() async {
        titleCell =
            await (driver.findElements(firstColumnSelector).skip(5).first);
        titleCell.click();
        rangeCell = await driver.findElement(rangeCellActiveRowSelector);
        rangeOldValues = (await rangeCell.text)
            .split('-')
            .map((t) => int.parse(t.trim()))
            .toList();
        expect(rangeOldValues[0], (e) => e >= 0 && e < 100);
        expect(rangeOldValues[1], (e) => e >= 0 && e < 200);

        await driver.mouse.moveTo(element: rangeCell);
        await driver.mouse.doubleClick();

        editors = await rangeCell.findElements(editorsSelector).toList();
        expect(
            int.parse(await editors[0].attributes['value']), rangeOldValues[0]);
        expect(
            int.parse(await editors[1].attributes['value']), rangeOldValues[1]);
        for (final e in editors) {
          e.clear();
        }
      });

      test('accept with enter', () async {
        await editors[0].sendKeys('${rangeNewValues[0]}${Keyboard.tab}');
        await editors[1].sendKeys('${rangeNewValues[1]}${Keyboard.enter}');
        expect(await rangeCell.elementExists(editorsSelector), isFalse);

        await new Future.delayed(const Duration(milliseconds: 10));
        expect(
            (await rangeCell.text)
                .split('-')
                .map((t) => int.parse(t.trim()))
                .toList(),
            orderedEquals(rangeNewValues));
      } /*, skip: 'temporary'*/);

      test('accept with click on other cell', () async {
        await editors[0].sendKeys('${rangeNewValues[0]}');
        await editors[1].click();
        await editors[1].sendKeys('${rangeNewValues[1]}');
        await titleCell.click();

        await new Future.delayed(const Duration(milliseconds: 10));
        expect(
            (await rangeCell.text)
                .split('-')
                .map((t) => int.parse(t.trim()))
                .toList(),
            orderedEquals(rangeNewValues));
      } /*, skip: 'temporary'*/);

      test('cancel with Esc', () async {
        await editors[0].sendKeys('${rangeNewValues[0]}${Keyboard.tab}');
        await editors[1].sendKeys('${rangeNewValues[1]}${Keyboard.escape}');
        expect(await titleCell.elementExists(editorsSelector), isFalse);

        await new Future.delayed(const Duration(milliseconds: 10));
        expect(
            (await rangeCell.text)
                .split('-')
                .map((t) => int.parse(t.trim()))
                .toList(),
            orderedEquals(rangeOldValues));
      });
    } /*, skip: 'temporary'*/);
  }, timeout: const Timeout(const Duration(seconds: 180)));
}
