import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'internal/commands.dart' as icmds;

Uuid uuid = Uuid();

enum CommandStatus {
  pending,
  authorizedToRun,
  unauthorizedToRun,
  success,
  executionError
}

typedef CommandExecutor = Future<NodeCommand> Function(NodeCommand);

typedef ResponseProcessor = Future<void> Function(NodeCommand);

class ConnectedSoldierNode {
  ConnectedSoldierNode(
      {@required this.name, @required this.address, this.lastSeen});

  final String name;
  final String address;
  DateTime lastSeen;
}

@immutable
class NodeCommand {
  const NodeCommand._createWithId(
      {@required this.id,
      @required this.name,
      @required this.executor,
      @required this.responseProcessor,
      @required this.from,
      this.payload = const <String, dynamic>{},
      this.arguments = const <dynamic>[],
      this.status = CommandStatus.pending,
      this.isExecuted = false,
      this.error});

  NodeCommand.define({
    @required this.name,
    @required this.executor,
    @required this.responseProcessor,
    this.arguments = const <dynamic>[],
  })  : this.payload = const <String, dynamic>{},
        this.status = CommandStatus.pending,
        this.isExecuted = false,
        this.error = null,
        this.from = null,
        this.id = uuid.v4().toString();

/*  NodeCommand.fromName({
    @required this.name,
    this.arguments = const <dynamic>[],
  })  : this.payload = const <String, dynamic>{},
        this.status = CommandStatus.pending,
        this.isExecuted = false,
        this.error = null,
        this.from = null,
        this.executor = null,
        this.responseProcessor = null,
        this.id = uuid.v4().toString();*/

  NodeCommand copyAndSetExecuted() => NodeCommand._createWithId(
      id: id,
      name: name,
      executor: executor,
      responseProcessor: responseProcessor,
      arguments: arguments,
      status: status,
      from: from,
      error: error,
      payload: payload,
      isExecuted: true);

  NodeCommand copyWithError(dynamic _error,
          {CommandStatus cmdStatus = CommandStatus.executionError}) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          executor: executor,
          responseProcessor: responseProcessor,
          arguments: arguments,
          status: cmdStatus,
          from: from,
          error: _error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyWithPayload(Map<String, dynamic> _payload,
          {CommandStatus cmdStatus = CommandStatus.success}) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          executor: executor,
          responseProcessor: responseProcessor,
          arguments: arguments,
          status: cmdStatus,
          from: from,
          error: error,
          payload: _payload,
          isExecuted: isExecuted);

  NodeCommand copyWithStatus(CommandStatus _status) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          executor: executor,
          responseProcessor: responseProcessor,
          arguments: arguments,
          status: _status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyWithArguments(List<dynamic> _args) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          executor: executor,
          responseProcessor: responseProcessor,
          arguments: _args,
          status: status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyWithFrom(String _from) => NodeCommand._createWithId(
      id: id,
      name: name,
      executor: executor,
      responseProcessor: responseProcessor,
      arguments: arguments,
      status: status,
      from: _from,
      error: error,
      payload: payload,
      isExecuted: isExecuted);

  NodeCommand copyWithExecMethods(
          {CommandExecutor exec, ResponseProcessor resp}) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          executor: exec,
          responseProcessor: resp,
          arguments: arguments,
          status: status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  final String id;
  final String name;
  final String from;
  final List<dynamic> arguments;
  final Map<String, dynamic> payload;
  final dynamic error;
  final CommandStatus status;
  final CommandExecutor executor;
  final ResponseProcessor responseProcessor;
  final bool isExecuted;

  Future<NodeCommand> execute() async {
    NodeCommand returnCmd;
    try {
      returnCmd = await executor(this);
      //print("EXEC RETURN CMD ${returnCmd.copyAndSetExecuted().toJson()}");
    } catch (e) {
      rethrow;
    }
    return returnCmd.copyAndSetExecuted();
  }

  Future<void> processResponse() async {
    try {
      await responseProcessor(this);
    } catch (e) {
      rethrow;
    }
  }

  factory NodeCommand.fromJson(dynamic data) {
    var c = NodeCommand._createWithId(
        id: data["id"].toString(),
        name: data["name"].toString(),
        executor: null,
        responseProcessor: null,
        from: data["from"].toString());
    if (data.containsKey("error") == true) {
      c = c.copyWithError(data["error"].toString());
    }
    if (data.containsKey("arguments") == true) {
      final args = json.decode(data["arguments"].toString()) as List<dynamic>;
      c = c.copyWithArguments(args);
    }
    if (data.containsKey("payload") == true) {
      final pl =
          json.decode(data["payload"].toString()) as Map<String, dynamic>;
      c = c.copyWithPayload(pl);
    }
    if (data["isExecuted"].toString() == "true") {
      c = c.copyAndSetExecuted();
    }
    return c;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      "id": id,
      "name": name,
      "from": from,
      "arguments": (arguments == null) ? <dynamic>[] : json.encode(arguments),
      "payload": (payload == null) ? <String, dynamic>{} : json.encode(payload),
      "error": (error == null) ? "" : error.toString(),
      "isExecuted": isExecuted.toString()
    };
    return data;
  }

  static NodeCommand ping() => icmds.ping;

  void info() {
    print("Command $name:");
    print("- Id: $id");
    print("- Arguments: $arguments");
    print("- From: $from");
    print("- Payload: $payload");
    print("- Error: $error");
    print("- Is executed: $isExecuted");
  }

  @override
  String toString() {
    return "$name";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeCommand &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
