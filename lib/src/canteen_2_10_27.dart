/*
 MIT License

Copyright (c) 2023 Tomáš Protiva and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:canteenlib/canteenlib.dart';

/// Reprezentuje kantýnu verze 2.10.27
///
/// **Všechny metody v případě chyby vrací [Future] s chybovou hláškou.**
class Canteen2v10v27 extends Canteen {
  /// Sušenky potřebné pro komunikaci
  Map<String, String> cookies = {"JSESSIONID": ""};

  /// Je uživatel přihlášen?
  @override
  bool prihlasen = false;

  Canteen2v10v27(String url) : super(url);

  /// Vrátí informace o uživateli ve formě instance [Uzivatel]
  @override
  Future<Uzivatel> ziskejUzivatele() async {
    if (!prihlasen) return Future.error("Nejdříve se musíte přihlásit");
    var r = await _getRequest("/web/setting");
    if (r.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Nejdříve se musíte přihlásit");
    }
    var kreditMatch = double.tryParse(
        RegExp(r' +<span id="Kredit" .+?>(.+?)(?=&)').firstMatch(r)!.group(1)!.replaceAll(",", ".").replaceAll(RegExp(r"[^\w.-]"), ""));
    var jmenoMatch = RegExp(r'(?<=jméno: <b>).+?(?=<\/b)').firstMatch(r);
    var prijmeniMatch = RegExp(r'(?<=příjmení: <b>).+?(?=<\/b)').firstMatch(r);
    var kategorieMatch = RegExp(r'(?<=kategorie: <b>).+?(?=<\/b)').firstMatch(r);
    var ucetMatch =
        RegExp(r'účet pro platby do jídelny:\s*<b>(\d+/\d+)</b>').firstMatch(r)?.group(1)?.replaceAll(RegExp(r'<\/?b>'), ''); //odstranit html tag <b>
    var varMatch = RegExp(r'(?<=variabilní symbol: <b>).+?(?=<\/b)').firstMatch(r);
    var specMatch = RegExp(r'(?<=specifický symbol: <b>).+?(?=<\/b)').firstMatch(r);

    var jmeno = jmenoMatch?.group(0) ?? "";
    var prijmeni = prijmeniMatch?.group(0) ?? "";
    var kategorie = kategorieMatch?.group(0) ?? "";
    var ucet = ucetMatch ?? "";
    var varSymbol = varMatch?.group(0) ?? "";
    var specSymbol = specMatch?.group(0) ?? "";
    var kredit = kreditMatch ?? 0.0;

    return Uzivatel(
        jmeno: jmeno, prijmeni: prijmeni, kategorie: kategorie, ucetProPlatby: ucet, varSymbol: varSymbol, specSymbol: specSymbol, kredit: kredit);
  }

  Future<void> _getFirstSession() async {
    var res = await http.get(Uri.parse('$url/faces/login.jsp'));
    _parseCookies(res.headers['set-cookie']!);
  }

  /// Převede cookie řetězec z požadavku do mapy
  void _parseCookies(String cookieString) {
    Map<String, String> cookies = this.cookies;
    var regCookie = RegExp(r'([A-Z\-]+=.+?(?=;))|(remember-me=.+?)(?=;)').allMatches(cookieString).toList();
    for (var cook in regCookie) {
      var c = cook.group(0).toString().split("=");
      cookies[c[0]] = c[1];
    }
  }

  /// Přihlášení do iCanteen
  ///
  /// Vstup:
  ///
  /// - `user` - uživatelské jméno | [String]
  /// - `password` - heslo | [String]
  ///
  /// Výstup:
  /// - [bool] ve [Future], v případě přihlášení `true`, v případě špatného hesla `false`
  @override
  Future<bool> login(String user, String password) async {
    if (cookies["JSESSIONID"] == "") {
      await _getFirstSession();
    }

    var res = await http.post(Uri.parse("$url/j_spring_security_check"), headers: {
      "Cookie": "JSESSIONID=${cookies["JSESSIONID"]!};",
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      "j_username": user,
      "j_password": password,
      "terminal": "false",
      "_spring_security_remember_me": "on",
      "targetUrl": "/faces/secured/main.jsp?terminal=false&status=true&printer=&keyboard="
    });

    if (res.headers['set-cookie']!.contains("remember-me=;")) {
      return false; // špatné heslo
    }

    if (res.statusCode != 302) {
      return Future.error("Chyba: ${res.body}");
    }
    _parseCookies(res.headers['set-cookie']!);

    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
  Future<String> _getRequest(String path) async {
    var r = await http.get(Uri.parse(url + path), headers: {
      "Cookie":
          "JSESSIONID=${cookies["JSESSIONID"]!}; ${cookies.containsKey("COOKIE") ? "SPRING_SECURITY_REMEMBER_ME_COOKIE=${cookies["COOKIE"]!};" : ""}",
    });

    if (r.statusCode != 200 || r.body.contains("fail") || r.body.contains("Chyba")) {
      return Future.error("Chyba: ${r.body}");
    }

    if (r.body.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error("Nejdříve se musíte přihlásit");
    }

    if (r.headers.containsKey("set-cookie")) {
      _parseCookies(r.headers["set-cookie"]!);
    }

    return r.body;
  }

  /// Získá jídelníček bez cen
  ///
  /// Výstup:
  /// - [List] s [Jidelnicek], který neobsahuje ceny
  ///
  /// __Lze použít bez přihlášení__
  @override
  Future<List<Jidelnicek>> ziskejJidelnicek() async {
    return []; //tato verze nemá jídelníček bez cen
  }

  /// Získá jídlo pro daný den
  ///
  /// __Vyžaduje přihlášení pomocí [login]__
  ///
  /// Vstup:
  /// - `den` - *volitelné*, určuje pro jaký den chceme získat jídelníček | [DateTime]
  ///
  /// Výstup:
  /// - [Jidelnicek] obsahující detaily, které vidí přihlášený uživatel
  @override
  Future<Jidelnicek> jidelnicekDen({DateTime? den}) async {
    if (!prihlasen) {
      return Future.error("Nejdříve se musíte přihlásit");
    }

    den ??= DateTime.now();

    String res;
    try {
      res = await _getRequest(
          "/faces/secured/main.jsp?day=${den.year}-${(den.month < 10) ? "0${den.month}" : den.month}-${(den.day < 10) ? "0${den.day}" : den.day}&terminal=false&printer=false&keyboard=false");
    } catch (e) {
      return Future.error(e);
    }
    //save response to file
    File("jidelnicek.html").writeAsStringSync(res);
    dom.Document document = parser.parse(res);
    late dom.Element jidelnicekData;
    try {
      jidelnicekData = document.getElementsByClassName("orderContent")[0];
    } catch (e) {
      return Future.error("Obědy nenalezeny");
    }

    List<Jidlo> jidla = <Jidlo>[];

    for (dom.Element obed in jidelnicekData.children[0].children) {
      // formátování do třídy
      String nazev = cleanString(obed.children[0].children[1].text);
      dom.Element tlacitko = obed.children[0].children[0].children[0];
      String objednavaciUrl = RegExp(r"'(.*?)'").firstMatch(tlacitko.attributes["onclick"]!.trim())!.group(1)!;
      print(objednavaciUrl);
      String textNaTlacitku = tlacitko.children[0].text.toLowerCase();
      String varianta = tlacitko.children[1].text.toLowerCase();
      double cena = double.parse(tlacitko.children[3].text.toLowerCase().replaceAll('kč', '').trim());
      bool objednano = textNaTlacitku.contains("zrušit");
      bool lzeObjednat = !textNaTlacitku.contains("nelze");
      print(objednano);
      jidla.add(
        Jidlo(
          nazev: nazev,
          objednano: objednano,
          varianta: varianta,
          lzeObjednat: lzeObjednat,
          cena: cena,
          orderUrl: objednavaciUrl,
          den: den,
          burzaUrl: null, //verze 2.10 nemá burzu
          naBurze: false, //verze 2.10 nemá burzu
          alergeny: <Alergen>[],
          kategorizovano: parseJidlo(nazev),
        ),
      );
      // KONEC formátování do třídy
    }

    return Jidelnicek(den, jidla);
  }

  /// Objedná vybrané jídlo
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme objednat | [Jidlo]
  ///
  /// Výstup:
  /// - Aktualizovaná instance [Jidlo] tohoto jídla
  @override
  Future<Jidlo> objednat(Jidlo j) async {
    if (!prihlasen) {
      return Future.error("Nejdříve se musíte přihlásit");
    }

    if (!j.lzeObjednat || j.orderUrl == null || j.orderUrl!.isEmpty) {
      return Future.error("Jídlo nelze objednat nebo nemá adresu pro objednání");
    }

    try {
      await _getRequest("/faces/secured/${j.orderUrl!}"); // provést operaci
    } catch (e) {
      return Future.error(e);
    }

    var novy = (await jidelnicekDen(den: j.den))
        .jidla
        .where(
          (element) => element.nazev == j.nazev,
        )
        .toList()[0];

    return novy; // vrátit novou instanci
  }

  /// Uloží vaše jídlo z/do burzy
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme dát/vzít do/z burzy | [Jidlo]
  ///
  /// Výstup:
  /// - Aktualizovaná instance [Jidlo] tohoto jídla NEBO [Future] jako chyba
  @override
  Future<Jidlo> doBurzy(Jidlo j, {int amount = 1}) async {
    return Future.error("Tato verze iCanteenu nemá burzu");
  }

  /// Získá aktuální jídla v burze
  ///
  /// Výstup:
  /// - List instancí [Burza], každá obsahuje informace o jídle v burze
  @override
  Future<List<Burza>> ziskatBurzu() async {
    return Future.error("Tato verze iCanteenu nemá burzu");
  }

  /// Objedná jídlo z burzy pomocí URL z instance třídy Burza
  ///
  /// Vstup:
  /// - `b` - Jídlo __z burzy__, které chceme objednat | [Burza]
  ///
  /// Výstup:
  /// - [bool], `true`, pokud bylo jídlo úspěšně objednáno z burzy, jinak `Exception`
  @override
  Future<bool> objednatZBurzy(Burza b) async {
    return Future.error("Tato verze iCanteenu nemá burzu");
  }
}
