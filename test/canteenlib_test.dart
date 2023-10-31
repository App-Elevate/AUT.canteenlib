import 'package:canteenlib/canteenlib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

//TODO: vylepšit testy
void main() {
  group('A group of tests', () {
    var envSecrets = DotEnv(includePlatformEnvironment: true)..load();
    Canteen canteenInstance = Canteen(envSecrets["URL"]!);

    test('Log-in test', () {
      canteenInstance.login(envSecrets["USER"]!, envSecrets["PASS"]!).then((r) => expect(r, true));
    });

    test('First Test', () {
      canteenInstance.login(envSecrets["USER"]!, envSecrets["PASS"]!).then((r) {
        canteenInstance.jidelnicekDen().then((jidelnicek) {
          expect(DateTime.now().day, jidelnicek.den.day);
        });
      });
    });

    test('Neprázdný jídelníček', () {
      canteenInstance.login(envSecrets["USER"]!, envSecrets["PASS"]!).then((_) {
        canteenInstance.jidelnicekDen(den: DateTime.now().add(Duration(days: 5))).then((jidelnicek) {
          print(jidelnicek.jidla[0].nazev);
          expect(jidelnicek.jidla[0].nazev.isNotEmpty, true);
        });
      });
    });
  });
}
