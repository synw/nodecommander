# Node Commander

 Network nodes communication in Dart. Send commands to nodes and get the responses. Powered by [Isohttpd](https://github.com/synw/isohttpd)

## Usage

Generate a key: `dart bin/main.dart`

### Create some commands

   ```dart
   import 'package:nodecommander/nodecommander.dart';

   const key = "7x70J-5n0AZptWlBLVMfknlRiOtALH-6dUT16tfCHCA=";

   final List<NodeCommand> commands = <NodeCommand>[sayHello];

   final NodeCommand sayHello = NodeCommand.define(
      name: "hello",
      key: key,
      /// The code executed on the soldier
      executor: (cmd) async {
        print("Saying hello to ${cmd.from}");
        return cmd.copyWithPayload(<String, dynamic>{"response": "hello"});
      },
      /// Optional: the code executed on the commander after
      /// the response is received from the soldier
      responseProcessor: (cmd) async =>
          print(cmd.payload["response"].toString()));
   ```
   
### Run a soldier node

   ```dart
   import 'dart:async';
   import 'package:nodecommander/nodecommander.dart';
   import 'commands.dart' as cmds;
   
   Future<void> main() async {
     final node = SoldierNode(
         name: "command_line_node_1", 
         key: key, 
         commands: cmds.commands, 
         verbose: true);
     // initialize the node
     await node.init();
     // print some info about the node
     node.info();
     // idle
     await Completer<void>().future;
   }
   ```

### Run a commander node

Declare and initialize the node:

   ```dart
   final node = CommanderNode(
       name: "commander",
       key: key, 
       commands: cmds.commands, 
       port: 8085, 
       verbose: true);
   // initialize the node
   await node.init();   
   // print some info about the node
   node.info();
   // Wait for the node to be ready to operate
   await node.onReady;
   ```

Discover soldier nodes on the network with udp broadcast:

   ```dart
   unawaited(node.discoverNodes());
   await Future<dynamic>.delayed(const Duration(seconds: 2));
   for (final s in node.soldiers) {
     print("Soldier ${s.name} at ${s.address}");
   }
   ```

Run commands on soldier nodes:

   ```dart
   final String to = node.soldierUri("command_line_node_1");
   // ping
   await node.sendCommand(NodeCommand.ping(), to);
   // send a command
   await node.sendCommand(sayHello, to);
   // or
   await node.sendCommand(node.cmd("hello"), to);
   ```

Listen to command responses from soldiers:

   ```dart
   node.commandsResponse.listen((NodeCommand cmd) {
      print("${cmd.from} has responded: ${cmd.payload}");
   }
   ```

This is optional. The command responses are received after the `response_processor` is
run if present

## Create a cli with custom commands

To run the cli:

```dart
import 'package:nodecommander/nodecommander.dart';

void main() {
  final node = CommanderNode(
      key: key,
      name: "cli",
      port: 8185,
      commands: <NodeCommand>[sayHello],
      verbose: true);
  NodeCommanderCli(node).run();
}
```