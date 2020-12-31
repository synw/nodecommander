import 'package:nodecommander/nodecommander.dart';

import 'commands.dart' as cmds;
import 'conf.dart';

void main() {
  print("init node");
  final node = CommanderNode(
      key: key,
      name: "cli",
      port: 8185,
      commands: cmds.commands,
      verbose: true);
  NodeCommanderCli(node).run();
}
