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
import 'package:canteenlib/canteenlib.dart';
import 'package:http/http.dart' as http;

/*  SUPPORT INFO

Tato verze je testována a podporována na webu jidelna.trebesin.cz.
není garantováno, že bude fungovat na jiných stránkách.

*/
/// Reprezentuje kantýnu verze **2.18.03**
///
/// **Všechny metody v případě chyby vrací [Future] s chybovou hláškou.**
class Canteen2v18v03 extends Canteen {
  /// icanteen je v této verzi buglý, takže je potřeba si uživatelské jméno pamatovat
  String username = "";

  @override
  get missingFeatures => <Features>[Features.burzaAmount, Features.viceVydejen];

  /// Sušenky potřebné pro komunikaci
  Map<String, String> cookies = {"JSESSIONID": "", "XSRF-TOKEN": ""};

  /// Je uživatel přihlášen?
  @override
  bool prihlasen = false;
  Canteen2v18v03(String url) : super(url);

  /// Vrátí informace o uživateli ve formě instance [Uzivatel]
  @override
  Future<Uzivatel> ziskejUzivatele() async {
    if (!prihlasen) return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    String r;
    try {
      r = await _getRequest("/web/setting");
    } catch (e) {
      return Future.error(CanteenLibExceptions.chybaSite);
    }
    // save r to file
    if (r.contains("přihlášení uživatele")) {
      prihlasen = false;
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
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
        jmeno: jmeno,
        prijmeni: prijmeni,
        kategorie: kategorie,
        ucetProPlatby: ucet,
        varSymbol: varSymbol,
        specSymbol: specSymbol,
        kredit: kredit,
        uzivatelskeJmeno: username);
  }

