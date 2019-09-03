import '../node.dart';
import 'state.dart';

void using() {
  if (soldier == null) {
    print("No soldier set");
    return;
  }
  print("Using soldier ${soldier.name}");
}

void use(CommanderNode node, String soldierName) {
  if (!node.hasSoldier(soldierName)) {
    print("Unknown soldier $soldierName. Available soldiers:");
    soldiers(node);
    return;
  }
  print("Using soldier $soldierName");
  for (final _soldier in node.soldiers) {
    if (_soldier.name == soldierName) {
      soldier = _soldier;
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

Future<void> discover(CommanderNode node) async {
  await node.discoverNodes();
  await Future<dynamic>.delayed(Duration(seconds: 2));
  print("Soldiers: ${node.soldiers}");
  for (final s in node.soldiers) {
    print("Found soldier ${s.name} at ${s.address}");
  }
}
