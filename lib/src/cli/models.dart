import 'package:nodecommander/nodecommander.dart';
import 'package:err/err.dart';

import 'commands.dart' as cmds;

class CliNodeCommand {
  factory CliNodeCommand.fromInput(CommanderNode node, String input) {
    assert(node != null);
    assert(input != null);
    return CliNodeCommand._getCmdFromInput(node, input);
  }

  CliNodeCommand._(this.node, this.name, this.args) : input = null;

  factory CliNodeCommand._getCmdFromInput(CommanderNode node, String cmdLine) {
    final args = <String>[];
    final l = cmdLine.split(" ");
    var name = cmdLine;
    if (l.length > 1) {
      name = l.removeAt(0);
      args.addAll(l);
    }
    // get cmd
    return CliNodeCommand._(node, name, args);
  }

  final String input;
  final CommanderNode node;

  String name;
  List<String> args;

  Future<ErrPack<dynamic>> execute() async {
    dynamic rv;
    try {
      switch (name) {
        case "/d":
          rv = await cmds.discover(node);
          break;
        case "/sl":
          cmds.soldiers(node);
          break;
        case "/s":
          cmds.using();
          break;
        case "/u":
          print("U $args");
          if (args.isNotEmpty) {
            cmds.use(node, args[0]);
          } else {
            cmds.use(node);
          }
          break;
        default:
          return ErrPack<String>.err(Err.error("Command not found"));
      }
    } catch (e) {
      return ErrPack<String>.err(Err.error(e));
    }
    return ErrPack<dynamic>.ok(rv);
  }
}
