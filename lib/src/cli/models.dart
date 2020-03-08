import 'package:nodecommander/nodecommander.dart';
import 'package:err/err.dart';

import 'commands.dart' as cmds;

class CliNodeCommand {
  factory CliNodeCommand.fromInput(CommanderNode node, String input) {
    assert(node != null);
    assert(input != null);
    return CliNodeCommand._getCmd(node, input);
  }

  CliNodeCommand._(this.node, this.name, this.args) : input = null;

  factory CliNodeCommand._getCmd(CommanderNode node, String cmdLine) {
    final l = cmdLine.split(" ");
    final name = l.removeAt(0);
    // get cmd
    return CliNodeCommand._(node, name, l);
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
          cmds.use(node, args[0]);
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
