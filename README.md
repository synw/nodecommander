# Node Commander

 Network nodes communication in Dart. Send commands to nodes and get the responses. Powered by [Isohttpd](https://github.com/synw/isohttpd)

## Example

 Soldier node:

   ```dart
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
     await Completer<void>().future;
   }
   ```

Commander node:

   ```dart
   import 'dart:async';
   import 'package:nodecommander/nodecommander.dart';

   void main() async {
     final node = CommanderNode(port: 8085, verbose: true);
     await node.init();
     node.commandsResponse.listen((NodeCommand cmd) {
       print("Processing response: ${cmd.payload}");
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
     await Completer<void>().future;
   }
   ```
