@TestOn('vm')
library bwu_datagrid_examples.test.e03_editing_test;

import 'dart:async' show Future, Stream;
//import 'dart:math' show Point, Rectangle;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'common.dart';

const pageUrl = '${server}/e03_editing.html';

main() {
  group('Chrome', () => tests(WebBrowser.chrome));
  group('Firefox', () => tests(WebBrowser.firefox),
      skip: 'blocked by FirefoxDriver issue - s');
// https://github.com/SeleniumHQ/selenium/issues/939
// https://github.com/SeleniumHQ/selenium/issues/940
}

tests(WebBrowser browser) {
  group('e03_editing', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver.close();
    });

    group('auto-edit off', () {
      group('title', () {
        const titleOldValue = 'Task 7';
        const titleNewValue = 'New Title';
        const editorSelector = const By.cssSelector('input[type="text"]');

        WebElement titleCell;
        WebElement editor;

        setUp(() async {
          titleCell =
              await (driver.findElements(firstColumnSelector).skip(7).first);
          expect(await titleCell.text, titleOldValue);

          await driver.mouse.moveTo(element: titleCell);
          await driver.mouse.doubleClick();

          editor = await titleCell.findElement(editorSelector);
          expect(await editor.attributes['value'], titleOldValue);
          editor.clear();
        });

        test('accept with enter', () async {
          editor.sendKeys('${titleNewValue}${Keyboard.enter}');
          expect(titleCell.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleNewValue);
        }, skip: 'temporary');

        test('accept with click on other cell', () async {
          editor.sendKeys('${titleNewValue}');
          (await driver.findElement(descriptionCellActiveRowSelector)).click();
          expect(titleCell.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleNewValue);
        }, skip: 'temporary');

        test('cancel with Esc', () async {
          editor.sendKeys('${titleNewValue}${Keyboard.escape}');
          expect(titleCell.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await titleCell.text, titleOldValue);
        }, skip: 'temporary');
      });

      group('description', () {
        const descriptionOldValue =
            'This is a sample task description.\n  It can be multiline';
        final descriptionOldValueOneLine =
        descriptionOldValue.replaceAll('\n', ' ').replaceAll('  ', ' ').replaceAll('  ', ' ');

        const descriptionNewValue =
            'Some other description\nwhich can also be multiline';
        const editorSelector = const By.cssSelector('body > div > textarea');

        WebElement editor;
        WebElement titleCell;
        WebElement descriptionCell;

        setUp(() async {
          titleCell =
              await (driver.findElements(firstColumnSelector).skip(9).first);
          await titleCell.click();

          descriptionCell =
              await driver.findElement(descriptionCellActiveRowSelector);
          expect(await descriptionCell.text,
              descriptionOldValueOneLine);
          await driver.mouse.moveTo(element: descriptionCell);
          await driver.mouse.doubleClick();

          editor = await driver.findElement(editorSelector);
          expect(await editor.attributes['value'], descriptionOldValue);
          editor.clear();
        });

        test('accept with Ctrl+Enter', () async {
          editor.sendKeys(
              '${descriptionNewValue}${Keyboard.control}${Keyboard.enter}');
          expect(driver.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionNewValue.replaceAll('\n', ' '));
        }, skip: 'temporary');

        test('accept with Save', () async {
          editor.sendKeys(descriptionNewValue);
          final WebElement saveButton = await findSaveButton(driver);
          saveButton.click();
          expect(driver.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionNewValue.replaceAll('\n', ' '));
        });

        test('cancel with Esc', () async {
          editor.sendKeys('${descriptionNewValue}${Keyboard.escape}');
          expect(driver.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionOldValueOneLine);
        });

        test('cancel with Cancel', () async {
          editor.sendKeys(descriptionNewValue);
          final WebElement cancelButton = await findCancelButton(driver);
          cancelButton.click();
          expect(driver.findElement(editorSelector),
              throwsA(new isInstanceOf<NoSuchElementException>()));

          await new Future.delayed(const Duration(milliseconds: 10));
          expect(await descriptionCell.text,
              descriptionOldValueOneLine);
        });
      });
    });
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

const buttonsSelector = const By.cssSelector('body > div > div > button');

Future<WebElement> findSaveButton(WebDriver driver) =>
    findButton(driver, 'Save');
Future<WebElement> findCancelButton(WebDriver driver) =>
    findButton(driver, 'Cancel');

Future<WebElement> findButton(WebDriver driver, String text) async {
  return driver
      .findElements(buttonsSelector)
      .asyncMap((e) async => {'button': e, 'text': await e.text})
      .where((m) => m['text'] == text)
      .map((m) => m['button'])
      .first;
}
