import 'dart:async';
import 'package:nodecommander/src/cli/state.dart';
import 'package:nodecommander/src/command/model.dart';
import 'package:prompts/prompts.dart' as prompts;
import '../node.dart';
import 'commands.dart';
import '../plugin.dart';

StreamSubscription<NodeCommand> cmdResponse;

void runCommanderCli(CommanderNode node,
    {List<NodeCommanderPlugin> plugins = const <NodeCommanderPlugin>[]}) async {
  await node.init();
  await node.onReady;
  node.info();
  //listen(node);
  await prompt(node, plugins);
}

void listen(CommanderNode node) {
  node.commandsResponse.listen((cmd) {
    print("Processing response: ${cmd.payload}");
  });
}

void prompt(CommanderNode node, List<NodeCommanderPlugin> plugins) async {
  assert(node != null);
  final cmdLine = prompts.get("command");
  bool found = false;
  Completer<Null> commandOk = Completer<Null>();
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
    found = true;
  }
  String to;
  NodeCommand cmd;
  if (found) {
    commandOk.complete();
  } else {
    if (soldier == null) {
      print("No soldier selected");
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
      StreamSubscription<NodeCommand> sub;
      sub = await node.commandsResponse.listen((_cmd) {
        print("Processing response: ${_cmd.payload}");
        commandOk.complete();
        sub.cancel();
      });
      await node.command(cmd, to);
    }
  }
  if (!found) {
    print("Unknown command");
  }
  await commandOk.future;
  prompt(node, plugins);
}

NodeCommand getCmd(String cmdLine) {
  final l = cmdLine.split(" ");
  final name = l.removeAt(0);
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
  node.discoverNodes();
  await Future<dynamic>.delayed(Duration(seconds: 2));
  print("Soldiers: ${node.soldiers}}");
  for (final s in node.soldiers) {
    print("Found soldier ${s.name} at ${s.address}");
  }
  return node;
}
