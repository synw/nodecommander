import 'dart:async';
import 'package:meta/meta.dart';
import 'package:nodecommander/nodecommander.dart';

class NodeCommanderPlugin {
  NodeCommanderPlugin(
      {@required this.name, @required this.commands, this.node});

  final String name;
  final List<NodeCommand> commands;
  CommanderNode node;

  void init({CommanderNode commanderNode}) => node = commanderNode;

  Future<void> executeCommand(
      {@required SoldierNode node,
      @required NodeCommand command,
      @required List<dynamic> parameters}) async {
    var found = false;
    for (final cmd in this.commands) {
      if (command.name == cmd.name) {
        command.executor = cmd.executor;
        command = await command.execute(command, parameters);
        found = true;
        break;
      }
    }
    if (!found) {
      command.isExecuted = true;
      command.error = "Can not find command";
    }
    await node.respond(command);
  }
}
