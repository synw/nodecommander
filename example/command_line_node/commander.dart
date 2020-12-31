import 'dart:async';

import 'package:nodecommander/nodecommander.dart';
import 'package:pedantic/pedantic.dart';

import 'commands.dart';
import 'conf.dart';

Future<void> main() async {
  final node = CommanderNode(
      key: key,
      name: "commander",
      commands: commands,
      port: 8085,
      verbose: true);
  await node.init();
  node.commandsResponse.listen((NodeCommand cmd) {
    switch (cmd.name) {
      case "counter":
        print("The counter is at ${cmd.payload["value"]}");
        break;
      case "hello":
        print("${cmd.from} is saying hello");
    }
  });
  node.info();
  await node.onReady;
  print("Discovering nodes");
  unawaited(node.discoverNodes());
  await Future<dynamic>.delayed(const Duration(seconds: 2));
  for (final s in node.soldiers) {
    print("Found soldier ${s.name} at ${s.address}");
  }
  await Future<dynamic>.delayed(const Duration(seconds: 2));
  if (node.hasSoldier("command_line_node_1")) {
    final String to = node.soldierUri("command_line_node_1");
    // ping
    await node.sendCommand(NodeCommand.ping(), to);
    await Future<dynamic>.delayed(const Duration(seconds: 2));
    // send a sendCommand
    await node.sendCommand(sayHello, to);
  }
  if (node.hasSoldier("flutter_node_1")) {
    final String to = node.soldierUri("flutter_node_1");
    // send a sendCommand
    await node.sendCommand(increment, to);
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    await node.sendCommand(increment, to);
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    await node.sendCommand(increment, to);
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    await node.sendCommand(increment, to);
  }
  await Completer<void>().future;
}
