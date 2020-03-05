/*import 'dart:async';
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
      {@required SoldierNode node, @required NodeCommand command}) async {
    var found = false;
    NodeCommand _cmd = command;
    for (final cmd in this.commands) {
      if (command.name == cmd.name) {
        command.executor = cmd.executor;
        _cmd = await command.execute();
        found = true;
        break;
      }
    }
    if (!found) {
      _cmd.isExecuted = true;
      _cmd.error = "Can not find command";
    }
    await node.respond(_cmd);
  }
}*/
