import 'package:nodecommander/nodecommander.dart';

final List<NodeCommand> commands = <NodeCommand>[
  sayHello,
  increment,
  decrement
];

int counter = 0;

final NodeCommand sayHello = NodeCommand.define(
    name: "hello",
    executor: (cmd) async {
      print("Saying hello to ${cmd.from}");
      return cmd.copyWithPayload(<String, dynamic>{"response": "hello"});
    },
    responseProcessor: (cmd) async =>
        print(cmd.payload["response"].toString()));

final NodeCommand increment = NodeCommand.define(
    name: "increment",
    executor: (cmd) async =>
        cmd.copyWithPayload(<String, dynamic>{"response": "hello"}),
    responseProcessor: (cmd) async =>
        print(cmd.payload["response"].toString()));

final NodeCommand decrement = NodeCommand.define(
    name: "decrement",
    executor: (cmd) async {
      ++counter;
      if (counter < 3) {
        return cmd.copyWithPayload(<String, dynamic>{"response": counter});
      }
      return cmd.copyWithError("The counter can not go over 3");
    },
    responseProcessor: (cmd) async =>
        print(cmd.payload["response"].toString()));
