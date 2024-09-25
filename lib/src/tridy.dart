class JidloKategorizovano {
  String? polevka;
  String? hlavniJidlo;
  String? salatovyBar;
  String? piti;
  String? ostatni;

  JidloKategorizovano({
    this.polevka,
    this.hlavniJidlo,
    this.salatovyBar,
    this.piti,
    this.ostatni,
  });

  /// Převést na JSON
  Map<String, dynamic> toJson() => {
        'polevka': polevka,
        'hlavniJidlo': hlavniJidlo,
        'salatovyBar': salatovyBar,
        'piti': piti,
        'ostatni': ostatni,
      };

  /// Převést z JSON
  factory JidloKategorizovano.fromJson(Map<String, dynamic> json) => JidloKategorizovano(
        polevka: json['polevka'],
        hlavniJidlo: json['hlavniJidlo'],
        salatovyBar: json['salatovyBar'],
        piti: json['piti'],
        ostatni: json['ostatni'],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is JidloKategorizovano &&
        other.polevka == polevka &&
        other.hlavniJidlo == hlavniJidlo &&
        other.salatovyBar == salatovyBar &&
        other.piti == piti &&
        other.ostatni == ostatni;
  }

  @override
  int get hashCode => polevka.hashCode ^ hlavniJidlo.hashCode ^ salatovyBar.hashCode ^ piti.hashCode ^ ostatni.hashCode;
}

/// Reprezentuje jedno jídlo z jídelníčku
class Jidlo {
  /// Název jídla
  String nazev;

  /// Kategorizované jídlo
  JidloKategorizovano? kategorizovano;

  /// Objednal si uživatel toto jídlo?
  bool objednano;

  /// Název varianty
  String varianta;

  /// Cena
  double? cena;

  ///Lze objednat?
  bool lzeObjednat;

  /// Je jídlo aktuálně na burze?
  bool naBurze;

  /// Den, který je jídlo vydáváno
  DateTime den;

  /// Seznam alergenů
  ///
  /// Pokud se žádný nepodařilo najít, vrací prázdný seznam
  List<Alergen> alergeny;

  /// URL pro požadavek na objednání jídla
  final String? orderUrl;

  /// URL pro vložení jídla na burzu
  final String? burzaUrl;

  Jidlo({
    required this.nazev,
    this.kategorizovano,
    required this.objednano,
    required this.varianta,
    required this.den,
    this.alergeny = const [],
    this.cena,
    required this.lzeObjednat,
    this.orderUrl,
    this.burzaUrl,
    required this.naBurze,
  });

  /// Převést na JSON
  Map<String, dynamic> toJson() => {
        'nazev': nazev,
        'kategorizovano': kategorizovano?.toJson(), // Assuming JidloKategorizovano has toJson()
        'objednano': objednano,
        'varianta': varianta,
        'cena': cena,
        'lzeObjednat': lzeObjednat,
        'naBurze': naBurze,
        'den': den.toIso8601String(),
        'alergeny': alergeny.map((a) => a.toJson()).toList(), // Assuming Alergen has toJson()
        'orderUrl': orderUrl,
        'burzaUrl': burzaUrl,
      };

  /// Převést z JSON
  factory Jidlo.fromJson(Map<String, dynamic> json) => Jidlo(
        nazev: json['nazev'],
        kategorizovano: json['kategorizovano'] != null ? JidloKategorizovano.fromJson(json['kategorizovano']) : null,
        objednano: json['objednano'],
        varianta: json['varianta'],
        cena: json['cena'],
        lzeObjednat: json['lzeObjednat'],
        naBurze: json['naBurze'],
        den: DateTime.parse(json['den']),
        alergeny: (json['alergeny'] as List).map((a) => Alergen.fromJson(a)).toList(), // Assuming Alergen has fromJson()
        orderUrl: json['orderUrl'],
        burzaUrl: json['burzaUrl'],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Jidlo &&
        other.nazev == nazev &&
        other.kategorizovano == kategorizovano &&
        other.objednano == objednano &&
        other.varianta == varianta &&
        other.cena == cena &&
        other.lzeObjednat == lzeObjednat &&
        other.naBurze == naBurze &&
        other.den == den &&
        _porovnatAlergenyList(other.alergeny, alergeny) &&
        other.orderUrl == orderUrl &&
        other.burzaUrl == burzaUrl;
  }

  bool _porovnatAlergenyList(List<Alergen> list1, List<Alergen> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      nazev.hashCode ^
      kategorizovano.hashCode ^
      objednano.hashCode ^
      varianta.hashCode ^
      cena.hashCode ^
      lzeObjednat.hashCode ^
      naBurze.hashCode ^
      den.hashCode ^
      _generovatAlergenyListHashCode(alergeny) ^
      orderUrl.hashCode ^
      burzaUrl.hashCode;

  // Generuje hashcode pro List<Alergen>
  int _generovatAlergenyListHashCode(List<Alergen> list) {
    return list.fold(0, (prev, element) => prev ^ element.hashCode);
  }
}

/// Popisuje alergen v jídelníčku
class Alergen {
  final int? kod;
  final String nazev;
  final String? popis;

  const Alergen({
    this.kod,
    required this.nazev,
    this.popis,
  });

  /// Převést na JSON
  Map<String, dynamic> toJson() => {
        'kod': kod,
        'nazev': nazev,
        'popis': popis,
      };

