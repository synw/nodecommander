import 'dart:async';

import 'package:pedantic/pedantic.dart';
import 'package:prompts/prompts.dart' as prompts;

import '../command/model.dart';
import '../node.dart';
import 'commands.dart';
import 'models.dart';
import 'state.dart';

StreamSubscription<NodeCommand> cmdResponse;

class NodeCommanderCli {
  NodeCommanderCli(this.node);

  final CommanderNode node;

  var _promptString = "command";

  Future<void> run() async {
    await node.init();
    await node.onReady;
    node.info();
    await prompt();
  }

  Future<void> prompt() async {
    assert(node != null);
    final cmdLine = prompts.get(_promptString);
    final commandOk = Completer<void>();
    if (cmdLine.startsWith("/")) {
      // cli command
      final cmd = CliNodeCommand.fromInput(node, cmdLine);
      final res = await cmd.execute();
      if (res.hasError) {
        print("Error executing the command ${cmd.name}: ${res.err.message}");
      }
      // use
      if (cmd.name == "/u") {
        _promptString = cmd.args[0];
      }
      commandOk.complete();
    } else {
      // normal cmd
      if (soldier == null) {
        print("No soldier selected");
        commandOk.complete();
      }
      StreamSubscription sub;
      sub = node.commandsResponse.listen((_cmd) async {
        //print("Processing response: ${_cmd.payload}");
        commandOk.complete();
        unawaited(sub.cancel());
      });
      NodeCommand cmd;
      if (cmdLine.contains(" ")) {
        final l = cmdLine.split(" ");
        final name = l.removeAt(0);
        cmd = node.cmd(name);
        if (cmd == null) {
          print("Command $cmdLine not found");
        } else {
          cmd = cmd.copyWithArguments(l);
          print("Sending command ${cmd.name} ${cmd.arguments}");
        }
      } else {
        cmd = node.cmd(cmdLine);
        if (cmd == null) {
          print("Command $cmdLine not found");
        } else {
          print("Sending command ${cmd.name}");
        }
      }
      await node.sendCommand(cmd, soldier.address);
      //commandOk.complete();
    }
    await commandOk.future;
    unawaited(prompt());
  }
}
