import 'dart:async';
import 'package:nodecommander/nodecommander.dart';

void main() async {
  final node = CommanderNode(port: 8085, verbose: true);
  await node.init();
  node.commandsResponse.listen((NodeCommand cmd) {
    print("Processing response: ${cmd.payload}");
    switch (cmd.name) {
      case "counter":
        print("The counter is at ${cmd.payload["value"]}");
    }
  });
  node.info();
  await node.onReady;
  node.discoverNodes();
  await Future<dynamic>.delayed(Duration(seconds: 2));
  for (final s in node.soldiers) {
    print("Found soldier ${s.name} at ${s.address}");
  }
  await Future<dynamic>.delayed(Duration(seconds: 2));
  if (node.hasSoldier("command_line_node_1")) {
    final String to = node.soldierUri("command_line_node_1");
    // send a command
    node.command(NodeCommand(name: "test_cmd"), to);
  }
  if (node.hasSoldier("flutter_node_1")) {
    final String to = node.soldierUri("flutter_node_1");
    // send a command
    node.command(NodeCommand(name: "counter"), to);
    await Future<dynamic>.delayed(Duration(seconds: 2));
    node.command(NodeCommand(name: "counter"), to);
    await Future<dynamic>.delayed(Duration(seconds: 2));
    node.command(NodeCommand(name: "counter"), to);
    await Future<dynamic>.delayed(Duration(seconds: 2));
    node.command(NodeCommand(name: "counter"), to);
  }
  final waiter = Completer<Null>();
  await waiter.future;
}