  /// Převést z JSON
  factory Alergen.fromJson(Map<String, dynamic> json) => Alergen(
        kod: json['kod'],
        nazev: json['nazev'],
        popis: json['popis'],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Alergen && other.kod == kod && other.nazev == nazev && other.popis == popis;
  }

  @override
  int get hashCode => kod.hashCode ^ nazev.hashCode ^ popis.hashCode;
}

enum Features {
  /// zda má test očekávat vícero výdejen
  viceVydejen,

  /// zda má test očekávat variabilní/specifický symbol
  variabilniSymbol,

  /// Získat informace o přihlášeném uživateli
  ziskatUzivatele,

  /// Získat informace o jídelníčku zvěřejněném na webu bez nutnosti přihlášení
  jidelnicekBezCen,

  /// Získat informace o jídelníčku zvěřejněném na webu s nutností přihlášení + objednání obědů
  jidelnicekDen,

  // Informace o jídelníčku za měsíc
  jidelnicekMesic,

  /// burza
  burza,

  // dát počet jídel na burzu
  burzaAmount,

  /// alergeny
  alergeny,
}

/// Reprezentuje cizí jídlo na burze
class Burza {
  /// Den, který je jídlo vydáváno
  DateTime den;

  /// URL pro objednání
  final String? url;

  /// Název jídla
  String nazev;

  /// Varianta
  String? varianta;

  /// Počet kusů tohoto jídla dostupného na burze
  int pocet;

  Burza({
    required this.den,
    required this.url,
    required this.nazev,
    required this.pocet,
    this.varianta,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Burza && other.den == den && other.url == url && other.nazev == nazev && other.varianta == varianta && other.pocet == pocet;
  }

  @override
  int get hashCode => den.hashCode ^ url.hashCode ^ nazev.hashCode ^ varianta.hashCode ^ pocet.hashCode;
}

/// Reprezentuje jídelníček pro jeden den
class Jidelnicek {
  /// Den, pro který je jídelníček zveřejněn
  DateTime den;

  /// Seznam jídel
  List<Jidlo> jidla;

  // Seznam výdejen (je prázdný, pokud je pouze jedna)
  Map<int, String> vydejny;

  Jidelnicek(
    this.den,
    this.jidla, {
    this.vydejny = const {},
  });

  /// Převést na JSON
  Map<String, dynamic> toJson() => {
        'den': den.toIso8601String(),
        'jidla': jidla.map((j) => j.toJson()).toList(),
        'vydejny': vydejny,
      };

  /// Převést z JSON
  factory Jidelnicek.fromJson(Map<String, dynamic> json) => Jidelnicek(
        DateTime.parse(json['den']),
        (json['jidla'] as List).map((j) => Jidlo.fromJson(j)).toList(),
        vydejny: Map<int, String>.from(json['vydejny']),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Jidelnicek && other.den == den && _porovnatJidlaList(other.jidla, jidla) && _porovnatVydejnyMap(other.vydejny, vydejny);
  }

  bool _porovnatJidlaList(List<Jidlo> list1, List<Jidlo> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _porovnatVydejnyMap(Map<int, String> map1, Map<int, String> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => den.hashCode ^ _generovatListHashCode(jidla) ^ _generovatMapHashCode(vydejny);

  int _generovatListHashCode(List<Jidlo> list) {
    return list.fold(0, (prev, element) => prev ^ element.hashCode);
  }

  int _generovatMapHashCode(Map<int, String> map) {
    return map.entries.fold(0, (prev, entry) => prev ^ entry.key.hashCode ^ entry.value.hashCode);
  }
}

/// Reprezentuje informace o přihlášeném uživateli
class Uzivatel {
  /// Uživatelské jméno
  String? uzivatelskeJmeno;

  /// Jméno, jak je uvedené v základních údajích o uživateli
  String? jmeno;

  /// Příjmení, jak je uvedené v základních údajích o uživateli
  String? prijmeni;

  /// Kategorie uživatele
  String? kategorie;

  /// Účet jídelny pro zasílání plateb
  String? ucetProPlatby;

  /// Variabilní symbol
  String? varSymbol;

  /// Specifický symbol
  String? specSymbol;

  /// Aktuální stav kreditu
  double kredit;

  Uzivatel({
    this.uzivatelskeJmeno,
    this.jmeno,
    this.prijmeni,
    this.kategorie,
    this.ucetProPlatby,
    this.varSymbol,
    this.kredit = 0.0,
    this.specSymbol,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Uzivatel &&
        other.uzivatelskeJmeno == uzivatelskeJmeno &&
        other.jmeno == jmeno &&
        other.prijmeni == prijmeni &&
        other.kategorie == kategorie &&
        other.ucetProPlatby == ucetProPlatby &&
        other.varSymbol == varSymbol &&
        other.kredit == kredit &&
        other.specSymbol == specSymbol;
  }

  @override
  int get hashCode =>
      uzivatelskeJmeno.hashCode ^
      jmeno.hashCode ^
      prijmeni.hashCode ^
      kategorie.hashCode ^
      ucetProPlatby.hashCode ^
      varSymbol.hashCode ^
      kredit.hashCode ^
      specSymbol.hashCode;
}

class LoginData {
  final String username;
  final String password;

  LoginData(
    this.username,
    this.password,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginData && other.username == username && other.password == password;
  }

  @override
  int get hashCode => username.hashCode ^ password.hashCode;
}
