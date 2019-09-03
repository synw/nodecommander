import 'dart:async';
import 'package:pedantic/pedantic.dart';
import 'package:prompts/prompts.dart' as prompts;
import '../command/model.dart';
import '../node.dart';
import 'commands.dart';
import '../plugin.dart';
import 'state.dart';

StreamSubscription<NodeCommand> cmdResponse;

class NodeCommanderCli {
  NodeCommanderCli();

  List<NodeCommanderPlugin> plugins;
  String promptString = "command";

  void run(CommanderNode node,
      {List<NodeCommanderPlugin> plugins =
          const <NodeCommanderPlugin>[]}) async {
    this.plugins = plugins;
    await node.init();
    await node.onReady;
    node.info();
    await prompt(node, plugins);
  }

  void prompt(CommanderNode node, List<NodeCommanderPlugin> plugins) async {
    assert(node != null);
    final cmdLine = prompts.get(promptString);
    bool found = false;
    final commandOk = Completer<Null>();
    // base command without args
    switch (cmdLine) {
      case "/d":
        await discover(node);
        found = true;
        break;
      case "/sl":
        soldiers(node);
        found = true;
        break;
      case "/s":
        using();
        found = true;
        break;
    }
    // base commands with args
    if (cmdLine.startsWith("/u")) {
      final soldierName = getArg(cmdLine);
      use(node, soldierName);
      promptString = soldierName;
      found = true;
    }
    String to;
    NodeCommand cmd;
    if (found) {
      commandOk.complete();
    } else {
      if (soldier == null) {
        print("No soldier selected");
        commandOk.complete();
      } else {
        // plugin commands
        for (final plugin in plugins) {
          for (final pcmd in plugin.commands) {
            cmd = getCmd(cmdLine);
            if (pcmd.name.startsWith(cmd.name)) {
              to = soldier.address;
              found = true;
            }
          }
        }
        StreamSubscription sub;
        sub = await node.commandsResponse.listen((_cmd) async {
          //print("Processing response: ${_cmd.payload}");
          //print("RECEIVE $_cmd");
          // find response processor
          for (final plugin in plugins) {
            for (final cmd in plugin.commands) {
              if (cmd.name == _cmd.name) {
                _cmd.responseProcessor =
                    cmd.responseProcessor as ResponseProcessor;
              }
            }
          }
          //print("PROC: ${_cmd.responseProcessor}");
          if (_cmd.responseProcessor == null) {
            throw ("Can not find response processor");
          }
          try {
            await _cmd.processResponse(_cmd);
          } catch (e) {
            throw ("Error processing response: $e");
          }
          commandOk.complete();
          unawaited(sub.cancel());
        });
        print("Sending command ${cmd.name} ${cmd.arguments}");
        await node.command(cmd, to);
      }
    }
    if (!found) {
      print("Unknown command");
      commandOk.complete();
    }
    await commandOk.future;
    prompt(node, plugins);
  }

  NodeCommand getCmd(String cmdLine) {
    final l = cmdLine.split(" ");
    final name = l.removeAt(0);
    // get response processor

    // create cmd
    final cmd = NodeCommand(name: name, arguments: l);
    return cmd;
  }

  String getArg(String cmdLine) {
    String arg;
    final l = cmdLine.split(" ");
    arg = l[1];
    return arg;
  }

  Future<CommanderNode> init() async {
    final node = CommanderNode(port: 8085, verbose: true);
    await node.init();
    /*node.commandsResponse.listen((NodeCommand cmd) {
    switch (cmd.name) {
      case "query":
        print("");
        for (final line
            in decodePayload(cmd.arguments[0].toString(), cmd.payload)) {
          print(line);
        }
        exit(0);
    }
  });*/
    node.info();
    await node.onReady;
    unawaited(node.discoverNodes());
    await Future<dynamic>.delayed(Duration(seconds: 2));
    print("Soldiers: ${node.soldiers}}");
    for (final s in node.soldiers) {
      print("Found soldier ${s.name} at ${s.address}");
    }
    return node;
  }
}
