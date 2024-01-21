/*
 MIT License

Copyright (c) 2022-2023 Matyáš Caras, Tomáš Protiva and contributors

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
/*
  testováno na webu http://obedy.zs-mat5.cz/
*/

import 'package:canteenlib/canteenlib.dart';
import 'package:http/http.dart' as http;

/// Reprezentuje kantýnu verze 2.18.19
///
/// **Všechny metody v případě chyby vrací [Future] s chybovou hláškou.**
class Canteen2v18v19 extends Canteen {
  /// Sušenky potřebné pro komunikaci
  Map<String, String> cookies = {"JSESSIONID": "", "XSRF-TOKEN": ""};

  @override
  get missingFeatures => <Features>[Features.burzaAmount, Features.viceVydejen];

  /// Je uživatel přihlášen?
  @override
  bool prihlasen = false;
  Canteen2v18v19(String url) : super(url);

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
    var uzivatelskeJmenoMatch = RegExp(r'title="Přihlašovací jméno:\s*(.*?)">').firstMatch(r);
    var jmenoMatch = RegExp(r'(?<=jméno: <b>).+?(?=<\/b)').firstMatch(r);
    var prijmeniMatch = RegExp(r'(?<=příjmení: <b>).+?(?=<\/b)').firstMatch(r);
    var kategorieMatch = RegExp(r'(?<=kategorie: <b>).+?(?=<\/b)').firstMatch(r);
    var ucetMatch = RegExp(r'účet pro platby do jídelny:\s*<b>(\d*-*\d+\/?\d*)<\/b>')
        .firstMatch(r)
        ?.group(1)
        ?.replaceAll(RegExp(r'<\/?b>'), ''); //odstranit html tag <b>
    var varMatch = RegExp(r'(?<=variabilní symbol: <b>).+?(?=<\/b)').firstMatch(r);
    var specMatch = RegExp(r'(?<=specifický symbol: <b>).+?(?=<\/b)').firstMatch(r);

    var uzivatelskeJmeno = uzivatelskeJmenoMatch?.group(1)?.substring(0, uzivatelskeJmenoMatch.group(1)?.indexOf('"')) ?? "";
    var jmeno = jmenoMatch?.group(0) ?? "";
    var prijmeni = prijmeniMatch?.group(0) ?? "";
    var kategorie = kategorieMatch?.group(0) ?? "";
    var ucet = ucetMatch ?? "";
    var varSymbol = varMatch?.group(0) ?? "";
    var specSymbol = specMatch?.group(0) ?? "";
    var kredit = kreditMatch ?? 0.0;

