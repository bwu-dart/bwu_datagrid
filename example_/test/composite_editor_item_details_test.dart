@TestOn('vm')
library bwu_datagrid_examples.test.autotooltips_test;

import 'dart:async' show Future, Stream;
//import 'dart:math' show Point, Rectangle;

import 'package:bwu_webdriver/bwu_webdriver.dart';
import 'package:test/test.dart';
import 'package:webdriver/io.dart';
import 'common.dart';

//class ByCss implements By {
//  static const _using = 'css selector';
//  final String _value;
//  final Browser browser;
//
//  const ByCss(this._value, this.browser);
//
//  @override
//  Map<String, String> toJson() {
//    if (browser == Browser.chrome || browser == Browser.firefox) {
//      return {'using': _using, 'value': _value};
//    } else {
//      return {
//        'using': _using,
//        'value': _value.replaceAll(' /deep/ ', ' ').replaceAll('::shadow', ' >')
//      };
//    }
//  }
//}

const pageUrl = '${server}/composite_editor_item_details.html';

const openEditDialogButtonSelector =
    const By.cssSelector('app-element::shadow .options-panel button');
const dialogTitleFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="title"] input');
const dialogDescriptionFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="desc"] input');
const dialogDurationFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="duration"] input');
const dialogPercentFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="percent"] input');
const dialogStartFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="start"] input');
const dialogFinishFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="finish"] input');
const dialogEffortDrivenFieldSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form [data-editorid="effort-driven"] input');

const dialogSaveButtonSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form button[data-action="save"]');
const dialogCancelButtonSelector = const By.cssSelector(
    'composite-editor-view::shadow div.item-details-form button[data-action="cancel"]');

const titleOldValue = 'Task 3';
const titleNewValue = 'replacement title';
const descriptionOldValue =
    'This is a sample task description.  It can be multiline';
const descriptionNewValue = 'replacement description.';
const durationOldValue = '5 days';
const durationNewValue = 'replacement duration.';
const percentNewValue = '76';
const startOldValue = '2009-01-01';
const startInsertValue = '07/11/2015';
const startNewValue = '2015-07-11';
const finishOldValue = '2009-01-05';
const finishInsertValue = '12/11/2015';
const finishNewValue = '2015-12-11';
const effortDrivenOldValue = null;

main() {
  group('Chrome', () => tests(WebBrowser.chrome));
  group('Firefox', () => tests(WebBrowser.firefox),
      skip: 'blocked by FirefoxDriver issue - s');
  // https://github.com/SeleniumHQ/selenium/issues/939
  // https://github.com/SeleniumHQ/selenium/issues/940
}

