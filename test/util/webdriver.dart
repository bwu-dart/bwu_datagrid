library bwu_datagrid.test.util.webdriver;

import 'dart:io' as io;
import 'dart:async' show Completer, Future, Stream;
import 'dart:convert' show Utf8Decoder, UTF8, Utf8Codec, LineSplitter;
import 'dart:collection' show UnmodifiableMapView;
import 'package:webdriver/webdriver.dart';
export 'package:webdriver/webdriver.dart';
import 'package:which/which.dart';
import 'package:bwu_utils/testing_server.dart' as util;

class PubServe {
  io.Process _process;
  io.Process get process => _process;

  int _port;
  final _directoryPorts = <String,int>{};
  Map<String,int> get directoryPorts => new UnmodifiableMapView( _directoryPorts);
  final _servingMessageRegex = new RegExp(r'^Serving [0-9a-zA-Z_]+ ([0-9a-zA-Z_]+) +on https?://.*:(\d{4,5})$');

  Future<io.Process> start({int port, directories: const ['test']}) async {
    final readyCompleter = new Completer<io.Process>();
    if (process != null) {
      return process;
    }
    if(port != null && port > 0) {
      _port = port;
    } else {
      _port = await util.getNextFreeIpPort();
    }
    if(directories == null || directories.isEmpty) {
      directories = ['test'];
    }
    directories.forEach((d) => _directoryPorts[d] = null);
    String packageRoot = util.packageRoot().path;
    _process = await io.Process.start(
        'pub', ['serve', '--port=${_port}']..addAll(directories),
        workingDirectory: packageRoot);
    process.exitCode.then((exitCode) {
      _process = null;
      _port = null;
    });
    print('pub serve is serving on port "${_port}".');
    process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((s) {
      print(s);
      final match = _servingMessageRegex.firstMatch(s);
      if(match != null) {
        _directoryPorts[match.group(1)] = int.parse(match.group(2));
      }
      if(!readyCompleter.isCompleted && !_directoryPorts.values.contains(null)) {
        readyCompleter.complete(process);
      }
    });
    process.stderr.transform(UTF8.decoder).listen(print);
    return readyCompleter.future;
  }

  bool stop() {
    if(process != null) {
      return process.kill(io.ProcessSignal.SIGTERM);
    }
    return false;
  }
}

DriverFactory createDriverFactory() {
  List<DriverFactory> factories = [
    new SauceLabsDriverFactory(),
    new ChromeDriverFactory(),
    new PhantomJSDriverFactory(),
  ];

  DriverFactory factory;

  for (DriverFactory f in factories) {
    if (f.isAvailable) {
      factory = f;
      break;
    }
  }

  if (factory == null) {
    print('No webdriver candidates found.');
    print('Either set up the env. variables for using saucelabs, or install '
        'chromedriver or phantomjs.');
    io.exit(1);
  }
  return factory;
}

abstract class DriverFactory {
  final String name;

  DriverFactory(this.name);

  bool get isAvailable;

  Future startFactory();
  Future stopFactory();

  Future<WebDriver> createDriver();

  String toString() => name;
}

class SauceLabsDriverFactory extends DriverFactory {
  SauceLabsDriverFactory() : super('saucelabs');

  bool get isAvailable => false;

  Future startFactory() => new Future.value();
  Future stopFactory() => new Future.value();

  Future<WebDriver> createDriver() => new Future.error('not implemented');
}

class PhantomJSDriverFactory extends DriverFactory {
  io.Process _process;

  PhantomJSDriverFactory() : super('phantomjs');

  bool get isAvailable => whichSync('phantomjs', orElse: () => null) != null;

  Future startFactory() {
    return io.Process.start('phantomjs', ['--webdriver=9515']).then((p) {
      _process = p;
      return new Future.delayed(new Duration(seconds: 1));
    });
  }

  Future stopFactory() {
    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  Future<WebDriver> createDriver() {
    return WebDriver.createDriver(
        uri: Uri.parse('http://127.0.0.1:9515/wd'),
        desiredCapabilities: Capabilities.chrome);
  }
}

class ChromeDriverFactory extends DriverFactory {
  io.Process _process;

  ChromeDriverFactory() : super('chromedriver');

  bool get isAvailable => whichSync('chromedriver', orElse: () => null) != null;

  Future startFactory() {
    print('starting chromedriver');

    return io.Process.start('chromedriver', []).then((p) {
      _process = p;
      return new Future.delayed(new Duration(seconds: 1));
    });
  }

  Future stopFactory() {
    print('stopping chromedriver');

    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  Future<WebDriver> createDriver() {
    Map capabilities = Capabilities.chrome;
    Map env = io.Platform.environment;
    Map chromeOptions = {};

    if (env['CHROMEDRIVER_BINARY'] != null) {
      chromeOptions['binary'] = env['CHROMEDRIVER_BINARY'];
    }
    if (env['CHROMEDRIVER_ARGS'] != null) {
      chromeOptions['args'] = env['CHROMEDRIVER_ARGS'].split(' ');
    }
    if (chromeOptions.isNotEmpty) {
      capabilities['chromeOptions'] = chromeOptions;
    }

    return WebDriver.createDriver(
        uri: Uri.parse('http://127.0.0.1:9515/wd'),
        desiredCapabilities: capabilities);
  }
}
