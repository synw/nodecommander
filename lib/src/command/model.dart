import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = Uuid();

enum CommandStatus {
  pending,
  authorizedToRun,
  unauthorizedToRun,
  success,
  executionError
}

typedef CommandExecutor = Future<NodeCommand> Function(
    NodeCommand command, List<dynamic> parameters);

typedef ResponseProcessor = Future<void> Function(NodeCommand command);

class ConnectedSoldierNode {
  ConnectedSoldierNode(
      {@required this.name, @required this.address, this.lastSeen});

  final String name;
  final String address;
  DateTime lastSeen;
}

class NodeCommand {
  NodeCommand(
      {@required this.name,
      this.from,
      this.arguments,
      this.executor,
      this.responseProcessor,
      this.payload,
      this.status = CommandStatus.pending,
      this.isExecuted = false})
      : this.id = uuid.v4().toString();

  String id;
  final String name;
  String from;
  List<dynamic> arguments;
  Map<String, dynamic> payload;
  dynamic error;
  CommandStatus status;
  CommandExecutor executor;
  ResponseProcessor responseProcessor;
  bool isExecuted;

  Future<NodeCommand> execute(NodeCommand cmd, List<dynamic> parameters) async {
    final NodeCommand returnCmd = await executor(cmd, parameters);
    returnCmd.isExecuted = true;
    return returnCmd;
  }

  Future<void> processResponse(NodeCommand cmd) async {
    try {
      await responseProcessor(cmd);
    } catch (e) {
      rethrow;
    }
  }

  NodeCommand.fromJson(dynamic data)
      : this.id = data["id"].toString(),
        this.name = data["name"].toString(),
        this.from = data["from"].toString(),
        this.arguments = null,
        this.payload = null,
        this.error = null,
        this.isExecuted = false {
    if (data.containsKey("error") == true) this.error = error.toString();
    if (data.containsKey("arguments") == true) {
      this.arguments =
          json.decode(data["arguments"].toString()) as List<dynamic>;
    }
    if (data.containsKey("payload") == true) {
      this.payload =
          json.decode(data["payload"].toString()) as Map<String, dynamic>;
    }
    this.isExecuted = data["isExecuted"].toString() == "true";
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

  void info() {
    print("Command $name:");
    print("- Id: $id");
    print("- Arguments: $arguments");
    print("- From: $from");
    print("- Payload: $payload");
    print("- Error: $error");
    print("- Is executed: $isExecuted");
  }

  String toMsg() {
    return json.encode(this.toJson());
  }

  @override
  String toString() {
    return "$name";
  }
}
