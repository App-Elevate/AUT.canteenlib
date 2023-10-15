import 'package:canteenlib/canteenlib.dart';

const String url = "kantyna.neco.cz";
const String username = "uzivatel";
const String password = "heslo123";

void main(List<String> args) async {
  /// Vytvoření instance kantýny
  Canteen canteenInstance = Canteen(url);

  /// Přihlášení (je nutné pro fungování všech funkcí krom tedy zíkání jídelníčku bez cen)
  print(await canteenInstance.login(username, password)
      ? "login succesful"
      : "login failed"); // přihlásit se

  /// Získání informací o uživateli
  Uzivatel uzivatel = await canteenInstance.ziskejUzivatele();
  vytisknoutInfoOUzivateli(uzivatel);

  /// Získání jídelníčku pro daný den
  DateTime datum = DateTime.now();
  datum = datum.add(Duration(days: 2));
  Jidelnicek jidelnicek = await canteenInstance.jidelnicekDen(den: datum);
  vytisknoutInfoOJidelnicku(jidelnicek);
  /*
  |------------------------------------------------------------------------------------------------------------------|
  |  Následující funkce objednávají obědy nebo dávají/odebírají jídla z burzy.                                       |
  |  Buďte si proto jistí, že je chcete spustit, ať nepřijdete o oběd.                                               |
  |                                                                                                                  |
  |------------------------------------------------------------------------------------------------------------------|
  */
  try {
    //jidelnicek.jidla[0] = await canteenInstance.objednat(jidelnicek.jidla[0]);
    vytisknoutInfoOJidelnicku(jidelnicek);
  } catch (e) {
    print(e);
  }
  try {
    //jidelnicek.jidla[0] = await canteenInstance.doBurzy(jidelnicek.jidla[0]);
    vytisknoutInfoOJidelnicku(jidelnicek);
  } catch (e) {
    print(e);
  }
}

void vytisknoutInfoOJidelnicku(Jidelnicek jidelnicek) {
  print('--------------jídelníček pro den ${jidelnicek.den}--------------');
  print('počet jídel: ${jidelnicek.jidla.length}');
  print(Canteen(url).parseHtmlString(jidelnicek.jidla[0].nazev));
  for (int i = 0; i < jidelnicek.jidla.length; i++) {
    print('------------Jídlo číslo $i------------');
    print('název: ${jidelnicek.jidla[i].nazev}');
    print('cena: ${jidelnicek.jidla[i].cena}');
    print('varianta: ${jidelnicek.jidla[i].varianta}');
    print('objednáno: ${jidelnicek.jidla[i].objednano}');
    print('lze objednat: ${jidelnicek.jidla[i].lzeObjednat}');
    print('na burze: ${jidelnicek.jidla[i].naBurze}');
    print('den: ${jidelnicek.jidla[i].den}');
    for (int k = 0; k < jidelnicek.jidla[i].alergeny.length; k++) {
      print(
          'alergen: ${jidelnicek.jidla[i].alergeny[k].nazev} - ${jidelnicek.jidla[i].alergeny[k].popis}');
    }
    print('orderUrl: ${jidelnicek.jidla[i].orderUrl}');
    print('burzaUrl: ${jidelnicek.jidla[i].burzaUrl}');
    if (jidelnicek.jidla[i].kategorizovano != null) {
      print('Hlavní jídlo: ${jidelnicek.jidla[i].kategorizovano!.hlavniJidlo}');
      print('pití: ${jidelnicek.jidla[i].kategorizovano!.piti}');
      print('polévka: ${jidelnicek.jidla[i].kategorizovano!.polevka}');
      print('Salátový bar: ${jidelnicek.jidla[i].kategorizovano!.salatovyBar}');
      print('ostatní: ${jidelnicek.jidla[i].kategorizovano!.ostatni}');
    }
    print('--------------------------------------\n\n');
  }
  print('--------------konec jídelníčku--------------');
}

void vytisknoutInfoOUzivateli(Uzivatel uzivatel) {
  print('Kredit: ${uzivatel.kredit}'); // získat kredit
  print('Jméno: ${uzivatel.jmeno}'); // získat jméno
  print('Příjmení: ${uzivatel.prijmeni}'); // získat příjmení
  print('Kategorie: ${uzivatel.kategorie}'); // získat kategorii
  print('Účet pro platby: ${uzivatel.ucetProPlatby}'); // získat účet pro platby
  print('Variabilní symbol: ${uzivatel.varSymbol}'); // získat variabilní symbol
  print(
      'Specifický symbol: ${uzivatel.specSymbol}'); // získat specifický symbol
  print(
      'Uživatelské jméno: ${uzivatel.uzivatelskeJmeno}'); // získat uživatelské jméno
}
