import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';
import 'package:emodebug/emodebug.dart';
import 'package:nodecommander/nodecommander.dart';

import 'command/model.dart';
import 'desktop/host.dart';
import 'http_handlers.dart';

const _ = EmoDebug();

class SoldierNode extends BaseSoldierNode {
  SoldierNode(
      {@required this.name,
      @required this.commands,
      this.host,
      this.port = 8084,
      this.verbose = false}) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (host == null) {
        throw ArgumentError("Please provide a host for the node");
      }
    }
  }

  @override
  String name;
  @override
  String host;
  @override
  int port;
  @override
  bool verbose;
  @override
  List<NodeCommand> commands;

  Future<void> init([String _host]) async {
    var _h = _host;
    _h ??= host;
    _h ??= await getHost();
    await _initSoldierNode(_h);
  }
}

class CommanderNode extends BaseCommanderNode {
  CommanderNode(
      {@required this.name,
      @required this.commands,
      this.host,
      this.port = 8084,
      this.verbose = false}) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (host == null) {
        throw ArgumentError("Please provide a host for the node");
      }
    }
  }

  @override
  String name;
  @override
  String host;
  @override
  int port;
  @override
  bool verbose;
  @override
  List<NodeCommand> commands;

  Future<void> init([String _host]) async {
    var _h = _host;
    _h ??= host;
    _h ??= await getHost();
    await _initCommanderNode(_h);
  }
}

abstract class BaseCommanderNode with BaseNode {
  List<ConnectedSoldierNode> get soldiers => _soldiers;

  Stream<NodeCommand> get commandsResponse => _commandsResponses.stream;

  Future<void> discoverNodes() async => _broadcastForDiscovery();

  Future<void> sendCommand(NodeCommand cmd, String to) => _sendCommand(cmd, to);

  Future<void> _initCommanderNode(String host) async {
    await _initNode(host, false, true);
  }

  bool hasSoldier(String name) {
    var has = false;
    for (final so in _soldiers) {
      if (so.name == name) {
        has = true;
        break;
      }
    }
    return has;
  }

  String soldierUri(String name) {
    String addr;
    for (final so in _soldiers) {
      if (so.name == name) {
        addr = so.address;
        break;
      }
    }
    return addr;
  }
}

abstract class BaseSoldierNode with BaseNode {
  //Stream<NodeCommand> get commandsIn => _commandsExecuted.stream;

  StreamSubscription<NodeCommand> _sub;

  Future<void> respond(NodeCommand cmd) => _sendCommandResponse(cmd);

