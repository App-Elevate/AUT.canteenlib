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

import 'package:http/http.dart' as http;
import 'package:canteenlib/canteenlib.dart';

/// Reprezentuje kantýnu verze 2.10.27
///
/// **Všechny metody v případě chyby vrací [Future] s chybovou hláškou.**
class Canteen2v10v27 extends Canteen {
  /// icanteen v této verzi nemá uživatelské jméno
  String username = "";
  @override
  int vydejna = 1;

  bool firstRequest = false;

  @override
  get missingFeatures => <Features>[
        Features.alergeny,
        Features.burza,
        Features.jidelnicekBezCen,
        Features.burzaAmount,
        Features.jidelnicekMesic,
        Features.variabilniSymbol
      ];

  /// Sušenky potřebné pro komunikaci
  Map<String, String> cookies = {"JSESSIONID": ""};

  /// Je uživatel přihlášen?
  @override
  bool prihlasen = false;

  Canteen2v10v27(String url) : super(url);

  /// Vrátí informace o uživateli ve formě instance [Uzivatel]
  @override
  Future<Uzivatel> ziskejUzivatele() async {
    firstRequest = false;
    if (!prihlasen) return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    String r;
    try {
      r = await _getRequest("/faces/secured/setting.jsp?terminal=false&keyboard=false&printer=false");
    } catch (e) {
      return Future.error(e);
    }
    dom.Document document = parser.parse(r);
    List<dom.Element> elementList = document.getElementsByTagName("tbody");
    dom.Element? element;
    for (dom.Element e in elementList) {
      if (e.text.contains('Datum narození')) {
        element = e;
        break;
      }
    }
    //print(element!.innerHtml);
    if (element == null) return Future.error("nepodařilo se získat informace o uživateli - HTML PARSING ERROR");

    dom.Element jmenoElement = element.firstChild!.firstChild!.children[0].children[0].children[1];
    dom.Element kategorieElement = element.firstChild!.firstChild!.children[0].children[0].children[3];
    dom.Element? kreditElement = document.getElementById('Kredit');
    String kredit = kreditElement?.text ?? '0.0';
    kredit = kredit.split(' ')[0];
    /*
    dom.Element datumNarozeniElement = element.firstChild!.firstChild!.children[0].children[0].children[2];
    dom.Element tridaElement = element.firstChild!.firstChild!.children[0].children[0].children[4];
    dom.Element cislaElement = element.firstChild!.firstChild!.children[0].children[0].children[5];
    dom.Element omezeniElement = element.firstChild!.firstChild!.children[0].children[0].children[6];
    dom.Element kontaktniUdajeElement = element.firstChild!.children[1].children[0].children[0].children[1];
    dom.Element adresaElement = element.firstChild!.children[1].children[0].children[0].children[2];
    dom.Element telefonElement = element.firstChild!.children[1].children[0].children[0].children[3];
    dom.Element zakonnyZastupceElement = element.firstChild!.children[1].children[0].children[0].children[4];
    */

    dom.Element variabilniSymbolElement = element.children[1].children[0].children[0].children[0].children[1];
    dom.Element ucetProPlatbyElement = element.children[1].children[0].children[0].children[0].children[2];
    //dom.Element ucetProVraceniPreplatku = element.children[1].children[0].children[0].children[0].children[2];

    String? jmeno = jmenoElement.children[0].text;
    String? prijmeni = jmenoElement.children[1].text;
    String? kategorie = kategorieElement.children[0].text;
    String? ucetProPlatby = ucetProPlatbyElement.children[0].text;
    String? variabilniSymbol = variabilniSymbolElement.children[0].text;
    try {
      variabilniSymbol = variabilniSymbol.split(': ')[1].trim();
    } catch (e) {
      variabilniSymbol = null;
    }
    try {
      ucetProPlatby = ucetProPlatby.split(': ')[1].trim();
    } catch (e) {
      ucetProPlatby = null;
    }
    try {
      jmeno = jmeno.split(': ')[1].trim();
    } catch (e) {
      jmeno = null;
    }
    try {
      kategorie = kategorie.split(': ')[1].trim();
    } catch (e) {
      kategorie = null;
    }
    try {
      prijmeni = prijmeni.split(': ')[1].trim();
    } catch (e) {
      prijmeni = null;
    }

    return Uzivatel(
      jmeno: jmeno,
      prijmeni: prijmeni,
      kategorie: kategorie,
      ucetProPlatby: ucetProPlatby,
      varSymbol: variabilniSymbol,
      specSymbol: null, // not supported
      kredit: double.parse(kredit),
      uzivatelskeJmeno: username,
    );
  }