    return Uzivatel(
        jmeno: jmeno,
        prijmeni: prijmeni,
        kategorie: kategorie,
        ucetProPlatby: ucet,
        varSymbol: varSymbol,
        specSymbol: specSymbol,
        kredit: kredit,
        uzivatelskeJmeno: uzivatelskeJmeno);
  }

  Future<void> _getFirstSession() async {
    if (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    } // odstranit lomítko
    var res = await http.get(Uri.parse(url));
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
    if (cookies["JSESSIONID"] == "" || cookies["XSRF-TOKEN"] == "") {
      await _getFirstSession();
    }

    var res = await http.post(Uri.parse("$url/j_spring_security_check"), headers: {
      "Cookie": "JSESSIONID=${cookies["JSESSIONID"]!}; XSRF-TOKEN=${cookies["XSRF-TOKEN"]!};",
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      "j_username": user,
      "j_password": password,
      "terminal": "false",
      "_csrf": cookies["XSRF-TOKEN"],
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
          "JSESSIONID=${cookies["JSESSIONID"]!}; XSRF-TOKEN=${cookies["XSRF-TOKEN"]!}${cookies.containsKey("remember-me") ? "; ${cookies["remember-me"]!};" : ";"}",
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
    var res = await _getRequest("/");
    var reg = RegExp(r'((?=<div class="jidelnicekDen">).+?(?=<div class="jidelnicekDen">))|((?=<div class="jidelnicekDen">).*<\/span>)', dotAll: true)
        .allMatches(res)
        .toList();

    List<Jidelnicek> jidelnicek = [];

    for (var t in reg) {
      // projedeme každý den individuálně
      var j = t.group(0).toString(); // převedeme text na něco přehlednějšího
      var den = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true).firstMatch(j)!.group(0).toString());
      var jidlaDenne = RegExp(r'(?=<div class="container">).+?<\/div>.+?(?=<\/div>)', dotAll: true)
          .allMatches(j)
          .toList(); // získáme jednotlivá jídla pro den / VERZE 2.18
      if (jidlaDenne.isEmpty) {
        jidlaDenne = RegExp(r'(?=<div style="padding: 2 0 2 20">).+?(?=<\/div>)', dotAll: true)
            .allMatches(j)
            .toList(); // získáme jednotlivá jídla pro den / VERZE 2.10
      }

      List<Jidlo> jidla = [];

      for (var jidloNaDen in jidlaDenne) {
        // projedeme vsechna jidla
        var s = jidloNaDen
            .group(0)!
            .replaceAll(RegExp(r'[a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:]  [a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:]'), ''); // odstraní dvojté mezery mezi písmeny

        var vydejna = RegExp(r'(?<=<span style="color: #1b75bb;">).+?(?=<)').firstMatch(s); // název výdejny / verze 2.18
        vydejna ??= RegExp(r'(?<=<span class="smallBoldTitle" style="color: #1b75bb;">).+?(?=<)').firstMatch(s); // název výdejny / verze 2.10

        var hlavni = RegExp(r' {20}(([a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:\/]+ )+[a-zA-ZěščřžýáíéÉÍÁÝŽŘČŠĚŤŇťň.,:\/]+)', dotAll: true)
            .firstMatch(s)!
            .group(1)
            .toString(); // Jídlo

        jidla.add(Jidlo(nazev: hlavni, objednano: false, varianta: vydejna!.group(0).toString(), lzeObjednat: false, den: den, naBurze: false));
      }
      jidelnicek.add(Jidelnicek(den, jidla));
    }
    return jidelnicek;
  }

  /// Získá jídlo do konce měsíce od aktuálního dne
  ///
  /// __Vyžaduje přihlášení pomocí [login]__
  ///
  /// Výstup:
  /// - list instancí [Jidelnicek] obsahující detaily, které vidí přihlášený uživatel
  @override
  Future<List<Jidelnicek>> jidelnicekMesic() async {
    if (!prihlasen) {
      return Future.error("Nejdříve se musíte přihlásit");
    }
    String res;
    try {
      await jidelnicekDen(); // replikování komunikace probíhající s prohlížečem, jinak nevrátí informace o obědech...
      res = await _getRequest("/faces/secured/month.jsp");
    } catch (e) {
      return Future.error(e);
    }
    var jidla = <Jidlo>[];
    var jidelnicek = RegExp(r'(?<=<div class="jidWrapLeft">).+?((fa-clock)|(fa-ban))', dotAll: true).allMatches(res).toList();
    for (var obed in jidelnicek) {
      jidla.add(_parsePrihlasenyJidlo(obed));
    }
    Map<DateTime, List<Jidlo>> jidlaMap = {};
    for (var jidlo in jidla) {
      if (jidlaMap.containsKey(jidlo.den)) {
        jidlaMap[jidlo.den]!.add(jidlo);
      } else {
        jidlaMap[jidlo.den] = [jidlo];
      }
    }
    List<Jidelnicek> jidelnicekList = [];
    for (var jidelnicek in jidlaMap.values) {
      jidelnicekList.add(Jidelnicek(jidelnicek[0].den, jidelnicek));
    }
    return jidelnicekList;
  }

  Jidlo _parsePrihlasenyJidlo(obed) {
    // formátování do třídy
    var o = obed.group(0).toString().replaceAll(RegExp(r'(   )+|([^>a-z]\n)'), '');
    var objednano = o.contains("Máte objednáno");
    var obedDen = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true).firstMatch(o)!.group(0).toString());
    var lzeObjednat = !(o.contains("nelze zrušit") || o.contains("nelze objednat") || o.contains("nelze změnit"));

    var cenaMatch = RegExp(r'((?<=Cena objednaného jídla">).+?(?=&))').firstMatch(o);
    cenaMatch ??= RegExp(r'(?<=Cena při objednání jídla:&nbsp;).+?(?=&)').firstMatch(o);
    cenaMatch ??= RegExp(r'(?<=Cena při objednání jídla">).+?(?=&)').firstMatch(o);

    var cena = double.parse(cenaMatch!.group(0).toString().replaceAll(",", "."));
    var jidlaProDen = RegExp(r'<div class="jidWrapCenter.+?>(.+?)(?=<\/div>)', dotAll: true)
        .firstMatch(o)!
        .group(1)
        .toString()
        .replaceAll(' ,', ",")
        .replaceAll(" <br>", "")
        .replaceAll("\n", "");
    var alergenyList = RegExp(r'(<span\s*title=.*?<\/span>)').allMatches(jidlaProDen).toList();
    var alergeny = alergenyList.map<Alergen>((e) {
      var jmeno = RegExp(r'<b>(.+?)<\/b>').firstMatch(e.group(1).toString())!.group(1);
      var popis = RegExp(r'<\/b> - (.+)').firstMatch(e.group(1).toString())?.group(1);
      var kod = RegExp(r'class="textGrey">(\d+?),?\s?').firstMatch(e.group(1).toString())?.group(1);
      return Alergen(nazev: jmeno!, kod: kod == null ? null : int.parse(kod), popis: popis);
    }).toList();

    var vydejna = RegExp(r'(?<=<span class="smallBoldTitle button-link-align">).+?(?=<)').firstMatch(o)!.group(0).toString();

    String? orderUrl;
    String? burzaUrl;
    if (lzeObjednat) {
      // pokud lze objednat, nastavíme adresu pro objednání
      var match = RegExp(r"(?<=ajaxOrder\(this, ').+?(?=')").firstMatch(o);
      if (match != null) {
        orderUrl = match.group(0)!.replaceAll("amp;", "");
      }
    } else {
      // jinak nastavíme URL pro burzu
      var match = RegExp(r"""db\/dbProcessOrder\.jsp.+?type=((plusburza)|(minusburza)|(multiburza)).+?(?=')""").firstMatch(o);
      if (match != null) {
        burzaUrl = match.group(0)!.replaceAll("amp;", "");
      }
    }
    var jidloJmeno = jidlaProDen.split('<sub>')[0];
    jidloJmeno = cleanString(jidloJmeno);
    return Jidlo(
      nazev: jidloJmeno.replaceAll(r' (?=[^a-zA-ZěščřžýáíéĚŠČŘŽÝÁÍÉŤŇťň])', ''),
      objednano: objednano,
      varianta: vydejna,
      lzeObjednat: lzeObjednat,
      cena: cena,
      orderUrl: orderUrl,
      den: obedDen,
      burzaUrl: burzaUrl,
      naBurze: (burzaUrl == null) ? false : burzaUrl.contains("minusburza"),
      alergeny: alergeny,
      kategorizovano: parseJidlo(jidloJmeno),
    );
    // KONEC formátování do třídy
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

    var jidla = <Jidlo>[];
    var jidelnicek = RegExp(r'(?<=<div class="jidWrapLeft">).+?((fa-clock)|(fa-ban))', dotAll: true).allMatches(res).toList();
    for (var obed in jidelnicek) {
      jidla.add(_parsePrihlasenyJidlo(obed));
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
  Future<Jidelnicek> objednat(Jidlo j) async {
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

    var novy = await jidelnicekDen(den: j.den);

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
    if (!prihlasen) {
      return Future.error("Nejdříve se musíte přihlásit");
    }

    if (j.burzaUrl == null || j.burzaUrl!.isEmpty) {
      return Future.error("Jídlo nelze uložit do burzy nebo nemá adresu pro uložení");
    }

    if (amount < 1 && j.burzaUrl!.endsWith("amount=")) {
      return Future.error("Nemůžeš dát do burzy méně než jeden kus");
    }
    var finalUrl = (j.burzaUrl!.endsWith("amount=")) ? "${j.burzaUrl}$amount" : j.burzaUrl;
    try {
      await _getRequest("/faces/secured/$finalUrl"); // provést operaci
    } catch (e) {
      return Future.error(e);
    }

    var novy = (await jidelnicekDen(den: j.den))
        .jidla
        .where(
          (element) => element.nazev == j.nazev,
        )
        .toList()[0];

    return novy; // vrátit upravenou instanci
  }

  /// Získá aktuální jídla v burze
  ///
  /// Výstup:
  /// - List instancí [Burza], každá obsahuje informace o jídle v burze
  @override
  Future<List<Burza>> ziskatBurzu() async {
    if (!prihlasen) return Future.error("Nejdříve se musíte přihlásit");
    List<Burza> burza = [];

    String res;
    try {
      res = await _getRequest("/faces/secured/burza.jsp");
    } catch (e) {
      return Future.error(e);
    }

    var dostupnaJidla = RegExp(r'(?<=<tr class="mouseOutRow">).+?(?=<\/tr>)', dotAll: true).allMatches(res); // vyfiltrujeme jednotlivá jídla
    if (dostupnaJidla.isNotEmpty) {
      for (var burzaMatch in dostupnaJidla) {
        var bu = burzaMatch.group(0)!;
        var data =
            RegExp(r'((?<=<td>).+?(?=<))|(?<=<td align="left">).+?(?=<)|((?<=<td align="right">).+?(?=<))', dotAll: true).allMatches(bu).toList();

        // Získat datum
        var datumRaw = RegExp(r'\d\d\.\d\d\.\d{4}').firstMatch(data[1].group(0)!)!.group(0)!.split(".");
        var datum = DateTime.parse("${datumRaw[2]}-${datumRaw[1]}-${datumRaw[0]}");
        // Získat variantu
        var varianta = data[0].group(0)!;
        // Získat název jídla
        var nazev = data[2].group(0)!.replaceAll(RegExp(r'\n|  '), "");
        // Získat počet kusů
        var pocet = int.parse(data[4].group(0)!.replaceAll(" ks", ""));
        var url = RegExp(r"(?<=')db.+?(?=')").firstMatch(bu)!.group(0)!.replaceAll("&amp;", "&");

        var jidlo = Burza(den: datum, varianta: varianta, nazev: nazev, pocet: pocet, url: url);
        burza.add(jidlo);
      }
    }
    return burza;
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
    if (!prihlasen) return Future.error("Nejdříve se musíte přihlásit");
    try {
      await _getRequest("/faces/secured/${b.url!}");
    } catch (e) {
      return Future.error(e.toString());
    }
    return true;
  }
}
