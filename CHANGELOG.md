## 0.1.0-alpha.14
- Oprava `ziskejBurzu`, kvůli špatnému parsování
## 0.1.0-alpha.13
- Další opravy
- Úprava metod `doBurzy` a `objednat`, aby opravdu mohly vracet aktualizované instance `Jidlo`
## 0.1.0-alpha.12
- Skutečná oprava
## 0.1.0-alpha.11
- Opravit nevkládání URL pro jídlo co má uživatel již v burze
## 0.1.0-alpha.10
- Doufám, že skutečně opraví získávání URL
- Lepší formátování názvu
## 0.1.0-alpha.9
- Vzít změny zpět
## 0.1.0-alpha.8
- Opravit získávání URL z burzy v `jidelnicekDen`
- tridy.dart - Burza: ~~jidlo~~ --> __nazev__
## 0.1.0-alpha.7
- Nastavovat `prihlasen` na `false` v případě chyby i u `ziskejUzivatele`
- Vylepšení dokumentace
- `getFirstSession` je nyní soukromá metoda
[Všechny změny](https://github.com/hernikplays/canteenlib/compare/0.1.0-alpha.6...0.1.0-alpha.7)

## 0.1.0-alpha.6
- `return` místo `throw`
[Všechny změny](https://github.com/hernikplays/canteenlib/compare/0.1.0-alpha.5...0.1.0-alpha.6)

## 0.1.0-alpha.5
- Přechod z `Exception` na `Future.error`
[Všechny změny](https://github.com/hernikplays/canteenlib/compare/0.1.0-alpha.4...0.1.0-alpha.5)

## 0.1.0-alpha.4
- Přidáno získání a objednávání cizích jídel z burzy
- Třída `Jidlo`: ~~cislo~~ 👉 **varianta**
- Nová třída `Burza` pro cizí jídla z burzy
- Více Exceptionů

[Všechny změny](https://github.com/hernikplays/canteenlib/compare/0.1.0-alpha.3...0.1.0-alpha.4)

## 0.1.0-alpha.3
- Kontrolovat správný status kód u GET požadavků

[Všechny změny](https://github.com/hernikplays/canteenlib/compare/0.1.0-alpha.1...0.1.0-alpha.4)

## 0.1.0-alpha.2
- Nevytvářet debugovací soubor
- Místo ziskejKredit používáme ziskejUzivatele (Třída Uzivatel)
- Requesty by měly vyhazovat Exception při chybném požadavku (status kódu)
## 0.1.0-alpha.1
- Aktualizace licence

## 0.1.0-alpha

- Funkční přihlášení
- Funkční zobrazení jídelníčku
- Funkční objednávání jídel z jídelníčku
- Funkční zobrazení kreditu
