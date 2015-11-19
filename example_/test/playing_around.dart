import 'package:webdriver/io.dart';
import 'dart:async';

main() async {
  WebDriver driver;
  try {
    driver = await createDriver(
        uri: Uri.parse('http://localhost:4444/wd/hub/'),
        desired: {
          'browserName': 'chrome',
          'platform': 'ANY',
          'version': '',
          'chromeOptions': {'androidPackage': 'com.android.chrome'}
        });

//        desired: {'browserName': 'MicrosoftEdge'});
//        desired: {'browserName': 'internet explorer', 'initialBrowserUrl': 'about:blank'});

//    await driver.switchTo.window(await driver.windows.last);
    await driver
        .get('http://192.168.2.156:21234/composite_editor_item_details.html');
    await driver
        .get('http://192.168.2.156:21234/composite_editor_item_details.html');

//        .get('http://www.google.com');
    print(driver.capabilities);
    await new Future.delayed(const Duration(milliseconds: 6000));
//    var x = await driver.pageSource;
    print('a');
    var element;

    while (element == null) {
      try {
        element = await driver.findElement(new By.cssSelector('script'));
      } on NoSuchWindowException catch (_) {
        await new Future.delayed(const Duration(milliseconds: 50));
      } on NoSuchElementException catch (_) {
        await new Future.delayed(const Duration(milliseconds: 50));
      } catch (e, s) {
        print('x');
        print(e);
        print(s);
      }
    }
    print('found');
    var ele = await driver.findElement(new By.cssSelector('* /deep/  #myGrid'));
    await ele.click();
  } catch (e, s) {
    print(e);
    print(s);
  } finally {
    print('y');
    driver.close();
    await driver.quit();
  }
}

// worked
//WebDriver driver = await createDriver(
//    uri: Uri.parse('http://localhost:4444/wd/hub/'), desired:
//     {'browserName': 'chrome', 'platform': 'ANY', 'version': '', 'chromeOptions': {
//        'androidPackage': 'com.android.chrome'}}
//);

// prefs
//desired: Capabilities.chrome
//  ..['chromeOptions'] = {'androidPackage': 'com.android.chrome'}..['prefs'] = {'discover_usb_devices': true});
