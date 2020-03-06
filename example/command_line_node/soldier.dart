import 'dart:async';

import 'package:nodecommander/nodecommander.dart';

import 'commands.dart';

Future<void> main() async {
  final node = SoldierNode(
      name: "command_line_node_1", commands: commands, verbose: true);
  await node.init();
  node.info();
  await Completer<void>().future;
}
