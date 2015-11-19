@Timeout(const Duration(minutes: 5))

//import 'dart:async' show Future, Stream;
import 'package:test/test.dart';

// TODO comment in when it's settled how to set up WebDriver tests
dynamic main() async {
//  DriverFactory wdFactory = createDriverFactory();
//  await wdFactory.startFactory();

  group('x', () {
//    WebDriver driver;
//    PubServe pubServe;
//    int finishedTests;

    setUp(() async {
//      if(pubServe == null) {
//        print('setUp');
//        pubServe = new PubServe();
//        await pubServe.start(directories: const ['example']);
//        driver = await wdFactory.createDriver();
//        print('driver = $driver');
//      }
    });

    tearDown(() async {
//      finishedTests++;
//      //if(finishedTests >= test.length) {
//        print('closing driver ${wdFactory}');
//        await driver.quit();
//
//        print('closing server');
//        pubServe.stop();
//        return wdFactory.stopFactory();
      //}
    });

    test('', () async {
//      final examplePubServePort = pubServe.directoryPorts['example'];
//      final url = 'http://localhost:${examplePubServePort}/e01_simple.html';
//      print('get: ${url}');
//      await driver.get(url);
//      await new Future.delayed(new Duration(seconds: 1), () {});
//      String title = await driver.title;
//      print('title: $title');
//      expect(title, startsWith('BWU Datagrid example 01: Basic grid'));
    }, timeout: const Timeout(const Duration(minutes: 5)));
  });
}
