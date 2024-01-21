import 'dart:async';

import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

DotEnv? envSecrets;
Canteen? canteenInstance;
Jidelnicek? jidelnicek;
Jidelnicek? jidelnicekMesic;
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

Future<void> ziskatJidelnicekMesic() async {
  envSecrets ??= DotEnv(includePlatformEnvironment: true)..load();
  canteenInstance ??= Canteen(envSecrets!["URL"]!);
  List<Jidelnicek> jidelnickyProMesic = await canteenInstance!.jidelnicekMesic();
  for (Jidelnicek jidelnicek in jidelnickyProMesic) {
    if (jidelnicek.jidla.isNotEmpty) {
      jidelnicekMesic = jidelnicek;
      break;
    }
  }
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
      test('Jídelníček má více výdejen', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.viceVydejen)) return;
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.vydejny.length > 1, true);
      });
      test('Jídelníček není prázdný', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla.isNotEmpty, true);
      });

      test('Jídelníček má aspoň dva obědy', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla.length >= 2, true);
      });

      test('Jídelníček má název', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        print(jidelnicek!.jidla[0].nazev);
        expect(jidelnicek!.jidla[0].nazev.isNotEmpty, true);
      });

      test('Jídelníček má cenu', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla[0].cena! > 10, true);
      });

      test('Jídelníček má variantu', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla[0].varianta.isNotEmpty, true);
      });

      test('Jídelníček je kategorizovaný', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
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
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekDen)) return;
        if (canteenInstance!.missingFeatures.contains(Features.alergeny)) return;
        await ziskatJidelnicek();
        expect(jidelnicek!.jidla[0].alergeny.isNotEmpty, true);
      });
    });

    group('Jídelníček měsíc:', () {
      test('Jídelníček má více výdejen', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.viceVydejen)) return;
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.vydejny.length > 1, true);
      });
      test('Jídelníček není prázdný', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.jidla.isNotEmpty, true);
      });

      test('Jídelníček má aspoň jeden oběd', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.jidla.isNotEmpty, true);
      });

      test('Jídelníček má název', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        print(jidelnicekMesic!.jidla[0].nazev);
        expect(jidelnicekMesic!.jidla[0].nazev.isNotEmpty, true);
      });

      test('Jídelníček má cenu', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.jidla[0].cena! > 10, true);
      });

      test('Jídelníček má variantu', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.jidla[0].varianta.isNotEmpty, true);
      });

      test('Jídelníček je kategorizovaný', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        await ziskatJidelnicekMesic();
        print('--------------------Jídelníček--------------------');
        print('Jídlo: ${jidelnicekMesic!.jidla[0].nazev}');
        print('Hlavní jídlo: ${jidelnicekMesic!.jidla[0].kategorizovano!.hlavniJidlo}');
        print('pití: ${jidelnicekMesic!.jidla[0].kategorizovano!.piti}');
        print('polévka: ${jidelnicekMesic!.jidla[0].kategorizovano!.polevka}');
        print('Salátový bar: ${jidelnicekMesic!.jidla[0].kategorizovano!.salatovyBar}');
        print('ostatní: ${jidelnicekMesic!.jidla[0].kategorizovano!.ostatni}');
        print('--------------------------------------------------');
        expect(jidelnicekMesic!.jidla[0].kategorizovano!.hlavniJidlo!.isNotEmpty, true);
      });
      test('Jídelníček má alergeny', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.jidelnicekMesic)) return;
        if (canteenInstance!.missingFeatures.contains(Features.alergeny)) return;
        await ziskatJidelnicekMesic();
        expect(jidelnicekMesic!.jidla[0].alergeny.isNotEmpty, true);
      });
    });

    group('Uživatel', () {
      test('Uživatel má kredit', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect(uzivatel!.kredit > -10000 && uzivatel!.kredit < 10000, true);
      });

      test('Uživatel má jméno', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect(uzivatel!.jmeno!.isNotEmpty, true);
      });

      test('Uživatel má příjmení', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect(uzivatel!.prijmeni!.isNotEmpty, true);
      });

      test('Uživatel má účet pro platby', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect(uzivatel!.ucetProPlatby!.isNotEmpty, true);
      });

      test('Uživatel má variablilní nebo specifický symbol', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.variabilniSymbol)) return;
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect((uzivatel!.varSymbol ?? "").isNotEmpty || (uzivatel!.specSymbol ?? "").isNotEmpty, true);
      });
      test('Uživatel má uživatelské jméno', () async {
        await prihlasitSe();
        if (canteenInstance!.missingFeatures.contains(Features.ziskatUzivatele)) return;
        await ziskatUzivatele();
        expect((uzivatel?.uzivatelskeJmeno ?? "").isNotEmpty, true);
      });
    });
  });
}
