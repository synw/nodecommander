import 'package:nodecommander/nodecommander.dart';

import '../node.dart';
import 'state.dart' as state;

void using() {
  if (state.soldier == null) {
    print("No soldier set");
    return;
  }
  print("Using soldier ${state.soldier.name}");
}

void use(CommanderNode node, [String soldierName]) {
  var name = soldierName;
  if (soldierName == null) {
    if (node.soldiers.isEmpty) {
      print("No soldiers connected");
      return;
    }
    //print("SOLDIERS ${node.soldiers}");
    name = node.soldiers[0].name;
  }
  if (!node.hasSoldier(name)) {
    print("Unknown soldier $name. Available soldiers:");
    soldiers(node);
    return;
  }
  print("Using soldier $name");
  for (final _soldier in node.soldiers) {
    if (_soldier.name == name) {
      state.soldier = _soldier;
      return;
    }
  }
}

void soldiers(CommanderNode node) {
  if (node.soldiers.isEmpty) {
    print("No soldiers found");
    return;
  }
  for (final soldier in node.soldiers) {
    print("${soldier.name} : ${node.soldierUri(soldier.name)}");
  }
}

Future<List<ConnectedSoldierNode>> discover(CommanderNode node) async {
  await node.discoverNodes();
  await Future<dynamic>.delayed(const Duration(seconds: 2));
  //print("Soldiers: ${node.soldiers}");
  for (final s in node.soldiers) {
    print("Found soldier ${s.name} at ${s.address}");
  }
  return node.soldiers;
}
