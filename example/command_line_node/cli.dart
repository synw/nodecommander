import 'package:nodecommander/nodecommander.dart';

import 'commands.dart' as cmds;

void main() {
  print("init node");
  final node = CommanderNode(
      name: "cli", port: 8185, commands: cmds.commands, verbose: true);
  NodeCommanderCli(node).run();
}