  Future<void> _getFirstSession() async {
    if (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    } // odstranit lomítko
    http.Response res;
    try {
      res = await http.get(Uri.parse(url));
    } catch (e) {
      return Future.error(CanteenLibExceptions.chybaSite);
    }
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
    username = user;
    if (cookies["JSESSIONID"] == "" || cookies["XSRF-TOKEN"] == "") {
      try {
        await _getFirstSession();
      } catch (e) {
        return Future.error(CanteenLibExceptions.chybaSite);
      }
    }
    http.Response res;
    try {
      res = await http.post(Uri.parse("$url/j_spring_security_check"), headers: {
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

    prihlasen = true;
    return true;
  }

  /// Builder pro GET request
  Future<String> _getRequest(String path) async {
    http.Response r;
    try {
      r = await http.get(Uri.parse(url + path), headers: {
        "Cookie":
            "JSESSIONID=${cookies["JSESSIONID"]!}; XSRF-TOKEN=${cookies["XSRF-TOKEN"]!}${cookies.containsKey("remember-me") ? "; ${cookies["remember-me"]!}" : ""}",
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

  /// Získá jídelníček bez cen
  ///
  /// Výstup:
  /// - [List] s [Jidelnicek], který neobsahuje ceny
  ///
  /// __Lze použít bez přihlášení__
  @override
  Future<List<Jidelnicek>> ziskejJidelnicek() async {
    String res;
    try {
      res = await _getRequest("/");
    } catch (e) {
      return Future.error(e);
    }
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

  Jidlo _parsePrihlasenyJidlo(RegExpMatch obed) {
    // formátování do třídy
    var o = obed.group(0).toString().replaceAll(RegExp(r'(   )+|([^>a-z]\n)'), '');
    var objednano = o.contains("Máte objednáno");
    var lzeObjednat = !(o.contains("nelze zrušit") || o.contains("nelze objednat") || o.contains("nelze změnit"));
    var obedDen = DateTime.parse(RegExp(r'(?<=day-).+?(?=")', dotAll: true).firstMatch(o)!.group(0).toString());

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
      var match = RegExp(r"""db\/dbProcessOrder\.jsp.+?type=((plusburza)|(minusburza)).+?(?=')""").firstMatch(o);
      if (match != null) {
        burzaUrl = match.group(0)!.replaceAll("amp;", "");
      }
    }
    var alergenyDetailMatch = RegExp(r'<span  title="(.*?)\s*class="').allMatches(jidlaProDen).toList();

    jidlaProDen = parseHtmlString(jidlaProDen);
    jidlaProDen = cleanString(jidlaProDen);
    String nazevjidla = jidlaProDen;
    List<Alergen> alergenyList = [];

    if (jidlaProDen.contains('(')) {
      nazevjidla = jidlaProDen.split('(')[0].trim();
      String alergeny = jidlaProDen.split('(')[1].trim();
      alergeny = alergeny.replaceAll(')', '');
      List<String> alergenyListRaw = alergeny.split(', ');
      int mensiDelka = alergenyListRaw.length < alergenyDetailMatch.length ? alergenyListRaw.length : alergenyDetailMatch.length;
      for (int i = 0; i < mensiDelka; i++) {
        alergenyList.add(Alergen(nazev: alergenyListRaw[i], popis: alergenyDetailMatch[i].group(1)));
      }
    }

    return Jidlo(
        nazev: nazevjidla,
        objednano: objednano,
        varianta: vydejna,
        lzeObjednat: lzeObjednat,
        cena: cena,
        orderUrl: orderUrl,
        den: obedDen,
        burzaUrl: burzaUrl,
        naBurze: (burzaUrl == null) ? false : !burzaUrl.contains("plusburza"),
        alergeny: alergenyList,
        kategorizovano: parseJidlo(nazevjidla));
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

  /// Získá jídlo do konce měsíce od aktuálního dne
  ///
  /// __Vyžaduje přihlášení pomocí [login]__
  ///
  /// Výstup:
  /// - list instancí [Jidelnicek] obsahující detaily, které vidí přihlášený uživatel
  @override
  Future<List<Jidelnicek>> jidelnicekMesic() async {
    if (!prihlasen) {
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    }
    String res;
    try {
      DateTime den = DateTime.now();
      // replikování komunikace s prohlížečem, v opačném případě nefunguje
      await _getRequest(
          "/faces/secured/main.jsp?day=${den.year}-${(den.month < 10) ? "0${den.month}" : den.month}-${(den.day < 10) ? "0${den.day}" : den.day}&terminal=false&printer=false&keyboard=false");
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
      if (isEnumItem(e, CanteenLibExceptions.values)) return Future.error(e);
      return Future.error(CanteenLibExceptions.chybaObjednani);
    }
    return jidelnicekDen(den: j.den);
  }

  /// Uloží vaše jídlo z/do burzy
  ///
  /// Vstup:
  /// - `j` - Jídlo, které chceme dát/vzít do/z burzy | [Jidlo]
  ///
  /// Výstup:
  /// - Aktualizovaná instance [Jidlo] tohoto jídla NEBO [Future] jako chyba
  /// TODO: amount not implemented
  @override
  Future<Jidelnicek> doBurzy(Jidlo j, {int? amount}) async {
    if (!prihlasen) {
      return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    }

    if (j.burzaUrl == null || j.burzaUrl!.isEmpty) {
      return Future.error(CanteenLibExceptions.jidloNelzeObjednat);
    }

    try {
      await _getRequest("/faces/secured/${j.burzaUrl!}"); // provést operaci
    } catch (e) {
      if (isEnumItem(e, CanteenLibExceptions.values)) return Future.error(e);
      return Future.error(CanteenLibExceptions.chybaObjednani);
    }

    return jidelnicekDen(den: j.den);
  }

  /// Získá aktuální jídla v burze
  ///
  /// Výstup:
  /// - List instancí [Burza], každá obsahuje informace o jídle v burze
  @override
  Future<List<Burza>> ziskatBurzu() async {
    if (!prihlasen) return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
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
  Future<Jidelnicek> objednatZBurzy(Burza b) async {
    if (!prihlasen) return Future.error(CanteenLibExceptions.jePotrebaSePrihlasit);
    try {
      await _getRequest("/faces/secured/${b.url!}");
    } catch (e) {
      if (isEnumItem(e, CanteenLibExceptions.values)) return Future.error(e);
      return Future.error(CanteenLibExceptions.chybaObjednani);
    }
    return jidelnicekDen(den: b.den);
  }
}
