import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:emodebug/emodebug.dart';

import 'internal/commands.dart' as icmds;

const _ = EmoDebug();

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
      this.token,
      this.payload = const <String, dynamic>{},
      this.arguments = const <dynamic>[],
      this.status = CommandStatus.pending,
      this.isExecuted = false,
      this.error,
      this.errorProcessor});

  NodeCommand.define({
    @required this.name,
    @required this.executor,
    this.token,
    this.responseProcessor,
    this.errorProcessor,
    this.arguments = const <dynamic>[],
  })  : this.payload = const <String, dynamic>{},
        this.status = CommandStatus.pending,
        this.isExecuted = false,
        this.error = null,
        this.from = null,
        this.id = uuid.v4().toString();

  NodeCommand copyWithToken(String _token) => NodeCommand._createWithId(
      id: id,
      name: name,
      token: _token,
      executor: executor,
      responseProcessor: responseProcessor,
      errorProcessor: errorProcessor,
      arguments: arguments,
      status: status,
      from: from,
      error: error,
      payload: payload,
      isExecuted: isExecuted);

  NodeCommand copyWithResponseProcessor(ResponseProcessor _responseProcessor) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          token: token,
          executor: executor,
          responseProcessor: _responseProcessor,
          errorProcessor: errorProcessor,
          arguments: arguments,
          status: status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyAndSetExecuted() => NodeCommand._createWithId(
      id: id,
      name: name,
      token: token,
      executor: executor,
      responseProcessor: responseProcessor,
      errorProcessor: errorProcessor,
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
          token: token,
          executor: executor,
          responseProcessor: responseProcessor,
          errorProcessor: errorProcessor,
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
          token: token,
          executor: executor,
          responseProcessor: responseProcessor,
          errorProcessor: errorProcessor,
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
          token: token,
          executor: executor,
          responseProcessor: responseProcessor,
          errorProcessor: errorProcessor,
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
          token: token,
          executor: executor,
          responseProcessor: responseProcessor,
          errorProcessor: errorProcessor,
          arguments: <dynamic>[...arguments, ..._args],
          status: status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyWithPrependedArguments(List<dynamic> _args) =>
      NodeCommand._createWithId(
          id: id,
          name: name,
          token: token,
          executor: executor,
          responseProcessor: responseProcessor,
          errorProcessor: errorProcessor,
          arguments: <dynamic>[..._args, ...arguments],
          status: status,
          from: from,
          error: error,
          payload: payload,
          isExecuted: isExecuted);

  NodeCommand copyWithFrom(String _from) => NodeCommand._createWithId(
      id: id,
      name: name,
      token: token,
      executor: executor,
      responseProcessor: responseProcessor,
      errorProcessor: errorProcessor,
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
          token: token,
          executor: exec,
          responseProcessor: resp,
          errorProcessor: errorProcessor,
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
  final ResponseProcessor errorProcessor;
  final bool isExecuted;
  final String token;

  bool get hasError => error != null;

  Future<NodeCommand> execute() async {
    NodeCommand returnCmd;
    try {
      returnCmd = await executor(this);
      //print("EXEC RETURN CMD ${returnCmd.copyAndSetExecuted().toJson()}");
      if (returnCmd.hasError) {
        _.error(returnCmd.error, "command execution error");
      }
    } catch (e) {
      rethrow;
    }
    return returnCmd.copyAndSetExecuted();
  }

  Future<void> processResponse() async {
    if (hasError) {
      _.error(this.error, "command response error");
      if (errorProcessor != null) {
        await errorProcessor(this);
      }
      return;
    }
    try {
      if (responseProcessor != null) {
        await responseProcessor(this);
      }
    } catch (e) {
      rethrow;
    }
  }

  factory NodeCommand.fromJson(dynamic data) {
    var c = NodeCommand._createWithId(
        id: data["id"].toString(),
        name: data["name"].toString(),
        token: data["token"].toString(),
        executor: null,
        error: null,
        responseProcessor: null,
        from: data["from"].toString());
    if (data.containsKey("error") == true) {
      final err = data["error"].toString();
      if (err != "") {
        c = c.copyWithError(err);
      }
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
      "token": token,
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
