import 'dart:async';

import 'package:nodecommander/nodecommander.dart';

final List<NodeCommand> commands = <NodeCommand>[increment, decrement];

int counter = 0;
final StreamController<int> counterController = StreamController<int>();

final NodeCommand increment = NodeCommand.define(
    name: "increment",
    executor: (cmd) async {
      ++counter;
      if (counter < 4) {
        counterController.sink.add(counter);
        return cmd.copyWithPayload(<String, dynamic>{"response": counter});
      }
      return cmd.copyWithError("The counter can not go over 3");
    },
    responseProcessor: (cmd) async =>
        print(cmd.payload["response"].toString()));

final NodeCommand decrement = NodeCommand.define(
    name: "decrement",
    executor: (cmd) async {
      --counter;
      counterController.sink.add(counter);
      return cmd.copyWithPayload(<String, dynamic>{"response": counter});
    },
    responseProcessor: (cmd) async =>
        print(cmd.payload["response"].toString()));
