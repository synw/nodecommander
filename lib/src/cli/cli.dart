import 'dart:async';

import 'package:pedantic/pedantic.dart';
import 'package:prompts/prompts.dart' as prompts;

import '../command/model.dart';
import '../node.dart';
import '../types.dart';
import 'models.dart';
import 'state.dart' as state;

class NodeCommanderCli {
  NodeCommanderCli(this.node, {this.onCommand});

  final CommanderNode node;
  final OnCommand onCommand;

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
        _promptString = state.soldier.name;
      }
      commandOk.complete();
    } else {
      // normal cmd
      if (state.soldier == null) {
        print("No soldier selected");
        commandOk.complete();
      }
      StreamSubscription<NodeCommand> sub;
      sub = node.commandsResponse.listen((_cmd) async {
        // callback
        if (onCommand != null) {
          onCommand(_cmd);
        }
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
      await node.sendCommand(cmd, state.soldier.address);
      //commandOk.complete();
    }
    await commandOk.future;
    unawaited(prompt());
  }
}
