import 'package:canteenlib/canteenlib.dart';

const String url = "kantyna.neco.cz";
const String username = "jmeno";
const String password = "heslo";

void main(List<String> args) async {
  Canteen canteenInstance = Canteen(url);
  print(await canteenInstance.login(username, password) ? "login succesful" : "login failed"); // přihlásit se
  Uzivatel uzivatel = await canteenInstance.ziskejUzivatele();
  print('Kredit: ${uzivatel.kredit}'); // získat kredit
  print('Jméno: ${uzivatel.jmeno}'); // získat jméno
  print('Příjmení: ${uzivatel.prijmeni}'); // získat příjmení
  print('Kategorie: ${uzivatel.kategorie}'); // získat kategorii
  print('Účet pro platby: ${uzivatel.ucetProPlatby}'); // získat účet pro platby
  print('Variabilní symbol: ${uzivatel.varSymbol}'); // získat variabilní symbol
  print('Specifický symbol: ${uzivatel.specSymbol}'); // získat specifický symbol
  print('Uživatelské jméno: ${uzivatel.uzivatelskeJmeno}'); // získat uživatelské jméno
  DateTime datum = DateTime.now();
  datum = DateTime(datum.year, datum.month, datum.day);
  datum = datum.add(Duration(days: 2));
  Jidelnicek jidelnicek = await canteenInstance.jidelnicekDen(den: datum);
  print('jídelníček pro den: ${jidelnicek.den}');
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
      print('alergen: ${jidelnicek.jidla[i].alergeny[k].nazev}');
    }
    print('orderUrl: ${jidelnicek.jidla[i].orderUrl}');
    print('burzaUrl: ${jidelnicek.jidla[i].burzaUrl}');
    if (jidelnicek.jidla[i].kategorizovano != null) {
      print('Hlavní jídlo: ${jidelnicek.jidla[i].kategorizovano!.hlavniJidlo}');
      print('pití: ${jidelnicek.jidla[i].kategorizovano!.piti}');
      print('polévka: ${jidelnicek.jidla[i].kategorizovano!.polevka}');
      print('Salátový bar: ${jidelnicek.jidla[i].kategorizovano!.salatovyBar}');
    }
    print('--------------------------------------\n\n');
  }

  /*------------objednávací akce, zkontrolujte si, zda opravdu chcete tyto akce provést-----------*/
  try {
    //jidelnicek.jidla[0] = await canteenInstance.objednat(jidelnicek.jidla[0]);
  } catch (e) {
    print(e);
  }
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
      print('alergen: ${jidelnicek.jidla[i].alergeny[k].nazev}');
    }
    print('orderUrl: ${jidelnicek.jidla[i].orderUrl}');
    print('burzaUrl: ${jidelnicek.jidla[i].burzaUrl}');
    if (jidelnicek.jidla[i].kategorizovano != null) {
      print('Hlavní jídlo: ${jidelnicek.jidla[i].kategorizovano!.hlavniJidlo}');
      print('pití: ${jidelnicek.jidla[i].kategorizovano!.piti}');
      print('polévka: ${jidelnicek.jidla[i].kategorizovano!.polevka}');
      print('Salátový bar: ${jidelnicek.jidla[i].kategorizovano!.salatovyBar}');
    }
    print('--------------------------------------\n\n');
  }
  try {
    jidelnicek.jidla[0] = await canteenInstance.doBurzy(jidelnicek.jidla[0]);
  } catch (e) {
    print(e);
  }
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
      print('alergen: ${jidelnicek.jidla[i].alergeny[k].nazev}');
    }
    print('orderUrl: ${jidelnicek.jidla[i].orderUrl}');
    print('burzaUrl: ${jidelnicek.jidla[i].burzaUrl}');
    if (jidelnicek.jidla[i].kategorizovano != null) {
      print('Hlavní jídlo: ${jidelnicek.jidla[i].kategorizovano!.hlavniJidlo}');
      print('pití: ${jidelnicek.jidla[i].kategorizovano!.piti}');
      print('polévka: ${jidelnicek.jidla[i].kategorizovano!.polevka}');
      print('Salátový bar: ${jidelnicek.jidla[i].kategorizovano!.salatovyBar}');
    }
    print('--------------------------------------\n\n');
  }
}