  Future<void> _getFirstSession() async {
    try {
      var res = await http.get(Uri.parse('$url/faces/login.jsp'));
      _parseCookies(res.headers['set-cookie']!);
    } catch (e) {
      return Future.error(CanteenLibExceptions.chybaSite);
    }
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
      try {
        await _getFirstSession();
      } catch (e) {
        return Future.error(e);
      }
    }
    http.Response res;
    try {
      res = await http.post(Uri.parse("$url/j_spring_security_check"), headers: {
        "Cookie": "JSESSIONID=${cookies["JSESSIONID"]!};",
        "Content-Type": "application/x-www-form-urlencoded",
      }, body: {
        "j_username": user,
        "j_password": password,
        "terminal": "false",
        "_spring_security_remember_me": "on",
        "targetUrl": "/faces/secured/main.jsp?terminal=false&status=true&printer=&keyboard="
      });
    } catch (e) {
      return Future.error(CanteenLibExceptions.chybaSite);
    }

    if (res.headers['set-cookie']!.contains("remember-me=;")) {
      return false; // špatné heslo
    }

    if (res.statusCode != 302) {
      return Future.error("Chyba: ${res.body}");
    }
    _parseCookies(res.headers['set-cookie']!);
    username = user;

    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
  Future<String> _getRequest(String path) async {
    http.Response r;
    try {
      r = await http.get(Uri.parse(url + path), headers: {
        "Cookie":
            "JSESSIONID=${cookies["JSESSIONID"]!}; ${cookies.containsKey("COOKIE") ? "SPRING_SECURITY_REMEMBER_ME_COOKIE=${cookies["COOKIE"]!};" : ""}",
      });
    } catch (e) {
      return Future.error(CanteenLibExceptions.chybaSite);
    }

    if (r.statusCode != 200 || r.body.contains("fail") || r.body.contains("Chyba")) {
      return Future.error("Chyba: ${r.body}");
    }

    if (r.body.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    }

    if (r.headers.containsKey("set-cookie")) {
      _parseCookies(r.headers["set-cookie"]!);
    }

    return r.body;
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
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    }
    if (!firstRequest && den != null) {
      DateTime den = DateTime.now();
      try {
        await _getRequest(
            "/faces/secured/main.jsp?day=${den.year}-${(den.month < 10) ? "0${den.month}" : den.month}-${(den.day < 10) ? "0${den.day}" : den.day}&terminal=false&printer=false&keyboard=false");
      } catch (e) {
        return Future.error(e);
      }
    }

    den ??= DateTime.now();

    String res;
    try {
      res = await _getRequest(
          "/faces/secured/main.jsp?vydejna=$vydejna&day=${den.year}-${(den.month < 10) ? "0${den.month}" : den.month}-${(den.day < 10) ? "0${den.day}" : den.day}&terminal=false&printer=false&keyboard=false");
    } catch (e) {
      return Future.error(e);
    }
    //save response to file
    dom.Document document = parser.parse(res);

    RegExp regex = RegExp(
        r'''onclick="javascript:location\.replace\('main\.jsp\?vydejna=(\d*)&amp;terminal=false&amp;keyboard=false&amp;printer=false'\);\"\/>\s*(.*)\<\/a\>''');

    Map<int, String> vydejny = {};
    Iterable<RegExpMatch> regExpMatch = regex.allMatches(res);
    for (RegExpMatch match in regExpMatch) {
      vydejny[int.parse(match.group(1)!)] = match.group(2)!;
    }

    late dom.Element jidelnicekData;
    try {
      jidelnicekData = document.getElementsByClassName("orderContent")[0];
    } catch (e) {
      return Future.error("Obědy nenalezeny - HTML PARSING ERROR");
    }

    List<Jidlo> jidla = <Jidlo>[];

    for (dom.Element obed in jidelnicekData.children[0].children) {
      // formátování do třídy
      try {
        String nazev = cleanString(obed.children[0].children[1].text);
        dom.Element tlacitko = obed.children[0].children[0].children[0];
        String objednavaciUrl = RegExp(r"'(.*?)'").firstMatch(tlacitko.attributes["onclick"]!.trim())!.group(1)!;
        String textNaTlacitku = tlacitko.children[0].text.toLowerCase();
        String varianta = tlacitko.children[1].text.toLowerCase();
        double cena = double.parse(tlacitko.children[3].text.toLowerCase().replaceAll('kč', '').trim());
        bool objednano = textNaTlacitku.contains("zrušit");
        bool lzeObjednat = !textNaTlacitku.contains("nelze");
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
          // KONEC formátování do třídy
        );
      } catch (e) {
        // jídlo chybí = není v nabídce v daný den
      }
    }

    return Jidelnicek(den, jidla, vydejny: vydejny);
  }

  /// Objedná vybrané jídlo
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme objednat | [Jidlo]
  ///
  /// Výstup:
  /// - Aktualizovaná instance [Jidlo] tohoto jídla
  @override
  Future<Jidelnicek> objednat(Jidlo j) async {
    if (!prihlasen) {
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    }

    if (!j.lzeObjednat || j.orderUrl == null || j.orderUrl!.isEmpty) {
      return Future.error(CanteenLibExceptions.jidloNelzeObjednat);
    }

    try {
      await _getRequest("/faces/secured/${j.orderUrl!}"); // provést operaci
    } catch (e) {
      if (isEnumItem(e, CanteenLibExceptions.values)) {
        return Future.error(e);
      }
      return Future.error(CanteenLibExceptions.chybaObjednani);
    }

    return jidelnicekDen(den: j.den);
  }
}
