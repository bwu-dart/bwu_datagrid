library bwu_datagrid_examples.tool.grind;

import 'dart:async' show Completer, Future, Stream, StreamTransformer;
import 'dart:collection';
import 'dart:convert' show LineSplitter, UTF8;
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:grinder/grinder.dart';
import 'package:bwu_docker/bwu_docker.dart';
import 'package:bwu_docker/tasks.dart' as task;
import 'package:bwu_utils/bwu_utils_server.dart' as utils;
export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart' hide main;

//const seleniumImageVersion = ':2.47.1';
const String seleniumImageVersion = ':local';

const String _seleniumHubImage = 'selenium/hub${seleniumImageVersion}';
const String _hubContainerName = 'selenium-hub';

//const seleniumChromeImage = 'selenium/node-chrome${seleniumImageVersion}';
const String _seleniumChromeImage =
    'selenium/node-chrome-android-debug${seleniumImageVersion}';

//const seleniumFirefoxImage = 'selenium/node-firefox${seleniumImageVersion}';
const String _seleniumFirefoxImage =
    'selenium/node-firefox-debug${seleniumImageVersion}';

//const webServer = 'webserver:192.168.2.96';
const int pubServePort = 21234;

dynamic main(List<String> args) async {
//  final origTestTask = grinderTasks.testTask;
//  grinderTasks.testTask = (List<String> platforms) async {
  try {
//    await _startSelenium();
//      origTestTask(platforms);
  } finally {
//      await stopSelenium();
  }
//  };
  grind(args);
}

@Task('dummy')
void dummy() {}

DockerConnection _dockerConnection;
CreateResponse _createdHubContainer;
CreateResponse _createdChromeNodeContainer;
CreateResponse _createdFirefoxNodeContainer;
PubServe _pubServe;

@Task('start-selenium')
dynamic startSelenium() => _startSelenium();

@Task('selenium-debug')
Future<Null> seleniumDebug() async {
  io.ProcessSignal.SIGINT.watch().listen((_) => _stopServices());
  io.ProcessSignal.SIGHUP.watch().listen((_) => _stopServices());
  io.ProcessSignal.SIGTERM.watch().listen((_) => _stopServices());
  io.ProcessSignal.SIGUSR1.watch().listen((_) => _stopServices());
  io.ProcessSignal.SIGUSR2.watch().listen((_) => _stopServices());
  io.ProcessSignal.SIGWINCH.watch().listen((_) => _stopServices());

  try {
    _pubServe = new PubServe();
    log('start pub serve');
    _pubServe.start(
        port: pubServePort,
        hostname: '0.0.0.0',
        directories: ['web']).then((_) {
      _pubServe.stdout.listen((List<int> e) => io.stdout.add(e));
      _pubServe.stderr.listen((List<int> e) => io.stderr.add(e));
    });

    await _startSelenium();
    final ContainerInfo chromeInfo = await _dockerConnection
        .container(_createdChromeNodeContainer.container);
    final int chromePort =
        chromeInfo.networkSettings.ports['5900/tcp'][0]['HostPort'];
    print('Chrome: ${chromePort}');
    io.Process.start('vinagre',
        ['--vnc-scale', '--geometry', '1280x1024+200+0', ':${chromePort}']);
//    io.Process.start('krdc', ['vnc://:${chromePort}']);
//    io.Process.start('xvnc4viewer', ['-Shared', ':${chromePort}']);
    final ContainerInfo firefoxInfo = await _dockerConnection
        .container(_createdFirefoxNodeContainer.container);
    final int firefoxPort =
        firefoxInfo.networkSettings.ports['5900/tcp'][0]['HostPort'];
    print('Firefox: ${firefoxPort}');
    await new Future<Null>.delayed(const Duration(seconds: 1));
    io.Process.start('vinagre',
        ['--vnc-scale', '--geometry', '1280x1024+300+0', ':${firefoxPort}']);
//    io.Process.start('krdc', ['vnc://:${firefoxPort}']);
//    io.Process.start('xvnc4viewer', ['-Shared', ':${firefoxPort}']);
  } catch (_) {
    _stopServices();
    rethrow;
  }
}

void _stopServices() {
  _pubServe?.stop();
  if (_dockerConnection != null) {
    _dockerConnection.stop(_createdChromeNodeContainer.container);
    _dockerConnection.stop(_createdFirefoxNodeContainer.container);
    _dockerConnection.stop(_createdHubContainer.container);
  }
}