tests(WebBrowser browser) {
  group('composite_editor_item_details', () {
    ExtendedWebDriver driver;
    setUp(() async {
      driver = await commonSetUp(pageUrl, browser);
    });

    tearDown(() {
      return driver.close();
    });

    test('edit and save', () async {
      await editRow(driver);

      WebElement saveButton =
          await driver.findElement(dialogSaveButtonSelector);
      expect(saveButton, isNotNull);
      await saveButton.click();

      // verify
      expect(await (await driver.findElement(titleCellActiveRowSelector)).text,
          titleNewValue);
      expect(
          await (await driver.findElement(descriptionCellActiveRowSelector))
              .text,
          descriptionNewValue);
      expect(
          await (await driver.findElement(durationCellActiveRowSelector)).text,
          durationNewValue);
      expect(
          await (await driver.findElement(
              percentCellActiveRowPercentBarSelector)).attributes['style'],
          contains('width: ${percentNewValue}%'));

      // TODO(zoechi) shouldn't be browser dependent. Needs a common
      // date lookup to fix though
      if (browser == Browser.firefox) {
        expect(
            await (await driver.findElement(startCellActiveRowSelector)).text,
            startInsertValue);
      } else {
        expect(
            await (await driver.findElement(startCellActiveRowSelector)).text,
            startNewValue);
      }
      // TODO(zoechi) shouldn't be browser dependent. Needs a common
      // date lookup to fix though
      if (browser == Browser.firefox) {
        expect(
            await (await driver.findElement(finishCellActiveRowSelector)).text,
            finishInsertValue);
      } else {
        expect(
            await (await driver.findElement(finishCellActiveRowSelector)).text,
            finishNewValue);
      }
      expect(
          await (await driver
              .findElement(effortDrivenCellActiveRowCheckedSelector)),
          isNotNull);

//      await new Future.delayed(const Duration(seconds: 150), () {});
    }, skip: 'temporary');

    test('edit and cancel', () async {
      final String percentOldValue = await (await driver.findElement(
          percentCellActiveRowPercentBarSelector)).attributes['style'];
      await editRow(driver);

      WebElement cancelButton =
          await driver.findElement(dialogCancelButtonSelector);
      expect(cancelButton, isNotNull);
      await cancelButton.click();

      // verify
      expect(await (await driver.findElement(titleCellActiveRowSelector)).text,
          titleOldValue);
      expect(
          await (await driver.findElement(descriptionCellActiveRowSelector))
              .text,
          descriptionOldValue);
      expect(
          await (await driver.findElement(durationCellActiveRowSelector)).text,
          durationOldValue);
      expect(
          await (await driver.findElement(
              percentCellActiveRowPercentBarSelector)).attributes['style'],
          contains('width: ${percentOldValue}%'));

      expect(await (await driver.findElement(startCellActiveRowSelector)).text,
          startOldValue);
      expect(await (await driver.findElement(finishCellActiveRowSelector)).text,
          finishOldValue);
      expect(
          await (await driver
              .findElement(effortDrivenCellActiveRowCheckedSelector)),
          effortDrivenOldValue);

//      await new Future.delayed(const Duration(seconds: 150), () {});
    }, skip: 'temporary');

    test('percent-complete editor with mouse', () async {
      WebElement editButton =
          await driver.findElement(openEditDialogButtonSelector);
      expect(editButton, isNotNull);
      await editButton.click();

      await driver.mouse.moveTo(
          element: await driver.findElement(const By.cssSelector(
              'composite-editor-view::shadow .editor-percentcomplete-picker')));

      final dialogPercentField =
          await driver.findElement(dialogPercentFieldSelector);
      await (await driver.findElement(const By.cssSelector(
              'composite-editor-view::shadow .editor-percentcomplete-picker button[val="0"]')))
          .click();
      expect(await dialogPercentField.attributes['value'], '0');

      await (await driver.findElement(const By.cssSelector(
              'composite-editor-view::shadow .editor-percentcomplete-picker button[val="50"]')))
          .click();
      expect(await dialogPercentField.attributes['value'], '50');

      await (await driver.findElement(const By.cssSelector(
              'composite-editor-view::shadow .editor-percentcomplete-picker button[val="100"]')))
          .click();
      expect(await dialogPercentField.attributes['value'], '100');

      final slider = await driver.findElement(const By.cssSelector(
          'composite-editor-view::shadow .editor-percentcomplete-picker input[type="range"]'));
      final sliderSize = await (slider).size;
      await driver.mouse
          .moveTo(element: slider, xOffset: sliderSize.width ~/ 2, yOffset: 1);
      await driver.mouse.click();
      expect(await dialogPercentField.attributes['value'], '0');

      await driver.mouse.moveTo(
          element: slider,
          xOffset: sliderSize.width ~/ 2,
          yOffset: sliderSize.height ~/ 2);
      await driver.mouse.click();
      expect(await dialogPercentField.attributes['value'], '50');

      await driver.mouse.moveTo(
          element: slider,
          xOffset: sliderSize.width ~/ 2,
          yOffset: sliderSize.height - 1);
      await driver.mouse.click();
      expect(await dialogPercentField.attributes['value'], '100');

      WebElement saveButton =
          await driver.findElement(dialogSaveButtonSelector);
      expect(saveButton, isNotNull);
      await saveButton.click();

      expect(
          await (await driver.findElement(
              percentCellActiveRowPercentBarSelector)).attributes['style'],
          contains('width: 100%'));

//      await new Future.delayed(const Duration(seconds: 150), () {});
    });
  }, timeout: const Timeout(const Duration(seconds: 180)));
}

Future editRow(ExtendedWebDriver driver) async {
  WebElement titleCell =
      await (driver.findElements(firstColumnSelector).skip(3).first);
  expect(await titleCell.text, titleOldValue);
  // make 3rd row active
  await titleCell.click();
  expect(await titleCell.attributes['class'], contains('active'));

  WebElement editButton =
      await driver.findElement(openEditDialogButtonSelector);
  expect(editButton, isNotNull);
  await editButton.click();

  WebElement titleField = await driver.findElement(dialogTitleFieldSelector);
  expect(titleField, isNotNull);
  expect(await titleField.attributes['value'], titleOldValue);
  await titleField.click();
  await titleField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    titleNewValue
  ].join());

  WebElement descriptionField =
      await driver.findElement(dialogDescriptionFieldSelector);
  expect(descriptionField, isNotNull);
  expect(await descriptionField.attributes['value'], descriptionOldValue);
  await descriptionField.click();
  await descriptionField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    descriptionNewValue
  ].join());

  WebElement durationField =
      await driver.findElement(dialogDurationFieldSelector);
  expect(durationField, isNotNull);
  expect(await durationField.attributes['value'], durationOldValue);
  await durationField.click();
  await durationField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    durationNewValue
  ].join());

  WebElement percentField =
      await driver.findElement(dialogPercentFieldSelector);
  expect(percentField, isNotNull);
  int oldValue = int.parse(await percentField.attributes['value']);
  expect(oldValue >= 0 && oldValue <= 100, isTrue);
  await percentField.click();
  await percentField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    percentNewValue
  ].join());

  WebElement startField = await driver.findElement(dialogStartFieldSelector);
  expect(startField, isNotNull);
  expect(await startField.attributes['value'], startOldValue);
  await startField.click();
  await startField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    startInsertValue
  ].join());

  WebElement finishField = await driver.findElement(dialogFinishFieldSelector);
  expect(finishField, isNotNull);
  expect(await finishField.attributes['value'], finishOldValue);
  await finishField.click();
  await finishField.sendKeys([
    Keyboard.end,
    Keyboard.shift,
    Keyboard.home,
    Keyboard.shift,
    finishInsertValue
  ].join());

  WebElement effortDrivenField =
      await driver.findElement(dialogEffortDrivenFieldSelector);
  expect(effortDrivenField, isNotNull);
  expect(await effortDrivenField.attributes['checked'], effortDrivenOldValue);
  await effortDrivenField.click();
  await effortDrivenField.sendKeys([Keyboard.space,].join());
}
