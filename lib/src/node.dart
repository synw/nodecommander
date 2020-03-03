import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';

import 'command/model.dart';
import 'desktop/host.dart';
import 'http_handlers.dart';

class SoldierNode extends BaseSoldierNode {
  SoldierNode(
      {@required this.name,
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

  Future<void> init([String _host]) async {
    var _h = _host;
    _h ??= host;
    _h ??= await getHost();
    await _initSoldierNode(_h);
  }
}

class CommanderNode extends BaseCommanderNode {
  CommanderNode({this.host, this.port = 8084, this.verbose = false}) {
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

  Future<void> command(NodeCommand cmd, String to) => _sendCommand(cmd, to);

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
  Stream<NodeCommand> get commandsIn => _commandsIn.stream;

  Future<void> respond(NodeCommand cmd) => _sendCommandResponse(cmd);

  Future<void> _initSoldierNode(String host) async {
    await _initNode(host, true, false);
  }
}

abstract class BaseNode {
  String name;
  String host;
  int port;
  IsoHttpdRunner iso;
  bool verbose;

  RawDatagramSocket _socket;
  final Completer<void> _socketReady = Completer<void>();
  final List<ConnectedSoldierNode> _soldiers = <ConnectedSoldierNode>[];
  final Dio _dio = Dio(BaseOptions(connectTimeout: 5000, receiveTimeout: 3000));
  bool _isSoldier;
  bool _isCommander;
  final Completer _readyCompleter = Completer<void>();
  final StreamController<NodeCommand> _commandsIn =
      StreamController<NodeCommand>();
  final StreamController<NodeCommand> _commandsResponses =
      StreamController<NodeCommand>.broadcast();
  final StreamController<dynamic> _logs = StreamController<dynamic>.broadcast();

  Future get onReady => _readyCompleter.future;

  Future<void> _initNode(String _host, bool isSoldier, bool isCommander) async {
    host = _host;
    _isSoldier = isSoldier;
    _isCommander = isCommander;
    final router = _initRoutes();
    // run isolate
    iso = IsoHttpdRunner(
        host: host, port: port, router: router, verbose: verbose);
    await iso.run(verbose: verbose);
    _listenToIso();
    await iso.onServerStarted;
    await _initForDiscovery();
    if (_isSoldier) {
      await _listenForDiscovery();
    }
    if (verbose) {
      print("Node is ready");
    }
    _readyCompleter.complete();
  }

  Future<void> _sendCommand(NodeCommand cmd, String to) async {
    assert(_isCommander);
    assert(to != null);
    assert(cmd != null);
    if (verbose) {
      print("< Sending command ${cmd.name} to $to");
      cmd.info();
    }
    final response = await _sendCommandRun(cmd, to, "/cmd");
    if (response.statusCode != HttpStatus.ok) {
      _logs.sink.add("Error sending the command: code ${response.statusCode}");
    }
  }

  Future<void> _sendCommandResponse(NodeCommand cmd) async {
    assert(_isSoldier);
    assert(cmd.from != null);
    cmd.isExecuted = true;
    if (verbose) {
      print("< Sending command response ${cmd.name} to ${cmd.from}");
      cmd.info();
    }
    final response = await _sendCommandRun(cmd, cmd.from, "/cmd/response");
    if (response.statusCode != HttpStatus.ok) {
      _logs.sink.add(
          "Error sending the command response: code ${response.statusCode}");
    }
  }

  void dispose() {
    _commandsIn.close();
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
    iso = IsoHttpdRunner(host: host, router: router);
    return router;
  }

  void _listenToIso() {
    iso.logs.listen((dynamic data) {
      print("ISO LOG $data");
      if (data is NodeCommand) {
        final cmd = data;
        print("COMMAND :");
        cmd.info();

        if (!cmd.isExecuted) {
          // command reveived by soldier
          if (!_isSoldier) {
            _logs.sink.add("Command ${cmd.name} received by non soldier node");
          } else {
            if (verbose) {
              print("> Command ${cmd.name} received from ${cmd.from}");
              cmd.info();
            }
            _commandsIn.sink.add(cmd);
          }
        } else {
          if (cmd.name == "connection_request_from_discovery") {
            final soldier = ConnectedSoldierNode(
                name: cmd.payload["name"].toString(),
                address: "${cmd.payload["host"]}:${cmd.payload["port"]}",
                lastSeen: DateTime.now());
            _soldiers.add(soldier);
            if (verbose) {
              print("Soldier ${soldier.name} connected at ${soldier.address}");
            }
          }
          if (verbose) {
            print("> Command response ${cmd.name} received from ${cmd.from}");
            cmd.info();
          }
          _commandsResponses.sink.add(cmd);
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
    cmd.from ??= "$host:$port";
    final uri = "http://$to$endPoint";
    Response response;
    try {
      final dynamic data = cmd.toJson();
      //print("URI $uri / DATA: $data");
      final _response = await _dio.post<dynamic>(uri, data: data);
      response = _response;
    } on DioError catch (e) {
      print("Dio error: ${e.type}");
      if (e.response != null) {
        print("RESPONSE:");
        print(e.response.data);
        print(e.response.headers);
        print(e.response.request.baseUrl);
        rethrow;
      } else {
        print("REQUEST");
        print(e.request.path);
        print(e.message);
        rethrow;
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
      print("Listenning on _socket ${_socket.address.host}");
    }
    _socket.listen((RawSocketEvent e) {
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
      final cmd = NodeCommand(
          name: "connection_request_from_discovery", payload: payload);
      final addr = "${data["host"]}:${data["port"]}";
      cmd
        ..from = addr
        ..isExecuted = true;
      _sendCommandResponse(cmd);
    });
  }
}
