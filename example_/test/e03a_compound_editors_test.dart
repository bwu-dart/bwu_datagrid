@TestOn('vm')
library bwu_datagrid_examples.test.e03a_compound_editors_test;

import 'dart:async' show Future, Stream;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart' show Keyboard;
import 'common.dart';

String pageUrl;

dynamic main() async {
  pageUrl = '${await webServer}/e03a_compound_editors.html';
  forEachBrowser(tests);
//  tests(WebBrowser.chrome);
}

// TODO(zoechi)
// - accept with tab

void tests(WebBrowser browser) {
  group('e03a_compound_editors,', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver?.quit();
    });

    group('range', () {
//      const titleOldValue = 'Task 7';
      const List<int> rangeNewValues = const [37, 70];
      const By editorsSelector = const By.cssSelector('input[type="text"]');
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
            .map/*<int>*/((String t) => int.parse(t.trim()))
            .toList();
        expect(rangeOldValues[0], (int e) => e >= 0 && e < 100);
        expect(rangeOldValues[1], (int e) => e >= 0 && e < 200);

        await driver.mouse.moveTo(element: rangeCell);
        await driver.mouse.doubleClick();

        editors = await rangeCell.findElements(editorsSelector).toList();
        expect(
            int.parse(await editors[0].attributes['value']), rangeOldValues[0]);
        expect(
            int.parse(await editors[1].attributes['value']), rangeOldValues[1]);
        for (final WebElement e in editors) {
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
                .map((String t) => int.parse(t.trim()))
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
                .map /*<String>*/ ((String t) => int.parse(t.trim()))
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
                .map((String t) => int.parse(t.trim()))
                .toList(),
            orderedEquals(rangeOldValues));
      });
    } /*, skip: 'temporary'*/);
  }, timeout: const Timeout(const Duration(seconds: 180)));
}
