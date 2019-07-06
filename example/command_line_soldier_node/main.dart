import 'dart:async';
import 'package:nodecommander/nodecommander.dart';

void main() async {
  final node = SoldierNode(name: "command_line_node_1", verbose: true);
  await node.init();
  node.info();
  node.commandsIn.listen((NodeCommand cmd) {
    switch (cmd.name) {
      case "test_cmd":
        cmd.payload = <String, dynamic>{"response": "ok"};
        break;
      default:
        cmd.error = "Unknown command";
    }
    node.respond(cmd);
  });
  final waiter = Completer<Null>();
  await waiter.future;
}