  Future<void> _initSoldierNode(String host) async {
    await _initNode(host, true, false);
    _sub = _commandsExecuted.stream.listen((c) => respond(c));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

abstract class BaseNode {
  String name;
  String host;
  int port;
  IsoHttpd iso;
  List<NodeCommand> commands;
  bool verbose;

  RawDatagramSocket _socket;
  final Completer<void> _socketReady = Completer<void>();
  final List<ConnectedSoldierNode> _soldiers = <ConnectedSoldierNode>[];
  final Dio _dio = Dio(BaseOptions(connectTimeout: 5000, receiveTimeout: 3000));
  bool _isSoldier;
  bool _isCommander;
  final Completer _readyCompleter = Completer<void>();
  final StreamController<NodeCommand> _commandsExecuted =
      StreamController<NodeCommand>();
  final StreamController<NodeCommand> _commandsResponses =
      StreamController<NodeCommand>.broadcast();
  final StreamController<dynamic> _logs = StreamController<dynamic>.broadcast();

  Future get onReady => _readyCompleter.future;

  NodeCommand _fromAuthorizedCommands(NodeCommand _cmd) {
    final isInternal = internalCommands.contains(_cmd);
    if (isInternal) {
      final _intCmd = internalCommands.where((c) => c == _cmd).toList()[0];
      return _cmd.copyWithExecMethods(
          exec: _intCmd.executor, resp: _intCmd.responseProcessor);
    }
    final knownCmds = commands.where((c) => c == _cmd).toList();
    if (knownCmds.isEmpty) {
      return null;
    }
    final kc = knownCmds[0];
    return _cmd.copyWithExecMethods(
        exec: kc.executor, resp: kc.responseProcessor);
  }

  Future<void> _initNode(String _host, bool isSoldier, bool isCommander) async {
    host = _host;
    _isSoldier = isSoldier;
    _isCommander = isCommander;
    final router = _initRoutes();
    // run isolate
    iso = IsoHttpd(host: host, port: port, router: router);
    await iso.run();
    _listenToIso();
    await iso.onServerStarted;
    await _initForDiscovery();
    if (_isSoldier) {
      await _listenForDiscovery();
    }
    if (verbose) {
      _.ok("Node is ready");
    }
    _readyCompleter.complete();
  }

  Future<void> _sendCommand(NodeCommand cmd, String to) async {
    assert(_isCommander);
    assert(to != null);
    assert(cmd != null);
    if (verbose) {
      _.smallArrowOut("Sending command ${cmd.name} to $to");
      //cmd.info();
    }
    final response = await _sendCommandRun(cmd, to, "/cmd");
    if (response == null || response.statusCode != HttpStatus.ok) {
      final code = response?.statusCode ?? "no response";
      _logs.sink.add("Error sending the command: $code");
    }
  }

  Future<void> _sendCommandResponse(NodeCommand cmd) async {
    assert(_isSoldier);
    assert(cmd.from != null);
    //print("CMD FROM ${cmd.from}");
    final _cmd = cmd.copyAndSetExecuted();
    //print("CMD FROM AFTER COPY ${_cmd.from}");
    if (verbose) {
      _.smallArrowOut("Sending command response ${_cmd.name} to ${_cmd.from}");
      //cmd.info();
    }
    final response = await _sendCommandRun(_cmd, _cmd.from, "/cmd/response");
    if (response == null || response.statusCode != HttpStatus.ok) {
      final code = response?.statusCode ?? "no response";
      _logs.sink.add("Error sending the command response: $code");
    }
  }

  void dispose() {
    _commandsExecuted.close();
    _commandsResponses.close();
    _logs.close();
  }

  void info() {
    var nt = _isSoldier ? "Soldier" : "Commander";
    if (_isSoldier && _isCommander) {
      nt = "Mixed";
    }
    print("\n******************************************");
    print("$nt node running on: $host:$port");
    print("******************************************\n");
  }

  IsoRouter _initRoutes() {
    this.host = host;
    this.port = port;
    final routes = <IsoRoute>[];
    if (_isSoldier) {
      routes.add(IsoRoute(handler: cmdSendHandler, path: "/cmd"));
    }
    if (_isCommander) {
      routes.add(IsoRoute(handler: cmdResponseHandler, path: "/cmd/response"));
    }
    final router = IsoRouter(routes);
    // run isolate
    iso = IsoHttpd(host: host, router: router);
    return router;
  }

  void _listenToIso() {
    iso.logs.listen((dynamic data) async {
      //print("ISO LOG $data / ${data.runtimeType}");
      if (data is NodeCommand) {
        // verify command
        final cmd = _fromAuthorizedCommands(data);
        if (cmd == null) {
          throw "Unauthorized command";
        }

        if (!cmd.isExecuted) {
          //print("CMD NOT EXECUTED $cmd");
          // command reveived by soldier
          if (!_isSoldier) {
            _logs.sink.add("Non executed command ${cmd.name} received by "
                "non soldier node");
            return;
          } else {
            if (verbose) {
              _.arrowIn("Command ${cmd.name} received from ${cmd.from}");
              //cmd.info();
            }
            final _cmd = await cmd.execute();
            _commandsExecuted.sink.add(_cmd);
          }
        } else {
          //print("CMD EXECUTED $cmd");
          //cmd.info();
          if (cmd.name == "connection_request_from_discovery") {
            //print("CONN REQUEST");
            final soldier = ConnectedSoldierNode(
                name: cmd.payload["name"].toString(),
                address: "${cmd.payload["host"]}:${cmd.payload["port"]}",
                lastSeen: DateTime.now());
            _soldiers.add(soldier);
            if (verbose) {
              _.state(
                  "Soldier ${soldier.name} connected at ${soldier.address}");
            }
          } else {
            if (verbose) {
              _.arrowIn(
                  "Command response ${cmd.name} received from ${cmd.from}");
              //cmd.info();
            }
            await cmd.processResponse();
            _commandsResponses.sink.add(cmd);
          }
        }
      } else {
        _logs.sink.add(data);
      }
    });
  }

  Future<Response> _sendCommandRun(
      NodeCommand cmd, String to, String endPoint) async {
    assert(cmd != null);
    assert(to != null);
    assert(endPoint != null);
    final _cmd = cmd.copyWithFrom("$host:$port");
    final uri = "http://$to$endPoint";
    Response response;
    try {
      final dynamic data = _cmd.toJson();
      //print("URI $uri / DATA: $data");
      final _response = await _dio.post<dynamic>(uri, data: data);
      response = _response;
    } on DioError catch (e) {
      if (e.response != null) {
        _.error(e, "http error with response");
        return response;
      } else {
        _.error(e, "http error with no response");
      }
    } catch (e) {
      rethrow;
    }
    return response;
  }

  Future<void> _broadcastForDiscovery() async {
    assert(host != null);
    assert(_isCommander);
    await _socketReady.future;
    final payload = '{"host":"$host", "port": "$port"}';
    final data = utf8.encode(payload);
    String broadcastAddr;
    final l = host.split(".");
    broadcastAddr = "${l[0]}.${l[1]}.${l[2]}.255";
    if (verbose) {
      print("Broadcasting to $broadcastAddr: $payload");
    }
    _socket.send(data, InternetAddress(broadcastAddr), 8889);
  }

  Future<void> _initForDiscovery() async {
    if (verbose) {
      print("Initializing for discovery on $host");
    }
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8889)
      ..broadcastEnabled = true;
    if (verbose) {
      print("Socket is ready at ${_socket.address.host}");
    }
    if (!_socketReady.isCompleted) {
      _socketReady.complete();
    }
  }

  Future<void> _listenForDiscovery() async {
    assert(_socket != null);
    await _socketReady.future;
    if (verbose) {
      print("Listenning on socket ${_socket.address.host}");
    }
    _socket.listen((RawSocketEvent e) async {
      final d = _socket.receive();
      if (d == null) {
        return;
      }
      final message = utf8.decode(d.data).trim();
      final dynamic data = json.decode(message);
      //print('Datagram from ${d.address.address}:${d.port}: ${message}');
      if (verbose) {
        print(
            "Received connection request from commander node ${data["host"]}");
      }
      final payload = <String, String>{
        "host": "$host",
        "port": "$port",
        "name": "$name"
      };
      final addr = "${data["host"]}:${data["port"]}";
      //print("RFD: addr: $addr");
      //requestForDiscovery.info();
      var _cmd = requestForDiscovery.copyWithFrom(addr);
      //print("RFD 1: addr: ${_cmd.from}");
      _cmd = _cmd.copyAndSetExecuted();
      _cmd = _cmd.copyWithPayload(payload);
      //print("SEND RESP ${_cmd.from}");
      //_cmd.info();
      await _sendCommandResponse(_cmd);
    });
  }
}
