import 'dart:async';

import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

DotEnv? envSecrets;
Canteen? canteenInstance;
Jidelnicek? jidelnicek;
Uzivatel? uzivatel;
Future<void> ziskatUzivatele() async {
  envSecrets ??= DotEnv(includePlatformEnvironment: true)..load();
  canteenInstance ??= Canteen(envSecrets!["URL"]!);
  uzivatel ??= await canteenInstance!.ziskejUzivatele();
}

Future<void> ziskatJidelnicek() async {
  envSecrets ??= DotEnv(includePlatformEnvironment: true)..load();
  canteenInstance ??= Canteen(envSecrets!["URL"]!);
  DateTime funkcniDatum = DateTime(2023, 11, 22);
  jidelnicek ??= await canteenInstance!.jidelnicekDen(den: funkcniDatum);
}

Future<bool> prihlasitSe() async {
  envSecrets ??= DotEnv(includePlatformEnvironment: true)..load();
  canteenInstance ??= Canteen(envSecrets!["URL"]!);
  if (canteenInstance!.prihlasen) return true;
  return await canteenInstance!.login(envSecrets!["USER"]!, envSecrets!["PASS"]!);
}

void main() {
  group('Test přihlášený Uživatel:', () {
    test('Přihlášení', () async {
      expect(await prihlasitSe(), true);
    });

    group('Jídelníček:', () {
      if ((canteenInstance?.missingFeatures ?? List<Features>.empty()).contains(Features.jidelnicekDen)) return;
      test('Jídelníček není prázdný', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla.isNotEmpty, true);
      });

      test('Jídelníček má aspoň dva obědy', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla.length >= 2, true);
      });

      test('Jídelníček má název', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        print(jidelnicek!.jidla[0].nazev);
        expect(jidelnicek!.jidla[0].nazev.isNotEmpty, true);
      });

      test('Jídelníček má cenu', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla[0].cena! > 10, true);
      });

      test('Jídelníček má variantu', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla[0].varianta.isNotEmpty, true);
      });

      test('Jídelníček je kategorizovaný', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        print('--------------------Jídelníček--------------------');
        print('Jídlo: ${jidelnicek!.jidla[0].nazev}');
        print('Hlavní jídlo: ${jidelnicek!.jidla[0].kategorizovano!.hlavniJidlo}');
        print('pití: ${jidelnicek!.jidla[0].kategorizovano!.piti}');
        print('polévka: ${jidelnicek!.jidla[0].kategorizovano!.polevka}');
        print('Salátový bar: ${jidelnicek!.jidla[0].kategorizovano!.salatovyBar}');
        print('ostatní: ${jidelnicek!.jidla[0].kategorizovano!.ostatni}');
        print('--------------------------------------------------');
        expect(jidelnicek!.jidla[0].kategorizovano!.hlavniJidlo!.isNotEmpty, true);
      });
      test('Jídelníček má alergeny', () async {
        await prihlasitSe();
        await ziskatJidelnicek();
        if (canteenInstance!.missingFeatures.contains(Features.alergeny)) {
          expect(true, true);
          return;
        }
        expect(jidelnicek!.jidla[0].alergeny.isNotEmpty, true);
      });
    });

    group('Uživatel', () {
      if ((canteenInstance?.missingFeatures ?? List<Features>.empty()).contains(Features.ziskatUzivatele)) return;
      test('Uživatel má kredit', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect(uzivatel!.kredit > -10000 && uzivatel!.kredit < 10000, true);
      });

      test('Uživatel má jméno', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect(uzivatel!.jmeno!.isNotEmpty, true);
      });

      test('Uživatel má příjmení', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect(uzivatel!.prijmeni!.isNotEmpty, true);
      });

      test('Uživatel má účet pro platby', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect(uzivatel!.ucetProPlatby!.isNotEmpty, true);
      });

      test('Uživatel má variablilní nebo specifický symbol', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect((uzivatel!.varSymbol ?? "").isNotEmpty || (uzivatel!.specSymbol ?? "").isNotEmpty, true);
      });
      test('Uživatel má uživatelské jméno', () async {
        await prihlasitSe();
        await ziskatUzivatele();
        expect((uzivatel?.uzivatelskeJmeno ?? "").isNotEmpty, true);
      });
    });
  });
}
