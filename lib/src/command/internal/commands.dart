import '../model.dart';

final List<NodeCommand> internalCommands = <NodeCommand>[
  requestForDiscovery,
  ping
];

final NodeCommand ping = NodeCommand.define(
    name: "ping",
    executor: (cmd) async =>
        cmd.copyWithPayload(<String, dynamic>{"response": "pong"}),
    responseProcessor: (cmd) async =>
        print("Node ${cmd.from} responded to ping"));

final NodeCommand requestForDiscovery = NodeCommand.define(
    name: "connection_request_from_discovery",
    executor: (cmd) async => cmd.copyWithPayload(<String, dynamic>{}),
    responseProcessor: (cmd) async =>
        print("Node ${cmd.from} responded to discovery request"));
