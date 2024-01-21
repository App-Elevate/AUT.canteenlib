bool isEnumItem(e, List enumValues) {
  return enumValues.contains(e);
}

enum CanteenLibExceptions {
  /// nepodporovanaFunkce,
  featureNepodporovana,

  /// je potřeba se přihlásit před použitím funkcí, které potřebují přihlášení
  jePotrebaSePrihlasit,

  /// neplatné url nebo server neodpovídá (nikdy není chybou v canteenlib, je to čistý get request)
  neplatneUrl,

  /// verze není zatím podporována a zdá se, že ani přes experimentální podporu nebude fungovat
  nepodporovanaVerze,

  /// chyba sítě (např. timeout). Rozdíl od neplatneUrl je ten, že tato chyba má větší pravděpodobnost, že je špatný internet
  chybaSite,

  /// Jídlo nelze objednat nebo nemá adresu pro objednání
  jidloNelzeObjednat,

  /// Chyba při objednání jídla (např. byla jídelna právě uzavřena, nebo jídlo už není v nabídce na burze apod.)
  chybaObjednani,

  /// Nelze do burzy vložit méně než jeden kus jídla
  meneNezJedenKus
}
