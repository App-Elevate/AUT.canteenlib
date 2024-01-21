import 'package:canteenlib/canteenlib.dart';

const String url = "kantyna.neco.cz";
const String username = "uzivatel";
const String heslo = "heslo123";

void main(List<String> args) async {
  /// Vytvoření instance kantýny. Všechna komunikace probíhá skrz ni.
  Canteen canteenInstance = Canteen(url);

  try {
    // příhlášení
    await canteenInstance.login(username, heslo); // přihlásit se

    // získání jídelníčku pro daný den i s cenami
    var jidelnicek = await canteenInstance.jidelnicekDen(den: DateTime.parse("2022-04-04"));

    // získání informací o uživateli, jako je například kredit
    print((await canteenInstance.ziskejUzivatele()).kredit);

    // objednání jídla
    var objednano = await canteenInstance.objednat(jidelnicek.jidla[0]);
    print(objednano.jidla[0].objednano);
  } catch (e) {
    print("Při získávání informací nastala chyba: $e");
  }
}
