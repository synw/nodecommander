import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

enum CommandStatus {
  pending,
  authorizedToRun,
  unauthorizedToRun,
  success,
  executionError
}

typedef Future<NodeCommand> CommandExecutor(NodeCommand command);

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
      this.payload,
      this.status = CommandStatus.pending,
      this.isExecuted = false})
      : this.id = uuid.v4().toString();

  String id;
  final String name;
  String from;
  dynamic arguments;
  Map<String, dynamic> payload;
  dynamic error;
  CommandStatus status;
  CommandExecutor executor;
  bool isExecuted;

  Future<NodeCommand> execute(NodeCommand cmd) async {
    final NodeCommand returnCmd = await executor(cmd);
    returnCmd.isExecuted = true;
    return returnCmd;
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
    if (data.containsKey("arguments") == true)
      this.arguments = data["arguments"];
    if (data.containsKey("payload") == true) {
      this.payload =
          json.decode(data["payload"].toString()) as Map<String, dynamic>;
    }
    this.isExecuted = (data["isExecuted"].toString() == "true");
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