Future<Null> _startSelenium({bool wait: true}) async {
  final String dockerHostStr =
      io.Platform.environment[dockerHostFromEnvironment];
  assert(dockerHostStr != null && dockerHostStr.isNotEmpty);
//  final dockerHost = Uri.parse(dockerHostStr);

  _dockerConnection = new DockerConnection(
      Uri.parse(io.Platform.environment[dockerHostFromEnvironment]),
      new http.Client());
  await _dockerConnection.init();
  _createdHubContainer = await task.run(_dockerConnection, _seleniumHubImage,
      detach: true,
      name: _hubContainerName,
      publish: const ['4444:4444'],
      rm: wait);
  _createdChromeNodeContainer = await task.run(
      _dockerConnection, _seleniumChromeImage,
      detach: true,
      link: const ['${_hubContainerName}:hub'],
      privileged: true,
      publishAll: true,
      rm: wait,
      volume: const ['/dev/bus/usb:/dev/bus/usb']
//      ,addHost: const [pubServeIp]
      );
  _createdFirefoxNodeContainer = await task.run(
      _dockerConnection, _seleniumFirefoxImage,
      detach: true,
      link: const ['${_hubContainerName}:hub'],
      publishAll: true,
      rm: wait
//      ,addHost: const [pubServeIp]
      );
}

// TODO(zoechi) move to bwu_grinder_tasks when stable
// A copy is still in bwu_utils_dev
class PubServe extends RunProcess {
  int _port;
  final Map<String, int> _directoryPorts = <String, int>{};

  Map<String, int> get directoryPorts =>
      new UnmodifiableMapView<String, int>(_directoryPorts);
  final RegExp _servingMessageRegex = new RegExp(
      r'^Serving [0-9a-zA-Z_]+ ([0-9a-zA-Z_]+) +on https?://.*:(\d{4,5})$');

  Future<io.Process> start(
      {int port,
      List<String> directories: const ['test'],
      String hostname}) async {
    final Completer<io.Process> readyCompleter = new Completer<io.Process>();
    if (port != null && port > 0) {
      _port = port;
    } else {
      _port = await utils.getFreeIpPort();
    }
    if (directories == null || directories.isEmpty) {
      directories = ['test'];
    }
    directories.forEach((String d) => _directoryPorts[d] = null);
    String packageRoot = utils.packageRoot().path;
    //_process = await io.Process.start(
    List<String> args = ['serve', '--port=${_port}'];
    if (hostname != null) {
      args.add('--hostname=${hostname}');
    }
    args.addAll(directories);
    await super._run('pub', args, workingDirectory: packageRoot);
    exitCode.then((int exitCode) {
      _port = null;
    });
    stdout
        .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
        .transform(new LineSplitter())
        .listen((String s) {
      //_log.fine(s);
      print(s);
      final Match match = _servingMessageRegex.firstMatch(s);
      if (match != null) {
        _directoryPorts[match.group(1)] = int.parse(match.group(2));
      }
      if (!readyCompleter.isCompleted &&
          !_directoryPorts.values.contains(null)) {
        readyCompleter.complete(process);
      }
    });
    stderr
        .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
        .listen(print);
    return readyCompleter.future;
  }
}

class RunProcess {
  io.Process _process;

  io.Process get process => _process;

  Stream<List<int>> _stdoutStream;

  Stream<List<int>> get stdout => _stdoutStream;

  Stream<List<int>> _stderrStream;

  Stream<List<int>> get stderr => _stderrStream;

  Future<int> _exitCode;

  Future<int> get exitCode => _exitCode;

  Future<io.Process> _run(String executable, List<String> args,
      {String workingDirectory}) async {
    if (process != null) {
      return process;
    }
    _process = await io.Process
        .start(executable, args, workingDirectory: workingDirectory);
    _exitCode = process.exitCode;
    process.exitCode.then((int exitCode) {
      _process = null;
    });

    _stdoutStream = process.stdout.asBroadcastStream();
    _stderrStream = process.stderr.asBroadcastStream();
    return null;
  }

  bool stop() {
    if (process != null) {
      return process.kill(io.ProcessSignal.SIGTERM);
    }
    return false;
  }
}
